import 'package:flutter/material.dart';
import 'UI/home.dart';
import 'features/pdf_reader.dart';
import 'dart:async';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'dart:io';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription? _intentSub;
  String? _sharedPdfPath;

  @override
  void initState() {
    super.initState();
    // Listen for shared files while app is in memory
    _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen(
      (List<SharedMediaFile> value) {
        if (value.isNotEmpty && value[0].path.toLowerCase().endsWith('.pdf')) {
          setState(() {
            _sharedPdfPath = value[0].path;
          });
        }
      },
      onError: (err) {
        // Handle error if needed
      },
    );
    // Listen for shared files when app is launched
    ReceiveSharingIntent.instance.getInitialMedia().then((
      List<SharedMediaFile> value,
    ) {
      if (value.isNotEmpty && value[0].path.toLowerCase().endsWith('.pdf')) {
        setState(() {
          _sharedPdfPath = value[0].path;
        });
      }
      // Reset after processing
      ReceiveSharingIntent.instance.reset();
    });
  }

  @override
  void dispose() {
    _intentSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'One',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home:
          _sharedPdfPath != null
              ? PdfReaderPage(filePath: _sharedPdfPath!)
              : HomePage(),
    );
  }
}
