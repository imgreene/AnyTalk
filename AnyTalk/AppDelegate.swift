import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem!
    var popover: NSPopover!
    var contentView: ContentView!
    var hotKeyService: HotKeyService!
    var isRecording = false
    var recordingStartTime: Date?
    
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
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusBarItem.button {
            button.image = NSImage(systemSymbolName: "mic.fill", accessibilityDescription: "AnyTalk")
            button.action = #selector(togglePopover)
        }
        
        // Setup menu
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Open AnyTalk", action: #selector(openPopover), keyEquivalent: "o"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Start Dictation", action: #selector(startDictation), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Stop Dictation", action: #selector(stopDictation), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
        
        statusBarItem.menu = menu
    }
    
    func setupHotKey() {
        hotKeyService = HotKeyService(
            startDictationCallback: { [weak self] in
                self?.startDictation()
            },
            stopDictationCallback: { [weak self] in
                self?.stopDictation()
            }
        )
        hotKeyService.registerDefaultHotKey()
        
        // Debug output
        let settings = SettingsManager.shared
        print("Initial hotkey setup - modifiers: \(settings.hotkeyModifiers), keyCode: \(settings.hotkeyKeyCode)")
    }
    
    // MARK: - Actions
    
    @objc func togglePopover() {
        if let button = statusBarItem.button {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                NSApp.activate(ignoringOtherApps: true)
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                popover.contentViewController?.view.window?.makeKey()
            }
        }
    }
    
    @objc func openPopover() {
        if !popover.isShown {
            if let button = statusBarItem.button {
                NSApp.activate(ignoringOtherApps: true)
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                popover.contentViewController?.view.window?.makeKey()
            }
        }
    }
    
    func updateMenuBarIcon() {
        if let button = statusBarItem.button {
            // Always use the same mic.fill icon, but change its color when recording
            let icon = NSImage(systemSymbolName: "mic.fill", accessibilityDescription: "AnyTalk")
            button.image = icon
            
            // Change the tint color based on recording state
            if isRecording {
                button.contentTintColor = NSColor.systemOrange
            } else {
                button.contentTintColor = nil
            }
            
            // Enable/disable menu items based on recording state
            if let menu = statusBarItem.menu {
                if let startItem = menu.item(withTitle: "Start Dictation"), let stopItem = menu.item(withTitle: "Stop Dictation") {
                    startItem.isEnabled = !isRecording
                    stopItem.isEnabled = isRecording
                }
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
        
        // Check if recording was too short (less than 0.5 second)
        if let startTime = recordingStartTime, Date().timeIntervalSince(startTime) < 0.5 {
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
            
            // Clear clipboard to prevent any accidental pasting
            NSPasteboard.general.clearContents()
            
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
            
            // Transcribe the audio
            WhisperService.shared.transcribe(audioURL: url) { result in
                switch result {
                case .success(let transcription):
                    // Check if transcription has valid content
                    if self?.isValidTranscription(transcription) == false {
                        print("Transcription content invalid, ignoring: \(transcription)")
                        
                        // Show notification that transcription was ignored
                        let notification = NSUserNotification()
                        notification.title = "Transcription Ignored"
                        notification.informativeText = "No valid speech detected"
                        NSUserNotificationCenter.default.deliver(notification)
                        
                        return
                    }
                    
                    // Save to history
                    HistoryManager.shared.addEntry(text: transcription)
                    
                    // Copy to clipboard
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(transcription, forType: .string)
                    
                    // Type the text at the current cursor position
                    self?.pasteTextAtCursor(transcription)
                    
                    // Play sound to indicate completion
                    NSSound(named: "Glass")?.play()
                    
                    // Show notification
                    let notification = NSUserNotification()
                    notification.title = "Transcription Complete"
                    notification.informativeText = "Text inserted at cursor position"
                    NSUserNotificationCenter.default.deliver(notification)
                    
                    // Update UI if needed
                    DispatchQueue.main.async {
                        self?.contentView.updateForNewTranscription()
                    }
                    
                case .failure(let error):
                    print("Transcription error: \(error)")
                    // Show error notification
                    let notification = NSUserNotification()
                    notification.title = "Transcription Failed"
                    notification.informativeText = error.localizedDescription
                    NSUserNotificationCenter.default.deliver(notification)
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
        // Get the frontmost application
        if let frontmostApp = NSWorkspace.shared.frontmostApplication {
            // Activate the frontmost application
            NSRunningApplication.current.activate(options: [])
            frontmostApp.activate(options: .activateIgnoringOtherApps)
            
            // Wait a moment for the app to activate
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                // Create a paste event
                let pasteCommand = CGEvent(keyboardEventSource: nil, virtualKey: 0x09, keyDown: true) // 0x09 is 'v'
                pasteCommand?.flags = .maskCommand // Command key
                
                // Post the paste event
                pasteCommand?.post(tap: .cghidEventTap)
                pasteCommand?.type = .keyUp
                pasteCommand?.post(tap: .cghidEventTap)
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