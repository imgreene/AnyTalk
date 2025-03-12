import Foundation

func processWithGPT(selectedText: String, userTranscription: String) async throws -> String {
    // API endpoint
    let url = URL(string: "https://api.openai.com/v1/chat/completions")!
    
    // Create the request
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("Bearer YOUR_API_KEY", forHTTPHeaderField: "Authorization")
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    
    // The system prompt that explains the task
    let systemPrompt = """
    You are an assistant for a dictation app that can either:
    1. Return "false" when the user's dictation has nothing to do with modifying the selected text
    2. Perform operations on selected text based on the user's verbal command, then return the modified text

    If the user's dictation is a command to modify the selected text (e.g., "translate this to Spanish", "make this more formal", "rewrite with more detail"), then perform that operation on the selected text and return the result.

    If the user's dictation has nothing to do with the selected text, return exactly "false" (without quotes).

    Examples:
    - If selected text is "Hello world" and dictation is "translate this to Spanish", return "Hola mundo"
    - If selected text is "Meeting notes" and dictation is "make this bold", return "**Meeting notes**"
    - If selected text is "We just wrapped up the phone call" and dictation is "I really want chipotle", return "false" (dictation unrelated to selected text)

    Only return the modified text or "false". No explanations or additional text.
    """
    
    // Create the request body
    let requestBody: [String: Any] = [
        "model": "gpt-3.5-turbo",
        "messages": [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": "Selected text: \"\(selectedText)\"\nUser dictation: \"\(userTranscription)\""]
        ],
        "temperature": 0.3,
        "max_tokens": 1000,
        "top_p": 1.0
    ]
    
    // Convert the request body to JSON data
    let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
    request.httpBody = jsonData
    
    // Make the API call
    let (data, response) = try await URLSession.shared.data(for: request)
    
    // Handle the response
    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
        throw NSError(domain: "API Error", code: (response as? HTTPURLResponse)?.statusCode ?? 0)
    }
    
    // Parse the response
    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
       let choices = json["choices"] as? [[String: Any]],
       let firstChoice = choices.first,
       let message = firstChoice["message"] as? [String: Any],
       let content = message["content"] as? String {
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    } else {
        throw NSError(domain: "Response Parsing Error", code: 0)
    }
}
