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
        
        guard FileManager.default.fileExists(atPath: audioURL.path) else {
            completion(.failure(WhisperError.invalidAudioFile))
            return
        }
        
        let url = URL(string: "https://api.openai.com/v1/audio/transcriptions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let boundary = UUID().uuidString
        request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let httpBody = NSMutableData()
        
        httpBody.append("--\(boundary)\r\n".data(using: .utf8)!)
        httpBody.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        httpBody.append("whisper-1\r\n".data(using: .utf8)!)
        
        let language = SettingsManager.shared.preferredLanguage
        if !language.isEmpty && language != "auto" {
            httpBody.append("--\(boundary)\r\n".data(using: .utf8)!)
            httpBody.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n".data(using: .utf8)!)
            httpBody.append("\(language)\r\n".data(using: .utf8)!)
        }
        
        httpBody.append("--\(boundary)\r\n".data(using: .utf8)!)
        httpBody.append("Content-Disposition: form-data; name=\"temperature\"\r\n\r\n".data(using: .utf8)!)
        httpBody.append("0.3\r\n".data(using: .utf8)!)
        
        let promptText = "Return text with proper grammar, punctuation, and formatting. Direct speech should be in quotation marks. Format numbers and dates properly."
        httpBody.append("--\(boundary)\r\n".data(using: .utf8)!)
        httpBody.append("Content-Disposition: form-data; name=\"prompt\"\r\n\r\n".data(using: .utf8)!)
        httpBody.append("\(promptText)\r\n".data(using: .utf8)!)

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
        
        httpBody.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = httpBody as Data
        
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
            
            do {
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
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
