import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'dart:io';
import 'dart:async';
import '../database_helper.dart';

class PdfReaderPage extends StatefulWidget {
  final String filePath;
  final int? initialPage;
  const PdfReaderPage({Key? key, required this.filePath, this.initialPage})
    : super(key: key);

  @override
  State<PdfReaderPage> createState() => _PdfReaderPageState();
}

class _PdfReaderPageState extends State<PdfReaderPage> {
  bool _showToolbar = true;
  bool _showAppBar = true;
  bool _nightMode = false;
  double _zoomLevel = 1.0;
  int _rotation = 0;
  Timer? _hideTimer;
  final PdfViewerController _pdfController = PdfViewerController();
  PdfTextSearchResult? _searchResult;
  String _searchQuery = '';

  void _hideUI() {
    setState(() {
      _showToolbar = false;
      _showAppBar = false;
    });
  }

  void _resetHideTimer() {
    _hideTimer?.cancel();
    setState(() {
      _showToolbar = true;
      _showAppBar = true;
    });
    _hideTimer = Timer(const Duration(milliseconds: 2500), () {
      setState(() {
        _showToolbar = false;
        _showAppBar = false;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialPage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pdfController.jumpToPage(widget.initialPage! + 1);
      });
    }
    // Save to recent PDFs on open
    _saveRecentPdf();
    // Listen for page changes
    _pdfController.addListener(_onPageChanged);
    _resetHideTimer();
  }

  void _onPageChanged() {
    _saveRecentPdf();
  }

  void _saveRecentPdf() async {
    final page = _pdfController.pageNumber - 1;
    await DatabaseHelper().insertOrUpdateRecentPdf(
      RecentPdf(
        filePath: widget.filePath,
        lastPage: page < 0 ? 0 : page,
        lastOpened: DateTime.now(),
      ),
    );
  }

  void _toggleNightMode() {
    setState(() {
      _nightMode = !_nightMode;
    });
  }

  void _zoomIn() {
    setState(() {
      _zoomLevel += 0.25;
      _pdfController.zoomLevel = _zoomLevel;
    });
  }

  void _zoomOut() {
    setState(() {
      _zoomLevel = (_zoomLevel - 0.25).clamp(1.0, 5.0);
      _pdfController.zoomLevel = _zoomLevel;
    });
  }

  void _rotate() {
    setState(() {
      _rotation = (_rotation + 90) % 360;
    });
  }

  void _bookmark() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Bookmark added (demo)!')));
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Settings'),
            content: Text('Settings dialog (demo).'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close'),
              ),
            ],
          ),
    );
  }

  void _showSearchSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: MediaQuery.of(context).viewInsets,
              child: Container(
                decoration: BoxDecoration(
                  color: _nightMode ? Colors.grey[900] : Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: 'Search in PDF...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              filled: true,
                              fillColor:
                                  _nightMode
                                      ? Colors.grey[850]
                                      : Colors.grey[200],
                              prefixIcon: Icon(Icons.search),
                            ),
                            onChanged: (value) async {
                              setModalState(() {
                                _searchQuery = value;
                              });
                              if (value.isNotEmpty) {
                                final result = await _pdfController.searchText(
                                  value,
                                );
                                setModalState(() {
                                  _searchResult = result;
                                });
                              } else {
                                setModalState(() {
                                  _searchResult = null;
                                });
                              }
                            },
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_searchResult != null &&
                        _searchResult!.totalInstanceCount > 0)
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Found ${_searchResult!.totalInstanceCount} results',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.arrow_upward),
                                    onPressed: () {
                                      _searchResult!.previousInstance();
                                      setModalState(() {});
                                    },
                                  ),
                                  Text(
                                    '${_searchResult!.currentInstanceIndex + 1}/${_searchResult!.totalInstanceCount}',
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.arrow_downward),
                                    onPressed: () {
                                      _searchResult!.nextInstance();
                                      setModalState(() {});
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      )
                    else if (_searchQuery.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text('No results found.'),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _pdfController.removeListener(_onPageChanged);
    _pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () {
        if (!_showToolbar && !_showAppBar) {
          setState(() {
            _showToolbar = true;
            _showAppBar = true;
          });
        }
        _resetHideTimer();
      },
      onPanDown: (_) => _resetHideTimer(),
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
                              onPressed: _showSearchSheet,
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
                  if (!_showToolbar || !_showAppBar) {
                    setState(() {
                      _showToolbar = true;
                      _showAppBar = true;
                    });
                  }
                  _resetHideTimer();
                }
                return false;
              },
              child: Container(
                decoration: BoxDecoration(
                  gradient:
                      _nightMode
                          ? LinearGradient(
                            colors: [Colors.black, Colors.grey[900]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                          : LinearGradient(
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
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final double width = constraints.maxWidth;
                          final double height = constraints.maxHeight;
                          return Transform.rotate(
                            angle: _rotation * 3.1415926535 / 180,
                            child: Container(
                              width: width,
                              height: height,
                              child: FittedBox(
                                fit: BoxFit.contain,
                                child: SizedBox(
                                  width: width / _zoomLevel,
                                  height: height / _zoomLevel,
                                  child: Card(
                                    elevation: 8,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    color:
                                        _nightMode
                                            ? Colors.black
                                            : Colors.white.withOpacity(0.95),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(24),
                                      child: SfPdfViewer.file(
                                        File(widget.filePath),
                                        controller: _pdfController,
                                        canShowScrollHead: true,
                                        canShowScrollStatus: true,
                                        pageLayoutMode:
                                            PdfPageLayoutMode.continuous,
                                        scrollDirection:
                                            PdfScrollDirection.vertical,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
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
                      color:
                          _nightMode
                              ? Colors.grey[900]!.withOpacity(0.95)
                              : Colors.white.withOpacity(0.95),
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
                          onPressed: () {
                            _zoomIn();
                            _resetHideTimer();
                          },
                          tooltip: 'Zoom In',
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.zoom_out,
                            color: colorScheme.secondary,
                          ),
                          onPressed: () {
                            _zoomOut();
                            _resetHideTimer();
                          },
                          tooltip: 'Zoom Out',
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.bookmark,
                            color: colorScheme.primary,
                          ),
                          onPressed: () {
                            _bookmark();
                            _resetHideTimer();
                          },
                          tooltip: 'Bookmark',
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.settings,
                            color: colorScheme.secondary,
                          ),
                          onPressed: () {
                            _showSettings();
                            _resetHideTimer();
                          },
                          tooltip: 'Settings',
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.nightlight_round,
                            color: colorScheme.primary,
                          ),
                          onPressed: () {
                            _toggleNightMode();
                            _resetHideTimer();
                          },
                          tooltip: 'Night Mode',
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.rotate_90_degrees_ccw,
                            color: colorScheme.secondary,
                          ),
                          onPressed: () {
                            _rotate();
                            _resetHideTimer();
                          },
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
