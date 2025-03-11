using AnyTalk.Models;

namespace AnyTalk
{
    public partial class SettingsForm : Form
    {
        private readonly Settings _settings;

        public SettingsForm()
        {
            InitializeComponent();
            _settings = SettingsManager.Instance.LoadSettings();
            LoadCurrentSettings();
        }

        private void LoadCurrentSettings()
        {
            txtApiKey.Text = _settings.ApiKey;
            cboMicrophone.SelectedItem = _settings.SelectedMicrophone;
            lblCurrentHotkey.Text = _settings.HotKey;
            chkLaunchAtStartup.Checked = _settings.LaunchAtStartup;
        }

        private void SaveSettings()
        {
            _settings.ApiKey = txtApiKey.Text;
            _settings.SelectedMicrophone = cboMicrophone.SelectedItem?.ToString() ?? string.Empty;
            _settings.HotKey = lblCurrentHotkey.Text;
            _settings.LaunchAtStartup = chkLaunchAtStartup.Checked;
            
            SettingsManager.Instance.SaveSettings(_settings);
        }

        private void btnSave_Click(object sender, EventArgs e)
        {
            SaveSettings();
            DialogResult = DialogResult.OK;
            Close();
        }
    }
}
