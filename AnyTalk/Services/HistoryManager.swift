import Foundation

class HistoryManager: ObservableObject {
    static let shared = HistoryManager()
    
    @Published var entries: [TranscriptionEntry] = []
    @Published var totalWordCount: Int = 0
    
    private let entriesKey = "transcriptionEntries"
    
    private init() {
        loadEntries()
        calculateTotalWordCount()
    }
    
    func addEntry(text: String) {
        let entry = TranscriptionEntry(text: text, timestamp: Date())
        entries.insert(entry, at: 0)  // Add to the beginning
        saveEntries()
        calculateTotalWordCount()
    }
    
    func deleteEntries(at indexSet: IndexSet) {
        entries.remove(atOffsets: indexSet)
        saveEntries()
        calculateTotalWordCount()
    }
    
    func calculateTotalWordCount() {
        totalWordCount = entries.reduce(0) { $0 + $1.wordCount }
    }
    
    private func saveEntries() {
        if let encoded = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(encoded, forKey: entriesKey)
        }
    }
    
    private func loadEntries() {
        if let data = UserDefaults.standard.data(forKey: entriesKey),
           let decoded = try? JSONDecoder().decode([TranscriptionEntry].self, from: data) {
            entries = decoded
        }
    }
    
    func clearAllEntries() {
        entries.removeAll()
        saveEntries()
        calculateTotalWordCount()
    }
} 