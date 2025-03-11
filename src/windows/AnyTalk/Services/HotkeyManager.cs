using System;
using System.Runtime.InteropServices;
using System.Windows.Forms;

public class HotkeyManager : IDisposable
{
    private bool _isRegistered;
    private readonly int _hotkeyId;
    private readonly IntPtr _handle;

    [DllImport("user32.dll")]
    private static extern bool RegisterHotKey(IntPtr hWnd, int id, uint fsModifiers, uint vk);

    [DllImport("user32.dll")]
    private static extern bool UnregisterHotKey(IntPtr hWnd, int id);

    [DllImport("kernel32.dll", CharSet = CharSet.Auto)]
    private static extern IntPtr GetModuleHandle(string? lpModuleName);

    public HotkeyManager(IntPtr handle, int hotkeyId)
    {
        _handle = handle;
        _hotkeyId = hotkeyId;
        _isRegistered = false;
    }

    public bool RegisterHotkey(Keys key, ModifierKeys modifiers)
    {
        if (_isRegistered)
        {
            UnregisterHotkey();
        }

        _isRegistered = RegisterHotKey(_handle, _hotkeyId, (uint)modifiers, (uint)key);
        return _isRegistered;
    }

    public void UnregisterHotkey()
    {
        if (_isRegistered)
        {
            UnregisterHotKey(_handle, _hotkeyId);
            _isRegistered = false;
        }
    }

    public static IntPtr GetModuleHandleForCurrentProcess()
    {
        return GetModuleHandle(null);
    }

    public void Dispose()
    {
        UnregisterHotkey();
    }
}
