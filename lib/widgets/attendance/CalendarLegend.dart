import 'package:flutter/material.dart';

class CalendarLegend extends StatelessWidget {
  const CalendarLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _calendarLegendItem(Colors.green, 'On Time'),
          const SizedBox(width: 16),
          /*_calendarLegendItem(Colors.blue, 'OT'),
          const SizedBox(width: 16),*/
          _calendarLegendItem(Colors.pink, 'UT'),
          const SizedBox(width: 16),
          _calendarLegendItem(Colors.red, 'Absent'),
          const SizedBox(width: 16),
          _calendarLegendItem(Colors.orange, 'On Leave'),
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
