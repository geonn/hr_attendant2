// attendant_service.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hr_attendant/services/api_service.dart';
import 'package:logger/logger.dart';
import 'package:intl/intl.dart';

class AttendantService {
  var log = Logger();
  final ApiService _apiService;

  AttendantService() : _apiService = ApiService();

  Future<Map<String, dynamic>?> doClockInOut(
      String date,
      String time,
      String location,
      double long,
      double lat,
      File selfieImage,
      String action) async {
    Map<String, String> params = {
      'user': 'hrapp',
      'key': '66505234721014515949f7875c8959403',
      'date': date,
      'time': time,
      'location': location,
      'long': long.toString(),
      'lat': lat.toString(),
      'category': action
    };
    Map<String, dynamic>? response = await _apiService.postWithFile(
        '/api/doClockInOut', params, selfieImage);
    print('api/doClockInOut');
    log.d(response);
    if (response != null && response['status'] == 'success') {
      return response;
    } else {
      return null;
    }
  }

  Future<Map<String, dynamic>?> doPatchClockInOut(
      String date, String time, String reason, String patchType) async {
    Map<String, String> params = {
      'user': 'hrapp',
      'key': '66505234721014515949f7875c8959403',
      'date': date,
      'time': time,
      'reason': reason,
      'patch_type': patchType,
    };
    print(params);
    Map<String, dynamic>? response = await _apiService.post(
      '/api/doPatchClockInOut',
      params,
    );
    print('api/doPatchClockInOut');
    log.d(response);
    if (response != null && response['status'] == 'success') {
      return response;
    } else {
      return null;
    }
  }

  Future<Map<DateTime, Map<String, dynamic>>> getMyAttendanceByDate(
      DateTime fromDate, DateTime toDate) async {
    Map<DateTime, Map<String, dynamic>> events = {};
    String fromDateString = DateFormat('yyyy-MM-dd').format(fromDate);
    String toDateString = DateFormat('yyyy-MM-dd').format(toDate);
    try {
      var response = await _apiService.post('/api/getMyAttendanceByDate', {
        'fromDate': fromDateString,
        'toDate': toDateString,
      });
      print({
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
            events[eventDate] = data[date];
          }
        }
      }
    } catch (e) {
      print('Failed to get attendance by date: $e');
      rethrow;
    }

    return events;
  }

  Future<Map<String, dynamic>?> doClockInOutOT(DateTime otInDateTime,
      DateTime otOutDateTime, bool isNightShift, bool isStandby) async {
    // Format DateTime objects to strings suitable for your API
    String otInDatetimeStr = otInDateTime.toString();
    String otOutDatetimeStr = otOutDateTime.toString();

    Map<String, String> body = {
      'ot_in_datetime': otInDatetimeStr,
      'ot_out_datetime': otOutDatetimeStr,
      'night_shift': isNightShift ? '1' : '0',
      'standby': isStandby ? "1" : "0",
    };

    try {
      // Assuming '/api/doClockInOutOT' is the correct endpoint for your API
      var response = await _apiService.post('/api/doClockInOutOT', body);
      // Handle response, parse JSON, etc.
      log.d(response);
      if (response != null && response['status'] == 'success') {
        return response;
      } else {
        return null;
      }
    } catch (e) {
      print('Failed to apply for OT: $e');
      rethrow; // You might want to handle this differently
    }
  }

  Future<void> submitData({
    required BuildContext context,
    required TimeOfDay clockTime,
    required DateTime currentDate,
    required File selfieImage,
  }) async {
    // Your API call or any other logic for submitting data

    // For example, you can print the data for now:
    print('Clock Time: ${clockTime.format(context)}');
    print('Date: $currentDate');
    print('Selfie Image: $selfieImage');
  }
}
