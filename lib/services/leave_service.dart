import 'dart:io';

import 'package:hr_attendant/models/leave.dart';
import 'package:hr_attendant/services/api_service.dart';
import 'package:logger/logger.dart';
import 'package:intl/intl.dart';

class LeaveService {
  final log = Logger();
  final ApiService _apiService;

  LeaveService() : _apiService = ApiService();

  Future<Map<String, dynamic>?> doSubmitLeave({
    required String leaveType,
    required DateTime fromDate,
    required DateTime toDate,
    required double days,
    required String reason,
    File? attachment,
    String? half_day,
    String? takeover1_uid,
  }) async {
    // Convert the parameters to the format expected by your API
    Map<String, String> parameters = {
      'leave_type': leaveType,
      'from_date': DateFormat('yyyy-MM-dd').format(fromDate),
      'to_date': DateFormat('yyyy-MM-dd').format(toDate),
      'days': days.toString(),
      'takeover1_uid': takeover1_uid ?? "",
      'reason': reason,
    };

    // If there's an attachment, add it to the parameters
    if (attachment != null) {
      parameters['attachment'] = attachment.path;
    }
    if (half_day != null) {
      parameters['half_day'] = half_day;
    }
    print(parameters);
    // Send the request
    final response = attachment != null
        ? await _apiService.postWithFile(
            '/api/doSubmitLeave', parameters, attachment)
        : await _apiService.post('/api/doSubmitLeave', parameters);
    print(response);
    if (response != null) {
      return response;
    } else {
      return null;
    }
  }

  Future<Map<String, dynamic>?> removeMyLeave(String id) async {
    try {
      var response = await _apiService.post('/api/removeMyLeave', {'id': id});
      log.d(id);
      return response;
    } catch (e) {
      print('Failed to remove leave. Error: $e');
    }
    return null;
  }

  Future<List<Leave>> getLeaveList() async {
    final response = await _apiService.post('/api/getMyLeaveList', {});

    if (response != null && response['status'] == 'success') {
      List<dynamic> data = response['data'];
      return data.map((leave) => Leave.fromJson(leave)).toList();
    } else {
      // If that call was not successful, throw an error.
      throw Exception('Failed to load leaves');
    }
  }
}
