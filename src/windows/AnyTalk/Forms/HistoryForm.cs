using AnyTalk.Services;
using System.Windows.Forms;

namespace AnyTalk.Forms
{
    public class HistoryForm : Form
    {
        private ListView? historyListView;
        private readonly HistoryManager historyManager;

        public HistoryForm()
        {
            historyManager = HistoryManager.Instance;
            InitializeComponents();
            LoadHistory();
        }

        private void InitializeComponents()
        {
            this.Text = "Transcription History";
            this.Size = new System.Drawing.Size(800, 600);

            historyListView = new ListView
            {
                Dock = DockStyle.Fill,
                View = View.Details,
                FullRowSelect = true,
                GridLines = true
            };

            historyListView.Columns.Add("Date/Time", 150);
            historyListView.Columns.Add("Text", 450);
            historyListView.Columns.Add("Word Count", 100);

            var contextMenu = new ContextMenuStrip();
            var copyItem = new ToolStripMenuItem("Copy", null, (s, e) => CopySelectedText());
            var deleteItem = new ToolStripMenuItem("Delete", null, (s, e) => DeleteSelectedEntry());
            contextMenu.Items.AddRange(new[] { copyItem, deleteItem });
            historyListView.ContextMenuStrip = contextMenu;

            this.Controls.Add(historyListView);
        }

        private void LoadHistory()
        {
            if (historyListView == null) return;
            
            historyListView.Items.Clear();
            var entries = historyManager.GetEntries();

            foreach (var entry in entries)
            {
                var item = new ListViewItem(entry.Timestamp.ToString("g"));
                item.SubItems.Add(entry.Text);
                item.SubItems.Add(entry.WordCount.ToString());
                item.Tag = entry;
                historyListView.Items.Add(item);
            }
        }

        private void CopySelectedText()
        {
            if (historyListView?.SelectedItems.Count > 0)
            {
                var text = historyListView.SelectedItems[0].SubItems[1].Text;
                Clipboard.SetText(text);
            }
        }

        private void DeleteSelectedEntry()
        {
            if (historyListView?.SelectedItems.Count > 0)
            {
                var entry = (TranscriptionEntry)historyListView.SelectedItems[0].Tag;
                var entries = historyManager.GetEntries().ToList();
                entries.Remove(entry);
                
                // Update the entries list
                var json = System.Text.Json.JsonSerializer.Serialize(entries, new System.Text.Json.JsonSerializerOptions 
                { 
                    WriteIndented = true 
                });
                File.WriteAllText(Path.Combine(
                    Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
                    "AnyTalk",
                    "history.json"
                ), json);

                LoadHistory(); // Refresh the list
            }
        }
    }
}
