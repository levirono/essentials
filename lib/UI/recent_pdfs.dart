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
  String _searchQuery = '';
  List<RecentPdf> _allPdfs = [];

  @override
  void initState() {
    super.initState();
    _loadRecentPdfs();
  }

  void _loadRecentPdfs() async {
    final pdfs = await DatabaseHelper().getRecentPdfs();
    setState(() {
      _allPdfs = pdfs;
    });
    _recentPdfsFuture = Future.value(pdfs);
  }

  void _showFileToolbar(RecentPdf pdf) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.share,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  tooltip: 'Share',
                  onPressed: () async {
                    Navigator.pop(context);
                    await Share.shareXFiles([XFile(pdf.filePath)]);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Delete',
                  onPressed: () async {
                    Navigator.pop(context);
                    await DatabaseHelper().deleteRecentPdf(pdf.filePath);
                    _loadRecentPdfs();
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.folder_open,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  tooltip: 'Open Location',
                  onPressed: () {
                    Navigator.pop(context);
                    _openFileLocation(pdf.filePath);
                  },
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredPdfs =
        _searchQuery.isEmpty
            ? _allPdfs
            : _allPdfs
                .where(
                  (pdf) => pdf.filePath.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ),
                )
                .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Recently Viewed PDFs')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search PDFs...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child:
                filteredPdfs.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.picture_as_pdf,
                            size: 80,
                            color: Colors.grey[400],
                          ),
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
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 12,
                      ),
                      itemCount: filteredPdfs.length,
                      itemBuilder: (context, index) {
                        final pdf = filteredPdfs[index];
                        return Card(
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 4,
                          ),
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
                              _loadRecentPdfs();
                            },
                            onLongPress: () => _showFileToolbar(pdf),
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
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () async {
                                  await DatabaseHelper().deleteRecentPdf(
                                    pdf.filePath,
                                  );
                                  _loadRecentPdfs();
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
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
