namespace AnyTalk;

public partial class MainForm : Form
{
    private TabControl tabControl;
    private Panel headerPanel;
    private Label titleLabel;
    private Label recordingLabel;
    private bool isRecording = false;
    private HotkeyManager? hotkeyManager;

    public MainForm()
    {
        // Initialize the form first
        InitializeComponent();
        
        // Then create the hotkey manager
        try
        {
            hotkeyManager = new HotkeyManager(this.Handle, OnHotkeyPressed);
        }
        catch (Exception ex)
        {
            MessageBox.Show($"Failed to initialize hotkeys: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
        }
    }

    private void InitializeComponent()
    {
        // Form settings
        this.Text = "AnyTalk";
        this.Size = new Size(320, 480);
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
        homeTab.Padding = new Padding(10);
        
        Label wordCountLabel = new Label
        {
            Text = "Total Words Dictated",
            Font = new Font("Segoe UI", 10),
            Location = new Point(10, 20),
            AutoSize = true
        };

        Label wordCount = new Label
        {
            Text = "0",
            Font = new Font("Segoe UI", 24, FontStyle.Bold),
            Location = new Point(10, 50),
            AutoSize = true
        };

        homeTab.Controls.Add(wordCountLabel);
        homeTab.Controls.Add(wordCount);

        // History Tab
        TabPage historyTab = new TabPage("History");
        ListView historyList = new ListView
        {
            Dock = DockStyle.Fill,
            View = View.Details
        };
        historyList.Columns.Add("Date", 100);
        historyList.Columns.Add("Text", 180);
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

        settingsLayout.Controls.Add(new Label { Text = "API Key:" }, 0, 0);
        settingsLayout.Controls.Add(new TextBox { Width = 200 }, 1, 0);
        settingsLayout.Controls.Add(new Label { Text = "Hotkey:" }, 0, 1);
        settingsLayout.Controls.Add(new TextBox { Width = 200, Text = "Ctrl+Alt", ReadOnly = true }, 1, 1);
        settingsLayout.Controls.Add(new Label { Text = "Launch at startup:" }, 0, 2);
        settingsLayout.Controls.Add(new CheckBox(), 1, 2);

        settingsTab.Controls.Add(settingsLayout);

        // Add tabs
        tabControl.TabPages.Add(homeTab);
        tabControl.TabPages.Add(historyTab);
        tabControl.TabPages.Add(settingsTab);

        // Add controls to form
        this.Controls.Add(headerPanel);
        this.Controls.Add(tabControl);
    }

    public void UpdateRecordingState(bool recording)
    {
        isRecording = recording;
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
