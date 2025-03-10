using System.Text.Json.Serialization;

namespace AnyTalk.Models;

public class TranscriptionEntry
{
    [JsonPropertyName("text")]
    public string Text { get; set; } = string.Empty;
    
    [JsonPropertyName("timestamp")]
    public DateTime Timestamp { get; set; }
    
    [JsonPropertyName("wordCount")]
    public int WordCount { get; set; }
}
