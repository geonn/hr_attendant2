import 'dart:convert';
import 'dart:io';
import 'package:hr_attendant/models/claimType.dart';
import 'package:hr_attendant/services/api_service.dart';
import 'package:http/http.dart' as http;

class ClaimService {
  final ApiService _apiService;

  ClaimService() : _apiService = ApiService();

  Future<List<ClaimType>> getClaimTypes() async {
    var url =
        Uri.parse('https://hrm.flexben.my/application/cache/EB_claimType.json');
    var response = await http.get(url);

    if (response.statusCode == 200) {
      List<dynamic> jsonData = jsonDecode(response.body);
      List<ClaimType> claimTypes =
          jsonData.map((json) => ClaimType.fromJson(json)).toList();
      return claimTypes;
    } else {
      throw Exception('Failed to load claim types');
    }
  }

  Future<Map<String, dynamic>?> getClaims() async {
    try {
      final response = await _apiService.post('/api/getMyClaimList', {});

      if (response != null && response['status'] == 'success') {
        return response;
      } else {
        return null;
      }
    } catch (e) {
      print(e.toString());
      throw Exception('Failed to load claims: $e');
    }
  }

  Future<Map<String, dynamic>?> submitClaim({
    required String category,
    required String visitDate,
    required String receiptNo,
    required String providerName,
    required String amount,
    required String remark,
    required File file,
  }) async {
    var response = await _apiService.postWithFile(
        '/api/doSubmitClaim',
        {
          'category': category,
          'visit_date': visitDate,
          'receipt_no': receiptNo,
          'provider_name': providerName,
          'amount': amount,
          'remark': remark,
        },
        file);
    return response;
  }
}
