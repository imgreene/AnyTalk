using NAudio.Wave;
using System.Threading.Tasks;

namespace AnyTalk.Services
{
    public class AudioRecorder
    {
        private WaveInEvent? waveIn;
        private WaveFileWriter? writer;
        private readonly string outputFilePath = Path.Combine(Path.GetTempPath(), "recording.wav");
        private Action<string>? onRecordingComplete;

        public void StartRecording()
        {
            waveIn = new WaveInEvent();
            waveIn.WaveFormat = new WaveFormat(44100, 1);
            writer = new WaveFileWriter(outputFilePath, waveIn.WaveFormat);

            waveIn.DataAvailable += (s, e) =>
            {
                writer.Write(e.Buffer, 0, e.BytesRecorded);
            };

            waveIn.RecordingStopped += (s, e) =>
            {
                writer?.Dispose();
                writer = null;
                waveIn?.Dispose();
                waveIn = null;

                if (File.Exists(outputFilePath))
                {
                    onRecordingComplete?.Invoke(outputFilePath);
                }
            };

            waveIn.StartRecording();
        }

        public void StopRecording(Action<string> completionHandler)
        {
            onRecordingComplete = completionHandler;
            waveIn?.StopRecording();
        }
    }
}
