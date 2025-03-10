using NAudio.Wave;
using System;

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
            // Constructor implementation
        }

        public void StartRecording()
        {
            // Existing implementation
        }

        public string StopRecording()
        {
            // Existing implementation
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
