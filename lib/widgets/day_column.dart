// lib/widgets/day_column.dart
import 'package:flutter/material.dart';
import '../models/event.dart';
import 'event_item.dart'; // Add this line to import EventItem

class DayColumn extends StatelessWidget {
  final DateTime date;
  final List<CalendarEvent> events;

  DayColumn({
    required this.date,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
      ),
      child: ListView.builder(
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return EventItem(event: event);
        },
      ),
    );
  }
}
