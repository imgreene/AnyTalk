// In your main processing function
func processAudioWithSmartFunctionality() async {
    do {
        // 1. Get transcription from Whisper API
        let transcription = try await getWhisperTranscription(audioData: recordedAudioData)
        
        // 2. Check if text is selected
        let selectedText = getCurrentlySelectedText() // Your function to get selected text
        
        if !selectedText.isEmpty {
            // Text is selected, determine if we need to transform it
            let result = try await processWithGPT(selectedText: selectedText, userTranscription: transcription)
            
            if result == "false" {
                // User's dictation has nothing to do with the selected text
                // Just paste the transcription as normal
                pasteText(transcription)
            } else {
                // User wanted to transform the text, paste the transformed result
                pasteText(result)
            }
        } else {
            // No text selected, just paste the transcription
            pasteText(transcription)
        }
    } catch {
        print("Error: \(error)")
    }
}
