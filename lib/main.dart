import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_sharing_intent/flutter_sharing_intent.dart';
import 'package:flutter_sharing_intent/model/sharing_file.dart';
import 'features/pdf_reader.dart';
import 'UI/home.dart';
import 'UI/recent_pdfs.dart';

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
        colorScheme: ColorScheme(
          brightness: Brightness.light,
          primary: Color(0xFF43A047), // Green
          onPrimary: Colors.white,
          secondary: Color(0xFF1E88E5), // Blue
          onSecondary: Colors.white,
          background: Color(0xFFF5F5F5), // Light gray
          onBackground: Colors.black,
          surface: Colors.white,
          onSurface: Colors.black,
          error: Colors.red,
          onError: Colors.white,
        ),
        scaffoldBackgroundColor: Color(0xFFF5F5F5),
        useMaterial3: true,
        fontFamily: 'Roboto',
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF43A047),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardTheme(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 4,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF1E88E5),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      routes: {'/recent_pdfs': (context) => const RecentPdfsPage()},
      home: Builder(
        builder: (context) {
          if (_sharedPdfPath != null) {
            // Use a Future to push PdfReaderPage and clear the path after pop
            Future.microtask(() async {
              final path = _sharedPdfPath;
              setState(() => _sharedPdfPath = null);
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PdfReaderPage(filePath: path!),
                ),
              );
            });
            return const SizedBox.shrink(); // Placeholder while navigating
          } else {
            return HomePage();
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }
}
