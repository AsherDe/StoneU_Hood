// lib/constants/theme_constants.dart
import 'package:flutter/material.dart';

class ThemeConstants {
  static const Color pastColor = Color(0xFFAAAAAA);
  static const Color currentColor = Color(0xFF000000);
  static const Color upcomingColor = Color(0xFF333333);
  static const Color gridLineColor = Color(0xFFE0E0E0);
  
  static const double eventDotSize = 6.0;
  static const double gridLineWidth = 1.0;
  static const double timeIndicatorHeight = 2.0;
  
  static TextStyle getPastTextStyle() {
    return TextStyle(
      color: pastColor,
      fontSize: 14,
      fontFamily: 'Arial',
    );
  }
  
  static TextStyle getCurrentTextStyle() {
    return TextStyle(
      color: currentColor,
      fontSize: 14,
      fontWeight: FontWeight.bold,
      fontFamily: 'Arial',
    );
  }
  
  static TextStyle getUpcomingTextStyle() {
    return TextStyle(
      color: upcomingColor,
      fontSize: 14,
      fontFamily: 'Arial',
    );
  }
}