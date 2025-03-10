namespace AnyTalk;

public partial class HotkeyRecorderForm : Form
{
    public string HotkeyString { get; private set; } = string.Empty;

    public HotkeyRecorderForm()
    {
        InitializeComponent();
        this.KeyDown += HotkeyRecorderForm_KeyDown;
        this.KeyUp += HotkeyRecorderForm_KeyUp;
    }

    private void HotkeyRecorderForm_KeyDown(object sender, KeyEventArgs e)
    {
        // Implementation
    }

    private void HotkeyRecorderForm_KeyUp(object sender, KeyEventArgs e)
    {
        // Implementation
    }
}
