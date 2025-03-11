// lib/constants/theme_constants.dart
import 'package:flutter/material.dart';
import 'app_theme.dart';

class ThemeConstants {
  static const Color pastColor = Color(0xFFAAAAAA);
  static const Color currentColor = AppTheme.primaryColor;
  static const Color upcomingColor = Color(0xFF333333);
  static const Color gridLineColor = Color(0xFFE0E0E0);
  
  static const double eventDotSize = 6.0;
  static const double gridLineWidth = 1.0;
  static const double timeIndicatorHeight = 2.0;
  
  static TextStyle getPastTextStyle() {
    return TextStyle(
      color: pastColor,
      fontSize: 14,
      fontFamily: 'NotoSansSC',
    );
  }
  
  static TextStyle getCurrentTextStyle() {
    return TextStyle(
      color: currentColor,
      fontSize: 16,
      fontWeight: FontWeight.bold,
      fontFamily: 'NotoSansSC',
    );
  }
  
  static TextStyle getUpcomingTextStyle() {
    return TextStyle(
      color: upcomingColor,
      fontSize: 14,
      fontFamily: 'NotoSansSC',
    );
  }
}