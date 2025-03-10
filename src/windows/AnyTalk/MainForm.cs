using AnyTalk.Models;
using AnyTalk.Services;
using System.Text.Json;
using NAudio.Wave;
using NAudio.CoreAudioApi;
using System.Diagnostics;

namespace AnyTalk;

public partial class MainForm : Form
{
    private TabControl tabControl = null!;
    private TabPage homeTab = null!;
    private TabPage historyTab = null!;
    private TabPage settingsTab = null!;
    private Panel headerPanel = null!;
    private Label titleLabel = null!;
    private Label recordingLabel = null!;
    private bool isRecording = false;
    private HotkeyManager? hotkeyManager;
    private List<TranscriptionEntry> historyEntries = new();
    private Label wordCountLabel = null!;
    private TextBox apiKeyTextBox = null!;
    private string historyFilePath = null!;

    public MainForm()
    {
        InitializeComponent();
        InitializeTabs();
        LoadHistory();
        InitializeHotkeys();
    }

    private void InitializeComponent()
    {
        // Form settings
        this.Text = "AnyTalk";
        this.Size = new Size(400, 500);
        this.MinimumSize = new Size(320, 400);
        this.FormBorderStyle = FormBorderStyle.FixedSingle;
        this.MaximizeBox = false;
        this.StartPosition = FormStartPosition.CenterScreen;

        // Header Panel
        headerPanel = new Panel
        {
            Dock = DockStyle.Top,
            Height = 40,
            BackColor = SystemColors.Control
        };

        titleLabel = new Label
        {
            Text = "AnyTalk",
            Font = new Font("Segoe UI", 12, FontStyle.Bold),
            Location = new Point(10, 10),
            AutoSize = true
        };

        recordingLabel = new Label
        {
            Text = "Recording",
            ForeColor = Color.Orange,
            Visible = false,
            Location = new Point(headerPanel.Width - 80, 10),
            AutoSize = true
        };

        headerPanel.Controls.Add(titleLabel);
        headerPanel.Controls.Add(recordingLabel);

        // Tab Control
        tabControl = new TabControl
        {
            Dock = DockStyle.Fill
        };

        // Home Tab
        homeTab = new TabPage("Home");
        wordCountLabel = new Label
        {
            Text = $"Total Words Dictated: {CalculateTotalWords()}",
            AutoSize = true,
            Location = new Point(10, 10)
        };
        homeTab.Controls.Add(wordCountLabel);

        // History Tab
        historyTab = new TabPage("History");
        ListView historyList = new ListView
        {
            Dock = DockStyle.Fill,
            View = View.Details,
            FullRowSelect = true
        };
        historyList.Columns.Add("Date", 150);
        historyList.Columns.Add("Text", 200);
        UpdateHistoryList(historyList);
        historyTab.Controls.Add(historyList);

        // Settings Tab
        settingsTab = new TabPage("Settings");
        InitializeSettingsTab();

        tabControl.TabPages.Add(homeTab);
        tabControl.TabPages.Add(historyTab);
        tabControl.TabPages.Add(settingsTab);

        // Add controls to form
        this.Controls.Add(headerPanel);
        this.Controls.Add(tabControl);
    }

    private void InitializeTabs()
    {
        tabControl = new TabControl
        {
            Dock = DockStyle.Fill
        };

        homeTab = new TabPage("Home");
        historyTab = new TabPage("History");
        settingsTab = new TabPage("Settings");

        tabControl.TabPages.Add(homeTab);
        tabControl.TabPages.Add(historyTab);
        tabControl.TabPages.Add(settingsTab);

        Controls.Add(tabControl);
        
        InitializeHomeTab();
        InitializeHistoryTab();
        InitializeSettingsTab();
    }

    private void InitializeHomeTab()
    {
        wordCountLabel = new Label
        {
            Text = $"Total Words Dictated: {CalculateTotalWords()}",
            AutoSize = true,
            Location = new Point(20, 20)
        };
        homeTab.Controls.Add(wordCountLabel);

        recordingLabel = new Label
        {
            Text = "Press Ctrl+Alt to start dictating",
            AutoSize = true,
            Location = new Point(20, 50)
        };
        homeTab.Controls.Add(recordingLabel);
    }

    private void InitializeHistoryTab()
    {
        var historyList = new ListView
        {
            Dock = DockStyle.Fill,
            View = View.Details,
            FullRowSelect = true
        };

        historyList.Columns.Add("Date", 150);
        historyList.Columns.Add("Text", 400);
        historyList.Columns.Add("Words", 70);

        UpdateHistoryList(historyList);
        historyTab.Controls.Add(historyList);
    }

    private void InitializeSettingsTab()
    {
        var layout = new TableLayoutPanel
        {
            Dock = DockStyle.Fill,
            ColumnCount = 2,
            RowCount = 2,
            Padding = new Padding(10)
        };

        layout.Controls.Add(new Label { Text = "OpenAI API Key:" }, 0, 0);
        
        apiKeyTextBox = new TextBox
        {
            Width = 300,
            PasswordChar = '•'
        };
        layout.Controls.Add(apiKeyTextBox, 1, 0);

        var saveButton = new Button
        {
            Text = "Save Settings",
            AutoSize = true
        };
        saveButton.Click += SaveSettings_Click;
        layout.Controls.Add(saveButton, 1, 1);

        settingsTab.Controls.Add(layout);

        // Load saved API key
        var settings = new SettingsManager();
        apiKeyTextBox.Text = settings.GetApiKey();
    }

    private void SaveSettings_Click(object sender, EventArgs e)
    {
        var settings = new SettingsManager();
        settings.SaveApiKey(apiKeyTextBox.Text);
        MessageBox.Show("Settings saved successfully!", "Success", MessageBoxButtons.OK, MessageBoxIcon.Information);
    }

    private void PopulateMicrophoneList(ComboBox combo)
    {
        combo.Items.Add("Default Device");
        foreach (string device in AudioRecorder.GetAvailableMicrophones())
        {
            combo.Items.Add(device);
        }
        combo.SelectedIndex = 0;
    }

    private void PopulateLanguageList(ComboBox combo)
    {
        var languages = new Dictionary<string, string>
        {
            {"en", "English"},
            {"es", "Spanish"},
            {"fr", "French"},
            {"de", "German"},
            {"it", "Italian"},
            {"pt", "Portuguese"},
            {"nl", "Dutch"},
            {"ru", "Russian"},
            {"ja", "Japanese"},
            {"ko", "Korean"},
            {"zh", "Chinese"}
        };

        foreach (var lang in languages)
        {
            combo.Items.Add(lang.Value);
        }
        combo.SelectedIndex = 0;
    }

    private void ApiKeyTextBox_TextChanged(object? sender, EventArgs e)
    {
        SettingsManager.Instance.ApiKey = apiKeyTextBox.Text;
    }

    private void StartupCheckBox_CheckedChanged(object? sender, EventArgs e)
    {
        if (sender is CheckBox checkBox)
        {
            SettingsManager.Instance.LaunchAtStartup = checkBox.Checked;
        }
    }

    private void UpdateHistoryList(ListView listView)
    {
        listView.Items.Clear();
        foreach (var entry in historyEntries)
        {
            var item = new ListViewItem(entry.Timestamp.ToString("g"));
            item.SubItems.Add(entry.Text);
            item.SubItems.Add(entry.WordCount.ToString());
            listView.Items.Add(item);
        }
    }

    private int CalculateTotalWords()
    {
        return historyEntries.Sum(entry => entry.WordCount);
    }

    public void AddTranscription(string text)
    {
        var entry = new TranscriptionEntry(text);
        historyEntries.Insert(0, entry);
        SaveHistory();
        
        wordCountLabel.Text = $"Total Words Dictated: {CalculateTotalWords()}";
        
        if (tabControl.SelectedTab.Text == "History")
        {
            var historyList = (ListView)tabControl.SelectedTab.Controls[0];
            UpdateHistoryList(historyList);
        }
    }

    private void LoadHistory()
    {
        try
        {
            if (File.Exists(historyFilePath))
            {
                string json = File.ReadAllText(historyFilePath);
                historyEntries = JsonSerializer.Deserialize<List<TranscriptionEntry>>(json) ?? new List<TranscriptionEntry>();
            }
        }
        catch (Exception ex)
        {
            MessageBox.Show($"Error loading history: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            historyEntries = new List<TranscriptionEntry>();
        }
    }

    private void SaveHistory()
    {
        try
        {
            string? directoryPath = Path.GetDirectoryName(historyFilePath);
            if (directoryPath != null)
            {
                Directory.CreateDirectory(directoryPath);
                string json = JsonSerializer.Serialize(historyEntries);
                File.WriteAllText(historyFilePath, json);
            }
        }
        catch (Exception ex)
        {
            MessageBox.Show($"Error saving history: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
        }
    }

    private void InitializeHotkeys()
    {
        hotkeyManager = new HotkeyManager(
            this.Handle,
            onHotkeyDown: () => {
                if (!isRecording)
                {
                    StartRecording();
                }
            },
            onHotkeyUp: () => {
                if (isRecording)
                {
                    StopRecording();
                }
            }
        );
    }

    private void StartRecording()
    {
        if (InvokeRequired)
        {
            Invoke(new Action(StartRecording));
            return;
        }

        isRecording = true;
        UpdateRecordingState(true);
        // Start your audio recording here
        System.Media.SystemSounds.Asterisk.Play(); // Optional: Play sound to indicate recording started
    }

    private void StopRecording()
    {
        if (InvokeRequired)
        {
            Invoke(new Action(StopRecording));
            return;
        }

        isRecording = false;
        UpdateRecordingState(false);
        // Stop recording and process the audio here
        System.Media.SystemSounds.Hand.Play(); // Optional: Play sound to indicate recording stopped
    }

    private void UpdateRecordingState(bool recording)
    {
        recordingLabel.Visible = recording;
        recordingLabel.Text = recording ? "● Recording" : "";
    }

    protected override void WndProc(ref Message m)
    {
        // Safely handle hotkey messages
        if (hotkeyManager != null)
        {
            hotkeyManager.HandleHotkey(m);
        }
        base.WndProc(ref m);
    }

    private void OnHotkeyPressed()
    {
        if (InvokeRequired)
        {
            Invoke(new Action(OnHotkeyPressed));
            return;
        }

        UpdateRecordingState(true);
        // Implement your recording logic here
    }

    protected override void OnFormClosing(FormClosingEventArgs e)
    {
        if (hotkeyManager != null)
        {
            hotkeyManager.Cleanup();
        }
        base.OnFormClosing(e);
    }

    private void RequestMicrophonePermission()
    {
        try
        {
            using (var audioClient = new MMDeviceEnumerator())
            {
                var devices = audioClient.EnumerateAudioEndPoints(DataFlow.Capture, DeviceState.Active);
                if (devices.Count > 0)
                {
                    using (var capture = new WasapiCapture(devices[0]))
                    {
                        capture.StartRecording(); // Changed from Initialize()
                        capture.StopRecording();
                    }
                }
            }
        }
        catch (UnauthorizedAccessException)
        {
            MessageBox.Show(
                "Microphone access is required for AnyTalk to work. Please enable it in Windows Settings > Privacy > Microphone.",
                "Microphone Access Required",
                MessageBoxButtons.OK,
                MessageBoxIcon.Warning
            );
            
            Process.Start(new ProcessStartInfo
            {
                FileName = "ms-settings:privacy-microphone",
                UseShellExecute = true
            });
        }
    }

    protected override void OnLoad(EventArgs e)
    {
        base.OnLoad(e);
        RequestMicrophonePermission();
    }
}
