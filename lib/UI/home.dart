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
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.purple.shade800,
              Colors.blue.shade600,
              Colors.green.shade500,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: Text(
                  'One',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.filter_1, size: 80, color: Colors.white),
                      SizedBox(height: 20),
                      Text(
                        'Welcome to One',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Your All-in-One Platform',
                        style: TextStyle(fontSize: 18, color: Colors.white70),
                      ),
                      SizedBox(height: 40),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          'Explore our features to discover how One can simplify your life.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.white70),
                        ),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton.icon(
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
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.purple.shade800,
                        ),
                      ),
                      SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: () async {
                          FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
                          if (result != null && result.files.single.path != null) {
                            await Share.shareXFiles([XFile(result.files.single.path!)]);
                          }
                        },
                        icon: Icon(Icons.share),
                        label: Text('Share PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.purple.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildFeatureButton(context, Icons.analytics, 'Notes'),
                    _buildFeatureButton(context, Icons.task_alt, 'Tasks'),
                    _buildFeatureButton(context, Icons.text_snippet, 'Sentence Analyzer'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureButton(
    BuildContext context,
    IconData icon,
    String label,
  ) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            if (label == 'Sentence Analyzer') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SentenceAnalyzerPage()),
              );
            }
            // if (label == 'Notes') {
            //   Navigator.push(
            //     context,
            //     MaterialPageRoute(builder: (context) => NotesPage()),
            //   );
            // } else if (label == 'Tasks') {
            //   Navigator.push(
            //     context,
            //     MaterialPageRoute(builder: (context) => TodosPage()),
            //   );
            // } else if (label == 'Community') {
            //   Navigator.push(
            //     context,
            //     MaterialPageRoute(builder: (context) => CommunityPage()),
            //   );
            // }
          },
          child: Icon(icon, color: Colors.purple.shade800),
          style: ElevatedButton.styleFrom(
            shape: CircleBorder(),
            padding: EdgeInsets.all(20),
            backgroundColor: Colors.white,
          ),
        ),
        SizedBox(height: 8),
        Text(label, style: TextStyle(color: Colors.white, fontSize: 14)),
      ],
    );
  }
}
