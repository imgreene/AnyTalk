using System.Runtime.InteropServices;

namespace AnyTalk;

public class HotkeyManager
{
    [DllImport("user32.dll", SetLastError = true)]
    private static extern bool RegisterHotKey(IntPtr hWnd, int id, uint fsModifiers, uint vk);

    [DllImport("user32.dll", SetLastError = true)]
    private static extern bool UnregisterHotKey(IntPtr hWnd, int id);

    // Modifiers
    private const uint MOD_ALT = 0x0001;
    private const uint MOD_CONTROL = 0x0002;
    private const uint MOD_SHIFT = 0x0004;
    private const uint MOD_WIN = 0x0008;
    private const uint MOD_NOREPEAT = 0x4000;

    private const int HOTKEY_ID = 1;
    private readonly IntPtr _handle;
    private readonly Action _onHotkeyPressed;
    private bool _isRegistered;

    public HotkeyManager(IntPtr handle, Action onHotkeyPressed)
    {
        _handle = handle;
        _onHotkeyPressed = onHotkeyPressed ?? throw new ArgumentNullException(nameof(onHotkeyPressed));
        RegisterDefaultHotkey();
    }

    public void RegisterDefaultHotkey()
    {
        if (_isRegistered)
        {
            UnregisterHotKey(_handle, HOTKEY_ID);
        }

        // Register Ctrl+Alt as default with no-repeat flag
        bool success = RegisterHotKey(_handle, HOTKEY_ID, MOD_CONTROL | MOD_ALT | MOD_NOREPEAT, 0);
        
        if (!success)
        {
            int error = Marshal.GetLastWin32Error();
            throw new Exception($"Failed to register hotkey. Error code: {error}");
        }

        _isRegistered = true;
    }

    public void HandleHotkey(Message m)
    {
        const int WM_HOTKEY = 0x0312;
        
        if (m.Msg == WM_HOTKEY && m.WParam.ToInt32() == HOTKEY_ID)
        {
            _onHotkeyPressed?.Invoke();
        }
    }

    public void Cleanup()
    {
        if (_isRegistered)
        {
            UnregisterHotKey(_handle, HOTKEY_ID);
            _isRegistered = false;
        }
    }
}
