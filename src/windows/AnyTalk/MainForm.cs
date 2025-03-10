using AnyTalk.Models;
using AnyTalk.Services;
using System.Text.Json;
using NAudio.Wave;
using NAudio.CoreAudioApi;
using System.Diagnostics;

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

        // Initialize all readonly fields in the constructor
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
        settings = new Settings();

        // Wire up event handlers
        startRecordingMenuItem.Click += StartRecording;
        stopRecordingMenuItem.Click += StopRecording;
        settingsMenuItem.Click += ShowSettings;
        exitMenuItem.Click += Exit;

        // Set up form properties
        this.WindowState = FormWindowState.Minimized;
        this.ShowInTaskbar = false;
    }

    private void StartRecording(object? sender, EventArgs e)
    {
        if (settings.ApiKey == null || settings.ApiKey.Trim().Length == 0)
        {
            MessageBox.Show("Please enter your OpenAI API key in Settings first.", "API Key Required",
                MessageBoxButtons.OK, MessageBoxIcon.Warning);
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
        audioRecorder.StopRecording();
    }

    private void ShowSettings(object? sender, EventArgs e)
    {
        using (var settingsForm = new SettingsForm(settings))
        {
            settingsForm.ShowDialog();
        }
    }

    private void Exit(object? sender, EventArgs e)
    {
        if (isRecording)
        {
            audioRecorder.StopRecording();
        }
        notifyIcon.Visible = false;
        Application.Exit();
    }

    protected override void OnFormClosing(FormClosingEventArgs e)
    {
        if (e.CloseReason == CloseReason.UserClosing)
        {
            e.Cancel = true;
            this.WindowState = FormWindowState.Minimized;
            this.Hide();
        }
        else
        {
            base.OnFormClosing(e);
        }
    }
}
