namespace AnyTalk.Models
{
    public class Settings
    {
        public string ApiKey { get; set; } = string.Empty;
        public string Language { get; set; } = "en";
        public bool LaunchAtStartup { get; set; } = false;
        public string SelectedMicrophone { get; set; } = string.Empty;
        public string HotKey { get; set; } = "Control+Alt+R";
    }
}
