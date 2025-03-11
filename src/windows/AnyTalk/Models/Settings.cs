namespace AnyTalk.Models
{
    public class Settings
    {
        public string ApiKey { get; set; } = string.Empty;
        public string HotKey { get; set; } = string.Empty;
        public string InputDevice { get; set; } = string.Empty;
        public bool LaunchAtStartup { get; set; }
        public string Language { get; set; } = "en";
    }
}
