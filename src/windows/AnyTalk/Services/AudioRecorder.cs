using NAudio.Wave;
using NAudio.CoreAudioApi;

namespace AnyTalk.Services
{
    public class AudioRecorder
    {
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
    }
}