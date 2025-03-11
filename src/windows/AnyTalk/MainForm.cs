using AnyTalk.Models;
using AnyTalk.Services;
using System;
using System.Windows.Forms;

namespace AnyTalk
{
    public partial class MainForm : Form
    {
        private readonly Settings _settings;
        private readonly AudioRecorder _audioRecorder;
        private readonly NotifyIcon notifyIcon;
        private bool _isRecording;

        public MainForm()
        {
            InitializeComponent();
            _settings = SettingsManager.Instance.LoadSettings();
            _audioRecorder = new AudioRecorder();
            
            notifyIcon = new NotifyIcon
            {
                Icon = Properties.Resources.AppIcon,
                Visible = true,
                Text = "AnyTalk"
            };

            InitializeHotkeys();
        }

        private void InitializeHotkeys()
        {
            var hotkeyManager = new HotkeyManager(
                Handle,
                () => StartRecording(),
                () => StopRecording()
            );
        }

        private void StartRecording()
        {
            if (_isRecording) return;
            _isRecording = true;
            _audioRecorder.StartRecording(_settings.InputDevice);
        }

        private async void StopRecording()
        {
            if (!_isRecording) return;
            _isRecording = false;

            string? audioFilePath = null;
            await _audioRecorder.StopRecording(path => audioFilePath = path);

            if (!string.IsNullOrEmpty(audioFilePath))
            {
                await ProcessRecording(audioFilePath);
            }
        }

        private async Task ProcessRecording(string audioFilePath)
        {
            try
            {
                this.Invoke(() => this.Cursor = Cursors.WaitCursor);

                var result = await WhisperService.Instance.TranscribeAudio(audioFilePath);

                if (!result.IsSuccess)
                {
                    string userMessage = result.Error switch
                    {
                        WhisperError.NoAPIKey => "Please enter your OpenAI API key in Settings first.",
                        WhisperError.InvalidAudioFile => "The audio file could not be processed.",
                        WhisperError.NetworkError => $"Network error: {result.ErrorMessage}",
                        WhisperError.APIError => $"API error: {result.ErrorMessage}",
                        _ => "An unknown error occurred."
                    };

                    MessageBox.Show(userMessage, "Transcription Error", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                    return;
                }

                var transcribedText = result.Value;
                if (string.IsNullOrWhiteSpace(transcribedText))
                {
                    MessageBox.Show("No speech detected in the recording.", 
                        "Empty Transcription", MessageBoxButtons.OK, MessageBoxIcon.Information);
                    return;
                }

                HistoryManager.Instance.AddEntry(transcribedText);

                await this.Invoke(async () =>
                {
                    Clipboard.SetText(transcribedText);
                    await Task.Delay(100);
                    SendKeys.SendWait("^v");
                });
            }
            finally
            {
                this.Invoke(() => this.Cursor = Cursors.Default);
                
                try
                {
                    if (File.Exists(audioFilePath))
                    {
                        File.Delete(audioFilePath);
                    }
                }
                catch { /* ignore cleanup errors */ }
            }
        }

        private void ShowMainWindow(object? sender, EventArgs e)
        {
            this.Show();
            this.WindowState = FormWindowState.Normal;
            this.Activate();
        }

        private void Exit(object? sender, EventArgs e)
        {
            notifyIcon.Visible = false;
            Application.Exit();
        }

        protected override void OnFormClosing(FormClosingEventArgs e)
        {
            base.OnFormClosing(e);
            SaveSettings();
        }

        private void StartRecording_Click(object? sender, EventArgs e)
        {
            StartRecording();
        }

        private void StopRecording_Click(object? sender, EventArgs e)
        {
            StopRecording();
        }

        private void Settings_Click(object? sender, EventArgs e)
        {
            ShowSettingsTab();
        }

        private void Exit_Click(object? sender, EventArgs e)
        {
            Application.Exit();
        }

        protected override void Dispose(bool disposing)
        {
            if (disposing)
            {
                components?.Dispose();
                notifyIcon?.Dispose();
                if (_audioRecorder is IDisposable disposableRecorder)
                {
                    disposableRecorder.Dispose();
                }
            }
            base.Dispose(disposing);
        }
    }
}
