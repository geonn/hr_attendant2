import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final String baseUrl = "https://hrm.flexben.my";
  String authToken = "";

  ApiService();

  Future<Map<String, dynamic>?> post(
      String path, Map<String, String> params) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? authToken = prefs.getString('authenticate');
    print("$baseUrl$path $authToken");
    try {
      Uri url = Uri.parse(baseUrl + path).replace(queryParameters: params);
      final response = await http.post(
        url,
        headers: <String, String>{
          if (authToken != null) 'AUTHENTICATE': authToken,
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        print('Request failed with status: ${response.statusCode}.');
        return null;
      }
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future<Map<String, dynamic>?> postWithFile(
      String path, Map<String, String> params, File file) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? authToken = prefs.getString('authenticate');
    try {
      Uri url = Uri.parse(baseUrl + path);
      var request = http.MultipartRequest('POST', url);

      // Attach the file to the request
      request.files
          .add(await http.MultipartFile.fromPath('Filedata', file.path));

      // Add other form fields
      request.fields.addAll(params);

      // Add the authentication header if it exists
      if (authToken != null) {
        request.headers['AUTHENTICATE'] = authToken;
      }

      // Send the request
      final response = await request.send();

      if (response.statusCode == 200) {
        // Read the response
        final responseBody = await response.stream.bytesToString();
        return json.decode(responseBody) as Map<String, dynamic>;
      } else {
        print('Request failed with status: ${response.statusCode}.');
        return null;
      }
    } catch (e) {
      print(e.toString());
      return null;
    }
  }
}
