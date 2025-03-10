namespace AnyTalk.Models;

public class TranscriptionEntry
{
    public string Text { get; set; }
    public DateTime Timestamp { get; set; }
    public int WordCount => Text.Split(new[] { ' ' }, StringSplitOptions.RemoveEmptyEntries).Length;

    public TranscriptionEntry(string text)
    {
        Text = text;
        Timestamp = DateTime.Now;
    }

    // Parameterless constructor for JSON deserialization
    public TranscriptionEntry()
    {
        Text = string.Empty;
        Timestamp = DateTime.Now;
    }
}
