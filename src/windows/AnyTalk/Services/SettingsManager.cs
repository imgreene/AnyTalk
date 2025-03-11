using AnyTalk.Models;
using System.Text.Json;

namespace AnyTalk.Services
{
    public class SettingsManager
    {
        private static readonly SettingsManager _instance = new();
        private readonly string _settingsPath = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
            "AnyTalk",
            "settings.json"
        );

        public static SettingsManager Instance => _instance;

        private SettingsManager()
        {
            Directory.CreateDirectory(Path.GetDirectoryName(_settingsPath)!);
        }

        public Settings LoadSettings()
        {
            if (!File.Exists(_settingsPath))
            {
                return new Settings();
            }

            try
            {
                var json = File.ReadAllText(_settingsPath);
                return JsonSerializer.Deserialize<Settings>(json) ?? new Settings();
            }
            catch
            {
                return new Settings();
            }
        }

        public void SaveSettings(Settings settings)
        {
            var json = JsonSerializer.Serialize(settings);
            File.WriteAllText(_settingsPath, json);
        }
    }
}
