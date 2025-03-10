import SwiftUI

struct HistoryView: View {
    var entries: [TranscriptionEntry]
    @ObservedObject private var historyManager = HistoryManager.shared
    
    var body: some View {
        VStack {
            if entries.isEmpty {
                VStack {
                    Spacer()
                    
                    Image(systemName: "doc.text")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                        .padding()
                    
                    Text("No transcriptions yet")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Your transcription history will appear here")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding()
                    
                    Spacer()
                }
            } else {
                List {
                    ForEach(entries) { entry in
                        TranscriptionEntryView(entry: entry)
                    }
                    .onDelete { indexSet in
                        historyManager.deleteEntries(at: indexSet)
                    }
                }
                .listStyle(InsetListStyle())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct TranscriptionEntryView: View {
    var entry: TranscriptionEntry
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.timestamp, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("-")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(entry.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: {
                    isExpanded.toggle()
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            if isExpanded {
                Text(entry.text)
                    .font(.body)
                    .padding(.vertical, 4)
                
                HStack {
                    Button(action: {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(entry.text, forType: .string)
                    }) {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                    
                    Text("\(entry.wordCount) words")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                Text(entry.text)
                    .font(.body)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
        .padding(.vertical, 6)
    }
}

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryView(entries: [
            TranscriptionEntry(text: "This is a sample transcription", timestamp: Date()),
            TranscriptionEntry(text: "Another test transcription that is a bit longer to test truncation", timestamp: Date().addingTimeInterval(-3600))
        ])
    }
} 