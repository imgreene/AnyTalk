namespace AnyTalk.Models;

public class TranscriptionEntry
{
    public string Text { get; set; } = string.Empty;
    public DateTime Timestamp { get; set; }
    public int WordCount => Text.Split(new[] { ' ' }, StringSplitOptions.RemoveEmptyEntries).Length;
}
