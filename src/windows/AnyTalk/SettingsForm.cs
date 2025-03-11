using AnyTalk.Models;
using AnyTalk.Services;
using System;
using System.Windows.Forms;

namespace AnyTalk
{
    public partial class SettingsForm : Form
    {
        private readonly Settings _settings;
        private readonly SettingsManager _settingsManager;

        public SettingsForm()
        {
            InitializeComponent();
            _settingsManager = SettingsManager.Instance;
            _settings = _settingsManager.LoadSettings();
            InitializeUI();
        }

        private void InitializeUI()
        {
            txtApiKey.Text = _settings.ApiKey;
            lblCurrentHotkey.Text = $"Current: {_settings.HotKey}";
        }

        private void btnSave_Click(object sender, EventArgs e)
        {
            _settings.ApiKey = txtApiKey.Text;
            _settingsManager.SaveSettings(_settings);
            DialogResult = DialogResult.OK;
            Close();
        }

        private void btnRecordHotkey_Click(object sender, EventArgs e)
        {
            using var hotkeyForm = new HotkeyRecorderForm();
            if (hotkeyForm.ShowDialog() == DialogResult.OK)
            {
                _settings.HotKey = hotkeyForm.HotkeyString;
                lblCurrentHotkey.Text = $"Current: {hotkeyForm.HotkeyString}";
            }
        }
    }
}
