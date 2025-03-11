using AnyTalk.Services;
using AnyTalk.Models;
using AnyTalk.Audio;

namespace AnyTalk
{
    public partial class MainForm : Form
    {
        private readonly Settings _settings;
        private readonly SettingsManager _settingsManager;
        private readonly AnyTalk.Audio.AudioRecorder _audioRecorder;
        private readonly WhisperService _whisperService;

        public MainForm()
        {
            InitializeComponent();
            _settingsManager = SettingsManager.Instance;
            _settings = _settingsManager.LoadSettings();
            _audioRecorder = new AnyTalk.Audio.AudioRecorder();
            _whisperService = WhisperService.Instance;
            InitializeUI();
        }

        private void InitializeUI()
        {
            UpdateUIState();
        }

        private async void btnRecord_Click(object sender, EventArgs e)
        {
            _audioRecorder.StartRecording();
        }

        private async void btnStop_Click(object sender, EventArgs e)
        {
            _audioRecorder.StopRecording(async (audioFile) => {
                if (audioFile != null)
                {
                    await ProcessAudioFileAsync(audioFile);
                }
            });
        }

        private async Task ProcessAudioFileAsync(string audioFile)
        {
            try
            {
                var result = await _whisperService.TranscribeAudio(audioFile);
                if (result.IsSuccess && result.Value != null)
                {
                    // Handle successful transcription
                    MessageBox.Show(result.Value, "Transcription Result");
                }
                else
                {
                    MessageBox.Show($"Transcription failed: {result.ErrorMessage}", "Error", 
                        MessageBoxButtons.OK, MessageBoxIcon.Error);
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Transcription failed: {ex.Message}", "Error", 
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
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
