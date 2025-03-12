
import Foundation
import SwiftUI
import AppKit
import Cocoa
import Carbon
import ServiceManagement
import AVFoundation
import ApplicationServices

// Remove the @_exported import line since GPTService is in the same module

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var isRecording = false
    private var recordingStartTime: Date?
    private var contentView: ContentView?
    private var hotKeyService: HotKeyService?
    
    // Notification observer for recording state changes
    private var recordingStateObserver: NSObjectProtocol?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupPopover()
        setupMenuBar()
        setupHotKey()
        
        // Ensure recording state is synced with settings
        isRecording = SettingsManager.shared.isRecording
        updateMenuBarIcon()
        
        // Listen for recording state changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(recordingStateChanged),
            name: Notification.Name("RecordingStateChanged"),
            object: nil
        )
    }
    
    func setupPopover() {
        let contentView = ContentView()
        self.contentView = contentView
        
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 480)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: contentView)
        self.popover = popover
    }
    
    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "microphone.and.signal.meter.fill", accessibilityDescription: "AnyTalk")
            button.action = #selector(togglePopover)
        }
        
        // Setup menu
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Open AnyTalk", action: #selector(openPopover), keyEquivalent: "o"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    func setupHotKey() {
        hotKeyService = HotKeyService(
            startDictationCallback: { [weak self] in
                // Check if toggle mode is enabled
                if SettingsManager.shared.isToggleMode {
                    // In toggle mode, we toggle the recording state
                    if self?.isRecording == true {
                        self?.stopDictation()
                    } else {
                        self?.startDictation()
                    }
                } else {
                    // In press-and-hold mode, just start recording
                    self?.startDictation()
                }
            },
            stopDictationCallback: { [weak self] in
                // Only stop recording in press-and-hold mode
                if !SettingsManager.shared.isToggleMode {
                    self?.stopDictation()
                }
            }
        )
        
        // Safely call registerDefaultHotKey
        hotKeyService?.registerDefaultHotKey()
        
        // Debug output
        let settings = SettingsManager.shared
        print("Initial hotkey setup - modifiers: \(settings.hotkeyModifiers), keyCode: \(settings.hotkeyKeyCode)")
    }
    
    // MARK: - Actions
    
    @objc func togglePopover() {
        if let button = statusItem?.button {
            if let popover = popover {
                if popover.isShown {
                    popover.performClose(nil)
                } else {
                    NSApp.activate(ignoringOtherApps: true)
                    popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                    popover.contentViewController?.view.window?.makeKey()
                }
            }
        }
    }
    
    @objc func openPopover() {
        if let popover = popover, !popover.isShown {
            if let button = statusItem?.button {
                NSApp.activate(ignoringOtherApps: true)
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                popover.contentViewController?.view.window?.makeKey()
            }
        }
    }
    
    func updateMenuBarIcon() {
        if let button = statusItem?.button {
            let icon = NSImage(systemSymbolName: "microphone.and.signal.meter.fill", accessibilityDescription: "AnyTalk")
            button.image = icon
            
            if isRecording {
                button.contentTintColor = NSColor.systemOrange
            } else {
                button.contentTintColor = nil
            }
            
            // Enable/disable menu items based on recording state
            if let menu = statusItem?.menu,
               let startItem = menu.item(withTitle: "Start Dictation"),
               let stopItem = menu.item(withTitle: "Stop Dictation") {
                startItem.isEnabled = !isRecording
                stopItem.isEnabled = isRecording
            }
        }
    }
    
    @objc func recordingStateChanged() {
        // Update our local state from settings
        isRecording = SettingsManager.shared.isRecording
        updateMenuBarIcon()
    }
    
    @objc func startDictation() {
        if isRecording {
            return // Already recording
        }
        
        print("Starting dictation")
        
        // Set recording state
        isRecording = true
        SettingsManager.shared.isRecording = true
        recordingStartTime = Date()
        
        // Update menubar icon to reflect recording state
        updateMenuBarIcon()
        
        // Show notification that recording has started
        let notification = NSUserNotification()
        notification.title = "Recording Started"
        notification.informativeText = "AnyTalk is now recording audio (hold hotkey to continue)"
        NSUserNotificationCenter.default.deliver(notification)
        
        // Start recording
        AudioRecorderService.shared.startRecording()
    }
    
    @objc func stopDictation() {
        if !isRecording {
            return // Not recording
        }
        
        print("Stopping dictation")
        
        // Calculate recording duration
        let recordingDuration = recordingStartTime.map { Date().timeIntervalSince($0) } ?? 0
        
        // Check if recording was too short (less than 0.5 second)
        if recordingDuration < 0.5 {
            print("Recording too short, cancelling")
            
            // Reset recording state
            isRecording = false
            SettingsManager.shared.isRecording = false
            updateMenuBarIcon()
            
            // Stop recording without processing
            AudioRecorderService.shared.cancelRecording()
            
            // Show notification that recording was too short
            let notification = NSUserNotification()
            notification.title = "Recording Too Short"
            notification.informativeText = "Recording was too short and has been cancelled."
            NSUserNotificationCenter.default.deliver(notification)
            
            return
        }
        
        // Set recording state
        isRecording = false
        SettingsManager.shared.isRecording = false
        
        // Update menubar icon to reflect recording state
        updateMenuBarIcon()
        
        // Stop recording and process audio
        AudioRecorderService.shared.stopRecording { [weak self] url in
            guard let url = url else { return }
            
            // 1. Save original clipboard content
            let pasteboard = NSPasteboard.general
            let originalClipboardContent = pasteboard.string(forType: .string)
            
            // 2. Clear clipboard completely
            pasteboard.clearContents()
            
            // 3. Simulate Command+C to try to copy any selected text
            let source = CGEventSource(stateID: .combinedSessionState)
            let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: true)
            let cDown = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: true)
            let cUp = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: false)
            let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: false)
            
            cmdDown?.flags = .maskCommand
            cDown?.flags = .maskCommand
            cUp?.flags = .maskCommand
            
            [cmdDown, cDown, cUp, cmdUp].forEach { $0?.post(tap: .cghidEventTap) }
            
            // Wait a brief moment for the copy operation to complete
            usleep(50000) // 0.05 seconds
            
            // 4. Check if anything was actually selected
            let selectedText = pasteboard.string(forType: .string)
            let hasSelectedText = selectedText != nil && !selectedText!.isEmpty
            
            // Transcribe the audio with Whisper
            WhisperService.shared.transcribe(audioURL: url) { result in
                switch result {
                case .success(let transcription):
                    // Save to history with duration
                    HistoryManager.shared.addEntry(text: transcription, duration: recordingDuration)
                    
                    if !hasSelectedText {
                        // NO SELECTED TEXT: Just paste transcription directly without GPT
                        print("Direct paste mode - no text selected")
                        
                        // Set transcription to clipboard and paste it
                        pasteboard.clearContents()
                        pasteboard.setString(transcription, forType: .string)
                        self?.pasteTextAtCursor(transcription)
                        
                        // Restore original clipboard content
                        if let originalContent = originalClipboardContent {
                            pasteboard.clearContents()
                            pasteboard.setString(originalContent, forType: .string)
                        }
                        
                        // Play completion sound if enabled
                        if SettingsManager.shared.playSounds {
                            NSSound(named: "Glass")?.play()
                        }
                        return  // Exit early - no GPT processing needed
                    }
                    
                    // SELECTED TEXT: Process with GPT
                    Task {
                        do {
                            print("Processing selected text: '\(selectedText ?? "")'")
                            print("With transcription: '\(transcription)'")
                            
                            let gptResult = try await GPTService.shared.processWithGPT(
                                selectedText: selectedText ?? "",
                                userTranscription: transcription
                            )
                            
                            let textToPaste = gptResult == "false" ? transcription : gptResult
                            
                            // Set the text to paste to clipboard before pasting
                            pasteboard.clearContents()
                            pasteboard.setString(textToPaste, forType: .string)
                            self?.pasteTextAtCursor(textToPaste)
                            
                            // Restore original clipboard content after paste
                            if let originalContent = originalClipboardContent {
                                pasteboard.clearContents()
                                pasteboard.setString(originalContent, forType: .string)
                            }
                            
                            if SettingsManager.shared.playSounds {
                                NSSound(named: "Glass")?.play()
                            }
                        } catch {
                            print("GPT processing error: \(error)")
                            
                            // Set transcription to clipboard before pasting
                            pasteboard.clearContents()
                            pasteboard.setString(transcription, forType: .string)
                            self?.pasteTextAtCursor(transcription)
                            
                            // Restore original clipboard content after paste
                            if let originalContent = originalClipboardContent {
                                pasteboard.clearContents()
                                pasteboard.setString(originalContent, forType: .string)
                            }
                        }
                    }
                    
                case .failure(let error):
                    print("Transcription error: \(error)")
                    // Show error notification
                    let notification = NSUserNotification()
                    notification.title = "Transcription Failed"
                    notification.informativeText = error.localizedDescription
                    NSUserNotificationCenter.default.deliver(notification)
                    
                    // Restore the original clipboard content
                    if let originalContent = originalClipboardContent {
                        pasteboard.clearContents()
                        pasteboard.setString(originalContent, forType: .string)
                    }
                }
            }
        }
    }
    
    @objc func toggleDictation() {
        if isRecording {
            stopDictation()
        } else {
            startDictation()
        }
    }
    
    private func pasteTextAtCursor(_ text: String) {
        print("Attempting to paste text: '\(text)'")
        
        // Create event source once and reuse
        guard let source = CGEventSource(stateID: .combinedSessionState) else { return }
        
        // Prepare text once
        let textToInsert = text.trimmingCharacters(in: .whitespaces) + " "
        
        // Use dispatch group to ensure synchronization
        let pasteGroup = DispatchGroup()
        pasteGroup.enter()
        
        DispatchQueue.global(qos: .userInteractive).async {
            print("Setting clipboard content to: '\(textToInsert)'")
            
            // Atomic clipboard operation
            NSPasteboard.general.prepareForNewContents(with: .currentHostOnly)
            NSPasteboard.general.setString(textToInsert, forType: .string)
            
            // Verify clipboard content
            let clipboardContent = NSPasteboard.general.string(forType: .string)
            print("Clipboard content before paste: '\(clipboardContent ?? "nil")'")
            
            // Pre-create all events with proper flags
            let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: true)
            let vDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
            let vUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
            let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: false)
            
            // Configure events
            cmdDown?.flags = .maskCommand
            vDown?.flags = .maskCommand
            vUp?.flags = .maskCommand
            
            // Post events in tight sequence if all events were created successfully
            if let cmdDown = cmdDown,
               let vDown = vDown,
               let vUp = vUp,
               let cmdUp = cmdUp {
                
                [cmdDown, vDown, vUp, cmdUp].forEach { event in
                    event.post(tap: .cghidEventTap)
                    usleep(1000) // Slight delay (1ms) to ensure events are processed in order
                }
            }
            
            // Verify paste completed
            usleep(10000) // Wait 10ms
            print("Paste operation completed")
            
            pasteGroup.leave()
        }
        
        // Wait for paste completion with timeout
        _ = pasteGroup.wait(timeout: .now() + 0.1)
    }
    
    private func isValidTranscription(_ text: String) -> Bool {
        // If empty or just whitespace, it's not valid
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        
        // Get the user's preferred language
        let preferredLanguage = SettingsManager.shared.preferredLanguage
        
        // For Chinese, Japanese, Korean - use different validation
        if ["zh", "ja", "ko"].contains(preferredLanguage) {
            // For these languages, we should validate differently since they use non-Latin characters
            // Just check if the string has some content and is not just punctuation or whitespace
            return trimmed.count > 1
        }
        
        // For other languages (mainly using Latin script)
        // Check if the text contains mostly non-Latin characters
        let latinCharacterSet = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.,?! -'\"")
        
        let latinCharCount = trimmed.unicodeScalars.filter { latinCharacterSet.contains($0) }.count
        let totalCharCount = trimmed.count
        
        // If less than 30% of characters are Latin/common for Latin-based languages, consider it invalid
        return latinCharCount > 0 && Double(latinCharCount) / Double(totalCharCount) >= 0.3
    }
    
    @objc func quitApp() {
        NSApp.terminate(nil)
    }
    
    func checkAccessibilityPermissions() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        if !accessEnabled {
            // Show alert to guide user
            let alert = NSAlert()
            alert.messageText = "Accessibility Access Required"
            alert.informativeText = "AnyTalk needs accessibility permissions to paste text. Please grant access in System Settings → Privacy & Security → Accessibility."
            alert.addButton(withTitle: "Open System Settings")
            alert.addButton(withTitle: "Later")
            
            if alert.runModal() == .alertFirstButtonReturn {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }
    
    func setupApp() {
        setupPopover()
        setupMenuBar()
        checkAccessibilityPermissions()
        setupHotKey()
        
        // Ensure recording state is synced with settings
        isRecording = SettingsManager.shared.isRecording
        updateMenuBarIcon()
        
        // Listen for recording state changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(recordingStateChanged),
            name: Notification.Name("RecordingStateChanged"),
            object: nil
        )
    }
}
