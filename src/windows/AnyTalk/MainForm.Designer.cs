using AnyTalk.Services;
using System.Windows.Forms;

namespace AnyTalk
{
    partial class MainForm
    {
        private System.ComponentModel.IContainer components = null;
        private Button btnRecord;
        private Button btnStop;
        private TableLayoutPanel mainPanel;

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
            
            // Form settings
            this.Text = "AnyTalk";
            this.Size = new System.Drawing.Size(800, 600);
            this.StartPosition = FormStartPosition.CenterScreen;
            this.MinimumSize = new System.Drawing.Size(800, 600);

            // Main panel
            mainPanel = new TableLayoutPanel
            {
                Dock = DockStyle.Fill,
                Padding = new Padding(10),
                ColumnCount = 2,
                RowCount = 2
            };

            // Recording controls
            btnRecord = new Button
            {
                Text = "Start Recording",
                Size = new Size(120, 30),
                Enabled = true
            };
            btnRecord.Click += btnRecord_Click;

            btnStop = new Button
            {
                Text = "Stop Recording",
                Size = new Size(120, 30),
                Enabled = false
            };
            btnStop.Click += btnStop_Click;

            mainPanel.Controls.Add(btnRecord);
            mainPanel.Controls.Add(btnStop);

            this.Controls.Add(mainPanel);
        }
    }
}
