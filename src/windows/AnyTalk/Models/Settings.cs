namespace AnyTalk.Models;

public class Settings
{
    public string? ApiKey { get; set; }
    public string? SelectedMicrophone { get; set; }
    public string? Language { get; set; } = "en";
    public bool LaunchAtStartup { get; set; }
    public string? HotKey { get; set; } = "Ctrl+Alt";
}