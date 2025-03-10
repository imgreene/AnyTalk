using AnyTalk.Services;

namespace AnyTalk
{
    partial class MainForm
    {
        private System.ComponentModel.IContainer components = null;

        protected override void Dispose(bool disposing)
        {
            if (disposing)
            {
                if (components != null)
                {
                    components.Dispose();
                }
                if (_hotkeyManager != null)
                {
                    _hotkeyManager.Dispose();
                }
                if (_audioRecorder != null)
                {
                    _audioRecorder.Dispose();
                }
            }
            base.Dispose(disposing);
        }

        private void InitializeComponent()
        {
            components = new System.ComponentModel.Container();
            
            // Form settings
            this.Text = "AnyTalk";
            this.Size = new System.Drawing.Size(800, 600);
            this.StartPosition = FormStartPosition.CenterScreen;
            this.MinimumSize = new System.Drawing.Size(800, 600);

            // Initialize tab control
            tabControl1 = new TabControl();
            tabControl1.Dock = DockStyle.Fill;

            // Home tab
            tabHome = new TabPage("Home");
            lblTotalWordsLabel = new Label
            {
                Text = "Total Words Dictated",
                AutoSize = true,
                Font = new Font(Font.FontFamily, 12, FontStyle.Bold),
                Location = new Point(20, 20)
            };
            lblTotalWords = new Label
            {
                Text = "0",
                AutoSize = true,
                Font = new Font(Font.FontFamily, 24, FontStyle.Bold),
                Location = new Point(20, 50)
            };
            tabHome.Controls.Add(lblTotalWordsLabel);
            tabHome.Controls.Add(lblTotalWords);

            // History tab
            tabHistory = new TabPage("History");
            listHistory = new ListView
            {
                Dock = DockStyle.Fill,
                View = View.Details
            };
            listHistory.Columns.Add("Date", 150);
            listHistory.Columns.Add("Text", 500);
            tabHistory.Controls.Add(listHistory);

            // Settings tab
            tabSettings = new TabPage("Settings");
            var settingsPanel = new TableLayoutPanel
            {
                Dock = DockStyle.Fill,
                Padding = new Padding(20),
                ColumnCount = 1,
                RowCount = 6,
                AutoSize = true
            };

            // API Key section
            var apiKeyLabel = new Label
            {
                Text = "OpenAI API Key",
                Font = new Font(Font.FontFamily, 10, FontStyle.Bold),
                AutoSize = true
            };
            txtApiKey = new TextBox
            {
                Width = 400,
                UseSystemPasswordChar = true
            };
            btnSaveApiKey = new Button
            {
                Text = "Save API Key",
                Width = 100,
                Height = 30
            };
            btnSaveApiKey.Click += (s, e) => SaveApiKey();

            // Hotkey section
            var hotkeyLabel = new Label
            {
                Text = "Recording Hotkey",
                Font = new Font(Font.FontFamily, 10, FontStyle.Bold),
                AutoSize = true
            };
            lblCurrentHotkey = new Label
            {
                Text = "Current: Ctrl+Alt",
                AutoSize = true
            };
            btnRecordHotkey = new Button
            {
                Text = "Record New Hotkey",
                Width = 150,
                Height = 30
            };
            btnRecordHotkey.Click += (s, e) => ShowHotkeyRecorder();

            // Language section
            lblLanguage = new Label
            {
                Text = "Preferred Language",
                Font = new Font(Font.FontFamily, 10, FontStyle.Bold),
                AutoSize = true
            };
            cboLanguage = new ComboBox
            {
                DropDownStyle = ComboBoxStyle.DropDownList,
                Width = 200
            };
            cboLanguage.Items.AddRange(new string[] { "English", "Spanish", "French", "German", "Italian", "Portuguese", "Dutch", "Russian", "Japanese", "Korean", "Chinese" });
            cboLanguage.SelectedIndex = 0;

            // Launch at startup
            chkLaunchAtStartup = new CheckBox
            {
                Text = "Launch at Startup",
                AutoSize = true
            };

            // Add controls to settings panel
            settingsPanel.Controls.Add(apiKeyLabel);
            settingsPanel.Controls.Add(txtApiKey);
            settingsPanel.Controls.Add(btnSaveApiKey);
            settingsPanel.Controls.Add(hotkeyLabel);
            settingsPanel.Controls.Add(lblCurrentHotkey);
            settingsPanel.Controls.Add(btnRecordHotkey);
            settingsPanel.Controls.Add(lblLanguage);
            settingsPanel.Controls.Add(cboLanguage);
            settingsPanel.Controls.Add(chkLaunchAtStartup);

            tabSettings.Controls.Add(settingsPanel);

            // Add tabs to tab control
            tabControl1.TabPages.Add(tabHome);
            tabControl1.TabPages.Add(tabHistory);
            tabControl1.TabPages.Add(tabSettings);

            // Add tab control to form
            this.Controls.Add(tabControl1);
        }

        private void SaveApiKey()
        {
            if (string.IsNullOrWhiteSpace(txtApiKey.Text))
            {
                MessageBox.Show("Please enter a valid API key.", "Invalid API Key", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            SettingsManager.Instance.SaveApiKey(txtApiKey.Text);
            MessageBox.Show("API key saved successfully!", "Success", MessageBoxButtons.OK, MessageBoxIcon.Information);
        }

        private void ShowHotkeyRecorder()
        {
            using (var hotkeyForm = new HotkeyRecorderForm())
            {
                if (hotkeyForm.ShowDialog() == DialogResult.OK)
                {
                    lblCurrentHotkey.Text = $"Current: {hotkeyForm.HotkeyString}";
                    SettingsManager.Instance.SaveHotkey(hotkeyForm.HotkeyString);
                }
            }
        }
    }
}
