using NAudio.Wave;
using NAudio.CoreAudioApi;
using System.IO;

namespace AnyTalk.Services
{
    public class AudioRecorder
    {
        private WaveInEvent? waveIn;
        private WaveFileWriter? writer;
        private string outputFilePath;

        public AudioRecorder()
        {
            outputFilePath = Path.Combine(Path.GetTempPath(), "recording.wav");
        }

        public static List<string> GetAvailableMicrophones()
        {
            var devices = new List<string>();
            using (var enumerator = new MMDeviceEnumerator())
            {
                foreach (var device in enumerator.EnumerateAudioEndPoints(DataFlow.Capture, DeviceState.Active))
                {
                    devices.Add(device.FriendlyName);
                }
            }
            return devices;
        }

        public void StartRecording()
        {
            waveIn = new WaveInEvent();
            waveIn.WaveFormat = new WaveFormat(44100, 1);
            writer = new WaveFileWriter(outputFilePath, waveIn.WaveFormat);

            waveIn.DataAvailable += (s, e) =>
            {
                writer.Write(e.Buffer, 0, e.BytesRecorded);
            };

            waveIn.StartRecording();
        }

        public void StopRecording()
        {
            waveIn?.StopRecording();
            writer?.Dispose();
            writer = null;
            waveIn?.Dispose();
            waveIn = null;
        }
    }
}
