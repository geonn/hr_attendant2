import 'package:flutter/material.dart';

class LeaveCalendarLegend extends StatelessWidget {
  const LeaveCalendarLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _calendarLegendItem(Colors.green, 'Approved'),
          const SizedBox(width: 16),
          _calendarLegendItem(Colors.orange, 'Pending'),
          const SizedBox(width: 16),
          _calendarLegendItem(Colors.red, 'Rejected'),
          // Add more items as needed
        ],
      ),
    );
  }

  Widget _calendarLegendItem(Color color, String label) {
    return Row(
      children: [
        Icon(Icons.circle, color: color, size: 16),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }
}
