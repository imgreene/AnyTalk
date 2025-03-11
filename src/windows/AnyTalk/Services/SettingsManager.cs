using AnyTalk.Models;
using Newtonsoft.Json;
using System;
using System.IO;

namespace AnyTalk.Services
{
    public class SettingsManager
    {
        private static readonly Lazy<SettingsManager> _instance = new(() => new SettingsManager());
        private readonly string _settingsPath;
        private Settings _settings;

        public static SettingsManager Instance => _instance.Value;

        private SettingsManager()
        {
            _settingsPath = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
                "AnyTalk",
                "settings.json"
            );
            _settings = LoadSettings();
        }

        public Settings LoadSettings()
        {
            try
            {
                if (File.Exists(_settingsPath))
                {
                    string json = File.ReadAllText(_settingsPath);
                    return JsonConvert.DeserializeObject<Settings>(json) ?? new Settings();
                }
            }
            catch (Exception)
            {
                // Log error if needed
            }
            return new Settings();
        }

        public void SaveSettings(Settings settings)
        {
            try
            {
                string directoryPath = Path.GetDirectoryName(_settingsPath)!;
                if (!Directory.Exists(directoryPath))
                {
                    Directory.CreateDirectory(directoryPath);
                }

                string json = JsonConvert.SerializeObject(settings, Formatting.Indented);
                File.WriteAllText(_settingsPath, json);
                _settings = settings;
            }
            catch (Exception)
            {
                // Log error if needed
            }
        }
    }
}
