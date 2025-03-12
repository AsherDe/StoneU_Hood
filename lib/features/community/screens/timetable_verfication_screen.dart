// lib/screens/timetable_verification_screen.dart
import 'package:flutter/material.dart';
import '../../calendar/services/timetable_webview.dart';
import '../services/auth_service.dart';
import '../../../core/constants/app_theme.dart';

class TimetableVerificationScreen extends StatefulWidget {
  final Function? onVerificationComplete;
  
  const TimetableVerificationScreen({Key? key, this.onVerificationComplete}) : super(key: key);

  @override
  _TimetableVerificationScreenState createState() => _TimetableVerificationScreenState();
}

class _TimetableVerificationScreenState extends State<TimetableVerificationScreen> {
  bool _isLoading = false;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('身份验证'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '为什么需要验证？',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '为了确保您是本校学生，我们需要您通过导入教务系统课表来验证身份。这样可以防止校外人员使用平台，保障校园社区的安全。',
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 16),
                Text(
                  '验证步骤：',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text('1. 在下方页面中登录教务系统'),
                Text('2. 进入"个人课表"或"学期理论课表"页面'),
                Text('3. 点击右上角下载图标解析课表'),
                Text('4. 验证成功后即可返回注册/登录'),
              ],
            ),
          ),
          Expanded(
            child: _isLoading 
              ? Center(child: CircularProgressIndicator())
              : TimetableWebView(
                  onEventsImported: (events) async {
                    if (events.isNotEmpty) {
                      setState(() {
                        _isLoading = true;
                      });
                      
                      // 检查验证状态
                      final authService = AuthService();
                      final isVerified = await authService.isTimetableVerified();
                      
                      setState(() {
                        _isLoading = false;
                      });
                      
                      if (isVerified) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('验证成功！现在您可以注册/登录了'))
                        );
                        
                        // 延迟一下再返回，让用户看到成功消息
                        Future.delayed(Duration(seconds: 2), () {
                          Navigator.of(context).pop(true);
                          // 如果有回调，执行回调
                          if (widget.onVerificationComplete != null) {
                            widget.onVerificationComplete!(true);
                          }
                        });
                      }
                    }
                  },
                  isVerification: true,
                ),
          ),
        ],
      ),
    );
  }
}