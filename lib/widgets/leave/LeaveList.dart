import 'package:flutter/material.dart';
import 'package:hr_attendant/models/leave.dart';
import 'package:hr_attendant/screens/leave/LeaveDetailScreen.dart';
import 'package:intl/intl.dart';

class LeaveList extends StatelessWidget {
  final Function() onLeaveListSuccess;
  final List<Leave> leaves;

  const LeaveList(
      {super.key, required this.leaves, required this.onLeaveListSuccess});

  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: Container(
            color: Colors.white,
            child: ListView.builder(
              itemCount: leaves.length,
              itemBuilder: (ctx, index) {
                List<DateTime> dates = _getDaysInBetween(
                    leaves[index].fromDate, leaves[index].toDate);
                return InkWell(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => LeaveDetailsScreen(
                      leave: leaves[index],
                      onLeaveDetailsSuccess: onLeaveListSuccess,
                    ),
                  )),
                  child: Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _eventColor(leaves[index].statusDesc),
                        child: Text(
                          leaves[index].statusDesc[0],
                          style: TextStyle(
                            color: useWhiteForeground(
                                    _eventColor(leaves[index].statusDesc))
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ),
                      title: Text(leaves[index].leaveType.name),
                      subtitle: SizedBox(
                        height: 30,
                        child: ListView.builder(
                          shrinkWrap: true,
                          scrollDirection: Axis.horizontal,
                          itemCount: dates.length,
                          itemBuilder: (context, index) {
                            return Container(
                              width: 30,
                              margin: const EdgeInsets.symmetric(horizontal: 5),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "${dates[index].day}",
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    DateFormat.MMM().format(dates[index]),
                                    style: const TextStyle(
                                      fontSize: 8,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      /*subtitle: Text(
                          'From: ${DateFormat('yyyy-MM-dd').format(leaves[index].fromDate)} '
                          'To: ${DateFormat('yyyy-MM-dd').format(leaves[index].toDate)}'),*/
                      trailing: _buildStatusIndicator(leaves[index].statusDesc),
                    ),
                  ),
                );
              },
            )));
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

  bool useWhiteForeground(Color backgroundColor) =>
      1.05 / (backgroundColor.computeLuminance() + 0.05) > 4.5;

  Widget _buildStatusIndicator(String status) {
    Color color;
    color = _eventColor(status);

    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
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
}
