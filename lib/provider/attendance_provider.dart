import 'package:flutter/material.dart';
import 'package:hr_attendant/services/api_service.dart';
import 'package:hr_attendant/services/attendant_service.dart';
import 'package:intl/intl.dart';

class AttendanceProvider with ChangeNotifier {
  Map<DateTime, Map<String, dynamic>> _attendance = {};
  final ApiService _apiService = ApiService();

  Map<DateTime, Map<String, dynamic>> get attendance => _attendance;

  Future<void> fetchTodayAttendance() async {
    String fromDateString = DateFormat('yyyy-MM-dd').format(DateTime.now());
    String toDateString = DateFormat('yyyy-MM-dd').format(DateTime.now());
    print(fromDateString);
    print(toDateString);
    try {
      final response = await _apiService.post('/api/getMyAttendanceByDate', {
        'fromDate': fromDateString,
        'toDate': toDateString,
      });
      print(response);
      if (response != null && response['status'] == 'success') {
        var data = response['data'];

        for (var date in data.keys) {
          DateTime eventDate = DateTime.parse(date);
          // Ensure the DateTime object only has the date part and is in UTC
          eventDate = DateTime(eventDate.year, eventDate.month, eventDate.day);
          if (data[date] != "") {
            _attendance[eventDate] = data[date];
          }
        }
      }

      notifyListeners();
    } catch (error) {
      // Handle any error that occurred during the API request
      print('Error fetching today\'s attendance: $error');
    }
  }

  void reset() {
    _attendance.clear();
    notifyListeners();
  }

  Map<String, dynamic>? getTodayAttendance() {
    print("getTodayAttendance");
    DateTime today = DateTime.now();
    // Ensure the DateTime object only has the date part and is in UTC
    DateTime currentDate = DateTime(today.year, today.month, today.day);
    return _attendance[currentDate];
  }

  Future<void> fetchAttendance(DateTime fromDate, DateTime toDate) async {
    try {
      final events =
          await AttendantService().getMyAttendanceByDate(fromDate, toDate);
      _attendance = events;
      print(_attendance);
      notifyListeners();
    } catch (error) {
      // Handle any error that occurred during the API request
      print('Error fetching attendance: $error');
    }
  }

  Map<String, int> countAttendanceStatusForCurrentMonth() {
    int onTimeCount = 0;
    int overtimeCount = 0;
    int absentCount = 0;

    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

    _attendance.forEach((date, details) {
      if (date.isAfter(firstDayOfMonth) &&
          (date.isAtSameMomentAs(lastDayOfMonth) ||
              date.isBefore(lastDayOfMonth))) {
        switch (details['status']) {
          case 'On Time':
            onTimeCount++;
            break;
          case 'Overtime':
            overtimeCount++;
            break;
          case 'Absent':
            absentCount++;
            break;
        }
      }
    });

    return {
      'onTimeCount': onTimeCount,
      'overtimeCount': overtimeCount,
      'absentCount': absentCount,
    };
  }

  String? getTodayInTime() {
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);
    String? inTime = "-";
    if (_attendance[todayKey] != null) {
      if (_attendance[todayKey]!['status'] == "Absent" ||
          _attendance[todayKey]!['status'] == "On Leave" ||
          _attendance[todayKey]!['status'] == "") {
        inTime = "-";
      } else if (_attendance[todayKey]!['in_time'] == "") {
        inTime = "-";
      } else {
        inTime = DateFormat('hh:mm a').format(
            DateFormat("HH:mm:ss").parse(_attendance[todayKey]!['in_time']));
      }
    }
    return inTime;
  }

  String? getTodayOutTime() {
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);
    String? outTime = "-";
    if (_attendance[todayKey] != null) {
      if (_attendance[todayKey]!['status'] == "Absent" ||
          _attendance[todayKey]!['status'] == "On Leave" ||
          _attendance[todayKey]!['status'] == "") {
        outTime = "-";
      } else if (_attendance[todayKey]!['out_time'] == "") {
        outTime = "-";
      } else {
        print(_attendance[todayKey]);
        outTime = DateFormat('hh:mm a').format(
            DateFormat("HH:mm:ss").parse(_attendance[todayKey]!['out_time']));
      }
    }

    return outTime;
  }
}
