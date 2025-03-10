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
        string appDataPath = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "AnyTalk"
        );

        if (!Directory.Exists(appDataPath))
        {
            Directory.CreateDirectory(appDataPath);
        }

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

    private Settings LoadSettingsFromFile()
    {
        try
        {
            if (File.Exists(settingsFilePath))
            {
                string json = File.ReadAllText(settingsFilePath);
                var loadedSettings = JsonSerializer.Deserialize<Settings>(json);
                if (loadedSettings != null)
                {
                    return loadedSettings;
                }
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
            string json = JsonSerializer.Serialize(settings, new JsonSerializerOptions 
            { 
                WriteIndented = true 
            });
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
