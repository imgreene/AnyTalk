import Foundation

struct TranscriptionEntry: Identifiable, Codable {
    var id = UUID()
    var text: String
    var timestamp: Date
    var wordCount: Int
    
    init(text: String, timestamp: Date) {
        self.text = text
        self.timestamp = timestamp
        self.wordCount = text.split(separator: " ").count
    }
} 