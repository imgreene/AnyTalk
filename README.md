# AnyTalk

AnyTalk is a desktop application that provides voice-to-text dictation using OpenAI's Whisper API. It runs in the background and is accessible via a menubar icon (macOS) or system tray icon (Windows).

## ⚠️ Important: OpenAI API Key Required
AnyTalk requires your own OpenAI API key to function. You will be charged by OpenAI based on your usage:
- You are responsible for any costs incurred through your OpenAI API key
- Whisper API costs approximately $0.006 per minute of audio
- You can monitor your usage on your [OpenAI usage dashboard](https://platform.openai.com/account/usage)

### Cost Estimates for 100,000 Words
Based on different speaking speeds:
- At 100 words/minute: ~$6.00 (16.7 minutes)
- At 120 words/minute: ~$5.00 (13.9 minutes)
- At 150 words/minute: ~$4.00 (11.1 minutes)
- At 200 words/minute: ~$3.00 (8.3 minutes)

These estimates are approximate and actual costs may vary based on factors like pauses between words and API pricing changes. Visit [OpenAI's pricing page](https://openai.com/pricing) for current rates.

### Cost Comparison
While similar dictation services charge a flat fee of $15/month regardless of usage, AnyTalk only charges for what you use:
- Light usage (5 minutes/month): ~$0.03
- Moderate usage (30 minutes/month): ~$0.18
- Heavy usage (2 hours/month): ~$0.72

This pay-as-you-go model ensures you only pay for actual usage, potentially saving hundreds of dollars per year compared to subscription-based alternatives.

If you find AnyTalk useful and it helps save you time and money, consider supporting its development:
```btc
BTC: bc1qwjy57p4pq6n4qejrvq6yfjjq37unqen33ckakz
```

## Features

- **Background Voice Dictation**: 
  - macOS: Press ⌘⌥ (Command+Option) to start dictating
  - Windows: Press Ctrl+Alt to start dictating
- **High-Quality Transcription**: Uses OpenAI's Whisper API (requires your API key)
- **Multi-Language Support**: Transcribe in multiple languages
- **Automatic Clipboard Copy**: Transcribed text is automatically copied
- **History Management**: View and manage past transcriptions
- **Customizable Settings**: Configure hotkeys, microphone, and more

## System Requirements

### macOS
- macOS 11.0 (Big Sur) or later
- Internet connection
- Microphone access
- OpenAI API key

### Windows
- Windows 10 or later
- Internet connection
- Microphone access
- OpenAI API key

## Download and Install

### macOS
1. Download `AnyTalk-macOS.zip` from the [releases page](https://github.com/imgreene/AnyTalk/releases/tag/v1.0.1)
2. Unzip the file
3. Move AnyTalk.app to your Applications folder
4. Launch AnyTalk
5. If you see a security warning:
   - Open System Preferences → Security & Privacy
   - Click "Open Anyway"

### Windows
1. Download `AnyTalk-Windows-Setup.exe` from the [releases page](https://github.com/imgreene/AnyTalk/releases/tag/v1.0.1)
2. Run the installer
3. Follow the installation wizard

## First-Time Setup

1. **Get Your OpenAI API Key** (Required):
   - Sign up at [OpenAI](https://platform.openai.com/signup)
   - Go to [API Keys](https://platform.openai.com/account/api-keys)
   - Create a new API key
   - Keep your API key secure and never share it

2. **Configure AnyTalk**:
   - Click the AnyTalk icon in the menubar (macOS) or system tray (Windows)
   - Go to Settings
   - Enter your OpenAI API key and click "Save"
   - Grant microphone permissions when prompted

## Usage

1. **Quick Dictation**:
   - Press the hotkey (⌘⌥ on macOS, Ctrl+Alt on Windows) anywhere to start dictation
   - Speak clearly into your microphone
   - Release the hotkey to stop and transcribe your speech
   - The transcribed text will be copied to your clipboard automatically

2. **Main Interface**:
   - Click the AnyTalk icon to access the main interface
   - **Home**: View your total words dictated
   - **History**: Access all your past transcriptions
   - **Settings**: Customize the app's behavior

3. **Settings Configuration**:
   - **API Key**: Enter your OpenAI API key (required)
   - **Hotkey**: Change the keyboard shortcut
   - **Microphone**: Select input device
   - **Language**: Choose transcription language
   - **Launch at Login**: Enable/disable automatic startup

## Privacy

- AnyTalk only records audio when you hold down the hotkey
- Audio data is sent to OpenAI's servers for transcription using your API key
- All transcription history is stored locally on your device
- No data is collected by the app developers

## Troubleshooting

### macOS
- If dictation isn't working, check:
  - System Preferences → Security & Privacy → Privacy → Microphone
  - Ensure AnyTalk has microphone access
  - Verify your API key is correctly entered in Settings

### Windows
- If dictation isn't working, check:
  - Windows Settings → Privacy → Microphone
  - Ensure AnyTalk has microphone access
  - Verify your API key is correctly entered in Settings

## Support

For issues, feature requests, or contributions, please visit our [GitHub repository](https://github.com/imgreene/anytalk).

## License

This project is licensed under [your chosen license]. See [LICENSE](LICENSE) for details.
