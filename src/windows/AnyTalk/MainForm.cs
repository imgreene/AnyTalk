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
        // Load and apply settings
        var settings = SettingsManager.Instance.LoadSettings();
        if (string.IsNullOrEmpty(settings.ApiKey))
        {
            ShowMainWindow(this, EventArgs.Empty);
            tabControl1.SelectedTab = tabSettings;
        }
    }

    private void UpdateWordCount()
    {
        var totalWords = HistoryManager.Instance.GetTotalWordCount();
        lblTotalWords.Text = $"{totalWords:N0}";
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
        startRecordingMenuItem.Enabled = false;
        stopRecordingMenuItem.Enabled = true;
        audioRecorder.StartRecording();
    }

    private void StopRecording(object? sender, EventArgs e)
    {
        isRecording = false;
        startRecordingMenuItem.Enabled = true;
        stopRecordingMenuItem.Enabled = false;
        audioRecorder.StopRecording(audioFilePath =>
        {
            // Process the audio file and update history
            ProcessRecording(audioFilePath);
        });
        UpdateWordCount();
    }

    private async void ProcessRecording(string audioFilePath)
    {
        try
        {
            // Here you would add the code to send the audio to OpenAI's Whisper API
            // and process the transcription
            // Then update the history with the transcribed text
            
            // For now, let's just verify the file exists
            if (File.Exists(audioFilePath))
            {
                MessageBox.Show("Recording saved successfully!", "Success", 
                    MessageBoxButtons.OK, MessageBoxIcon.Information);
            }
        }
        catch (Exception ex)
        {
            MessageBox.Show($"Error processing recording: {ex.Message}", "Error",
                MessageBoxButtons.OK, MessageBoxIcon.Error);
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
        if (e.CloseReason == CloseReason.UserClosing)
        {
            e.Cancel = true;
            this.Hide();
        }
        else
        {
            base.OnFormClosing(e);
        }
    }
}
