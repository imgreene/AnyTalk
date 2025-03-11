
import Foundation
import SwiftUI
import AppKit
import Cocoa

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
            button.image = NSImage(systemSymbolName: "mic.fill", accessibilityDescription: "AnyTalk")
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
            let icon = NSImage(systemSymbolName: "mic.fill", accessibilityDescription: "AnyTalk")
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
        
        // Save the original clipboard content
        let pasteboard = NSPasteboard.general
        let originalContent = pasteboard.string(forType: .string)
        
        // Stop recording and process audio
        AudioRecorderService.shared.stopRecording { [weak self] url in
            guard let url = url else { return }
            
            // Transcribe the audio
            WhisperService.shared.transcribe(audioURL: url) { result in
                switch result {
                case .success(let transcription):
                    // Save to history with duration
                    HistoryManager.shared.addEntry(text: transcription, duration: recordingDuration)
                    
                    // Save the original clipboard content
                    let pasteboard = NSPasteboard.general
                    let originalContent = pasteboard.string(forType: .string)
                    
                    // Type the text at the current cursor position
                    self?.pasteTextAtCursor(transcription)
                    
                    // Play sound to indicate completion only if sounds are enabled
                    if SettingsManager.shared.playSounds {
                        NSSound(named: "Glass")?.play()
                    }
                    
                    // Show notification
                    let notification = NSUserNotification()
                    notification.title = "Transcription Complete"
                    notification.informativeText = "Text inserted at cursor position"
                    NSUserNotificationCenter.default.deliver(notification)
                    
                    // Restore the original clipboard content after a longer delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        if let originalContent = originalContent {
                            pasteboard.clearContents()
                            pasteboard.setString(originalContent, forType: .string)
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
                    if let originalContent = originalContent {
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
        // Create a pasteboard instance
        let pasteboard = NSPasteboard.general
        
        // Prepare the text with smart space handling
        let trimmedText = text.trimmingCharacters(in: .whitespaces)
        let textToInsert = trimmedText + " " // Add space at the end instead of beginning
        
        // Set our transcribed text
        pasteboard.clearContents()
        pasteboard.setString(textToInsert, forType: .string)
        
        // Create and post the paste event
        if let source = CGEventSource(stateID: .combinedSessionState) {
            // Command down
            let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: true)
            cmdDown?.flags = .maskCommand
            
            // V down/up
            let vDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
            vDown?.flags = .maskCommand
            let vUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
            vUp?.flags = .maskCommand
            
            // Command up
            let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: false)
            
            // Post all events in sequence
            [cmdDown, vDown, vUp, cmdUp].forEach { event in
                event?.post(tap: .cgAnnotatedSessionEventTap)
                usleep(1000) // 1ms delay
            }
        }
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
} 
