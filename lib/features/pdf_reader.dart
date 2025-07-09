import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'dart:io';
import 'dart:async';

class PdfReaderPage extends StatefulWidget {
  final String filePath;
  const PdfReaderPage({Key? key, required this.filePath}) : super(key: key);

  @override
  State<PdfReaderPage> createState() => _PdfReaderPageState();
}

class _PdfReaderPageState extends State<PdfReaderPage> {
  bool _showToolbar = true;
  bool _showAppBar = true;
  Timer? _hideTimer;
  final PdfViewerController _pdfController = PdfViewerController();

  void _hideUI() {
    setState(() {
      _showToolbar = false;
      _showAppBar = false;
    });
  }

  @override
  void initState() {
    super.initState();
    // UI is visible at start, but will hide on first tap/scroll
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: _hideUI,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar:
            _showAppBar
                ? PreferredSize(
                  preferredSize: Size.fromHeight(70),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5.0,
                      vertical: 10.0,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.7),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withOpacity(0.2),
                              blurRadius: 16,
                              offset: Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: colorScheme.secondary.withOpacity(0.2),
                            width: 1.5,
                          ),
                        ),
                        child: AppBar(
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          title: const Text(
                            'PDF Reader',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                              letterSpacing: 1.2,
                            ),
                          ),
                          centerTitle: true,
                          iconTheme: IconThemeData(color: Colors.white),
                          actions: [
                            IconButton(
                              icon: Icon(Icons.search, color: Colors.white),
                              onPressed: () {},
                              tooltip: 'Search',
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.bookmark_border,
                                color: Colors.white,
                              ),
                              onPressed: () {},
                              tooltip: 'Bookmarks',
                            ),
                            IconButton(
                              icon: Icon(Icons.share, color: Colors.white),
                              onPressed: () {},
                              tooltip: 'Share',
                            ),
                            IconButton(
                              icon: Icon(Icons.more_vert, color: Colors.white),
                              onPressed: () {},
                              tooltip: 'More',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
                : null,
        body: Stack(
          children: [
            NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollUpdateNotification &&
                    notification.metrics.axis == Axis.vertical) {
                  _hideUI();
                }
                return false;
              },
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary.withOpacity(0.7),
                      colorScheme.secondary.withOpacity(0.7),
                      colorScheme.background,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(0.0),
                      child: Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        color: Colors.white.withOpacity(0.95),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: SfPdfViewer.file(
                            File(widget.filePath),
                            controller: _pdfController,
                            canShowScrollHead: true,
                            canShowScrollStatus: true,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (_showToolbar)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: AnimatedOpacity(
                  opacity: _showToolbar ? 1.0 : 0.0,
                  duration: Duration(milliseconds: 300),
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 8),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: Icon(Icons.zoom_in, color: colorScheme.primary),
                          onPressed: _hideUI,
                          tooltip: 'Zoom In',
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.zoom_out,
                            color: colorScheme.secondary,
                          ),
                          onPressed: _hideUI,
                          tooltip: 'Zoom Out',
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.bookmark,
                            color: colorScheme.primary,
                          ),
                          onPressed: _hideUI,
                          tooltip: 'Bookmark',
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.settings,
                            color: colorScheme.secondary,
                          ),
                          onPressed: _hideUI,
                          tooltip: 'Settings',
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.nightlight_round,
                            color: colorScheme.primary,
                          ),
                          onPressed: _hideUI,
                          tooltip: 'Night Mode',
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.rotate_90_degrees_ccw,
                            color: colorScheme.secondary,
                          ),
                          onPressed: _hideUI,
                          tooltip: 'Rotate',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
