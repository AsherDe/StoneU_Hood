// lib/widgets/week_indicator.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/calendar_theme.dart';

class WeekIndicator extends StatelessWidget {
  final DateTime startOfWeek;
  final DateTime endOfWeek;
  final int weekNumber;
  final VoidCallback onTap;
  final bool isCurrentWeek;

  const WeekIndicator({
    Key? key,
    required this.startOfWeek,
    required this.endOfWeek,
    required this.weekNumber,
    required this.onTap,
    this.isCurrentWeek = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isCurrentWeek ? ThemeConstants.currentColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCurrentWeek ? ThemeConstants.currentColor : Colors.grey[300]!,
            width: isCurrentWeek ? 1 : 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '第${weekNumber}周',
              style: TextStyle(
                color: isCurrentWeek ? ThemeConstants.currentColor : ThemeConstants.upcomingColor,
                fontWeight: isCurrentWeek ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            SizedBox(width: 8),
            Text(
              '${DateFormat('MM/dd').format(startOfWeek)}-${DateFormat('MM/dd').format(endOfWeek)}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}