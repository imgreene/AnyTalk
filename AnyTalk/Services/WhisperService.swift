import Foundation
import AVFoundation

enum WhisperError: Error {
    case noAPIKey
    case invalidAudioFile
    case networkError(String)
    case apiError(String)
}

class WhisperService {
    static let shared = WhisperService()
    
    private init() {}
    
    func transcribe(audioURL: URL, completion: @escaping (Result<String, Error>) -> Void) {
        let apiKey = SettingsManager.shared.apiKey
        guard !apiKey.isEmpty else {
            completion(.failure(WhisperError.noAPIKey))
            return
        }
        
        // Check if the audio file exists
        guard FileManager.default.fileExists(atPath: audioURL.path) else {
            completion(.failure(WhisperError.invalidAudioFile))
            return
        }
        
        // Prepare the request
        let url = URL(string: "https://api.openai.com/v1/audio/transcriptions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        // Create form data
        let boundary = UUID().uuidString
        request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Create the multipart form data
        let httpBody = NSMutableData()
        
        // Add the model parameter
        httpBody.append("--\(boundary)\r\n".data(using: .utf8)!)
        httpBody.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        httpBody.append("whisper-1\r\n".data(using: .utf8)!)
        
        // Add language parameter if user has set a preferred language
        let language = SettingsManager.shared.preferredLanguage
        if !language.isEmpty && language != "auto" {
            httpBody.append("--\(boundary)\r\n".data(using: .utf8)!)
            httpBody.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n".data(using: .utf8)!)
            httpBody.append("\(language)\r\n".data(using: .utf8)!)
        }
        
        // Set a lower temperature for more deterministic results
        httpBody.append("--\(boundary)\r\n".data(using: .utf8)!)
        httpBody.append("Content-Disposition: form-data; name=\"temperature\"\r\n\r\n".data(using: .utf8)!)
        httpBody.append("0.3\r\n".data(using: .utf8)!)
        
        // Add the audio file
        httpBody.append("--\(boundary)\r\n".data(using: .utf8)!)
        httpBody.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(audioURL.lastPathComponent)\"\r\n".data(using: .utf8)!)
        httpBody.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        
        if let audioData = try? Data(contentsOf: audioURL) {
            httpBody.append(audioData)
            httpBody.append("\r\n".data(using: .utf8)!)
        } else {
            completion(.failure(WhisperError.invalidAudioFile))
            return
        }
        
        // End the multipart form
        httpBody.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        // Set the http body
        request.httpBody = httpBody as Data
        
        // Create the task
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(WhisperError.networkError(error.localizedDescription)))
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(WhisperError.networkError("No data received")))
                }
                return
            }
            
            // Parse the response
            do {
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                    // Try to extract error message
                    if let errorResponse = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let errorMessage = errorResponse["error"] as? [String: Any],
                       let message = errorMessage["message"] as? String {
                        DispatchQueue.main.async {
                            completion(.failure(WhisperError.apiError(message)))
                        }
                    } else {
                        DispatchQueue.main.async {
                            completion(.failure(WhisperError.apiError("API error with status code: \(httpResponse.statusCode)")))
                        }
                    }
                    return
                }
                
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                
                if let text = json?["text"] as? String {
                    DispatchQueue.main.async {
                        completion(.success(text))
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(.failure(WhisperError.apiError("Could not parse response")))
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
        
        task.resume()
    }
} 
