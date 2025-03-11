namespace AnyTalk
{
    partial class HotkeyRecorderForm
    {
        // Keep only one declaration of components
        private System.ComponentModel.IContainer components = null;
        private Label lblInstructions;
        private Label lblCurrentKeys;

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
            this.Text = "Record Hotkey";
            this.Size = new Size(400, 200);
            this.StartPosition = FormStartPosition.CenterParent;
            this.FormBorderStyle = FormBorderStyle.FixedDialog;
            this.MaximizeBox = false;
            this.MinimizeBox = false;

            lblInstructions = new Label
            {
                Text = "Press the desired key combination\n(e.g., Ctrl+Alt+X)",
                TextAlign = ContentAlignment.MiddleCenter,
                AutoSize = false,
                Dock = DockStyle.Top,
                Height = 50
            };

            lblCurrentKeys = new Label
            {
                Text = "Waiting for input...",
                TextAlign = ContentAlignment.MiddleCenter,
                AutoSize = false,
                Dock = DockStyle.Fill
            };

            this.Controls.Add(lblCurrentKeys);
            this.Controls.Add(lblInstructions);
        }
    }
}
