// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../core/constants/app_theme.dart';
import './home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  bool _otpSent = false;
  bool _isLoading = false;

  final sceneId = "SMS_480220263";

  @override
  void initState() {
    super.initState();
  }

  void _sendOtp() async {
    if (_phoneController.text.trim().length != 11) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('请输入正确的手机号码')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.sendOtp(_phoneController.text.trim(), sceneId);

      setState(() {
        _otpSent = true;
        _isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('验证码已发送到您的手机，请注意查收')));
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      String errorMessage = '发送验证码失败';
      if (e is Exception) {
        errorMessage += ': ${e.toString().replaceAll('Exception: ', '')}';
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }

  void _verifyOtp() async {
    if (_otpController.text.trim().length != 4) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('请输入4位验证码')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await Provider.of<AuthProvider>(
        context,
        listen: false,
      ).verifyOtp(_phoneController.text.trim(), _otpController.text.trim());

      if (success) {
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => HomeScreen()));
      } else {
        throw Exception('验证失败');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      String errorMessage = '验证码错误';
      if (e is Exception) {
        errorMessage += ': ${e.toString().replaceAll('Exception: ', '')}';
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('欢迎使用匿名校园互助平台'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Icon(Icons.school, size: 80, color: AppTheme.primaryColor),
                    SizedBox(height: 20),
                    Text(
                      '手机号登录/注册',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
<<<<<<< HEAD
                    SizedBox(height: 10),
                    // 课表验证状态指示器
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      decoration: BoxDecoration(
                        color: _timetableVerified 
                            ? Colors.green.withOpacity(0.1) 
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _timetableVerified 
                                ? Icons.check_circle 
                                : Icons.error_outline,
                            color: _timetableVerified ? Colors.green : Colors.red,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            _timetableVerified 
                                ? '身份已验证' 
                                : '需要验证身份',
                            style: TextStyle(
                              color: _timetableVerified ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!_timetableVerified)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: TextButton(
                          onPressed: _navigateToTimetableVerification,
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primaryColor,
                          ),
                          child: Text('点击验证身份'),
                        ),
                      ),
=======

>>>>>>> gitee/auto-15499326-main-fd46b1ad-1
                    SizedBox(height: 20),
                    TextField(
                      controller: _phoneController,
                      enabled: (!_otpSent || !_isLoading),
                      decoration: InputDecoration(
                        labelText: '手机号码',
                        hintText: '请输入11位手机号码',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),

                    SizedBox(height: 15),
                    if (_otpSent)
                      TextField(
                        controller: _otpController,
                        decoration: InputDecoration(
                          labelText: '验证码',
                          hintText: '请输入4位验证码',
                          prefixIcon: Icon(Icons.lock_outline),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 4, // 限制验证码长度为4
                      ),

                    SizedBox(height: 25),
                    _isLoading
                        ? CircularProgressIndicator()
                        : ElevatedButton(
                          onPressed: _otpSent ? _verifyOtp : _sendOtp,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 15),
                            backgroundColor: AppTheme.primaryColor,
                          ),
                          child: Text('获取验证码', style: TextStyle(fontSize: 16)),
                        ),

                    if (_otpSent)
                      TextButton(
                        onPressed: _isLoading ? null : _sendOtp,
                        child: Text('重新发送验证码'),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
