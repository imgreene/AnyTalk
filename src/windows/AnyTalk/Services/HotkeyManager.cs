using System;
using System.Runtime.InteropServices;
using System.Windows.Forms;

namespace AnyTalk
{
    [Flags]
    public enum ModifierKeys : uint
    {
        None = 0x0000,
        Alt = 0x0001,
        Control = 0x0002,
        Shift = 0x0004,
        Win = 0x0008
    }

    public class HotkeyManager : IDisposable
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

        private const int HOTKEY_ID_DOWN = 1;
        private const int HOTKEY_ID_UP = 2;
        private readonly IntPtr _handle;
        private readonly Action _onHotkeyDown;
        private readonly Action _onHotkeyUp;
        private bool _isRegistered;

        public HotkeyManager(IntPtr handle, Action onHotkeyDown, Action onHotkeyUp)
        {
            _handle = handle;
            _onHotkeyDown = onHotkeyDown ?? throw new ArgumentNullException(nameof(onHotkeyDown));
            _onHotkeyUp = onHotkeyUp ?? throw new ArgumentNullException(nameof(onHotkeyUp));
            RegisterDefaultHotkey();
        }

        public void RegisterDefaultHotkey()
        {
            if (_isRegistered)
            {
                UnregisterHotKey(_handle, HOTKEY_ID_DOWN);
                UnregisterHotKey(_handle, HOTKEY_ID_UP);
            }

            // Register for both key down and key up events
            bool successDown = RegisterHotKey(_handle, HOTKEY_ID_DOWN, MOD_CONTROL | MOD_ALT, 0);
            bool successUp = RegisterHotKey(_handle, HOTKEY_ID_UP, 0, 0);  // Register for key up with no modifiers
            
            if (!successDown || !successUp)
            {
                int error = Marshal.GetLastWin32Error();
                throw new Exception($"Failed to register hotkey. Error code: {error}");
            }

            _isRegistered = true;
        }

        public void HandleHotkey(Message m)
        {
            const int WM_HOTKEY = 0x0312;
            
            if (m.Msg == WM_HOTKEY)
            {
                int id = m.WParam.ToInt32();
                
                if (id == HOTKEY_ID_DOWN)
                {
                    _onHotkeyDown?.Invoke();
                }
                else if (id == HOTKEY_ID_UP)
                {
                    _onHotkeyUp?.Invoke();
                }
            }
        }

        public void Cleanup()
        {
            if (_isRegistered)
            {
                UnregisterHotKey(_handle, HOTKEY_ID_DOWN);
                UnregisterHotKey(_handle, HOTKEY_ID_UP);
                _isRegistered = false;
            }
        }

        public void Dispose()
        {
            Cleanup();
        }
    }
}
