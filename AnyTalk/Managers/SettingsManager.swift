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
    
    // Add isToggleMode with the other @Published properties
    @Published var isToggleMode: Bool = false {
        didSet {
            defaults.set(isToggleMode, forKey: isToggleModeKey)
        }
    }
    
    @Published var isRecording = false {
        didSet {
            defaults.set(isRecording, forKey: isRecordingKey)
            NotificationCenter.default.post(name: Notification.Name("RecordingStateChanged"), object: nil)
        }
    }
    // ... rest of your existing @Published properties ...

    private init() {
        // Load isToggleMode with other saved values
        self.isToggleMode = defaults.bool(forKey: isToggleModeKey)
        
        // ... rest of your existing initialization code ...
    }
    
    // ... rest of your existing methods ...
}
