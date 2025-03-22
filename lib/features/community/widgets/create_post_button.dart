// lib/widgets/create_post_button.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_theme.dart';

class CreatePostButton extends StatelessWidget {
  final VoidCallback onPressed;
  
  const CreatePostButton({super.key, required this.onPressed});
  
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
        elevation: 0,
        highlightElevation: 0,
        child: Icon(
          Icons.add,
          size: 30,
          color: Colors.white,
        ),
      ),
    );
  }
}