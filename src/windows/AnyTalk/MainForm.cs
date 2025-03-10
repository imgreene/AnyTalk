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
    private readonly AudioRecorder audioRecorder;
    private readonly Settings settings;
    private bool isRecording;

    public MainForm()
    {
        InitializeComponent();
        LoadSettings();

        // Initialize all readonly fields
        notifyIcon = new NotifyIcon
        {
            Icon = new Icon("Resources/AppIcon.ico"),
            Visible = true,
            Text = "AnyTalk"
        };

        contextMenu = new ContextMenuStrip();
        startRecordingMenuItem = new ToolStripMenuItem("Start Recording");
        stopRecordingMenuItem = new ToolStripMenuItem("Stop Recording") { Enabled = false };
        settingsMenuItem = new ToolStripMenuItem("Settings");
        exitMenuItem = new ToolStripMenuItem("Exit");

        // Set up menu items
        contextMenu.Items.Add(startRecordingMenuItem);
        contextMenu.Items.Add(stopRecordingMenuItem);
        contextMenu.Items.Add(new ToolStripSeparator());
        contextMenu.Items.Add(settingsMenuItem);
        contextMenu.Items.Add(new ToolStripSeparator());
        contextMenu.Items.Add(exitMenuItem);

        notifyIcon.ContextMenuStrip = contextMenu;

        // Initialize audio recorder and settings
        audioRecorder = new AudioRecorder();
        settings = SettingsManager.Instance.LoadSettings();

        // Wire up event handlers
        startRecordingMenuItem.Click += StartRecording;
        stopRecordingMenuItem.Click += StopRecording;
        settingsMenuItem.Click += ShowMainWindow;
        exitMenuItem.Click += Exit;
        notifyIcon.DoubleClick += ShowMainWindow;

        // Update word count
        UpdateWordCount();
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
        lblTotalWords.Text = $"{totalWords:N0}";
    }

    private void UpdateRecordingState()
    {
        startRecordingMenuItem.Enabled = !isRecording;
        stopRecordingMenuItem.Enabled = isRecording;
        // You can add more UI updates based on recording state
    }

    private void StartRecording(object? sender, EventArgs e)
    {
        if (string.IsNullOrEmpty(settings.ApiKey))
        {
            MessageBox.Show("Please enter your OpenAI API key in Settings first.", "API Key Required",
                MessageBoxButtons.OK, MessageBoxIcon.Warning);
            ShowMainWindow(this, EventArgs.Empty);
            tabControl1.SelectedTab = tabSettings;
            return;
        }

        isRecording = true;
        UpdateRecordingState();
        audioRecorder.StartRecording();
    }

    private void StopRecording(object? sender, EventArgs e)
    {
        isRecording = false;
        UpdateRecordingState();
        audioRecorder.StopRecording(async audioFilePath =>
        {
            await ProcessRecording(audioFilePath);
        });
        UpdateWordCount();
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

            // Save to history
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
}
