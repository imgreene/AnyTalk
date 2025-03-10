namespace AnyTalk.Services;

public class HistoryManager
{
    private static HistoryManager? instance;
    private const string HistoryFileName = "history.json";

    public static HistoryManager Instance
    {
        get
        {
            instance ??= new HistoryManager();
            return instance;
        }
    }

    private HistoryManager()
    {
    }

    public int GetTotalWordCount()
    {
        // TODO: Implement actual word counting from history
        return 0;
    }
}