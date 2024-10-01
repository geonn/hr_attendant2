import 'package:flutter/material.dart';

class AttendanceOverviewBox extends StatelessWidget {
  final int onTimeCount;
  final int absentCount;
  final int overtimeCount;

  const AttendanceOverviewBox({
    super.key,
    required this.onTimeCount,
    required this.absentCount,
    required this.overtimeCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Attendance',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _AttendanceCountItem(
                title: 'On Time',
                count: onTimeCount,
                icon: Icons.timer_sharp,
              ),
              const SizedBox(height: 16.0),
              _AttendanceCountItem(
                title: 'Absent',
                count: absentCount,
                icon: Icons.timer_off,
              ),
              /*const SizedBox(height: 16.0),
              _AttendanceCountItem(
                title: 'Over Time',
                count: overtimeCount,
                icon: Icons.timer_rounded,
              ),*/
            ],
          ),
        ],
      ),
    );
  }
}

class _AttendanceCountItem extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;

  const _AttendanceCountItem({
    required this.title,
    required this.count,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 24,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(width: 8),
        Text(
          "$title: ",
          style: const TextStyle(
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
