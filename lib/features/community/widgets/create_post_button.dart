// lib/widgets/create_post_button.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_theme.dart';

class CreatePostButton extends StatelessWidget {
  final VoidCallback onPressed;
  
  CreatePostButton({required this.onPressed});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: AppTheme.primaryColor,
        child: Icon(
          Icons.add,
          size: 30,
          color: Colors.white,
        ),
        elevation: 0,
        highlightElevation: 0,
      ),
    );
  }
}