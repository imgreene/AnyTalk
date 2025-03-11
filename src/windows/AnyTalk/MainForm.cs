using AnyTalk.Models;
using AnyTalk.Services;
using System.Text.Json;

namespace AnyTalk;

public partial class MainForm : Form
{
    private readonly NotifyIcon notifyIcon;
    private readonly ContextMenuStrip contextMenu;
    private readonly ToolStripMenuItem startRecordingMenuItem;
    private readonly ToolStripMenuItem stopRecordingMenuItem;
    private readonly ToolStripMenuItem settingsMenuItem;
    private readonly ToolStripMenuItem exitMenuItem;
    private readonly AudioRecorder _audioRecorder;
    private readonly Settings settings;
    private bool isRecording;
    private readonly HotkeyManager _hotkeyManager;
    private bool _isRecording = false;

    public MainForm()
    {
        InitializeComponent();
        LoadSettings();

        // Initialize all readonly fields
        notifyIcon = new NotifyIcon
        {
            Icon = new Icon("Resources/AppIcon.ico"),
            Visible = true
        };

        _audioRecorder = new AudioRecorder();
        
        _hotkeyManager = new HotkeyManager(
            this.Handle,
            onHotkeyDown: () => {
                if (!_isRecording)
                {
                    BeginInvoke(StartRecording);
                }
            },
            onHotkeyUp: () => {
                if (_isRecording)
                {
                    BeginInvoke(StopRecording);
                }
            }
        );
    }

    private void LoadSettings()
    {
        var settings = SettingsManager.Instance.LoadSettings();
        txtApiKey.Text = settings.ApiKey;
        // Load other settings...
    }

    private void SaveSettings()
    {
        SettingsManager.Instance.SaveApiKey(txtApiKey.Text);
        // Save other settings...
    }

    private void UpdateWordCount()
    {
        var totalWords = HistoryManager.Instance.GetTotalWordCount();
        this.Invoke(() => lblTotalWords.Text = $"{totalWords:N0}");
    }

    private void UpdateRecordingState()
    {
        startRecordingMenuItem.Enabled = !isRecording;
        stopRecordingMenuItem.Enabled = isRecording;
        // You can add more UI updates based on recording state
    }

    private void StartRecording()
    {
        if (string.IsNullOrEmpty(SettingsManager.Instance.ApiKey))
        {
            MessageBox.Show("Please enter your OpenAI API key in Settings first.", 
                "API Key Required", MessageBoxButtons.OK, MessageBoxIcon.Warning);
            ShowSettingsTab();
            return;
        }

        _isRecording = true;
        UpdateRecordingState();
        _audioRecorder.StartRecording();
        
        notifyIcon.Icon = Properties.Resources.RecordingIcon;
        notifyIcon.Text = "AnyTalk (Recording...)";
    }

    private async void StopRecording()
    {
        if (!_isRecording)
        {
            return;
        }

        _isRecording = false;
        UpdateRecordingState();
        
        notifyIcon.Icon = Properties.Resources.DefaultIcon;
        notifyIcon.Text = "AnyTalk";

        var audioFilePath = _audioRecorder.StopRecording();
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

            // Save to history - this will also trigger word count update
            HistoryManager.Instance.AddEntry(transcribedText);

            // Copy to clipboard and paste
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
            
            // Cleanup the temporary audio file
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

    protected override void Dispose(bool disposing)
    {
        if (disposing && (components != null))
        {
            components.Dispose();
        }
        base.Dispose(disposing);
    }
}
