import 'package:hr_attendant/models/profile.dart';
import 'package:hr_attendant/models/user_model.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

final log = Logger();

class AuthService {
  final ApiService _apiService;

  AuthService() : _apiService = ApiService();

  Future<UserModel?> login(String email, String password) async {
    Map<String, String> params = {
      'user': 'hrapp',
      'key': '66505234721014515949f7875c8959403',
      'email': email,
      'password': password,
    };
    Map<String, dynamic>? response =
        await _apiService.post('/api/doLogin', params);

    if (response != null && response['status'] == 'success') {
      log.d(response);
      String authToken = response[
          'authenticate']; // Get the authentication token from the API response
      ApiService apiService = ApiService();
      apiService.authToken =
          authToken; // Set the authToken property of the ApiService class
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('authenticate', authToken);
      return UserModel(
          uid: response['data']['id'], email: response['data']['email']);
    } else {
      return null;
    }
  }

  Future<void> logout() async {
    // Remove the authentication token from the shared preferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('authenticate');
  }

  Future<String?> forgetPassword(String email) async {
    // Implement the logic to handle password reset requests
    // Return true if the request is successful, false otherwise
    Map<String, String> params = {
      'email': email,
    };
    Map<String, dynamic>? response =
        await _apiService.post('/api/forgetPassword', params);
    log.d(response);
    if (response != null && response['data']['status'] == 'success') {
      return null;
    } else {
      return response?['data']['data'].join('\n') ?? 'An error occurred';
    }
  }

  Future<Profile> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    String deviceToken = prefs.getString('fcm_token') ?? '';
    final response = await _apiService.post(
      '/api/getUserProfile',
      {"device_token": deviceToken},
    );
    if (response != null && response['status'] == 'success') {
      print(response);
      return Profile.fromJson(response['data']);
    } else {
      await logout();
      throw Exception('Failed to load profile. User logged out.');
    }
  }

  Future<bool> isAuthenticated() async {
    // Check for authentication token or user ID in local storage, etc.
    // Return true if authenticated, false otherwise
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? authToken = prefs.getString('authenticate');

    if (authToken != null && authToken.isNotEmpty) {
      return true;
    } else {
      return false;
    }
  }
}
