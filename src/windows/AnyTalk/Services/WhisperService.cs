using System.Net.Http.Headers;
using System.Text.Json;

namespace AnyTalk.Services;

public enum WhisperError
{
    NoAPIKey,
    InvalidAudioFile,
    NetworkError,
    APIError
}

public class WhisperService
{
    private static WhisperService? instance;
    private readonly HttpClient httpClient;

    public static WhisperService Instance
    {
        get
        {
            instance ??= new WhisperService();
            return instance;
        }
    }

    private WhisperService()
    {
        httpClient = new HttpClient();
    }

    public async Task<Result<string>> TranscribeAudio(string audioFilePath)
    {
        var settings = SettingsManager.Instance.LoadSettings();
        var apiKey = settings.ApiKey;

        if (string.IsNullOrEmpty(apiKey))
        {
            return Result<string>.Failure(WhisperError.NoAPIKey, "API key is required");
        }

        // Check if the audio file exists
        if (!File.Exists(audioFilePath))
        {
            return Result<string>.Failure(WhisperError.InvalidAudioFile, "Audio file not found");
        }

        try
        {
            var request = new HttpRequestMessage(HttpMethod.Post, "https://api.openai.com/v1/audio/transcriptions");
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", apiKey);

            var boundary = Guid.NewGuid().ToString();
            var content = new MultipartFormDataContent(boundary);

            // Add the model parameter
            content.Add(new StringContent("whisper-1"), "model");

            // Add language parameter if user has set a preferred language
            if (!string.IsNullOrEmpty(settings.Language) && settings.Language != "auto")
            {
                content.Add(new StringContent(settings.Language), "language");
            }

            // Set a lower temperature for more deterministic results
            content.Add(new StringContent("0.3"), "temperature");

            // Add the audio file
            var fileContent = new ByteArrayContent(File.ReadAllBytes(audioFilePath));
            fileContent.Headers.ContentType = MediaTypeHeaderValue.Parse("audio/m4a");
            content.Add(fileContent, "file", Path.GetFileName(audioFilePath));

            request.Content = content;

            var response = await httpClient.SendAsync(request);
            var responseBody = await response.Content.ReadAsStringAsync();

            // Add debug logging
            Console.WriteLine($"Response Status Code: {response.StatusCode}");
            Console.WriteLine($"Response Body: {responseBody}");

            if (!response.IsSuccessStatusCode)
            {
                try
                {
                    var errorResponse = JsonSerializer.Deserialize<ErrorResponse>(responseBody);
                    var errorMessage = errorResponse?.Error?.Message ?? $"API error with status code: {response.StatusCode}";
                    return Result<string>.Failure(WhisperError.APIError, errorMessage);
                }
                catch (JsonException ex)
                {
                    return Result<string>.Failure(WhisperError.APIError, $"Failed to parse error response: {responseBody}");
                }
            }

            try
            {
                // Match the Mac implementation's response structure
                using var jsonDoc = JsonDocument.Parse(responseBody);
                var root = jsonDoc.RootElement;
                
                if (root.TryGetProperty("text", out var textElement))
                {
                    var transcribedText = textElement.GetString();
                    if (!string.IsNullOrEmpty(transcribedText))
                    {
                        return Result<string>.Success(transcribedText);
                    }
                }
                
                // If we get here, we couldn't find the text property
                return Result<string>.Failure(WhisperError.APIError, 
                    $"Could not find 'text' in response: {responseBody}");
            }
            catch (JsonException ex)
            {
                return Result<string>.Failure(WhisperError.APIError, 
                    $"Failed to parse success response: {ex.Message}. Response: {responseBody}");
            }
        }
        catch (Exception ex)
        {
            return Result<string>.Failure(WhisperError.NetworkError, ex.Message);
        }
    }

    private class WhisperResponse
    {
        public string Text { get; set; } = string.Empty;
    }

    private class ErrorResponse
    {
        public ErrorDetail? Error { get; set; }
    }

    private class ErrorDetail
    {
        public string Message { get; set; } = string.Empty;
    }
}

public class Result<T>
{
    public bool IsSuccess { get; private set; }
    public T? Value { get; private set; }
    public WhisperError Error { get; private set; }
    public string ErrorMessage { get; private set; }

    private Result(bool isSuccess, T? value, WhisperError error, string errorMessage)
    {
        IsSuccess = isSuccess;
        Value = value;
        Error = error;
        ErrorMessage = errorMessage;
    }

    public static Result<T> Success(T value)
    {
        return new Result<T>(true, value, default, string.Empty);
    }

    public static Result<T> Failure(WhisperError error, string message)
    {
        return new Result<T>(false, default, error, message);
    }
}
