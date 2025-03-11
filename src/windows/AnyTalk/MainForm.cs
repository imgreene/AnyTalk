using AnyTalk.Services;
using AnyTalk.Models;
using AnyTalk.Audio;
using System.Windows.Forms;

namespace AnyTalk
{
    public partial class MainForm : Form
    {
        private readonly Settings _settings;
        private readonly SettingsManager _settingsManager;
        private readonly AnyTalk.Audio.AudioRecorder _audioRecorder;
        private readonly WhisperService _whisperService;
        private readonly HotkeyManager _hotkeyManager;
        private NotifyIcon _trayIcon;
        private bool _isRecording;

        public MainForm()
        {
            InitializeComponent();
            _settingsManager = SettingsManager.Instance;
            _settings = _settingsManager.LoadSettings();
            _audioRecorder = new AnyTalk.Audio.AudioRecorder();
            _whisperService = WhisperService.Instance;

            // Initialize hotkey manager
            _hotkeyManager = new HotkeyManager(
                this.Handle,
                StartRecording,
                StopRecording
            );

            InitializeUI();
            SetupTrayIcon();

            // Hide main window on startup
            this.WindowState = FormWindowState.Minimized;
            this.ShowInTaskbar = false;
            this.Hide();
        }

        private void SetupTrayIcon()
        {
            _trayIcon = new NotifyIcon
            {
                Icon = Properties.Resources.AppIcon,
                Visible = true,
                Text = "AnyTalk"
            };

            // Create context menu
            var contextMenu = new ContextMenuStrip();
            
            var startDictationItem = new ToolStripMenuItem("Start Dictation", null, (s, e) => StartRecording());
            var stopDictationItem = new ToolStripMenuItem("Stop Dictation", null, (s, e) => StopRecording());
            var settingsItem = new ToolStripMenuItem("Settings", null, (s, e) => ShowSettings());
            var exitItem = new ToolStripMenuItem("Exit", null, (s, e) => Application.Exit());

            contextMenu.Items.AddRange(new ToolStripItem[]
            {
                startDictationItem,
                stopDictationItem,
                new ToolStripSeparator(),
                settingsItem,
                new ToolStripSeparator(),
                exitItem
            });

            _trayIcon.ContextMenuStrip = contextMenu;

            // Double-click to show settings
            _trayIcon.DoubleClick += (s, e) => ShowSettings();
        }

        private void ShowSettings()
        {
            this.Show();
            this.WindowState = FormWindowState.Normal;
            this.Activate();
        }

        private void UpdateTrayIcon()
        {
            if (_trayIcon != null)
            {
                _trayIcon.Text = _isRecording ? "AnyTalk (Recording...)" : "AnyTalk";
                
                // Update menu items
                var menu = _trayIcon.ContextMenuStrip;
                if (menu != null)
                {
                    menu.Items[0].Enabled = !_isRecording; // Start Dictation
                    menu.Items[1].Enabled = _isRecording;  // Stop Dictation
                }
            }
        }

        protected override void WndProc(ref Message m)
        {
            _hotkeyManager?.HandleHotkey(m);
            base.WndProc(ref m);
        }

        private void StartRecording()
        {
            if (InvokeRequired)
            {
                Invoke(new Action(StartRecording));
                return;
            }

            if (!_isRecording)
            {
                _isRecording = true;
                _audioRecorder.StartRecording();
                UpdateUIState(true);
                UpdateTrayIcon();

                // Show notification
                _trayIcon.ShowBalloonTip(
                    2000,
                    "AnyTalk",
                    "Recording started",
                    ToolTipIcon.Info
                );
            }
        }

        private void StopRecording()
        {
            if (InvokeRequired)
            {
                Invoke(new Action(StopRecording));
                return;
            }

            if (_isRecording)
            {
                _isRecording = false;
                _audioRecorder.StopRecording(async (audioFile) => {
                    if (audioFile != null)
                    {
                        await ProcessAudioFileAsync(audioFile);
                    }
                });
                UpdateUIState(false);
                UpdateTrayIcon();
            }
        }

        private async Task ProcessAudioFileAsync(string audioFile)
        {
            try
            {
                _trayIcon.ShowBalloonTip(
                    2000,
                    "AnyTalk",
                    "Transcribing audio...",
                    ToolTipIcon.Info
                );

                var result = await _whisperService.TranscribeAudio(audioFile);
                if (result.IsSuccess && result.Value != null)
                {
                    // Copy to clipboard
                    if (!string.IsNullOrEmpty(result.Value))
                    {
                        Clipboard.SetText(result.Value);
                        _trayIcon.ShowBalloonTip(
                            2000,
                            "AnyTalk",
                            "Transcription copied to clipboard",
                            ToolTipIcon.Info
                        );
                    }
                }
                else
                {
                    _trayIcon.ShowBalloonTip(
                        2000,
                        "AnyTalk",
                        $"Transcription failed: {result.ErrorMessage}",
                        ToolTipIcon.Error
                    );
                }
            }
            catch (Exception ex)
            {
                _trayIcon.ShowBalloonTip(
                    2000,
                    "AnyTalk",
                    $"Transcription failed: {ex.Message}",
                    ToolTipIcon.Error
                );
            }
        }

        private void UpdateUIState(bool isRecording)
        {
            // Update UI elements based on recording state
            if (btnRecord != null) btnRecord.Enabled = !isRecording;
            if (btnStop != null) btnStop.Enabled = isRecording;
        }

        protected override void OnFormClosing(FormClosingEventArgs e)
        {
            if (e.CloseReason == CloseReason.UserClosing)
            {
                e.Cancel = true;
                this.Hide();
                return;
            }

            _trayIcon?.Dispose();
            _hotkeyManager?.Dispose();
            _audioRecorder?.Dispose();
            base.OnFormClosing(e);
        }

        // Handle manual button clicks
        private void btnRecord_Click(object sender, EventArgs e)
        {
            StartRecording();
        }

        private void btnStop_Click(object sender, EventArgs e)
        {
            StopRecording();
        }
    }
}
