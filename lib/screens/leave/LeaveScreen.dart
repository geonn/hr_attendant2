import 'package:flutter/material.dart';
import 'package:hr_attendant/models/leave.dart';
import 'package:hr_attendant/provider/LeaveProvider.dart';
import 'package:hr_attendant/screens/leave/RequestLeaveScreen.dart';
import 'package:hr_attendant/widgets/leave/LeaveCalendarLegend.dart';
import 'package:hr_attendant/widgets/leave/LeaveList.dart';
import 'package:hr_attendant/widgets/home/buildCircleButton.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

class LeavePage extends StatefulWidget {
  const LeavePage({super.key});

  @override
  _LeavePageState createState() => _LeavePageState();
}

class _LeavePageState extends State<LeavePage> {
  CalendarFormat _calendarFormat = CalendarFormat.twoWeeks;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDate = DateTime.now();
  List<Leave> selectedLeaves = [];
  //final LeaveService _leaveService = LeaveService();

  List<Map<String, dynamic>> leaves = [
    // Add more sample data if needed
  ];
  List<Leave> leaveObjects = [];

  @override
  void initState() {
    leaveObjects = leaves.map((leaveMap) => Leave.fromJson(leaveMap)).toList();
    // TODO: implement initState
    super.initState();
    _selectedDate = DateTime.now(); // set to current day
    _focusedDay = DateTime.now(); // set to current day
    /*Provider.of<LeaveProvider>(context, listen: false)
        .fetchLeaves()
        .then((value) => _fetchLeavesForSelectedDay);*/
    fetchLeaves();
  }

  @override
  Widget build(BuildContext context) {
    leaveObjects = Provider.of<LeaveProvider>(context).leaves;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave'),
      ),
      floatingActionButton: CircleButton(
        text: 'Request Leave',
        buttonSize: ButtonSize.medium,
        onPressed: _navigateToRequestLeavePage,
      ),
      body: Column(
        children: [
          const SizedBox(
            height: 5,
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.0),
                topRight: Radius.circular(16.0),
              ),
            ),
            child: TableCalendar(
                onFormatChanged: (format) {
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
                  setState(() {
                    _selectedDate = selectedDay;
                    _focusedDay = focusedDay;
                    _fetchLeavesForSelectedDay();
                  });
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
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
                  return leaveObjects
                      .where((leave) =>
                          getDaysInBetween(leave.fromDate, leave.toDate)
                              .any((date) => isSameDay(date, day)))
                      .map((leave) => leave.statusDesc)
                      .toList();
                }),
          ),
          const LeaveCalendarLegend(),
          LeaveList(
            leaves: selectedLeaves,
            onLeaveListSuccess: fetchLeaves,
          ),
        ],
      ),
    );
  }

  List<DateTime> getDaysInBetween(DateTime startDate, DateTime endDate) {
    List<DateTime> days = [];
    for (var day = startDate;
        day.isBefore(endDate.add(const Duration(days: 1)));
        day = day.add(const Duration(days: 1))) {
      days.add(day);
    }
    return days;
  }

  void _fetchLeavesForSelectedDay() {
    // Filter the leaves for the selected day
    print(_fetchLeavesForSelectedDay);
    print(leaveObjects);
    setState(() {
      selectedLeaves = leaveObjects
          .where((leave) => getDaysInBetween(leave.fromDate, leave.toDate)
              .any((date) => isSameDay(date, _selectedDate)))
          .toList();
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
      case 'Approved':
        return Colors.green;
      case 'Pending':
        return Colors.orange;
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  void _navigateToRequestLeavePage() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => RequestLeavePage(
                onLeaveRequestSuccess: fetchLeaves,
              )),
    );
  }

  Future<void> fetchLeaves() async {
    Provider.of<LeaveProvider>(context, listen: false)
        .fetchLeaves()
        .then((value) => _fetchLeavesForSelectedDay());
    /*try {
      List<Leave> fetchedLeaves = await _leaveService.getLeaveList();
      setState(() {
        leaveObjects = fetchedLeaves;
      });
    } catch (e) {
      // Handle any errors here, for example by showing a message to the user
      print('Failed to fetch leaves: $e');
    }*/
    //_fetchLeavesForSelectedDay();
  }
}
