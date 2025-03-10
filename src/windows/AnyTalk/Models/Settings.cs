using System.Text.Json.Serialization;

namespace AnyTalk.Models;

public class Settings
{
    [JsonPropertyName("apiKey")]
    public string ApiKey { get; set; } = string.Empty;
    
    [JsonPropertyName("hotKey")]
    public string HotKey { get; set; } = string.Empty;
    
    [JsonPropertyName("language")]
    public string Language { get; set; } = "en";
    
    [JsonPropertyName("launchAtStartup")]
    public bool LaunchAtStartup { get; set; } = false;
    
    [JsonPropertyName("selectedMicrophone")]
    public string? SelectedMicrophone { get; set; }
}
