using System.Text.Json;
using AnyTalk.Models;

namespace AnyTalk.Services;

public class SettingsManager
{
    private static SettingsManager? instance;
    private Settings settings;
    private readonly string settingsFilePath;

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
        // Get the application data path
        string appDataPath = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "AnyTalk"
        );

        // Create the directory if it doesn't exist
        if (!Directory.Exists(appDataPath))
        {
            Directory.CreateDirectory(appDataPath);
        }

        // Set the full path for the settings file
        settingsFilePath = Path.Combine(appDataPath, "settings.json");
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
        try
        {
            if (File.Exists(settingsFilePath))
            {
                var json = File.ReadAllText(settingsFilePath);
                return JsonSerializer.Deserialize<Settings>(json) ?? new Settings();
            }
        }
        catch (Exception ex)
        {
            MessageBox.Show(
                $"Error loading settings: {ex.Message}",
                "Settings Error",
                MessageBoxButtons.OK,
                MessageBoxIcon.Warning
            );
        }
        return new Settings();
    }

    private void SaveSettingsToFile()
    {
        try
        {
            var json = JsonSerializer.Serialize(settings, new JsonSerializerOptions { WriteIndented = true });
            File.WriteAllText(settingsFilePath, json);
        }
        catch (Exception ex)
        {
            MessageBox.Show(
                $"Error saving settings: {ex.Message}",
                "Settings Error",
                MessageBoxButtons.OK,
                MessageBoxIcon.Warning
            );
        }
    }
}
