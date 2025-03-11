using AnyTalk.Models;
using AnyTalk.Services;
using System;
using System.Windows.Forms;

namespace AnyTalk
{
    public partial class SettingsForm : Form
    {
        private readonly Settings _settings;
        
        // Remove these duplicate declarations since they should only be in Designer.cs
        // private Label lblCurrentHotkey;
        // private TextBox txtApiKey;
        // private Button btnSaveApiKey;
        // private Button btnRecordHotkey;

        public SettingsForm()
        {
            InitializeComponent();
            _settings = SettingsManager.Instance.LoadSettings();
            InitializeUI();
        }

        private void InitializeUI()
        {
            lblCurrentHotkey.Text = $"Current: {_settings.HotKey}";
            txtApiKey.Text = _settings.ApiKey;
        }

        private void btnRecordHotkey_Click(object sender, EventArgs e)
        {
            using (var hotkeyForm = new HotkeyRecorderForm())
            {
                if (hotkeyForm.ShowDialog() == DialogResult.OK)
                {
                    lblCurrentHotkey.Text = $"Current: {hotkeyForm.HotkeyString}";
                    _settings.HotKey = hotkeyForm.HotkeyString;
                    SettingsManager.Instance.SaveSettings(_settings);
                }
            }
        }
    }
}
