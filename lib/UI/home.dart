import 'package:essentials/UI/sentence_analyzer.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../features/pdf_reader.dart';
import 'package:share_plus/share_plus.dart';
// import 'notes/notes_page.dart';
// import 'todos/todo_page.dart';
// import 'community/cummunity_page.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Text('One', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 24),
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Icon(Icons.filter_1, size: 64, color: colorScheme.primary),
                        SizedBox(height: 16),
                        Text(
                          'Welcome to One',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Your All-in-One Platform',
                          style: TextStyle(fontSize: 18, color: colorScheme.secondary),
                        ),
                        SizedBox(height: 24),
                        Text(
                          'Explore our features to discover how One can simplify your life.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: colorScheme.onSurface.withOpacity(0.7)),
                        ),
                        SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildFeatureButton(context, Icons.analytics, 'Notes', colorScheme),
                            _buildFeatureButton(context, Icons.task_alt, 'Tasks', colorScheme),
                            _buildFeatureButton(context, Icons.text_snippet, 'Sentence Analyzer', colorScheme),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
                          if (result != null && result.files.single.path != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PdfReaderPage(filePath: result.files.single.path!),
                              ),
                            );
                          }
                        },
                        icon: Icon(Icons.picture_as_pdf),
                        label: Text('Open PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
                          if (result != null && result.files.single.path != null) {
                            await Share.shareXFiles([XFile(result.files.single.path!)]);
                          }
                        },
                        icon: Icon(Icons.share),
                        label: Text('Share PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.secondary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 32),
                Text(
                  'Made with Flutter',
                  style: TextStyle(color: colorScheme.onBackground.withOpacity(0.5)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureButton(BuildContext context, IconData icon, String label, ColorScheme colorScheme) {
    return Column(
      children: [
        Material(
          color: colorScheme.surface,
          shape: CircleBorder(),
          elevation: 4,
          child: InkWell(
            customBorder: CircleBorder(),
            onTap: () {
              if (label == 'Sentence Analyzer') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SentenceAnalyzerPage()),
                );
              }
              // Add navigation for Notes and Tasks as needed
            },
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Icon(icon, color: colorScheme.primary, size: 32),
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(label, style: TextStyle(color: colorScheme.primary, fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
