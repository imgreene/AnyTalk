import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @ObservedObject private var settingsManager = SettingsManager.shared
    @ObservedObject private var historyManager = HistoryManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("AnyTalk")
                    .font(.headline)
                    .padding(.leading)
                
                Spacer()
                
                if settingsManager.isRecording {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 10, height: 10)
                        
                        Text("Recording")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    .padding(.trailing, 5)
                }
            }
            .padding(.vertical, 10)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Custom Tab Bar
            CustomTabBar(selectedTab: $selectedTab)
                .padding(.vertical, 5)
                .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Content based on selected tab
            TabContent(selectedTab: selectedTab, totalWords: historyManager.totalWordCount, entries: historyManager.entries)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 320, minHeight: 400)
    }
    
    func updateForNewTranscription() {
        historyManager.calculateTotalWordCount()
    }
}

// Custom Tab Bar Component
struct CustomTabBar: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack(spacing: 0) {
            TabButton(title: "Home", icon: "house", isSelected: selectedTab == 0) {
                selectedTab = 0
            }
            
            TabButton(title: "History", icon: "clock", isSelected: selectedTab == 1) {
                selectedTab = 1
            }
            
            TabButton(title: "Settings", icon: "gear", isSelected: selectedTab == 2) {
                selectedTab = 2
            }
        }
        .padding(.horizontal)
    }
}

// Tab Button Component
struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(isSelected ? Color.gray.opacity(0.3) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
        .foregroundColor(isSelected ? .primary : .secondary)
    }
}

// Tab Content Component
struct TabContent: View {
    let selectedTab: Int
    let totalWords: Int
    let entries: [TranscriptionEntry]
    
    var body: some View {
        Group {
            if selectedTab == 0 {
                HomeView(totalWords: totalWords)
            } else if selectedTab == 1 {
                HistoryView(entries: entries)
            } else {
                SettingsView()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
} 