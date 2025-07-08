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
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: _onInteraction,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
                ),
              ),
            ),
          ),
        ),
        body: Stack(
          children: [
            Container(
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
                          icon: Icon(Icons.zoom_in, color: colorScheme.primary),
                          onPressed: _onInteraction,
                          tooltip: 'Zoom In',
                        ),
                        IconButton(
                          icon: Icon(Icons.zoom_out, color: colorScheme.secondary),
                          onPressed: _onInteraction,
                          tooltip: 'Zoom Out',
                        ),
                        IconButton(
                          icon: Icon(Icons.bookmark, color: colorScheme.primary),
                          onPressed: _onInteraction,
                          tooltip: 'Bookmark',
                        ),
                        IconButton(
                          icon: Icon(Icons.settings, color: colorScheme.secondary),
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
