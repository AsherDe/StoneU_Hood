// lib/screens/donation_page.dart
import 'package:flutter/material.dart';
import '../../../core/constants/theme_constants.dart';

class DonationPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('请作者喝杯奶茶', style: TextStyle(color: ThemeConstants.currentColor)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: ThemeConstants.currentColor),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20),
              Icon(
                Icons.volunteer_activism,
                size: 80,
                color: ThemeConstants.currentColor,
              ),
              SizedBox(height: 24),
              Text(
                '感谢您的支持！',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: ThemeConstants.currentColor,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                '石大日历是一个免费的日程管理应用，为石河子大学的学生们提供便利。'
                '如果您觉得这个应用对您有帮助，可以考虑请作者喝一杯奶茶，这将是对我工作的莫大鼓励！',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40),
              // 支付宝二维码
              Column(
                children: [
                  Text(
                    '支付宝',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  // 这里使用占位图 - 实际使用时需替换成真实的二维码图片
                  Image.asset(
                    'images/alipay_receive.png',
                    width: 200,
                    height: 200,
                  )
                ]
              ),
              SizedBox(height: 40),
              Text(
                '您的每一份支持都将帮助我们做得更好！',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                  color: ThemeConstants.currentColor,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                '有任何问题或建议，请联系: asher.ji@icloud.com',
                style: TextStyle(
                  fontSize: 14, 
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}