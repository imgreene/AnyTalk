using AnyTalk.Models;
using AnyTalk.Services;
using System.Text.Json;

namespace AnyTalk;

public partial class MainForm : Form
{
    private TabControl tabControl;
    private Panel headerPanel;
    private Label titleLabel;
    private Label recordingLabel;
    private bool isRecording = false;
    private HotkeyManager? hotkeyManager;
    private List<TranscriptionEntry> historyEntries = new();
    private Label wordCountLabel;
    private TextBox apiKeyTextBox;
    private string historyFilePath;

    public MainForm()
    {
        historyFilePath = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
            "AnyTalk",
            "history.json"
        );
        
        LoadHistory();
        InitializeComponent();
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
            Dock = DockStyle.Fill,
            Padding = new Point(10, 3)
        };

        // Home Tab
        TabPage homeTab = new TabPage("Home");
        wordCountLabel = new Label
        {
            Text = $"Total Words Dictated: {CalculateTotalWords()}",
            AutoSize = true,
            Location = new Point(10, 10)
        };
        homeTab.Controls.Add(wordCountLabel);

        // History Tab
        TabPage historyTab = new TabPage("History");
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
        TabPage settingsTab = new TabPage("Settings");
        TableLayoutPanel settingsLayout = new TableLayoutPanel
        {
            Dock = DockStyle.Fill,
            Padding = new Padding(10),
            RowCount = 4,
            ColumnCount = 2
        };

        // API Key
        settingsLayout.Controls.Add(new Label { Text = "API Key:" }, 0, 0);
        apiKeyTextBox = new TextBox 
        { 
            Width = 200,
            Text = SettingsManager.Instance.ApiKey
        };
        apiKeyTextBox.TextChanged += ApiKeyTextBox_TextChanged;
        settingsLayout.Controls.Add(apiKeyTextBox, 1, 0);

        // Hotkey
        settingsLayout.Controls.Add(new Label { Text = "Hotkey:" }, 0, 1);
        settingsLayout.Controls.Add(new TextBox 
        { 
            Width = 200, 
            Text = "Ctrl+Alt", 
            ReadOnly = true 
        }, 1, 1);

        // Launch at startup
        settingsLayout.Controls.Add(new Label { Text = "Launch at startup:" }, 0, 2);
        CheckBox startupCheckBox = new CheckBox
        {
            Checked = SettingsManager.Instance.LaunchAtStartup
        };
        startupCheckBox.CheckedChanged += StartupCheckBox_CheckedChanged;
        settingsLayout.Controls.Add(startupCheckBox, 1, 2);

        settingsTab.Controls.Add(settingsLayout);

        // Add tabs
        tabControl.TabPages.Add(homeTab);
        tabControl.TabPages.Add(historyTab);
        tabControl.TabPages.Add(settingsTab);

        // Add controls to form
        this.Controls.Add(headerPanel);
        this.Controls.Add(tabControl);
    }

    private void ApiKeyTextBox_TextChanged(object sender, EventArgs e)
    {
        SettingsManager.Instance.ApiKey = apiKeyTextBox.Text;
    }

    private void StartupCheckBox_CheckedChanged(object sender, EventArgs e)
    {
        CheckBox checkBox = (CheckBox)sender;
        SettingsManager.Instance.LaunchAtStartup = checkBox.Checked;
    }

    private void UpdateHistoryList(ListView listView)
    {
        listView.Items.Clear();
        foreach (var entry in historyEntries)
        {
            var item = new ListViewItem(entry.Timestamp.ToString("g"));
            item.SubItems.Add(entry.Text);
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
            Directory.CreateDirectory(Path.GetDirectoryName(historyFilePath));
            string json = JsonSerializer.Serialize(historyEntries);
            File.WriteAllText(historyFilePath, json);
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
}
