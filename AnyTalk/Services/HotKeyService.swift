import Cocoa
import Carbon

class HotKeyService {
    private var startDictationCallback: () -> Void
    private var stopDictationCallback: () -> Void
    private var eventHandler: EventHandlerRef?
    private var hotKeyID = EventHotKeyID()
    private var hotKeyRef: EventHotKeyRef?
    private var modifierMonitorEventHandler: Any?
    private var lastModifierPressTime: Date?
    private var modifierOnlyHotkey = false
    private var isHotkeyPressed = false
    
    init(startDictationCallback: @escaping () -> Void, stopDictationCallback: @escaping () -> Void) {
        self.startDictationCallback = startDictationCallback
        self.stopDictationCallback = stopDictationCallback
        
        // Set up notification for hotkey changes
        NotificationCenter.default.addObserver(self, 
                                              selector: #selector(hotkeyChanged), 
                                              name: Notification.Name("HotkeyChanged"), 
                                              object: nil)
    }
    
    deinit {
        unregisterHotKey()
        if let modifierMonitorEventHandler = modifierMonitorEventHandler {
            NSEvent.removeMonitor(modifierMonitorEventHandler)
        }
        NotificationCenter.default.removeObserver(self)
    }
    
    func registerDefaultHotKey() {
        let settings = SettingsManager.shared
        let modifiers = UInt32(settings.hotkeyModifiers)
        let keyCode = UInt32(settings.hotkeyKeyCode)
        
        registerHotKey(modifiers: modifiers, keyCode: keyCode)
    }
    
    private func registerHotKey(modifiers: UInt32, keyCode: UInt32) {
        // Unregister any existing hotkey
        unregisterHotKey()
        
        // Debug output
        print("Registering hotkey with modifiers: \(modifiers), keyCode: \(keyCode)")
        
        if modifiers == 0 {
            // If no modifiers, set up modifier-only hotkey monitoring
            setupModifierOnlyHotkey(modifiers: modifiers)
            return
        }
        
        // Create a unique ID
        hotKeyID = EventHotKeyID(signature: OSType(fourCharCodeFrom("AnyT")), id: 1)
        
        // Register the callback
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), 
                          { (_, _, _) -> OSStatus in
                            DispatchQueue.main.async {
                                NotificationCenter.default.post(name: Notification.Name("HotKeyPressed"), object: nil)
                            }
                            return noErr
                        }, 
                          1, 
                          &eventType, 
                          nil, 
                          &eventHandler)
        
        // Register the hotkey
        let status = RegisterEventHotKey(keyCode, 
                                       modifiers, 
                                       hotKeyID, 
                                       GetApplicationEventTarget(), 
                                       0, 
                                       &hotKeyRef)
        
        if status != noErr {
            print("Failed to register hotkey: \(status)")
            // If registration fails, try setting up modifier-only hotkey
            setupModifierOnlyHotkey(modifiers: modifiers)
        } else {
            print("Successfully registered hotkey")
            
            // Listen for hotkey press
            NotificationCenter.default.addObserver(self, 
                                                 selector: #selector(hotKeyPressed), 
                                                 name: Notification.Name("HotKeyPressed"), 
                                                 object: nil)
        }
    }
    
    private func setupModifierOnlyHotkey(modifiers: UInt32) {
        // Remove any existing monitor
        if let modifierMonitorEventHandler = modifierMonitorEventHandler {
            NSEvent.removeMonitor(modifierMonitorEventHandler)
            self.modifierMonitorEventHandler = nil
        }
        
        // Create a flag set from the modifiers
        let requiredFlags = NSEvent.ModifierFlags(rawValue: UInt(modifiers))
        print("Setting up modifier-only hotkey with flags: \(requiredFlags.rawValue)")
        
        // Set up a global event monitor for flagsChanged events
        modifierMonitorEventHandler = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            guard let self = self else { return }
            
            let currentFlags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            
            // Check if the current flags exactly match our required flags
            if currentFlags == requiredFlags && requiredFlags.rawValue > 0 {
                // If hotkey is not already pressed, start dictation
                if !self.isHotkeyPressed {
                    self.isHotkeyPressed = true
                    print("Modifier hotkey pressed - starting dictation")
                    
                    // Trigger the start callback
                    DispatchQueue.main.async {
                        self.startDictationCallback()
                    }
                }
            } else if self.isHotkeyPressed {
                // If hotkey was pressed but now released, stop dictation
                self.isHotkeyPressed = false
                print("Modifier hotkey released - stopping dictation")
                
                // Trigger the stop callback
                DispatchQueue.main.async {
                    self.stopDictationCallback()
                }
            }
        }
    }
    
    private func unregisterHotKey() {
        // Unregister standard hotkey if exists
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        
        // Remove the handler
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
        
        // Remove modifier-only monitor if exists
        if let modifierMonitorEventHandler = modifierMonitorEventHandler {
            NSEvent.removeMonitor(modifierMonitorEventHandler)
            self.modifierMonitorEventHandler = nil
        }
        
        // Reset modifier-only state
        modifierOnlyHotkey = false
        lastModifierPressTime = nil
        isHotkeyPressed = false
    }
    
    @objc private func hotKeyPressed() {
        print("Hotkey pressed event received")
        // Execute the callback on the main thread
        DispatchQueue.main.async {
            self.startDictationCallback()
        }
    }
    
    @objc private func hotkeyChanged() {
        let settings = SettingsManager.shared
        let modifiers = UInt32(settings.hotkeyModifiers)
        let keyCode = UInt32(settings.hotkeyKeyCode)
        
        print("Hotkey changed notification received: modifiers=\(modifiers), keyCode=\(keyCode)")
        registerHotKey(modifiers: modifiers, keyCode: keyCode)
    }
}

// Helper function to convert a four-character string to OSType
func fourCharCodeFrom(_ string: String) -> UInt32 {
    var result: UInt32 = 0
    let chars = Array(string.utf8)
    for i in 0..<min(chars.count, 4) {
        result = result << 8 + UInt32(chars[i])
    }
    return result
} 