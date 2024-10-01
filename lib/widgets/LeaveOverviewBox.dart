import 'package:flutter/material.dart';

class LeaveOverviewBox extends StatelessWidget {
  final double totalLeave;
  final double leaveBalance;
  final double leaveApplied;
  final double leaveApproved;

  const LeaveOverviewBox({
    super.key,
    required this.totalLeave,
    required this.leaveBalance,
    required this.leaveApplied,
    required this.leaveApproved,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
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
            'Leave',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text('Total Leave: $totalLeave'),
          const SizedBox(height: 10),
          Text('Leave Balance: $leaveBalance'),
          const SizedBox(height: 10),
          Text('Total Leave Applied: $leaveApplied'),
          const SizedBox(height: 10),
          Text('Approved Leave: $leaveApproved'),
        ],
      ),
    );
  }
}
