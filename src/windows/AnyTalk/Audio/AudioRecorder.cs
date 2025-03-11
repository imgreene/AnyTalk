using NAudio.Wave;
using System;
using System.IO;

namespace AnyTalk.Audio
{
    public class AudioRecorder : IDisposable
    {
        private WaveInEvent? _waveIn;
        private WaveFileWriter? _writer;
        private string? _outputFilePath;
        private readonly string _tempDirectory;

        public AudioRecorder()
        {
            _tempDirectory = Path.Combine(Path.GetTempPath(), "AnyTalk");
            Directory.CreateDirectory(_tempDirectory);
        }

        public void StartRecording()
        {
            StopRecording(_ => { }); // Clean up any existing recording

            _outputFilePath = Path.Combine(_tempDirectory, $"recording_{DateTime.Now:yyyyMMddHHmmss}.wav");
            
            _waveIn = new WaveInEvent
            {
                WaveFormat = new WaveFormat(44100, 1)
            };

            _writer = new WaveFileWriter(_outputFilePath, _waveIn.WaveFormat);
            _waveIn.DataAvailable += OnDataAvailable;
            _waveIn.StartRecording();
        }

        public void StopRecording(Action<string> onComplete)
        {
            if (_waveIn != null)
            {
                _waveIn.StopRecording();
                _waveIn.DataAvailable -= OnDataAvailable;
                _waveIn.Dispose();
                _waveIn = null;
            }

            if (_writer != null)
            {
                _writer.Dispose();
                _writer = null;
            }

            if (_outputFilePath != null)
            {
                onComplete(_outputFilePath);
                _outputFilePath = null;
            }
        }

        private void OnDataAvailable(object? sender, WaveInEventArgs e)
        {
            if (_writer != null)
            {
                _writer.Write(e.Buffer, 0, e.BytesRecorded);
            }
        }

        public void Dispose()
        {
            StopRecording(_ => { });
        }
    }
}
