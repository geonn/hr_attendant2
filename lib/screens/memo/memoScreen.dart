import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:hr_attendant/models/memo.dart';
import 'package:hr_attendant/screens/pdfViewer.dart';
import 'package:hr_attendant/services/api_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

class MemoScreen extends StatefulWidget {
  const MemoScreen({super.key});

  @override
  State<MemoScreen> createState() => _MemoScreenState();
}

class _MemoScreenState extends State<MemoScreen> {
  late List<Memo> data;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    ApiService api = ApiService();
    var response = await api.post("/api/getMemo", {});
    if (response != null && response['status'] == 'success') {
      setState(() {
        data = (response['data'] as List).map((i) => Memo.fromJson(i)).toList();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Company Memo"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: data.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Card(
                    child: ListTile(
                      title: Text(data[index].subject),
                      subtitle: Text(data[index].message),
                      trailing: data[index].attachment != null
                          ? IconButton(
                              icon: const Icon(Icons.attachment),
                              onPressed: () async {
                                // Check file type and perform actions
                                if (isImageFile(data[index].attachment!)) {
                                  // Code to show image in a popup
                                  showImagePopup(
                                      context, data[index].attachment!);
                                } else if (isPdfFile(data[index].attachment!)) {
                                  // Code to download and open PDF
                                  openPdfFile(data[index].attachment!);
                                  /*String filePath = await downloadFileToCache(
                                      data[index].attachment!);
                                  openPdfFile(filePath);*/
                                }
                              },
                            )
                          : null,
                    ),
                  ),
                );
              },
            ),
    );
  }

  bool isImageFile(String filePath) {
    // Implement logic to determine if the file is an image
    return filePath.endsWith('.png') ||
        filePath.endsWith('.jpg') ||
        filePath.endsWith('.jpeg');
  }

  bool isPdfFile(String filePath) {
    // Implement logic to determine if the file is a PDF
    return filePath.endsWith('.pdf');
  }

  void showImagePopup(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Image.network(imageUrl),
          actions: <Widget>[
            TextButton(
              child: const Text('Download'),
              onPressed: () {
                // Implement logic to download the image
                downloadImage(imageUrl);
              },
            ),
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> downloadImage(String imageUrl) async {
    try {
      // Requesting storage permission
      var status = await Permission.storage.request();
      if (status.isGranted) {
        // Fetching the image from the internet
        http.Response response = await http.get(Uri.parse(imageUrl));

        // Saving the image to the gallery
        await Gal.putImageBytes(Uint8List.fromList(response.bodyBytes));
        /*final result = await ImageGallerySaver.saveImage(
          Uint8List.fromList(response.bodyBytes),
          quality: 100,
          name: "image_name_here",
        );*/

        showSnackBar(context, "Image saved to gallery");
      } else {
        showSnackBar(context, "Storage permission denied");
      }
    } catch (e) {
      showSnackBar(context, "Error downloading image: $e");
    }
  }

  void showSnackBar(BuildContext context, String message) {
    final snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<String> downloadFileToCache(String fileUrl) async {
    // Implement logic to download file to cache
    // Return the local file path
    return "";
  }

  void openPdfFile(String filePath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PDF(filePath),
      ),
    );
    // Implement logic to open PDF file using flutter_pdfview
  }
}
