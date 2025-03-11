import AVFoundation
import AppKit
import CoreAudio
import CoreAudioKit

class AudioRecorderService: NSObject, AVAudioRecorderDelegate {
    static let shared = AudioRecorderService()
    
    private var audioRecorder: AVAudioRecorder?
    private var completionHandler: ((URL?) -> Void)?
    private var levelTimer: Timer?
    
    var availableMicrophones: [String] {
        // Get all audio devices
        let devices = getSystemAudioDevices()
        
        // Filter for input devices and get their names
        let micNames = devices.compactMap { deviceID -> String? in
            // Only include if it's an input device
            guard isInputDevice(deviceID) else {
                return nil
            }
            
            // Get the device name
            let name = getDeviceName(for: deviceID)
            
            // Filter out entries with "speaker" in the name (case insensitive)
            if let deviceName = name?.lowercased(), deviceName.contains("speaker") {
                return nil
            }
            
            return name
        }
        
        // Remove duplicates while preserving order, but only if they have exactly the same name
        let uniqueNames = NSOrderedSet(array: micNames)
        return uniqueNames.array as? [String] ?? []
    }
    
    override private init() {
        super.init()
        setupDeviceNotifications()
    }
    
    private func setupDeviceNotifications() {
        // Listen for audio device changes
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleAudioDeviceChange),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
        
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleAudioDeviceChange),
            name: .init("com.apple.audio.AudioDeviceChanged"),
            object: nil
        )
    }
    
    @objc private func handleAudioDeviceChange() {
        // Notify settings view to update device list
        NotificationCenter.default.post(name: Notification.Name("AudioDevicesChanged"), object: nil)
    }
    
    private func getBluetoothAudioDevices() -> [String]? {
        // This is handled by availableMicrophones now
        return nil
    }
    
    private func setupAudioSession() {
        // Not needed for macOS
    }
    
    private func showNotification(title: String, message: String) {
        let notification = NSUserNotification()
        notification.title = title
        notification.informativeText = message
        NSUserNotificationCenter.default.deliver(notification)
    }
    
    func startRecording() {
        // Get the selected microphone from settings
        let selectedMic = SettingsManager.shared.selectedMicrophone ?? "Default"
        
        // Set the active input device
        if !setActiveInputDevice(deviceName: selectedMic) {
            print("Failed to set input device, using default")
        }
        
        // Get filename
        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a")
        
        // Delete any previous recording
        try? FileManager.default.removeItem(at: audioFilename)
        
        // Recording settings
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        // Create the audio recorder
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.prepareToRecord()
            audioRecorder?.record()
            
            // Start a timer to update audio levels
            startLevelTimer()
            
            // Notify that recording has started
            SettingsManager.shared.isRecording = true
            
            // Only play sound if enabled
            if SettingsManager.shared.playSounds {
                NSSound(named: "Pop")?.play()
            }
        } catch {
            print("Failed to start recording: \(error)")
            showNotification(title: "Recording Failed", 
                           message: "Could not start recording: \(error.localizedDescription)")
        }
    }
    
    func stopRecording(completion: @escaping (URL?) -> Void) {
        guard let audioRecorder = audioRecorder, audioRecorder.isRecording else {
            completion(nil)
            return
        }
        
        // Stop the level timer
        stopLevelTimer()
        
        self.completionHandler = completion
        audioRecorder.stop()
        SettingsManager.shared.isRecording = false
        
        // Only play sound if enabled
        if SettingsManager.shared.playSounds {
            NSSound(named: "Blow")?.play()
        }
    }
    
    func cancelRecording() {
        guard let audioRecorder = audioRecorder, audioRecorder.isRecording else {
            return
        }
        
        print("Canceling recording")
        
        // Stop the level timer
        stopLevelTimer()
        
        // Stop recording
        audioRecorder.stop()
        
        // Delete the recording file
        do {
            try FileManager.default.removeItem(at: audioRecorder.url)
            print("Deleted canceled recording file")
        } catch {
            print("Failed to delete canceled recording file: \(error)")
        }
        
        // Reset recording state
        SettingsManager.shared.isRecording = false
        
        // Ensure any system dictation is canceled
        NSPasteboard.general.clearContents()
        
        // Use a softer sound for recording cancel
        NSSound(named: "Funk")?.play()  // Changed from "Basso"
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            completionHandler?(recorder.url)
        } else {
            completionHandler?(nil)
            showNotification(title: "Recording Failed", 
                            message: "Failed to save the recording.")
        }
        
        // Reset
        completionHandler = nil
    }
    
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    // MARK: - Audio Level Monitoring
    
    private func startLevelTimer() {
        stopLevelTimer()
        
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let recorder = self.audioRecorder, recorder.isRecording else {
                return
            }
            
            recorder.updateMeters()
            let averagePower = recorder.averagePower(forChannel: 0)
            let peakPower = recorder.peakPower(forChannel: 0)
            
            // Normalize values to 0-1 range (dB values are negative)
            let normalizedAverage = self.normalizeDb(averagePower)
            let normalizedPeak = self.normalizeDb(peakPower)
            
            // Post notification with audio levels
            NotificationCenter.default.post(
                name: Notification.Name("AudioLevelUpdate"),
                object: nil,
                userInfo: [
                    "average": normalizedAverage,
                    "peak": normalizedPeak
                ]
            )
        }
    }
    
    private func stopLevelTimer() {
        levelTimer?.invalidate()
        levelTimer = nil
    }
    
    private func normalizeDb(_ dbValue: Float) -> Float {
        // Convert dB value (typically -160 to 0) to 0-1 range
        let minDb: Float = -60.0 // Treat anything below -60 as silence
        let normalizedValue = (dbValue - minDb) / (0 - minDb)
        return max(0, min(1, normalizedValue)) // Clamp to 0-1
    }
    
    private func getSystemAudioDevices() -> [AudioDeviceID] {
        var propertySize: UInt32 = 0
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        // Get the size of the property value first
        let _ = AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &propertySize
        )
        
        let deviceCount = Int(propertySize) / MemoryLayout<AudioDeviceID>.size
        var deviceIDs = [AudioDeviceID](repeating: 0, count: deviceCount)
        
        // Get the actual device IDs
        let _ = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &propertySize,
            &deviceIDs
        )
        
        return deviceIDs
    }
    
    private func getDeviceName(for deviceID: AudioDeviceID) -> String? {
        var propertySize: UInt32 = 0
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceNameCFString,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        // Get the size of the property
        let status = AudioObjectGetPropertyDataSize(
            deviceID,
            &propertyAddress,
            0,
            nil,
            &propertySize
        )
        
        guard status == kAudioHardwareNoError else {
            return nil
        }
        
        // Get the name
        var name: CFString = "" as CFString
        let _ = AudioObjectGetPropertyData(
            deviceID,
            &propertyAddress,
            0,
            nil,
            &propertySize,
            &name
        )
        
        return name as String
    }
    
    private func isInputDevice(_ deviceID: AudioDeviceID) -> Bool {
        var propertySize: UInt32 = 0
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamConfiguration,
            mScope: kAudioDevicePropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain
        )
        
        // First check if it's a regular input device
        let status = AudioObjectGetPropertyDataSize(
            deviceID,
            &propertyAddress,
            0,
            nil,
            &propertySize
        )
        
        if status == kAudioHardwareNoError {
            let bufferList = UnsafeMutablePointer<AudioBufferList>.allocate(capacity: 1)
            defer { bufferList.deallocate() }
            
            let _ = AudioObjectGetPropertyData(
                deviceID,
                &propertyAddress,
                0,
                nil,
                &propertySize,
                bufferList
            )
            
            let buffers = UnsafeMutableAudioBufferListPointer(bufferList)
            if buffers.count > 0 {
                return true
            }
        }
        
        // Then check if it's a Bluetooth device
        propertyAddress.mSelector = kAudioDevicePropertyTransportType
        var transportType: UInt32 = 0
        propertySize = UInt32(MemoryLayout<UInt32>.size)
        
        let transportStatus = AudioObjectGetPropertyData(
            deviceID,
            &propertyAddress,
            0,
            nil,
            &propertySize,
            &transportType
        )
        
        return transportStatus == kAudioHardwareNoError &&
               (transportType == kAudioDeviceTransportTypeBluetooth ||
                transportType == kAudioDeviceTransportTypeBluetoothLE)
    }
    
    private func setActiveInputDevice(deviceName: String) -> Bool {
        print("Attempting to set input device to: \(deviceName)")
        
        // If "Default" is selected, we don't need to do anything
        if deviceName == "Default" {
            print("Using system default input device")
            return true
        }
        
        // Get all audio devices
        let devices = getSystemAudioDevices()
        
        // Find the device ID matching the selected name
        for deviceID in devices {
            if let name = getDeviceName(for: deviceID), name == deviceName {
                // Set this device as the default input device
                var propertyAddress = AudioObjectPropertyAddress(
                    mSelector: kAudioHardwarePropertyDefaultInputDevice,
                    mScope: kAudioObjectPropertyScopeGlobal,
                    mElement: kAudioObjectPropertyElementMain
                )
                
                let propertySize = UInt32(MemoryLayout<AudioDeviceID>.size)
                var mutableDeviceID = deviceID  // Create mutable copy
                let status = AudioObjectSetPropertyData(
                    AudioObjectID(kAudioObjectSystemObject),
                    &propertyAddress,
                    0,
                    nil,
                    propertySize,
                    &mutableDeviceID
                )
                
                if status == kAudioHardwareNoError {
                    print("Successfully set input device to: \(deviceName)")
                    return true
                } else {
                    print("Failed to set input device: \(status)")
                    return false
                }
            }
        }
        
        print("Device not found: \(deviceName)")
        return false
    }
}
