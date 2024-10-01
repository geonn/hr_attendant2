import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfx/pdfx.dart';
import 'package:internet_file/internet_file.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class PDF extends StatefulWidget {
  String url;
  PDF(this.url, {super.key});

  @override
  _PDFState createState() => _PDFState();
}

class _PDFState extends State<PDF> {
  late PdfController _pdfControllerPinch;
  static const int _initialPage = 1;

  @override
  void initState() {
    super.initState();
    _pdfControllerPinch = PdfController(
      // document: PdfDocument.openAsset('assets/hello.pdf'),
      document: PdfDocument.openData(
        InternetFile.get(
          widget.url,
        ),
      ),
      initialPage: _initialPage,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('PDF Viewer'),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () {
                // Implement logic to download the PDF
                downloadPdf(context, widget.url);
              },
            ),
          ],
        ),
        body: PdfView(
          controller: _pdfControllerPinch,
          onDocumentLoaded: (document) {},
          onPageChanged: (page) {},
        ));
  }

  Future<void> downloadPdf(BuildContext context, String pdfUrl) async {
    try {
      // Fetching the PDF from the internet
      http.Response response = await http.get(Uri.parse(pdfUrl));
      Uint8List pdfBytes = response.bodyBytes;

      // Extracting the file name from the URL
      Uri uri = Uri.parse(pdfUrl);
      String fileName = uri.pathSegments.last;

      if (Platform.isAndroid) {
        // Save PDF to Downloads directory on Android
        await _saveFileToDownloadsAndroid(pdfBytes, fileName);
      } else if (Platform.isIOS) {
        // Use internal storage for iOS
        Directory dir = await getApplicationDocumentsDirectory();
        File file = File('${dir.path}/$fileName');
        await file.writeAsBytes(pdfBytes);
        showSnackBar(context, "PDF downloaded: $fileName");
        _openPdf(context, file.path);

        //OpenFile.open(file.path);
      }
    } catch (e) {
      showSnackBar(context, "Error downloading PDF: $e");
    }
  }

  Future<void> _saveFileToDownloadsAndroid(
      Uint8List fileBytes, String fileName) async {
    const platform = MethodChannel('com.flexben.downloads');
    try {
      final String result = await platform.invokeMethod('saveFileToDownloads', {
        'bytes': fileBytes,
        'fileName': fileName,
      });
      if (result.isNotEmpty) {
        //OpenFile.open(result);
        _openPdf(context, result);

        showSnackBar(context, "PDF downloaded: $fileName");
        print('File saved to Downloads: $result');
      } else {
        print('Failed to get the file path');
      }
    } on PlatformException catch (e) {
      print("Failed to save file: '${e.message}'.");
    }
  }

  void _openPdf(BuildContext context, String filePath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PDF(filePath),
      ),
    );
  }

  Future<void> downloadPdf2(BuildContext context, String pdfUrl) async {
    try {
      // Requesting storage permission
      var status = await Permission.storage.request();

      if (status.isGranted) {
        // Fetching the PDF from the internet
        http.Response response = await http.get(Uri.parse(pdfUrl));

        // Getting the Downloads directory
        Directory? dir = (Platform.isIOS)
            ? await getApplicationDocumentsDirectory()
            : await getDownloadsDirectory();
        if (dir == null) {
          showSnackBar(context, "Unable to find the Downloads directory");
          return;
        }
        String path = dir.path;

        // Extracting the file name from the URL
        Uri uri = Uri.parse(pdfUrl);
        String fileName = uri.pathSegments.last;

        // Creating a file in the Downloads directory
        File file = File('$path/$fileName');
        await file.writeAsBytes(response.bodyBytes);

        // Showing a success message
        showSnackBar(context, "PDF downloaded: $fileName");

        // Optionally, open the file
        _openPdf(context, file.path);
        //OpenFile.open(file.path);
      } else {
        showSnackBar(context, "Storage permission denied");
      }
    } catch (e) {
      showSnackBar(context, "Error downloading PDF: $e");
    }
  }

  void showSnackBar(BuildContext context, String message) {
    final snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
