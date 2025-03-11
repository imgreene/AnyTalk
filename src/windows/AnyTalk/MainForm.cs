using AnyTalk.Services;
using AnyTalk.Models;

namespace AnyTalk
{
    public partial class MainForm : Form
    {
        private readonly Settings _settings;
        private readonly SettingsManager _settingsManager;
        private readonly AudioRecorderService _audioRecorder;
        private readonly WhisperService _whisperService;

        public MainForm()
        {
            InitializeComponent();
            _settingsManager = SettingsManager.Instance;
            _settings = _settingsManager.LoadSettings();
            _audioRecorder = new AudioRecorderService();
            _whisperService = new WhisperService(_settings);
            InitializeUI();
        }

        private void InitializeUI()
        {
            // Initialize UI components
            UpdateUIState();
        }

        private async Task StartRecordingAsync()
        {
            try
            {
                await _audioRecorder.StartRecordingAsync();
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Failed to start recording: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private async Task StopRecordingAsync()
        {
            try
            {
                var audioFile = await _audioRecorder.StopRecordingAsync();
                if (audioFile != null)
                {
                    await ProcessAudioFileAsync(audioFile);
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Failed to stop recording: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private async Task ProcessAudioFileAsync(string audioFile)
        {
            try
            {
                var transcription = await _whisperService.TranscribeAudioAsync(audioFile);
                // Handle transcription result
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Transcription failed: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private void SaveSettings()
        {
            _settingsManager.SaveSettings(_settings);
            UpdateUIState();
        }

        private void ShowSettingsTab()
        {
            if (tabControl1.TabPages.Contains(tabSettings))
            {
                tabControl1.SelectedTab = tabSettings;
            }
        }

        private void UpdateUIState()
        {
            // Update UI based on current settings
        }

        protected override void OnFormClosing(FormClosingEventArgs e)
        {
            _audioRecorder?.Dispose();
            base.OnFormClosing(e);
        }
    }
}
