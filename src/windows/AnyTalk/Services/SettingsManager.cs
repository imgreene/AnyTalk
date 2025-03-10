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
        using var key = Registry.CurrentUser.OpenSubKey(RegPath);
        if (key == null) return defaultValue;
        
        var value = key.GetValue(name);
        if (value == null) return defaultValue;
        
        return (T)Convert.ChangeType(value, typeof(T));
    }

    private void SaveSetting<T>(string name, T? value)
    {
        using var key = Registry.CurrentUser.CreateSubKey(RegPath);
        if (key != null)
        {
            key.SetValue(name, value);
        }
    }

    private void SetStartupRegistry(bool enable)
    {
        using var key = Registry.CurrentUser.OpenSubKey(@"SOFTWARE\Microsoft\Windows\CurrentVersion\Run", true);
        if (key != null)
        {
            if (enable)
            {
                key.SetValue(AppName, Application.ExecutablePath);
            }
            else
            {
                key.DeleteValue(AppName, false);
            }
        }
    }

    public void SetRegistryValue(string name, object? value)
    {
        using var key = Registry.CurrentUser.CreateSubKey(@"SOFTWARE\AnyTalk");
        if (value != null)
        {
            key.SetValue(name, value);
        }
    }
}
