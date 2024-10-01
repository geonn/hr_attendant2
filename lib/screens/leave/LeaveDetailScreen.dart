import 'package:flutter/material.dart';
import 'package:hr_attendant/models/leave.dart';
import 'package:hr_attendant/services/leave_service.dart';
import 'package:hr_attendant/widgets/leave/ChatMessage.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';

class LeaveDetailsScreen extends StatefulWidget {
  final Function() onLeaveDetailsSuccess;
  final Leave leave;

  const LeaveDetailsScreen(
      {super.key, required this.onLeaveDetailsSuccess, required this.leave});

  @override
  State<LeaveDetailsScreen> createState() => _LeaveDetailsScreenState();
}

class _LeaveDetailsScreenState extends State<LeaveDetailsScreen> {
  final LeaveService _leaveService = LeaveService();

  @override
  Widget build(BuildContext context) {
    List<DateTime> dates =
        _getDaysInBetween(widget.leave.fromDate, widget.leave.toDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Details'),
      ),
      body: SingleChildScrollView(
        child: CupertinoListSection(
          footer: (widget.leave.leaveType.name == 'Medical' &&
                  widget.leave.imgPath != null)
              ? ListTile(
                  subtitle: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.white,
                            width: 5.0, // You can set the width to your liking
                          ),
                          borderRadius: BorderRadius.circular(
                              5), // You can set the radius to your liking
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: Image.network('${widget.leave.imgPath}'),
                        ),
                      ),
                      Positioned(
                        top: 20,
                        child: Container(
                          color: Colors.white,
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Text("Attachment"),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Container(),
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: SizedBox(
                height: 60,
                child: ListView.builder(
                  shrinkWrap: true,
                  scrollDirection: Axis.horizontal,
                  itemCount: dates.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 60,
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "${dates[index].day}",
                            style: const TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            DateFormat.MMM().format(dates[index]),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            CupertinoListTile(
              title: const Text('Leave Type'),
              additionalInfo: Text(widget.leave.leaveType.name),
            ),
            CupertinoListTile(
              title: const Text('From Date'),
              additionalInfo:
                  Text(DateFormat('yyyy-MM-dd').format(widget.leave.fromDate)),
            ),
            CupertinoListTile(
              title: const Text('To Date'),
              additionalInfo:
                  Text(DateFormat('yyyy-MM-dd').format(widget.leave.toDate)),
            ),
            CupertinoListTile(
              title: const Text('Status'),
              additionalInfo: Text(widget.leave.statusDesc),
            ),
            Column(
              children: [
                ChatMessage(
                  title: 'User',
                  message: '${widget.leave.reason}',
                  isUser: true,
                ),
                if (widget.leave.remark != "")
                  ChatMessage(
                    title: 'HR / Supervisor',
                    message: '${widget.leave.remark}',
                  ),
              ],
            ),
            if (widget.leave.statusDesc == 'Pending')
              ListTile(
                title: ElevatedButton(
                  child: const Text('Remove Leave'),
                  onPressed: () => _confirmRemoveLeave(context),
                ),
              ),
            // Show the attachment if the leave type is 'Medical'
          ],
        ),
      ),
    );
  }

  Future<void> _confirmRemoveLeave(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button to close dialog!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm'),
          content: const SingleChildScrollView(
            child: Text('Are you sure you want to remove this leave?'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
              },
            ),
            TextButton(
              child: const Text('Remove'),
              onPressed: () async {
                Navigator.of(context).pop(); // Dismiss the dialog
                await _removeLeave(); // Call the function to remove the leave
              },
            ),
          ],
        );
      },
    );
  }

  List<DateTime> _getDaysInBetween(DateTime startDate, DateTime endDate) {
    List<DateTime> days = [];
    for (var day = startDate;
        day.isBefore(endDate.add(const Duration(days: 1)));
        day = day.add(const Duration(days: 1))) {
      days.add(day);
    }
    return days;
  }

  _removeLeave() async {
    Map<String, dynamic>? respond = await _leaveService.removeMyLeave(widget
        .leave
        .id); // make sure you replace LeaveService() with actual service instance

    if (respond != null) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(respond['status']),
          content: Text(respond['data']),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                // Close the dialog
                if (respond['status'] == "success") {
                  widget.onLeaveDetailsSuccess();
                  Navigator.pop(context);
                }
                // Close the current page
                Navigator.pop(context);
              },
            ),
          ],
        ),
      );
    } else {
      Navigator.of(context).pop();
    }
  }
}
