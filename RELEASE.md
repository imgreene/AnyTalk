# AnyTalk v1.0.1

## Download and Install
1. Download `AnyTalk-macOS.zip` from the releases page
2. Unzip the file
3. Move AnyTalk.app to your Applications folder
4. Launch AnyTalk

## First-Time Setup
1. Enter your OpenAI API key in Settings and click Save
2. Complete your first transcription (it will not paste yet)
3. When prompted about accessibility features:
   - Click "Open System Settings"
   - Allow AnyTalk in Privacy & Security → Accessibility
4. Transcriptions will now paste to wherever your cursor is

## Usage
### Basic Dictation
1. Press ⌘⌥ (Command+Option) to start dictation
2. Speak while holding the hotkey
3. Release to transcribe
4. Text will automatically copy to clipboard and paste at cursor position

### AI Text Enhancement (New!)
1. Select any text in any application
2. Press ⌘⌥ and speak a command like:
   - "Improve this prompt"
   - "Convert this to a prompt"
   - "Translate this to Spanish"
3. Release to process
4. Enhanced text will replace your selection

Example:
- Select text: "I have an idea for an app that removes backgrounds from images"
- Say: "convert this to a prompt"
- Result: "Create a mobile application design that features an intuitive interface for automatic background removal from photos. Include a main screen with drag-and-drop functionality, preview window, and export options. The design should emphasize user-friendly controls and a clean, modern aesthetic"

## What's New in v1.0.1
- Added AI text manipulation capabilities
- Select any text and use voice commands to:
  - Improve prompts
  - Convert text to prompts
  - Translate to other languages
  - And more text operations!

## Cost Information
- Whisper API costs $0.006 per minute of audio
- Monitor usage at: https://platform.openai.com/account/usage
- Example costs (at 150 words/minute):
  - 5 minutes/month = $0.03
  - 30 minutes/month = $0.18
  - 2 hours/month = $0.72

## Privacy
- Records only while hotkey is pressed
- Audio processed through your OpenAI API key
- History stored locally
- No data collection by app developers
