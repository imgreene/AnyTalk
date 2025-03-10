using System;
using System.Runtime.InteropServices;
using System.Windows.Forms;

public class HotkeyManager : IDisposable
{
    private readonly IntPtr _handle;
    private bool _isRegistered;
    private readonly Action _onHotkeyDown;
    private readonly Action _onHotkeyUp;
    private const int HOTKEY_ID_DOWN = 1;
    private const int HOTKEY_ID_UP = 2;

    // Windows API constants
    private const int MOD_ALT = 0x0001;
    private const int MOD_CONTROL = 0x0002;
    private const int WM_HOTKEY = 0x0312;
    private const int WM_KEYDOWN = 0x0100;
    private const int WM_KEYUP = 0x0101;
    private const int WH_KEYBOARD_LL = 13;

    private IntPtr _hookID = IntPtr.Zero;
    private bool _isHotkeyPressed = false;
    private readonly LowLevelKeyboardProc _proc;

    [DllImport("user32.dll")]
    private static extern bool RegisterHotKey(IntPtr hWnd, int id, int fsModifiers, int vk);

    [DllImport("user32.dll")]
    private static extern bool UnregisterHotKey(IntPtr hWnd, int id);

    [DllImport("user32.dll")]
    private static extern IntPtr SetWindowsHookEx(int idHook, LowLevelKeyboardProc lpfn, IntPtr hMod, uint dwThreadId);

    [DllImport("user32.dll")]
    private static extern bool UnhookWindowsHookEx(IntPtr hhk);

    [DllImport("user32.dll")]
    private static extern IntPtr CallNextHookEx(IntPtr hhk, int nCode, IntPtr wParam, IntPtr lParam);

    [DllImport("kernel32.dll")]
    private static extern IntPtr GetModuleHandle(string lpModuleName);

    private delegate IntPtr LowLevelKeyboardProc(int nCode, IntPtr wParam, IntPtr lParam);

    public HotkeyManager(IntPtr handle, Action onHotkeyDown, Action onHotkeyUp)
    {
        _handle = handle;
        _onHotkeyDown = onHotkeyDown ?? throw new ArgumentNullException(nameof(onHotkeyDown));
        _onHotkeyUp = onHotkeyUp ?? throw new ArgumentNullException(nameof(onHotkeyUp));
        _proc = HookCallback;
        _hookID = SetHook(_proc);
    }

    private IntPtr SetHook(LowLevelKeyboardProc proc)
    {
        using (var curProcess = System.Diagnostics.Process.GetCurrentProcess())
        using (var curModule = curProcess.MainModule)
        {
            return SetWindowsHookEx(WH_KEYBOARD_LL, proc,
                GetModuleHandle(curModule?.ModuleName), 0);
        }
    }

    private IntPtr HookCallback(int nCode, IntPtr wParam, IntPtr lParam)
    {
        if (nCode >= 0)
        {
            int vkCode = Marshal.ReadInt32(lParam);
            bool isCtrlPressed = (Control.ModifierKeys & Keys.Control) == Keys.Control;
            bool isAltPressed = (Control.ModifierKeys & Keys.Alt) == Keys.Alt;

            if (isCtrlPressed && isAltPressed)
            {
                if (!_isHotkeyPressed && wParam == (IntPtr)WM_KEYDOWN)
                {
                    _isHotkeyPressed = true;
                    _onHotkeyDown?.Invoke();
                }
                else if (_isHotkeyPressed && wParam == (IntPtr)WM_KEYUP)
                {
                    _isHotkeyPressed = false;
                    _onHotkeyUp?.Invoke();
                }
            }
            else if (_isHotkeyPressed && (!isCtrlPressed || !isAltPressed))
            {
                _isHotkeyPressed = false;
                _onHotkeyUp?.Invoke();
            }
        }
        return CallNextHookEx(_hookID, nCode, wParam, lParam);
    }

    public void Dispose()
    {
        if (_hookID != IntPtr.Zero)
        {
            UnhookWindowsHookEx(_hookID);
            _hookID = IntPtr.Zero;
        }
    }
}
