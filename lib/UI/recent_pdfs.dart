import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../features/pdf_reader.dart';

class RecentPdfsPage extends StatefulWidget {
  const RecentPdfsPage({Key? key}) : super(key: key);

  @override
  State<RecentPdfsPage> createState() => _RecentPdfsPageState();
}

class _RecentPdfsPageState extends State<RecentPdfsPage> {
  late Future<List<RecentPdf>> _recentPdfsFuture;

  @override
  void initState() {
    super.initState();
    _loadRecentPdfs();
  }

  void _loadRecentPdfs() {
    _recentPdfsFuture = DatabaseHelper().getRecentPdfs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recently Viewed PDFs')),
      body: FutureBuilder<List<RecentPdf>>(
        future: _recentPdfsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.picture_as_pdf, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 24),
                  Text(
                    'No recently viewed PDFs',
                    style: TextStyle(
                      fontSize: 22,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Open a PDF to see it appear here.',
                    style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }
          final pdfs = snapshot.data!;
          return ListView.builder(
            itemCount: pdfs.length,
            itemBuilder: (context, index) {
              final pdf = pdfs[index];
              return ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: Text(pdf.filePath.split('/').last),
                subtitle: Text(
                  'Last page:  ${pdf.lastPage + 1} • Viewed: ${pdf.lastOpened}',
                ),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => PdfReaderPage(
                            filePath: pdf.filePath,
                            initialPage: pdf.lastPage,
                          ),
                    ),
                  );
                  setState(() {
                    _loadRecentPdfs();
                  });
                },
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    await DatabaseHelper().deleteRecentPdf(pdf.filePath);
                    setState(() {
                      _loadRecentPdfs();
                    });
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
