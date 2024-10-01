import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hr_attendant/provider/attendance_provider.dart';
import 'package:hr_attendant/screens/%20attendance/ClockTimePage.dart';
import 'package:hr_attendant/services/attendant_service.dart';
import 'package:hr_attendant/widgets/attendance/CalendarLegend.dart';
import 'package:hr_attendant/widgets/attendance/TransactionList.dart';
import 'package:hr_attendant/widgets/home/buildCircleButton.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:image/image.dart' as img;

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  _AttendancePageState createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  bool isLoading = false;
  final ImagePicker _picker = ImagePicker();
  CalendarFormat _calendarFormat = CalendarFormat.twoWeeks;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDate = DateTime.now();
  //Map<DateTime, Map<String, dynamic>> _events = {};
  final Map<DateTime, List<String>> _events_arr = {};
  DateTime now = DateTime.now();
  Logger log = Logger();
  File? _selfieImage;
  List<Map<String, dynamic>> transactions = [
    // Add more sample data if needed
  ];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    refreshAttendanceData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            isLoading
                ? const LinearProgressIndicator()
                : const SizedBox.shrink(),
            Container(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(
                      height: 20,
                    ),
                    CircleButton(
                      text: 'Clock Time',
                      buttonSize: ButtonSize.small,
                      onPressed: _navigateToClockTimePage,
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16.0),
                            topRight: Radius.circular(16.0),
                          ),
                        ),
                        child: TableCalendar(
                          onFormatChanged: (format) {
                            // Handle format changes here if necessary
                            setState(() {
                              _calendarFormat = format;
                            });
                          },
                          firstDay: DateTime.utc(2010, 10, 16),
                          lastDay: DateTime.utc(2030, 3, 14),
                          focusedDay: _focusedDay,
                          calendarFormat: _calendarFormat,
                          selectedDayPredicate: (day) {
                            return isSameDay(_selectedDate, day);
                          },
                          onDaySelected: (selectedDay, focusedDay) {
                            bool isNotToday =
                                !isSameDay(selectedDay, DateTime.now());
                            setState(() {
                              print('official selectedDate');
                              print(selectedDay);
                              _selectedDate = selectedDay;
                              _focusedDay =
                                  focusedDay; // update `_focusedDay` here as well
                              // Fetch the clocked-in/out transactions for the selected day
                              // You can replace this with a function that fetches the data from the server or database
                              _fetchTransactionsForSelectedDay();
                              print(isNotToday);
                              if (isNotToday &&
                                  ((transactions[0].isNotEmpty &&
                                          transactions[0]['out_time'] == "") ||
                                      transactions[0]['status'] == "Absent")) {
                                print(transactions[0]);
                                print('not in??');
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return _InOutTimeFormDialog(
                                        status: transactions[0]['status'],
                                        outTime:
                                            transactions[0]['out_time'] ?? "",
                                        date: DateFormat('yyyy-MM-dd')
                                            .format(selectedDay),
                                        onFormSubmit: (inTime, outTime) {
                                          // Update the attendance data with the input from the user
                                          // You might also want to update this data on the server
                                          setState(() {
                                            refreshAttendanceData();
                                            print(inTime);
                                            print(outTime);
                                          });
                                        });
                                  },
                                );
                              }
                            });
                          },
                          onPageChanged: (focusedDay) {
                            _focusedDay = focusedDay;
                            refreshAttendanceData();
                          },
                          calendarBuilders: CalendarBuilders(
                            markerBuilder: (context, date, events) {
                              if (events.isNotEmpty) {
                                return Positioned(
                                  bottom: 1,
                                  child: _buildEventsMarker(date, events),
                                );
                              }
                              return Container();
                            },
                          ),
                          eventLoader: (day) {
                            DateTime eventDay =
                                DateTime(day.year, day.month, day.day);

                            Map<DateTime, Map<String, dynamic>> events =
                                Provider.of<AttendanceProvider>(context,
                                        listen: false)
                                    .attendance;
                            if (events.containsKey(eventDay)) {
                              if (events[eventDay]!['status'] != null &&
                                  events[eventDay]!['status'].isNotEmpty) {
                                return [events[eventDay]!['status']];
                              } else {
                                return [];
                              }
                            } else {
                              return [];
                            }
                            //return _events_arr[eventDay] ?? [];
                          },
                        )),
                    // Rest of your page
                    const CalendarLegend(),
                    TransactionList(transactions: transactions),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void refreshAttendanceData() {
    print('refreshAttendanceData');
    final attendanceProvider =
        Provider.of<AttendanceProvider>(context, listen: false);
    attendanceProvider.fetchTodayAttendance();
    print(_calendarFormat);
    var visibleRange = _getVisibleRange(_calendarFormat, _focusedDay);

    DateTime startOfMonth =
        visibleRange.start; //DateTime(_focusedDay.year, _focusedDay.month, 1);
    DateTime endOfMonth = visibleRange
        .end; //DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    Provider.of<AttendanceProvider>(context, listen: false)
        .fetchAttendance(startOfMonth, endOfMonth)
        .then((value) => _fetchTransactionsForSelectedDay());
    /*AttendantService()
        .getMyAttendanceByDate(startOfMonth, endOfMonth)
        .then((events) {
      setState(() {
        _events = events;
        for (DateTime eventDate in _events.keys) {
          // Ensure the DateTime object only has the date part and is in UTC
          eventDate = DateTime(eventDate.year, eventDate.month, eventDate.day);
          if (_events[eventDate] != "") {
            _events_arr[eventDate] = [_events[eventDate]!['status']];
          }
        }
        ;
      });
      _fetchTransactionsForSelectedDay();
    });*/
  }

  void _fetchTransactionsForSelectedDay() {
    // Replace this with the actual function to fetch the data for the selected date
    print('_fetchTransactionsForSelectedDay');
    print(_selectedDate);
    Map<DateTime, Map<String, dynamic>> events =
        Provider.of<AttendanceProvider>(context, listen: false).attendance;

    DateTime eventDay =
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);

    if (events[eventDay] != null) {
      events[eventDay] = {
        ...events[eventDay]!,
        'date': eventDay,
      };
    }
    setState(() {
      transactions = [events[eventDay] ?? {}];
    });
  }

  Widget _buildEventsMarker(DateTime date, List<dynamic> events) {
    return Row(
      children: events.map((event) => _singleMarker(event)).toList(),
    );
  }

  Widget _singleMarker(dynamic event) {
    return Container(
        width: 8,
        height: 8,
        margin: const EdgeInsets.symmetric(horizontal: 1.0),
        decoration:
            BoxDecoration(shape: BoxShape.circle, color: _eventColor(event)));
  }

  Color _eventColor(String eventType) {
    switch (eventType) {
      case 'On Time':
        return Colors.green;
      case 'Absent':
        return Colors.red;
      /*case 'OT':
        return Colors.blue;*/

      case 'UT':
        return Colors.pink;
      case 'On Leave':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  Future<File> resizeImage(File imageFile, {int targetWidth = 640}) async {
    // Read the image from the file
    img.Image? image = img.decodeImage(await imageFile.readAsBytes());

    if (image == null) {
      throw Exception('Failed to decode image.');
    }

    // Calculate the new height to maintain the aspect ratio
    final int targetHeight = (image.height * targetWidth / image.width).round();

    // Resize the image
    img.Image resizedImage =
        img.copyResize(image, width: targetWidth, height: targetHeight);

    // Generate a new file path with '-resized' appended to the file name
    final filePath = imageFile.absolute.path;
    final lastIndex = filePath.lastIndexOf('.');
    final newPath =
        '${filePath.substring(0, lastIndex)}-resized${filePath.substring(lastIndex)}';

    // Save the resized image to the new file
    final resizedFile = File(newPath);
    await resizedFile.writeAsBytes(img.encodeJpg(resizedImage));

    return resizedFile;
  }

  Future<File?> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxHeight: 600,
        maxWidth: 600,
        imageQuality:
            40, // Optionally reduce the image quality when capturing the image
      );

      if (pickedFile != null) {
        final resizedImage = await resizeImage(File(pickedFile.path));
        return resizedImage;
      } else {
        print('No image selected.');
      }
    } catch (error) {
      log.d("error: $error");
    }
    return null;
  }

  Future<void> _navigateToClockTimePage() async {
    /*setState(() {
      isLoading = true; // Start loading
    });
    File? selfie = await _pickImage();
    setState(() {
      isLoading = false; // Stop loading
    });
    if (selfie != null) {*/
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClockTimePage(
          onClockTimeSuccess: refreshAttendanceData,
        ), // Pass your callback function here
        //selfie: selfie),
      ),
    );
    //}
  }

  DateTimeRange _getVisibleRange(CalendarFormat format, DateTime focusedDay) {
    switch (format) {
      case CalendarFormat.month:
        return _daysInMonth(focusedDay);
      case CalendarFormat.twoWeeks:
        return _daysInTwoWeeks(focusedDay);
      case CalendarFormat.week:
        return _daysInWeek(focusedDay);
      default:
        return _daysInMonth(focusedDay);
    }
  }

  DateTimeRange _daysInMonth(DateTime day) {
    final startDate = DateTime(day.year, day.month);
    final endDate =
        DateTime(day.year, day.month + 1).subtract(const Duration(days: 1));
    return DateTimeRange(start: startDate, end: endDate);
  }

  DateTimeRange _daysInTwoWeeks(DateTime day) {
    // Subtract 14 days from the current day to get the start date
    final startDate = day.subtract(const Duration(days: 14));
    // Add 14 days to the current day to get the end date
    final endDate = day.add(const Duration(days: 14));
    return DateTimeRange(start: startDate, end: endDate);
  }

  DateTimeRange _daysInWeek(DateTime day) {
    final startDate = day.subtract(Duration(days: day.weekday - 1));
    final endDate = startDate.add(const Duration(days: 6));
    return DateTimeRange(start: startDate, end: endDate);
  }
}

class _InOutTimeFormDialog extends StatefulWidget {
  final String status;
  final String outTime;
  final String date;
  final Function(String?, String?) onFormSubmit;

  const _InOutTimeFormDialog({
    required this.status,
    required this.outTime,
    required this.date,
    required this.onFormSubmit,
  });

  @override
  _InOutTimeFormDialogState createState() => _InOutTimeFormDialogState();
}

class _InOutTimeFormDialogState extends State<_InOutTimeFormDialog> {
  TimeOfDay? _inTime;
  TimeOfDay? _outTime;
  String _reason = "";
  final AttendantService _attendantService = AttendantService();

  @override
  void initState() {
    super.initState();
  }

  Future<void> _selectTime(BuildContext context, bool isForInTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        if (isForInTime) {
          _inTime = picked;
        } else {
          _outTime = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String title = '';
    String explanatoryText = '';
    if (widget.status == 'Absent') {
      title = 'Update Absent Status';
      explanatoryText =
          'This day is marked as absent. Do you want to resubmit the time?';
    } else if (widget.outTime.isEmpty) {
      title = 'Update OUT Time';
      explanatoryText =
          'The OUT time is empty. Do you want to resubmit the OUT time?';
    }

    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(explanatoryText),
          const SizedBox(height: 10),
          if (widget.status == 'Absent')
            ListTile(
              title: Text(_inTime == null
                  ? 'Select IN Time'
                  : 'IN Time: ${_inTime!.format(context)}'),
              trailing: const Icon(Icons.access_time),
              onTap: () => _selectTime(context, true),
            ),
          if (widget.outTime.isEmpty)
            ListTile(
              title: Text(_outTime == null
                  ? 'Select OUT Time'
                  : 'OUT Time: ${_outTime!.format(context)}'),
              trailing: const Icon(Icons.access_time),
              onTap: () => _selectTime(context, false),
            ),
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Reason',
              enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(
                      color: Color.fromARGB(74, 32, 31, 31), width: 1),
                  borderRadius: BorderRadius.all(Radius.circular(15))),
              focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: Theme.of(context).primaryColor, width: 2),
                  borderRadius: const BorderRadius.all(Radius.circular(15))),
            ),
            onChanged: (value) => _reason = value,
            onSaved: (value) {
              _reason = value!;
            },
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('No'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_inTime != null) {
              await _attendantService.doPatchClockInOut(
                widget.date,
                '${_inTime!.hour.toString().padLeft(2, '0')}:${_inTime!.minute.toString().padLeft(2, '0')}:00',
                _reason,
                'in',
              );
            }

            if (_outTime != null) {
              await _attendantService.doPatchClockInOut(
                widget.date,
                '${_outTime!.hour.toString().padLeft(2, '0')}:${_outTime!.minute.toString().padLeft(2, '0')}:00',
                _reason,
                'out',
              );
            }

            widget.onFormSubmit(_inTime.toString(), _outTime.toString());
            Navigator.of(context).pop();
          },
          child: const Text('Submit'),
        ),
      ],
    );
  }
}
