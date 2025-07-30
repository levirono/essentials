import 'package:flutter/material.dart';

class JournalEntry {
  final String text;
  final String mood;
  final DateTime date;

  JournalEntry(this.text, this.mood, this.date);
}

class DailyJournal extends StatefulWidget {
  @override
  _DailyJournalState createState() => _DailyJournalState();
}

class _DailyJournalState extends State<DailyJournal> {
  final _controller = TextEditingController();
  String _selectedMood = '😊';
  List<JournalEntry> _entries = [];

  void _saveEntry() {
    final text = _controller.text;
    if (text.isEmpty) return;
    final entry = JournalEntry(text, _selectedMood, DateTime.now());
    setState(() {
      _entries.add(entry);
      _controller.clear();
      _selectedMood = '😊';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Daily Journal")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                DropdownButton<String>(
                  value: _selectedMood,
                  items:
                      ['😊', '😐', '😢', '😡']
                          .map(
                            (m) => DropdownMenuItem(value: m, child: Text(m)),
                          )
                          .toList(),
                  onChanged: (val) => setState(() => _selectedMood = val!),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(labelText: 'How was your day?'),
                  ),
                ),
                IconButton(icon: Icon(Icons.save), onPressed: _saveEntry),
              ],
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _entries.length,
                itemBuilder: (context, index) {
                  final e = _entries[index];
                  return ListTile(
                    leading: Text(e.mood, style: TextStyle(fontSize: 24)),
                    title: Text(e.text),
                    subtitle: Text(e.date.toLocal().toString().split(" ")[0]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
