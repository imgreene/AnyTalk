using AnyTalk.Models;

namespace AnyTalk.Services;

public class SettingsManager
{
    private static SettingsManager? instance;
    private Settings settings;
    private const string SettingsFileName = "settings.json";

    public static SettingsManager Instance
    {
        get
        {
            instance ??= new SettingsManager();
            return instance;
        }
    }

    private SettingsManager()
    {
        settings = LoadSettingsFromFile();
    }

    public Settings LoadSettings()
    {
        return settings;
    }

    public void SaveApiKey(string apiKey)
    {
        settings.ApiKey = apiKey;
        SaveSettingsToFile();
    }

    public void SaveHotkey(string hotkey)
    {
        settings.HotKey = hotkey;
        SaveSettingsToFile();
    }

    private Settings LoadSettingsFromFile()
    {
        if (File.Exists(SettingsFileName))
        {
            var json = File.ReadAllText(SettingsFileName);
            return System.Text.Json.JsonSerializer.Deserialize<Settings>(json) ?? new Settings();
        }
        return new Settings();
    }

    private void SaveSettingsToFile()
    {
        var json = System.Text.Json.JsonSerializer.Serialize(settings);
        File.WriteAllText(SettingsFileName, json);
    }
}
