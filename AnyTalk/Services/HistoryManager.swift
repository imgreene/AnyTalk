
import Foundation
import SwiftUI

class HistoryManager: ObservableObject {
    static let shared = HistoryManager()
    
    @Published var entries: [TranscriptionEntry] = []
    @Published var totalWordCount: Int = 0
    @Published var totalSeconds: Int = 0 // New property for time tracking
    
    private let entriesKey = "transcriptionEntries"
    private let totalSecondsKey = "totalRecordingSeconds"
    
    private init() {
        loadEntries()
        loadTotalSeconds()
        calculateTotalWordCount()
    }
    
    func addEntry(text: String, duration: TimeInterval) {
        let entry = TranscriptionEntry(text: text, timestamp: Date())
        entries.insert(entry, at: 0)  // Add to the beginning
        totalSeconds += Int(duration)
        saveEntries()
        saveTotalSeconds()
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
    
    private func loadTotalSeconds() {
        totalSeconds = UserDefaults.standard.integer(forKey: totalSecondsKey)
    }
    
    private func saveTotalSeconds() {
        UserDefaults.standard.set(totalSeconds, forKey: totalSecondsKey)
    }
    
    func clearAllEntries() {
        entries.removeAll()
        totalSeconds = 0
        saveEntries()
        saveTotalSeconds()
        calculateTotalWordCount()
    }
} 