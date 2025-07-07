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
  Timer? _hideTimer;

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      setState(() {
        _showToolbar = false;
      });
    });
  }

  void _onInteraction() {
    setState(() {
      _showToolbar = true;
    });
    _startHideTimer();
  }

  @override
  void initState() {
    super.initState();
    _startHideTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onInteraction,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'PDF Reader',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.green.shade500,
                    Colors.blue.shade600,
                    Colors.grey.shade900,
                    Colors.black,
                  ],
                ),
              ),
              child: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
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
                          canShowScrollHead: true,
                          canShowScrollStatus: true,
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: Icon(Icons.zoom_in, color: Colors.green.shade700),
                          onPressed: _onInteraction,
                          tooltip: 'Zoom In',
                        ),
                        IconButton(
                          icon: Icon(Icons.zoom_out, color: Colors.red.shade700),
                          onPressed: _onInteraction,
                          tooltip: 'Zoom Out',
                        ),
                        IconButton(
                          icon: Icon(Icons.bookmark, color: Colors.blue.shade700),
                          onPressed: _onInteraction,
                          tooltip: 'Bookmark',
                        ),
                        IconButton(
                          icon: Icon(Icons.settings, color: Colors.grey.shade700),
                          onPressed: _onInteraction,
                          tooltip: 'Settings',
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
