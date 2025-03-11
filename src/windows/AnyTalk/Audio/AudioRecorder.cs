using NAudio.Wave;
using System;
using System.IO;

namespace AnyTalk.Audio
{
    public class AudioRecorder : IDisposable
    {
        private WaveInEvent waveIn;
        private WaveFileWriter writer;
        private string tempFilePath;
        private bool disposed = false;

        public AudioRecorder()
        {
            tempFilePath = Path.Combine(Path.GetTempPath(), "recording.wav");
        }

        public void StartRecording()
        {
            waveIn = new WaveInEvent();
            waveIn.WaveFormat = new WaveFormat(44100, 1);
            writer = new WaveFileWriter(tempFilePath, waveIn.WaveFormat);

            waveIn.DataAvailable += (s, e) =>
            {
                writer.Write(e.Buffer, 0, e.BytesRecorded);
            };

            waveIn.StartRecording();
        }

        public string StopRecording()
        {
            if (waveIn != null)
            {
                waveIn.StopRecording();
                waveIn.Dispose();
                waveIn = null;
            }

            if (writer != null)
            {
                writer.Dispose();
                writer = null;
            }

            return tempFilePath;
        }

        public void Dispose()
        {
            Dispose(true);
            GC.SuppressFinalize(this);
        }

        protected virtual void Dispose(bool disposing)
        {
            if (!disposed)
            {
                if (disposing)
                {
                    waveIn?.Dispose();
                    writer?.Dispose();
                }
                disposed = true;
            }
        }

        ~AudioRecorder()
        {
            Dispose(false);
        }
    }
}
