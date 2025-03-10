# AnyTalk

AnyTalk is a desktop application that provides voice-to-text dictation using OpenAI's Whisper API. It runs in the background and is accessible via a menubar icon (macOS) or system tray icon (Windows).

## Features

- **Background Voice Dictation**: 
  - macOS: Press ⌘⌥ (Command+Option) to start dictating
  - Windows: Press Ctrl+Alt to start dictating
- **High-Quality Transcription**: Uses OpenAI's Whisper API
- **Multi-Language Support**: Transcribe in multiple languages
- **Automatic Clipboard Copy**: Transcribed text is automatically copied
- **History Management**: View and manage past transcriptions
- **Customizable Settings**: Configure hotkeys, microphone, and more

## System Requirements

### macOS
- macOS 11.0 (Big Sur) or later
- Internet connection
- Microphone access

### Windows
- Windows 10 or later
- Internet connection
- Microphone access

## Download and Install

### macOS
1. Download `AnyTalk-macOS.zip` from the [releases page](https://github.com/yourusername/anytalk/releases)
2. Unzip the file
3. Move AnyTalk.app to your Applications folder
4. Launch AnyTalk
5. If you see a security warning:
   - Open System Preferences → Security & Privacy
   - Click "Open Anyway"

### Windows
1. Download `AnyTalk-Windows-Setup.exe` from the [releases page](https://github.com/yourusername/anytalk/releases)
2. Run the installer
3. Follow the installation wizard

## First-Time Setup

1. Get your OpenAI API key from https://platform.openai.com/account/api-keys
2. Click the AnyTalk icon in the menubar (macOS) or system tray (Windows)
3. Go to Settings
4. Enter your OpenAI API key and click "Save"
5. Grant microphone permissions when prompted

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
   - **API Key**: Enter your OpenAI API key
   - **Hotkey**: Change the keyboard shortcut
   - **Microphone**: Select input device
   - **Language**: Choose transcription language
   - **Launch at Login**: Enable/disable automatic startup

## Privacy

- AnyTalk only records audio when you hold down the hotkey
- Audio data is sent to OpenAI's servers for transcription
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

For issues, feature requests, or contributions, please visit our [GitHub repository](https://github.com/yourusername/anytalk).

## License

This project is licensed under [your chosen license]. See [LICENSE](LICENSE) for details.
