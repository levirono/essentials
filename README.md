# essentials

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## PDF Reader Feature

This app allows you to open and read PDF files using the Syncfusion PDF Viewer.

### How to Use
- On the homepage, tap the 'Open PDF' button.
- Select a PDF file from your device using the file picker.
- The PDF will open in a dedicated reader page with full viewing capabilities.

### Web Support
- For web, the required pdf.js script is already included in `web/index.html` for Syncfusion PDF Viewer compatibility.

### Dependencies
- [syncfusion_flutter_pdfviewer](https://pub.dev/packages/syncfusion_flutter_pdfviewer)
- [file_picker](https://pub.dev/packages/file_picker)

### Open With (Android/iOS)
- To enable 'Open with' from other apps, you may need to implement platform-specific intent handling (not included in this basic setup). For advanced integration, see the Syncfusion and Flutter documentation for deep linking and intent filters.
