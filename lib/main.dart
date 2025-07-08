import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_sharing_intent/flutter_sharing_intent.dart';
import 'package:flutter_sharing_intent/model/sharing_file.dart';
import 'features/pdf_reader.dart';
import 'UI/home.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late StreamSubscription _intentDataStreamSubscription;
  String? _sharedPdfPath;

  @override
  void initState() {
    super.initState();
    // Listen for shared files while app is in memory
    _intentDataStreamSubscription = FlutterSharingIntent.instance
        .getMediaStream()
        .listen(
          (List<SharedFile> value) {
            if (value.isNotEmpty &&
                value[0].value != null &&
                value[0].value!.toLowerCase().endsWith('.pdf')) {
              setState(() {
                _sharedPdfPath = value[0].value;
              });
            }
          },
          onError: (err) {
            print("getMediaStream error: $err");
          },
        );

    // Listen for shared files when app is launched
    FlutterSharingIntent.instance.getInitialSharing().then((
      List<SharedFile> value,
    ) {
      if (value.isNotEmpty && value[0].value!.toLowerCase().endsWith('.pdf')) {
        setState(() {
          _sharedPdfPath = value[0].value;
        });
      }
    });
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

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }
}
