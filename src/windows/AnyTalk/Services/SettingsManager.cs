using Microsoft.Win32;

namespace AnyTalk.Services;

public class SettingsManager
{
    private const string AppName = "AnyTalk";
    private const string RegPath = @"SOFTWARE\AnyTalk";
    
    public static SettingsManager Instance { get; } = new SettingsManager();

    public string ApiKey
    {
        get => GetSetting("ApiKey", "");
        set => SaveSetting("ApiKey", value);
    }

    public bool LaunchAtStartup
    {
        get => GetSetting("LaunchAtStartup", false);
        set
        {
            SaveSetting("LaunchAtStartup", value);
            SetStartupRegistry(value);
        }
    }

    public string PreferredLanguage
    {
        get => GetSetting("PreferredLanguage", "en");
        set => SaveSetting("PreferredLanguage", value);
    }

    private T GetSetting<T>(string name, T defaultValue)
    {
        using var key = Registry.CurrentUser.CreateSubKey(RegPath);
        var value = key.GetValue(name);
        return value != null ? (T)Convert.ChangeType(value, typeof(T)) : defaultValue;
    }

    private void SaveSetting<T>(string name, T value)
    {
        using var key = Registry.CurrentUser.CreateSubKey(RegPath);
        key.SetValue(name, value?.ToString() ?? string.Empty);
    }

    private void SetStartupRegistry(bool enable)
    {
        using var key = Registry.CurrentUser.CreateSubKey(@"SOFTWARE\Microsoft\Windows\CurrentVersion\Run");
        if (enable)
        {
            var exePath = Application.ExecutablePath;
            key.SetValue(AppName, exePath);
        }
        else
        {
            key.DeleteValue(AppName, false);
        }
    }

    // Compatibility methods for existing code
    public string GetApiKey() => ApiKey;
    public void SaveApiKey(string apiKey) => ApiKey = apiKey;
}
