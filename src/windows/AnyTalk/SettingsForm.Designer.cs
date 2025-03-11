namespace AnyTalk
{
    partial class SettingsForm
    {
        private System.ComponentModel.IContainer components = null;
        
        // Designer fields
        private Label lblCurrentHotkey;
        private TextBox txtApiKey;
        private Button btnSave;
        private Button btnRecordHotkey;

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
            // Designer initialization code
            btnSave.Click += new EventHandler(btnSave_Click);
            btnRecordHotkey.Click += new EventHandler(btnRecordHotkey_Click);
        }
    }
}
