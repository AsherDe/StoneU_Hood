// screens/register_screen.dart - 注册界面
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../widgets/custom_text_field.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _phoneController = TextEditingController();
  final _verificationCodeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  String? _selectedCollege;
  String? _selectedClass;
  String? _selectedGender;
  bool _isVerificationSent = false;

  final List<String> _colleges = [
    '计算机科学学院',
    '数学学院',
    '物理学院',
    '化学学院',
    '生物学院',
    '经济学院',
    '管理学院',
    '外国语学院',
    '文学院',
    '历史学院',
    '哲学学院',
    '艺术学院',
    '医学院',
    '法学院',
  ];

  List<String> _classes = [];

  void _updateClasses(String college) {
    // 根据选择的学院更新班级列表
    switch (college) {
      case '计算机科学学院':
        _classes = ['软件工程1班', '软件工程2班', '计算机科学1班', '计算机科学2班', '网络工程1班', '人工智能1班'];
        break;
      case '数学学院':
        _classes = ['数学1班', '数学2班', '统计学1班', '应用数学1班'];
        break;
      default:
        _classes = ['1班', '2班', '3班', '4班'];
    }
    
    // 重置选择的班级
    _selectedClass = null;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _verificationCodeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('注册账号'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                  
                  // 验证码输入
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _verificationCodeController,
                          labelText: '验证码',
                          hintText: '请输入验证码',
                          prefixIcon: Icons.message,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '请输入验证码';
                            }
                            if (value.length != 6) {
                              return '验证码为6位数字';
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {
                          if (_phoneController.text.length == 11) {
                            // 发送验证码逻辑
                            setState(() {
                              _isVerificationSent = true;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('验证码已发送到手机')),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('请输入正确的手机号')),
                            );
                          }
                        },
                        child: Text(_isVerificationSent ? '重新发送' : '获取验证码'),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 16),
                  
                  // 密码输入
                  CustomTextField(
                    controller: _passwordController,
                    labelText: '设置密码',
                    hintText: '请设置6位以上密码',
                    prefixIcon: Icons.lock_outline,
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请设置密码';
                      }
                      if (value.length < 6) {
                        return '密码长度不能少于6位';
                      }
                      return null;
                    },
                  ),
                  
                  SizedBox(height: 16),
                  
                  // 确认密码
                  CustomTextField(
                    controller: _confirmPasswordController,
                    labelText: '确认密码',
                    hintText: '请再次输入密码',
                    prefixIcon: Icons.lock,
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请确认密码';
                      }
                      if (value != _passwordController.text) {
                        return '两次输入的密码不一致';
                      }
                      return null;
                    },
                  ),
                  
                  SizedBox(height: 24),
                  
                  // 选择学院
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: '选择学院',
                      prefixIcon: Icon(Icons.school),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    value: _selectedCollege,
                    items: _colleges.map((college) {
                      return DropdownMenuItem<String>(
                        value: college,
                        child: Text(college),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCollege = value;
                        if (value != null) {
                          _updateClasses(value);
                        }
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请选择学院';
                      }
                      return null;
                    },
                  ),
                  
                  SizedBox(height: 16),
                  
                  // 选择班级
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: '选择班级',
                      prefixIcon: Icon(Icons.group),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    value: _selectedClass,
                    items: _classes.map((className) {
                      return DropdownMenuItem<String>(
                        value: className,
                        child: Text(className),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedClass = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请选择班级';
                      }
                      return null;
                    },
                    isExpanded: true,
                  ),
                  
                  SizedBox(height: 16),
                  
                  // 选择性别（可选）
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: '选择性别（可选）',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    value: _selectedGender,
                    items: [
                      DropdownMenuItem<String>(
                        value: '男',
                        child: Text('男'),
                      ),
                      DropdownMenuItem<String>(
                        value: '女',
                        child: Text('女'),
                      ),
                      DropdownMenuItem<String>(
                        value: '不透露',
                        child: Text('不透露'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedGender = value;
                      });
                    },
                    isExpanded: true,
                  ),
                  
                  SizedBox(height: 32),
                  
                  // 注册按钮
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        if (_selectedCollege == null || _selectedClass == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('请选择学院和班级')),
                          );
                          return;
                        }
                        
                        // 注册逻辑
                        Provider.of<UserModel>(context, listen: false).register(
                          _phoneController.text, 
                          _passwordController.text,
                          _selectedCollege!,
                          _selectedClass!,
                          _selectedGender
                        );
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('注册成功')),
                        );
                        
                        // 注册成功后跳转到主页
                        Navigator.pushReplacementNamed(context, '/home');
                      }
                    },
                    child: Text('注册', style: TextStyle(fontSize: 16)),
                  ),
                  
                  SizedBox(height: 16),
                  
                  // 返回登录
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('已有账号？'),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text('返回登录'),
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
