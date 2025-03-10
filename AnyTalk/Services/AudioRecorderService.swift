import AVFoundation
import AppKit
import UserNotifications

class AudioRecorderService: NSObject, AVAudioRecorderDelegate {
    static let shared = AudioRecorderService()
    
    private var audioRecorder: AVAudioRecorder?
    private var completionHandler: ((URL?) -> Void)?
    private var levelTimer: Timer?
    
    lazy var availableMicrophones: [String] = {
        return AVCaptureDevice.devices(for: .audio).map { $0.localizedName }
    }()
    
    override private init() {
        super.init()
        setupAudioSession()
        requestNotificationPermission()
    }
    
    private func setupAudioSession() {
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.record, mode: .default)
            try session.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
        #endif
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Error requesting notification permission: \(error)")
            }
        }
    }
    
    private func requestPermission(completion: @escaping (Bool) -> Void) {
        #if os(iOS)
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
        #else
        // macOS doesn't require explicit microphone permission through AVAudioSession
        completion(true)
        #endif
    }
    
    private func showNotification(title: String, message: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error showing notification: \(error)")
            }
        }
    }
    
    func startRecording() {
        requestPermission { [weak self] granted in
            guard let self = self, granted else {
                print("Microphone permission denied")
                self?.showNotification(title: "Microphone Access Required", 
                                      message: "AnyTalk needs microphone access to record audio for transcription.")
                return
            }
            
            // Get filename
            let audioFilename = self.getDocumentsDirectory().appendingPathComponent("recording.m4a")
            
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
                self.audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
                self.audioRecorder?.delegate = self
                self.audioRecorder?.isMeteringEnabled = true
                self.audioRecorder?.prepareToRecord()
                self.audioRecorder?.record()
                
                // Start a timer to update audio levels
                self.startLevelTimer()
                
                // Notify that recording has started
                SettingsManager.shared.isRecording = true
                
                // Play a sound to indicate recording has started
                NSSound(named: "Pop")?.play()
            } catch {
                print("Failed to start recording: \(error)")
                self.showNotification(title: "Recording Failed", 
                                     message: "Could not start recording: \(error.localizedDescription)")
            }
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
        
        // Play a sound to indicate recording has stopped
        NSSound(named: "Blow")?.play()
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
        
        // Play a sound to indicate recording has been canceled
        NSSound(named: "Basso")?.play()
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
} 