import SwiftUI

struct HomeView: View {
    var totalWords: Int
    @ObservedObject private var settingsManager = SettingsManager.shared
    @ObservedObject private var historyManager = HistoryManager.shared
    
    var formattedTime: String {
        let minutes = historyManager.totalSeconds / 60
        let seconds = historyManager.totalSeconds % 60
        if minutes == 0 {
            return "\(seconds) seconds"
        } else if minutes == 1 {
            return "\(minutes) minute and \(seconds) seconds"
        } else {
            return "\(minutes) minutes and \(seconds) seconds"
        }
    }

    var wordsPerMinute: String {
        let totalMinutes = Double(historyManager.totalSeconds) / 60.0
        if totalMinutes > 0 {
            let wpm = Double(totalWords) / totalMinutes
            return "(\(Int(round(wpm))) words/min)"
        }
        return ""
    }
    
    var body: some View {
        VStack {
            Spacer()
            
            Text("Total Words Dictated")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("\(totalWords)")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .padding(.bottom, 4)
            
            Text(formattedTime)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(wordsPerMinute)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom)
            
            Spacer()
            
            // Dictation button with consistent microphone icon
            DictationButton(isRecording: settingsManager.isRecording)
                .padding()
            
            // Status text
            if settingsManager.isRecording {
                HStack(spacing: 8) {
                    // Orange dot indicator
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 8, height: 8)
                    
                    Text("Recording in progress...")
                        .foregroundColor(.orange)
                        .font(.caption)
                }
            } else {
                Text("Press \(settingsManager.hotkeyDescription) to start dictation")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// Custom Dictation Button Component
struct DictationButton: View {
    let isRecording: Bool
    
    var body: some View {
        Button(action: {
            NSApp.sendAction(#selector(AppDelegate.toggleDictation), to: nil, from: nil)
        }) {
            HStack {
                Image(systemName: "mic.fill")
                    .foregroundColor(.white)
                Text(isRecording ? "Stop Dictation" : "Start Dictation")
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(isRecording ? Color.orange : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(totalWords: 1234)
    }
} 