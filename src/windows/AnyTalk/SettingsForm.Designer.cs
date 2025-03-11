namespace AnyTalk
{
    partial class SettingsForm
    {
        private System.ComponentModel.IContainer components = null;
        
        // Keep these declarations in Designer.cs
        private Label lblCurrentHotkey;
        private TextBox txtApiKey;
        private Button btnSaveApiKey;
        private Button btnRecordHotkey;
        private ComboBox cboMicrophone;
        private ComboBox cboLanguage;
        private CheckBox chkLaunchAtStartup;
        private TextBox txtHotKey;
        private Button btnSave;

        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        private void InitializeComponent()
        {
            components = new System.ComponentModel.Container();
            txtApiKey = new TextBox();
            cboMicrophone = new ComboBox();
            cboLanguage = new ComboBox();
            chkLaunchAtStartup = new CheckBox();
            txtHotKey = new TextBox();
            btnSave = new Button();

            // Basic form setup
            this.AutoScaleDimensions = new System.Drawing.SizeF(7F, 15F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(400, 300);
            this.Text = "Settings";

            // Add controls to form
            this.Controls.AddRange(new Control[] {
                txtApiKey, cboMicrophone, cboLanguage,
                chkLaunchAtStartup, txtHotKey, btnSave
            });

            btnSave.Click += new EventHandler(btnSave_Click);
        }
    }
}
