import 'package:flutter/material.dart';
import 'UI/home.dart';
import 'features/pdf_reader.dart';
import 'dart:async';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? _sharedPdfPath;
  StreamSubscription? _intentDataStreamSubscription;

  @override
  void initState() {
    super.initState();
    // For app in memory
    _intentDataStreamSubscription = ReceiveSharingIntent.getMediaStream().listen((List<SharedMediaFile> value) {
      if (value.isNotEmpty && value[0].path.toLowerCase().endsWith('.pdf')) {
        setState(() {
          _sharedPdfPath = value[0].path;
        });
      }
    }, onError: (err) {});
    // For app launch
    ReceiveSharingIntent.getInitialMedia().then((List<SharedMediaFile> value) {
      if (value.isNotEmpty && value[0].path.toLowerCase().endsWith('.pdf')) {
        setState(() {
          _sharedPdfPath = value[0].path;
        });
      }
    });
  }

  @override
  void dispose() {
    _intentDataStreamSubscription?.cancel();
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
      home: _sharedPdfPath != null ? PdfReaderPage(filePath: _sharedPdfPath!) : HomePage(),
    );
  }
}
