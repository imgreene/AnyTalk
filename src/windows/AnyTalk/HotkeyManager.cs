using System.Runtime.InteropServices;

namespace AnyTalk;

public class HotkeyManager
{
    [DllImport("user32.dll")]
    private static extern bool RegisterHotKey(IntPtr hWnd, int id, uint fsModifiers, uint vk);

    [DllImport("user32.dll")]
    private static extern bool UnregisterHotKey(IntPtr hWnd, int id);

    // Modifiers
    private const uint MOD_ALT = 0x0001;
    private const uint MOD_CONTROL = 0x0002;
    private const uint MOD_SHIFT = 0x0004;
    private const uint MOD_WIN = 0x0008;

    private const int HOTKEY_ID = 1;
    private IntPtr Handle;
    private Action OnHotkeyPressed;

    public HotkeyManager(IntPtr handle, Action onHotkeyPressed)
    {
        Handle = handle;
        OnHotkeyPressed = onHotkeyPressed;
        RegisterDefaultHotkey();
    }

    public void RegisterDefaultHotkey()
    {
        // Register Ctrl+Alt as default
        RegisterHotKey(Handle, HOTKEY_ID, MOD_CONTROL | MOD_ALT, 0);
    }

    public void HandleHotkey(Message m)
    {
        if (m.Msg == 0x0312 && m.WParam.ToInt32() == HOTKEY_ID)
        {
            OnHotkeyPressed?.Invoke();
        }
    }

    public void Cleanup()
    {
        UnregisterHotKey(Handle, HOTKEY_ID);
    }
}