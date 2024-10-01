import 'package:flutter/material.dart';
import 'package:hr_attendant/models/payslip.dart';
import 'package:hr_attendant/services/api_service.dart';

class PayslipProvider with ChangeNotifier {
  List<Payslip> _payslips = [];
  final ApiService _apiService = ApiService();

  List<Payslip> get payslips => _payslips;

  void reset() {
    _payslips.clear();
    notifyListeners();
  }

  Future<void> fetchPayslips() async {
    var response = await _apiService.post('/api/getMyPayslip', {});
    if (response != null && response['status'] == 'success') {
      _payslips = (response['data'] as List)
          .map((item) => Payslip.fromJson(item))
          .toList();
      notifyListeners();
    }
  }
}
