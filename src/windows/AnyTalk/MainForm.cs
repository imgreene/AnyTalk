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
    private readonly Settings _settings;
    private bool _isRecording = false;

    public MainForm()
    {
        // Initialize all required fields before InitializeComponent
        contextMenu = new ContextMenuStrip();
        startRecordingMenuItem = new ToolStripMenuItem("Start Recording", null, StartRecording_Click);
        stopRecordingMenuItem = new ToolStripMenuItem("Stop Recording", null, StopRecording_Click);
        settingsMenuItem = new ToolStripMenuItem("Settings", null, Settings_Click);
        exitMenuItem = new ToolStripMenuItem("Exit", null, Exit_Click);
        _audioRecorder = new AudioRecorder();
        _settings = SettingsManager.Instance.LoadSettings() ?? new Settings();

        InitializeComponent();
        InitializeNotifyIcon();
        LoadSettings();
    }

    private void InitializeNotifyIcon()
    {
        contextMenu.Items.AddRange(new ToolStripItem[]
        {
            startRecordingMenuItem,
            stopRecordingMenuItem,
            new ToolStripSeparator(),
            settingsMenuItem,
            new ToolStripSeparator(),
            exitMenuItem
        });

        notifyIcon = new NotifyIcon
        {
            Icon = new Icon("Resources/AppIcon.ico"),
            ContextMenuStrip = contextMenu,
            Visible = true
        };

        UpdateRecordingState();
    }

    private void LoadSettings()
    {
        settings = SettingsManager.Instance.LoadSettings();
        txtApiKey.Text = settings.ApiKey;
    }

    private void SaveSettings()
    {
        SettingsManager.Instance.SaveSettings(settings);
    }

    private void UpdateWordCount()
    {
        var totalWords = HistoryManager.Instance.GetTotalWordCount();
        this.Invoke(() => lblTotalWords.Text = $"{totalWords:N0}");
    }

    private void UpdateRecordingState()
    {
        startRecordingMenuItem.Enabled = !_isRecording;
        stopRecordingMenuItem.Enabled = _isRecording;
    }

    private void ShowSettingsTab()
    {
        tabControl1.SelectedTab = tabSettings;
    }

    private void StartRecording()
    {
        if (string.IsNullOrEmpty(settings.ApiKey))
        {
            MessageBox.Show("Please enter your OpenAI API key in Settings first.", 
                "API Key Required", MessageBoxButtons.OK, MessageBoxIcon.Warning);
            ShowSettingsTab();
            return;
        }

        _isRecording = true;
        UpdateRecordingState();
        _audioRecorder.StartRecording();
        
        notifyIcon.Icon = new Icon("Resources/RecordingIcon.ico");
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
        
        if (notifyIcon != null)
        {
            notifyIcon.Icon = new Icon("Resources/DefaultIcon.ico");
            notifyIcon.Text = "AnyTalk";
        }

        string? audioFilePath = null;
        _audioRecorder.StopRecording(path => audioFilePath = path);

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
            notifyIcon?.Dispose();
            contextMenu?.Dispose();
            _audioRecorder?.Dispose();
            components?.Dispose();
        }
        base.Dispose(disposing);
    }
}
