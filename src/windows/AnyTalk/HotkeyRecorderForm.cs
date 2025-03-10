namespace AnyTalk
{
    public partial class HotkeyRecorderForm : Form
    {
        public string HotkeyString { get; private set; } = "";
        private Keys currentKeys = Keys.None;

        public HotkeyRecorderForm()
        {
            InitializeComponent();
            this.KeyPreview = true;
            this.KeyDown += HotkeyRecorderForm_KeyDown;
            this.KeyUp += HotkeyRecorderForm_KeyUp;
        }

        private void HotkeyRecorderForm_KeyDown(object sender, KeyEventArgs e)
        {
            currentKeys = e.KeyData;
            lblCurrentKeys.Text = GetKeyString(currentKeys);
            e.Handled = true;
        }

        private void HotkeyRecorderForm_KeyUp(object sender, KeyEventArgs e)
        {
            if (currentKeys != Keys.None)
            {
                HotkeyString = GetKeyString(currentKeys);
                this.DialogResult = DialogResult.OK;
                this.Close();
            }
        }

        private string GetKeyString(Keys keys)
        {
            var str = "";
            if ((keys & Keys.Control) == Keys.Control) str += "Ctrl+";
            if ((keys & Keys.Alt) == Keys.Alt) str += "Alt+";
            if ((keys & Keys.Shift) == Keys.Shift) str += "Shift+";

            var mainKey = keys & ~(Keys.Control | Keys.Alt | Keys.Shift);
            str += mainKey.ToString();

            return str;
        }
    }
}