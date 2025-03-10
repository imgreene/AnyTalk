import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settingsManager = SettingsManager.shared
    @State private var showingHotkeyRecorder = false
    @State private var selectedMicrophone: String
    @State private var apiKey: String
    @State private var selectedLanguage: String
    @Environment(\.colorScheme) private var colorScheme
    
    init() {
        let initialMicrophone = SettingsManager.shared.selectedMicrophone ?? "Default"
        let initialApiKey = SettingsManager.shared.apiKey ?? ""
        let initialLanguage = SettingsManager.shared.preferredLanguage
        
        self._selectedMicrophone = State(initialValue: initialMicrophone)
        self._apiKey = State(initialValue: initialApiKey)
        self._selectedLanguage = State(initialValue: initialLanguage)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                Text("Settings")
                    .font(.system(size: 28, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .opacity(0.0) // Hide this title since it's shown in the tab bar
                
                // Hotkey Settings
                SettingsCard(title: "Recording Hotkey", icon: "keyboard") {
                    Button(action: {
                        showingHotkeyRecorder.toggle()
                    }) {
                        HStack {
                            Text("Current shortcut")
                                .foregroundColor(.primary)
                            Spacer()
                            
                            HStack(spacing: 4) {
                                Text(settingsManager.hotkeyDescription)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.secondary.opacity(0.2))
                                    .cornerRadius(6)
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .sheet(isPresented: $showingHotkeyRecorder) {
                        HotkeyRecorderView(isPresented: $showingHotkeyRecorder)
                    }
                }
                
                // Microphone Settings
                SettingsCard(title: "Microphone", icon: "mic.fill") {
                    Picker("Input Device", selection: $selectedMicrophone) {
                        Text("Default Device").tag("Default")
                        
                        if !AudioRecorderService.shared.availableMicrophones.isEmpty {
                            Divider()
                                .padding(.vertical, 2)
                        }
                        
                        ForEach(AudioRecorderService.shared.availableMicrophones, id: \.self) { mic in
                            Text(mic).tag(mic)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: selectedMicrophone) { newValue in
                        settingsManager.selectedMicrophone = newValue
                    }
                }
                
                // Transcription Settings
                SettingsCard(title: "Transcription", icon: "text.bubble.fill") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Preferred Language")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Picker("Preferred Language", selection: $selectedLanguage) {
                            Text("Auto Detect").tag("auto")
                            
                            Divider()
                                .padding(.vertical, 2)
                            
                            ForEach(settingsManager.availableLanguages.sorted(by: { $0.value < $1.value }), id: \.key) { key, value in
                                Text(value).tag(key)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .onChange(of: selectedLanguage) { newValue in
                            settingsManager.updatePreferredLanguage(newValue)
                        }
                        
                        Text("Whisper will prioritize transcribing in this language")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .padding(.top, 2)
                    }
                }
                
                // API Key Settings
                SettingsCard(title: "API Key", icon: "key.fill") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("OpenAI API Key")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        SecureField("Enter your OpenAI API key", text: $apiKey)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button(action: {
                            settingsManager.updateApiKey(apiKey)
                        }) {
                            Text("Save API Key")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        
                        Text("Get your API key from platform.openai.com")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                
                // App Settings
                SettingsCard(title: "App Options", icon: "gearshape.fill") {
                    Toggle("Launch at Login", isOn: $settingsManager.launchAtLogin)
                        .onChange(of: settingsManager.launchAtLogin) { newValue in
                            settingsManager.setLaunchAtLogin(enabled: newValue)
                        }
                }
                
                // App Info
                VStack(spacing: 4) {
                    Text("AnyTalk")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Version 1.0")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 16)
                .padding(.bottom, 20)
            }
            .padding(.bottom, 20)
        }
    }
}

// Card component for settings sections
struct SettingsCard<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    @Environment(\.colorScheme) private var colorScheme
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 24, height: 24)
                
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
            }
            .padding(.bottom, 4)
            
            // Content
            content
                .padding(.leading, 34)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.windowBackgroundColor).opacity(0.7) : Color(.controlBackgroundColor))
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.05), radius: 1, x: 0, y: 1)
        )
        .padding(.horizontal)
    }
}

struct HotkeyRecorderView: View {
    @Binding var isPresented: Bool
    @ObservedObject private var settingsManager = SettingsManager.shared
    @State private var modifiers: NSEvent.ModifierFlags = []
    @State private var keyCode: UInt16 = 0
    @State private var isRecording = false
    @State private var allowModifiersOnly = false
    @State private var lastFlagsChanged = Date()
    @State private var modifiersStable = false
    @State private var monitorHandler: Any?
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "keyboard")
                    .font(.system(size: 36))
                    .foregroundColor(.primary)
                    .padding(.bottom, 4)
                
                Text("Record New Hotkey")
                    .font(.system(size: 20, weight: .bold))
                
                Text("Press the key combination you want to use")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Display current hotkey
            VStack {
                Text(isRecording ? "Recording..." : (modifiers.isEmpty && keyCode == 0) ? "No hotkey set" : hotkeyDescription)
                    .font(.system(size: 18, weight: isRecording ? .bold : .medium))
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isRecording 
                                ? Color.blue.opacity(0.1)
                                : (colorScheme == .dark 
                                    ? Color(.textBackgroundColor).opacity(0.5)
                                    : Color(.controlBackgroundColor)))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(
                                        isRecording 
                                            ? Color.blue.opacity(0.5)
                                            : Color.secondary.opacity(0.2),
                                        lineWidth: 1
                                    )
                            )
                    )
                    .animation(.easeInOut(duration: 0.2), value: isRecording)
            }
            .padding(.horizontal)
            
            // Settings
            VStack(alignment: .leading, spacing: 8) {
                Toggle("Allow modifier keys only (e.g., ⌘⌥)", isOn: $allowModifiersOnly)
                    .onChange(of: allowModifiersOnly) { newValue in
                        if newValue {
                            // When enabling modifier-only mode, reset the key code
                            keyCode = 0
                        }
                    }
                
                if allowModifiersOnly {
                    Text("Hold the modifier keys for 1 second to set")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Buttons
            HStack(spacing: 12) {
                Button("Cancel") {
                    cleanupMonitor()
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)
                .buttonStyle(SecondaryButtonStyle())
                
                Button("Save") {
                    // If using modifiers only and allowModifiersOnly is true, set keyCode to 0
                    if allowModifiersOnly && modifiers.rawValue > 0 {
                        settingsManager.setHotkey(modifiers: modifiers, keyCode: 0)
                    } else {
                        settingsManager.setHotkey(modifiers: modifiers, keyCode: keyCode)
                    }
                    cleanupMonitor()
                    isPresented = false
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(PrimaryButtonStyle())
                .disabled(modifiers.isEmpty || (!allowModifiersOnly && keyCode == 0))
            }
            .padding()
        }
        .padding()
        .frame(width: 380, height: 360)
        .onAppear {
            // Load current settings
            let currentModifiers = NSEvent.ModifierFlags(rawValue: settingsManager.hotkeyModifiers)
            modifiers = currentModifiers
            keyCode = settingsManager.hotkeyKeyCode
            
            // Check if current hotkey is modifier-only
            allowModifiersOnly = (keyCode == 0 && modifiers.rawValue > 0)
            
            setupKeyMonitor()
            
            // Start recording after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isRecording = true
            }
        }
        .onDisappear {
            cleanupMonitor()
        }
    }
    
    private func setupKeyMonitor() {
        // Clean up any existing monitor
        cleanupMonitor()
        
        // Set up a timer to check if modifiers have been stable
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if allowModifiersOnly && isRecording && modifiers.rawValue > 0 {
                if Date().timeIntervalSince(lastFlagsChanged) > 1.0 && !modifiersStable {
                    // Modifiers have been stable for 1 second
                    modifiersStable = true
                    isRecording = false
                    // Keep keyCode as 0 for modifier-only hotkey
                    keyCode = 0
                    print("Modifier-only hotkey set: \(modifiers.rawValue)")
                }
            }
            
            // Stop the timer if we're not recording anymore
            if !isRecording {
                timer.invalidate()
            }
        }
        
        // Set up the event monitor
        monitorHandler = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { event in
            if isRecording {
                if event.type == .flagsChanged {
                    // Update modifiers
                    modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
                    lastFlagsChanged = Date()
                    modifiersStable = false
                    print("Flags changed: \(modifiers.rawValue)")
                } else if event.type == .keyDown {
                    // Update key code and modifiers
                    modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
                    keyCode = event.keyCode
                    isRecording = false
                    print("Key down: keyCode=\(keyCode), modifiers=\(modifiers.rawValue)")
                }
            }
            return event
        }
    }
    
    private func cleanupMonitor() {
        if let handler = monitorHandler {
            NSEvent.removeMonitor(handler)
            monitorHandler = nil
        }
    }
    
    var hotkeyDescription: String {
        var description = ""
        
        if modifiers.contains(.command) {
            description += "⌘"
        }
        if modifiers.contains(.option) {
            description += "⌥"
        }
        if modifiers.contains(.control) {
            description += "⌃"
        }
        if modifiers.contains(.shift) {
            description += "⇧"
        }
        
        // Add key character
        if keyCode > 0, let char = KeyCodeMap.map[keyCode] {
            description += char
        }
        
        return description.isEmpty ? "Not Set" : description
    }
}

// Custom button styles
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(minWidth: 80)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(configuration.isPressed ? Color.blue.opacity(0.7) : Color.blue)
            )
            .foregroundColor(.white)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(minWidth: 80)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(configuration.isPressed
                        ? Color.secondary.opacity(colorScheme == .dark ? 0.2 : 0.15)
                        : Color.secondary.opacity(colorScheme == .dark ? 0.15 : 0.1))
            )
            .foregroundColor(.primary)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .previewDisplayName("Light Mode")
        
        SettingsView()
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
    }
} 
