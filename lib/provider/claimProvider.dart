import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hr_attendant/models/claim.dart';
import 'package:hr_attendant/models/claimType.dart';
import 'package:hr_attendant/services/claim_service.dart';

class ClaimProvider with ChangeNotifier {
  List<Claim> _claims = [];
  final ClaimService _claimService = ClaimService();
  List<ClaimType> _claimTypes = [];
  bool isLoading = false;
  String? errorMessage;

  List<ClaimType> get claimTypes => _claimTypes;
  List<Claim> get claims => [..._claims];

  fetchClaimTypes() async {
    _claimTypes = await _claimService.getClaimTypes();
    notifyListeners();
  }

  void reset() {
    _claims.clear();
    _claimTypes.clear();
    notifyListeners();
  }

  Future<void> submitClaim(String category, String visitDate, String receiptNo,
      String providerName, double amount, String remark, File file) async {
    try {
      // Call the submitClaim method of the ClaimService
      final response = await _claimService.submitClaim(
        category: category,
        visitDate: visitDate,
        receiptNo: receiptNo,
        providerName: providerName,
        amount: amount.toString(),
        remark: remark,
        file: file,
      );

      // Handle the response, e.g., by updating the list of claims
      // and calling notifyListeners() to update the UI
    } catch (error) {
      // Handle any errors, e.g., by storing the error message in a variable
      // and calling notifyListeners() to update the UI
      rethrow; // Or handle the error in a different way
    }
  }

  Future<void> fetchClaims() async {
    isLoading = true;
    errorMessage = null;
    try {
      var response = await ClaimService().getClaims();
      _claims = Claim.fromJsonArray(response!['data']);
    } catch (error) {
      errorMessage = error.toString();
    }

    isLoading = false;
    notifyListeners();
  }
}
