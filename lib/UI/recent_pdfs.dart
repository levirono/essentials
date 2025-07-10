import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';

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
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            itemCount: pdfs.length,
            itemBuilder: (context, index) {
              final pdf = pdfs[index];
              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: InkWell(
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
                  onLongPress: () async {
                    showModalBottomSheet(
                      context: context,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(18),
                        ),
                      ),
                      builder:
                          (context) => SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: Icon(Icons.share),
                                  title: Text('Share'),
                                  onTap: () async {
                                    Navigator.pop(context);
                                    // Use share_plus for sharing
                                    // ignore: use_build_context_synchronously
                                    await Share.shareXFiles([
                                      XFile(pdf.filePath),
                                    ]);
                                  },
                                ),
                                ListTile(
                                  leading: Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  title: Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                  onTap: () async {
                                    Navigator.pop(context);
                                    await DatabaseHelper().deleteRecentPdf(
                                      pdf.filePath,
                                    );
                                    setState(() {
                                      _loadRecentPdfs();
                                    });
                                  },
                                ),
                                ListTile(
                                  leading: Icon(Icons.folder_open),
                                  title: Text('Open Location'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _openFileLocation(pdf.filePath);
                                  },
                                ),
                              ],
                            ),
                          ),
                    );
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 18,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: Colors.red[100],
                      child: Icon(
                        Icons.picture_as_pdf,
                        color: Colors.red[700],
                        size: 30,
                      ),
                      radius: 28,
                    ),
                    title: Text(
                      pdf.filePath.split('/').last,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          'Last page:  ${pdf.lastPage + 1}',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Viewed: ${pdf.lastOpened}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        await DatabaseHelper().deleteRecentPdf(pdf.filePath);
                        setState(() {
                          _loadRecentPdfs();
                        });
                      },
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _openFileLocation(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await OpenFile.open(file.path);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('File not found: $filePath'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
