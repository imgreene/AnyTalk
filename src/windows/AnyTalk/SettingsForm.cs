using AnyTalk.Models;

namespace AnyTalk
{
    public partial class SettingsForm : Form
    {
        private readonly Settings settings;

        public SettingsForm(Settings settings)
        {
            InitializeComponent();
            this.settings = settings;
            LoadSettings();
        }

        private void LoadSettings()
        {
            if (settings != null)
            {
                txtApiKey.Text = settings.ApiKey;
                cboMicrophone.Text = settings.SelectedMicrophone;
                cboLanguage.Text = settings.Language;
                chkLaunchAtStartup.Checked = settings.LaunchAtStartup;
                txtHotKey.Text = settings.HotKey;
            }
        }

        private void btnSave_Click(object sender, EventArgs e)
        {
            settings.ApiKey = txtApiKey.Text;
            settings.SelectedMicrophone = cboMicrophone.Text;
            settings.Language = cboLanguage.Text;
            settings.LaunchAtStartup = chkLaunchAtStartup.Checked;
            settings.HotKey = txtHotKey.Text;
            DialogResult = DialogResult.OK;
            Close();
        }
    }
}