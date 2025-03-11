<p align="center">
  <img src="assets/anytalk-logo.png" width="128" height="128" alt="AnyTalk Logo">
</p>

# AnyTalk

⚠️ **Installation Options**

**Option 1: Run [Downloaded App](https://github.com/imgreene/AnyTalk/releases/tag/v1.0.0)**
1. Double-click AnyTalk.app
2. At "malicious software" warning → Click "Done"
3. Open System Settings → Privacy & Security
4. Scroll to bottom → Click "Open Anyway"
5. Click "Open Anyway" again
6. Enter your computer password when prompted

**Option 2: Build from Source**
- Clone repo and build in Xcode
- Or create archive from Xcode and run locally

> Why the warnings? AnyTalk is open-source and not notarized with Apple. You can review the source code and build it yourself, or use our pre-built app following the steps above.

## First-Time Setup
1. Enter your OpenAI API key and click Save
2. Complete your first transcription (it will not paste yet)
3. When prompted about accessibility features:
   - Click "Open System Settings"
   - Allow AnyTalk in Privacy & Security → Accessibility
4. Transcriptions will not paste to wherever your cursor is

---

AnyTalk is a macOS menubar application that provides voice-to-text dictation using OpenAI's Whisper API.

Developed by [@GreeneChase](https://X.com/GreeneChase)

Windows version coming soon! (if you fork and add windows, please open a PR!)

## ⚠️ OpenAI API Key Required
- Requires your OpenAI API key
- Whisper API currently costs $0.006 per minute of audio
- You can monitor your usage on your [OpenAI usage dashboard](https://platform.openai.com/account/usage)

### Cost Comparison
Traditional dictation services charge $15/month flat fee. AnyTalk's pay-as-you-go model:

Speaking at 150 words/minute (average speed):
- 11.1 minutes (100,000 words) = $0.067
- 5 minutes/month = $0.03
- 30 minutes/month = $0.18
- 2 hours/month = $0.72

These estimates are approximate and actual costs may vary based on factors like API pricing changes. Visit [OpenAI's pricing page](https://platform.openai.com/docs/pricing) for current rates.

If AnyTalk saves you time and money, consider supporting development:
```btc
BTC: bc1qwjy57p4pq6n4qejrvq6yfjjq37unqen33ckakz
```

## Features
- **Global Hotkey**: Press ⌘⌥ (Command+Option) to dictate anywhere
- **Multi-Language**: Supports multiple languages
- **Auto-Copy**: Transcribed text automatically copies to clipboard
- **History**: View and manage past transcriptions
- **Statistics**: Track words dictated and speaking speed
- **Customizable**: Configure hotkey, microphone, and language

## System Requirements
- macOS 11.0 (Big Sur) or later
- Internet connection
- Microphone access
- OpenAI API key

## Quick Start
1. Download `AnyTalk-macOS.zip` from [releases](https://github.com/imgreene/AnyTalk/releases/tag/v1.0.0)
2. Move AnyTalk.app to Applications
3. Launch AnyTalk
4. Enter your [OpenAI API key](https://platform.openai.com/account/api-keys) in Settings
5. Grant microphone access when prompted

## Usage
1. Press ⌘⌥ and speak
2. Release to transcribe
3. Text automatically copies to clipboard

## Privacy
- Records only while hotkey is pressed
- Audio processed through your OpenAI API key
- History stored locally
- No data collection by app developers

## Support
Visit our [GitHub repository](https://github.com/imgreene/anytalk) for:
- Bug reports
- Feature requests
- Contributions

## License
Licensed under MIT License. See [LICENSE](LICENSE) for details.
