import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settingsManager = SettingsManager.shared
    @State private var showingHotkeyRecorder = false
    @State private var selectedMicrophone: String
    @State private var apiKey: String
    @State private var selectedLanguage: String
    @State private var availableMicrophones: [String] = []
    @Environment(\.colorScheme) private var colorScheme
    @State private var confirmingClearHistory = false
    @State private var clearHistoryTimer: Timer?
    
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
                // Hotkey Settings
                SettingsCard(title: "Recording Hotkey", icon: "keyboard", isInteractive: true) {
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
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .sheet(isPresented: $showingHotkeyRecorder) {
                    HotkeyRecorderView(isPresented: $showingHotkeyRecorder)
                }
                .padding(.top, 12) // Add a small top padding to the first card
                
                // Recording Mode Settings
                SettingsCard(title: "Recording Mode", icon: "record.circle") {
                    VStack(spacing: 12) {
                        Button(action: {
                            settingsManager.isToggleMode = false
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Press and Hold")
                                        .font(.system(size: 15, weight: .semibold))
                                    Text("Hold key combination to record, release to stop")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if !settingsManager.isToggleMode {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(!settingsManager.isToggleMode ? 
                                        Color.blue.opacity(0.1) : 
                                        Color.secondary.opacity(0.05))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())

                        Button(action: {
                            settingsManager.isToggleMode = true
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Press to Toggle")
                                        .font(.system(size: 15, weight: .semibold))
                                    Text("Press once to start, press again to stop")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if settingsManager.isToggleMode {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(settingsManager.isToggleMode ? 
                                        Color.blue.opacity(0.1) : 
                                        Color.secondary.opacity(0.05))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                // Microphone Settings
                SettingsCard(title: "Microphone", icon: "mic.fill") {
                    Picker("Input Device", selection: $selectedMicrophone) {
                        Text("Default Device").tag("Default")
                        
                        let devices = AudioRecorderService.shared.availableMicrophones
                        if !devices.isEmpty {
                            Divider()
                                .padding(.vertical, 2)
                        }
                        
                        ForEach(devices, id: \.self) { mic in
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
                    VStack(spacing: 12) {
                        Toggle(isOn: $settingsManager.launchAtLogin) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Launch at Login")
                                    .font(.system(size: 13))
                                Text("Start AnyTalk automatically when you log in")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .onChange(of: settingsManager.launchAtLogin) { newValue in
                            settingsManager.setLaunchAtLogin(enabled: newValue)
                        }
                        
                        Divider()
                        
                        Toggle(isOn: $settingsManager.playSounds) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Play Sounds")
                                    .font(.system(size: 13))
                                Text("Audio feedback when recording starts/stops")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                
                // Clear History
                SettingsCard(title: "Clear History", icon: "trash.fill") {
                    VStack(spacing: 12) {
                        Button(action: {
                            if confirmingClearHistory {
                                // Actually clear the history
                                HistoryManager.shared.clearAllEntries()
                                confirmingClearHistory = false
                                clearHistoryTimer?.invalidate()
                            } else {
                                confirmingClearHistory = true
                                // Reset after 3 seconds
                                clearHistoryTimer?.invalidate()
                                clearHistoryTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
                                    confirmingClearHistory = false
                                }
                            }
                        }) {
                            Text(confirmingClearHistory ? "Confirm Clear History" : "Clear AnyTalk History")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .background(confirmingClearHistory ? Color.red : Color.red.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        
                        if !confirmingClearHistory {
                            Text("This will permanently delete all transcription history")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }

                // App Info
                VStack(spacing: 4) {
                    Text("AnyTalk")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Version 1.0.1")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 16)
                .padding(.bottom, 20)
            }
            .padding(.bottom, 20)
        }
        .onAppear {
            NotificationCenter.default.addObserver(
                forName: Notification.Name("OpenHotkeyRecorder"),
                object: nil,
                queue: .main
            ) { _ in
                showingHotkeyRecorder = true
            }
            
            // Listen for audio device changes
            NotificationCenter.default.addObserver(
                forName: Notification.Name("AudioDevicesChanged"),
                object: nil,
                queue: .main
            ) { _ in
                // Force refresh the picker
                let devices = AudioRecorderService.shared.availableMicrophones
                if !devices.contains(selectedMicrophone) {
                    selectedMicrophone = "Default"
                    settingsManager.selectedMicrophone = "Default"
                }
            }
        }
    }
}

// Card component for settings sections
struct SettingsCard<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    let isInteractive: Bool
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false
    
    init(title: String, icon: String, isInteractive: Bool = false, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.isInteractive = isInteractive
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
                .fill(colorScheme == .dark 
                    ? Color(.windowBackgroundColor).opacity(isPressed ? 0.5 : 0.7)
                    : Color(.controlBackgroundColor).opacity(isPressed ? 0.7 : 1))
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.05), radius: 1, x: 0, y: 1)
        )
        .padding(.horizontal)
        .if(isInteractive) { view in
            view
                .onHover { hovering in
                    if hovering {
                        NSCursor.pointingHand.set()
                    } else {
                        NSCursor.arrow.set()
                    }
                }
                .simultaneousGesture(
                    TapGesture()
                        .onEnded {
                            NotificationCenter.default.post(name: Notification.Name("OpenHotkeyRecorder"), object: nil)
                        }
                )
                .pressAction(onPress: { pressed in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = pressed
                    }
                })
        }
    }
}

struct HotkeyRecorderView: View {
    @Binding var isPresented: Bool
    @ObservedObject private var settingsManager = SettingsManager.shared
    @State private var currentModifiers: NSEvent.ModifierFlags = []
    @State private var savedModifiers: NSEvent.ModifierFlags = []
    @Environment(\.colorScheme) private var colorScheme
    @State private var monitorHandler: Any?
    @State private var isRecordingNew: Bool = false
    
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
                
                // Hotkey display
                Text(hotkeyDescription)
                    .font(.system(size: 24, weight: .medium))
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(NSColor.textBackgroundColor))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
                            )
                    )
                
                Text("Modifier keys only")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
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
                    settingsManager.setHotkey(modifiers: NSEvent.ModifierFlags(rawValue: savedModifiers.rawValue), keyCode: 0)
                    cleanupMonitor()
                    isPresented = false
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(PrimaryButtonStyle())
                .disabled(savedModifiers.isEmpty)
            }
            .padding()
        }
        .padding()
        .frame(width: 380, height: 360)
        .onAppear {
            setupKeyMonitor()
        }
        .onDisappear {
            cleanupMonitor()
        }
    }
    
    private func setupKeyMonitor() {
        cleanupMonitor()
        
        monitorHandler = NSEvent.addLocalMonitorForEvents(matching: [.flagsChanged]) { event in
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            
            // If starting a new recording
            if !flags.isEmpty && !isRecordingNew {
                isRecordingNew = true
                savedModifiers = []
            }
            
            // Update both current and saved modifiers
            currentModifiers = flags
            if !flags.isEmpty {
                // Combine the new flags with existing ones instead of replacing
                savedModifiers = savedModifiers.union(flags)
            }
            
            // Only clear saved modifiers if all keys are released
            if flags.isEmpty {
                isRecordingNew = false
                currentModifiers = savedModifiers
            }
            
            return nil
        }
    }
    
    var hotkeyDescription: String {
        var description = ""
        let modFlags = savedModifiers
        
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
        
        return description.isEmpty ? "Press keys" : description
    }
    
    private func cleanupMonitor() {
        if let monitorHandler = monitorHandler {
            NSEvent.removeMonitor(monitorHandler)
            self.monitorHandler = nil
        }
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

// Add this extension to support press detection
extension View {
    func pressAction(onPress: @escaping (_ isPressed: Bool) -> Void) -> some View {
        modifier(PressActionModifier(onPress: onPress))
    }
}

struct PressActionModifier: ViewModifier {
    let onPress: (_ isPressed: Bool) -> Void
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        onPress(true)
                    }
                    .onEnded { _ in
                        onPress(false)
                    }
            )
    }
}

// Add this extension to support conditional modifiers
extension View {
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
