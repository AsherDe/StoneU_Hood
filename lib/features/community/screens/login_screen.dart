// screens/login_screen.dart - 登录界面
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../widgets/custom_text_field.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 60),
                  // 应用图标和名称
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.school,
                          size: 80,
                          color: Theme.of(context).primaryColor,
                        ),
                        SizedBox(height: 16),
                        Text(
                          '校园社区',
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '连接校园生活的每一刻',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 60),
                  
                  // 手机号输入
                  CustomTextField(
                    controller: _phoneController,
                    labelText: '手机号',
                    hintText: '请输入手机号',
                    prefixIcon: Icons.phone_android,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入手机号';
                      }
                      if (value.length != 11) {
                        return '请输入11位手机号';
                      }
                      return null;
                    },
                  ),
                  
                  SizedBox(height: 16),
                  
                  // 密码输入
                  CustomTextField(
                    controller: _passwordController,
                    labelText: '密码',
                    hintText: '请输入密码',
                    prefixIcon: Icons.lock_outline,
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入密码';
                      }
                      if (value.length < 6) {
                        return '密码长度不能少于6位';
                      }
                      return null;
                    },
                  ),
                  
                  SizedBox(height: 8),
                  
                  // 忘记密码
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // 忘记密码处理
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('忘记密码功能开发中')),
                        );
                      },
                      child: Text('忘记密码？'),
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  
                  // 登录按钮
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        // 登录逻辑
                        Provider.of<UserModel>(context, listen: false)
                            .login(_phoneController.text, _passwordController.text);
                        Navigator.pushReplacementNamed(context, '/home');
                      }
                    },
                    child: Text('登录', style: TextStyle(fontSize: 16)),
                  ),
                  
                  SizedBox(height: 16),
                  
                  // 注册入口
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('还没有账号？'),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/register');
                        },
                        child: Text('立即注册'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}