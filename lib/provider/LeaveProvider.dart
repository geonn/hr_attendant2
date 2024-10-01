import 'package:flutter/material.dart';
import 'package:hr_attendant/models/leave.dart';
import 'package:hr_attendant/services/api_service.dart';

class LeaveProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  late Map<String, dynamic> _leaveSummary;
  List<Leave> _leaves = [];

  Map<String, dynamic> get leaveSummary => _leaveSummary;
  List<Leave> get leaves => _leaves;

  void reset() {
    _leaveSummary.clear();
    _leaves.clear();
    notifyListeners();
  }

  Future<void> fetchLeaves() async {
    try {
      var response = await _apiService.post('/api/getMyLeaveList', {});
      if (response != null && response['status'] == 'success') {
        var data2 = response['data2'];

        if (data2 is Map<String, dynamic>) {
          _leaveSummary = data2;
        } else if (data2 is List) {
          // Handle the case when it's a list. Maybe assign default values or handle as list.
          _leaveSummary =
              {}; // assign an empty map as default, or handle appropriately
        } else {
          _leaveSummary = {}; // default to an empty map
        }
        var data = response['data'];
        if (data is List) {
          // check that 'data' is a List
          _leaves = data.map((leave) => Leave.fromJson(leave)).toList();
        } else {
          print('Error: data is not a list');
        }

        notifyListeners();
      }
    } catch (error) {
      // Handle any error that occurred during the API request
      print('Error fetching leaves: $error');
    }
  }
}
