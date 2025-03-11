import Foundation
import SwiftUI
import ServiceManagement

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    private let defaults = UserDefaults.standard
    private let hotkeyModifiersKey = "hotkeyModifiers"
    private let hotkeyKeyCodeKey = "hotkeyKeyCode"
    private let selectedMicrophoneKey = "selectedMicrophone"
    private let launchAtLoginKey = "launchAtLogin"
    private let apiKeyKey = "apiKey"
    private let isRecordingKey = "isRecording"
    private let preferredLanguageKey = "preferredLanguage"
    private let isToggleModeKey = "isToggleMode"
    private let playSoundsKey = "playSounds"
    
    // Default values
    private let defaultHotkeyModifiers: UInt = NSEvent.ModifierFlags.command.rawValue | NSEvent.ModifierFlags.option.rawValue
    private let defaultKeyCode: UInt16 = 7 // X key
    private let defaultLanguage = "en" // English
    
    @Published var isRecording = false {
        didSet {
            defaults.set(isRecording, forKey: isRecordingKey)
            
            // Post notification for UI updates
            NotificationCenter.default.post(name: Notification.Name("RecordingStateChanged"), object: nil)
        }
    }
    @Published var launchAtLogin: Bool = false
    @Published var hotkeyModifiers: UInt = 0
    @Published var hotkeyKeyCode: UInt16 = 0
    @Published var selectedMicrophone: String?
    @Published private(set) var apiKey: String = ""
    @Published var preferredLanguage: String = "en"
    @Published var isToggleMode: Bool = false {
        didSet {
            defaults.set(isToggleMode, forKey: isToggleModeKey)
        }
    }
    @Published var playSounds: Bool = true {
        didSet {
            defaults.set(playSounds, forKey: playSoundsKey)
        }
    }
    
    // Available languages (code, name) for selection
    let availableLanguages = [
        "en": "English",
        "es": "Spanish",
        "fr": "French",
        "de": "German",
        "it": "Italian",
        "pt": "Portuguese",
        "nl": "Dutch",
        "ru": "Russian",
        "ja": "Japanese",
        "ko": "Korean",
        "zh": "Chinese"
    ]
    
    var hotkeyDescription: String {
        var description = ""
        
        let modFlags = NSEvent.ModifierFlags(rawValue: hotkeyModifiers)
        
        if modFlags.contains(.command) {
            description += "⌘"
        }
        if modFlags.contains(.option) {
            description += "⌥"
        }
        if modFlags.contains(.control) {
            description += "⌃"
        }
        if modFlags.contains(.shift) {
            description += "⇧"
        }
        
        // Add key character only if it's not a modifier-only hotkey
        if hotkeyKeyCode > 0, let char = KeyCodeMap.map[hotkeyKeyCode] {
            description += (description.isEmpty ? "" : "+") + char.uppercased()
        }
        
        return description.isEmpty ? "Not Set" : description
    }
    
    private init() {
        // Load saved values
        loadSavedValues()
        
        // Initialize with empty API key
        if apiKey.isEmpty {
            defaults.set("", forKey: apiKeyKey)
        }
        
        // Add this to your initialization
        self.isToggleMode = defaults.bool(forKey: isToggleModeKey)
        self.playSounds = defaults.object(forKey: playSoundsKey) as? Bool ?? true
    }
    
    private func loadSavedValues() {
        // Load recording state
        isRecording = defaults.bool(forKey: isRecordingKey)
        
        // Load hotkey modifiers
        let storedModifiers = defaults.integer(forKey: hotkeyModifiersKey)
        if storedModifiers == 0 {
            hotkeyModifiers = defaultHotkeyModifiers
            defaults.set(hotkeyModifiers, forKey: hotkeyModifiersKey)
        } else {
            hotkeyModifiers = UInt(storedModifiers)
        }
        
        // Load key code
        let storedKeyCode = defaults.integer(forKey: hotkeyKeyCodeKey)
        if storedKeyCode == 0 && storedModifiers != 0 {
            // This is a modifier-only hotkey, keep it as 0
            hotkeyKeyCode = 0
        } else if storedKeyCode == 0 {
            // This is not a modifier-only hotkey, set default
            hotkeyKeyCode = defaultKeyCode
            defaults.set(hotkeyKeyCode, forKey: hotkeyKeyCodeKey)
        } else {
            hotkeyKeyCode = UInt16(storedKeyCode)
        }
        
        // Load launch at login setting
        launchAtLogin = defaults.bool(forKey: launchAtLoginKey)
        
        // Load microphone selection
        selectedMicrophone = defaults.string(forKey: selectedMicrophoneKey)
        
        // Load API key
        if let savedKey = defaults.string(forKey: apiKeyKey) {
            apiKey = savedKey
        } else {
            apiKey = ""
            defaults.set(apiKey, forKey: apiKeyKey)
        }
        
        // Load preferred language
        if let language = defaults.string(forKey: preferredLanguageKey) {
            preferredLanguage = language
        } else {
            preferredLanguage = defaultLanguage
            defaults.set(preferredLanguage, forKey: preferredLanguageKey)
        }
    }
    
    func setHotkey(modifiers: NSEvent.ModifierFlags, keyCode: UInt16) {
        print("Setting hotkey - modifiers: \(modifiers.rawValue), keyCode: \(keyCode)")
        self.hotkeyModifiers = modifiers.rawValue
        self.hotkeyKeyCode = keyCode
        
        // Save changes to UserDefaults
        defaults.set(hotkeyModifiers, forKey: hotkeyModifiersKey)
        defaults.set(hotkeyKeyCode, forKey: hotkeyKeyCodeKey)
        
        // Notify hotkey service to update
        updateHotkey()
    }
    
    func resetToDefaultHotkey() {
        setHotkey(modifiers: NSEvent.ModifierFlags(rawValue: defaultHotkeyModifiers), 
                 keyCode: defaultKeyCode)
    }
    
    private func updateHotkey() {
        // Notify hotkey service to update the registered hotkey
        NotificationCenter.default.post(name: Notification.Name("HotkeyChanged"), object: nil)
    }
    
    func setLaunchAtLogin(enabled: Bool) {
        launchAtLogin = enabled
        defaults.set(enabled, forKey: launchAtLoginKey)
        
        // Update launch at login setting
        let bundleID = Bundle.main.bundleIdentifier ?? "com.anytalk.app"
        SMLoginItemSetEnabled(bundleID as CFString, enabled)
    }
    
    func updateSelectedMicrophone(_ microphone: String?) {
        selectedMicrophone = microphone
        defaults.set(microphone, forKey: selectedMicrophoneKey)
    }
    
    func updateApiKey(_ key: String?) {
        apiKey = key ?? ""
        defaults.set(apiKey, forKey: apiKeyKey)
    }
    
    func updatePreferredLanguage(_ language: String) {
        preferredLanguage = language
        defaults.set(language, forKey: preferredLanguageKey)
    }
}

// Extension to get bundle identifier from URL
extension URL {
    var bundleIdentifier: String? {
        if self.pathExtension == "app" {
            return Bundle(url: self)?.bundleIdentifier
        }
        return nil
    }
} 
