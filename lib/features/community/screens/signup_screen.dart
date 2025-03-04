// lib/features/community/screens/signup_screen.dart
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../community_controller.dart';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _departmentController = TextEditingController();
  final _gradeController = TextEditingController();
  
  bool _isLoading = false;
  String? _userId;
  String? _errorMessage;
  
  bool _usePhone = false; // 是否使用手机号注册
  
  // 验证相关
  bool _showVerification = false;
  File? _calendarFile;
  File? _studentCardImage;
  bool _isVerifying = false;
  String? _verificationMessage;
  bool _verificationSuccess = false;
  
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _departmentController.dispose();
    _gradeController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final controller = Provider.of<CommunityController>(context, listen: false);
      
      final result = await controller.signup(
        _nameController.text,
        _emailController.text,
        _passwordController.text,
        phone: _usePhone ? _phoneController.text : null,
        department: _departmentController.text,
        grade: _gradeController.text,
      );
      
      if (result['success']) {
        setState(() {
          _userId = result['userId'];
          _showVerification = true;
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
      } else {
        setState(() {
          _errorMessage = result['message'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '注册过程中发生错误: $e';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _pickCalendarFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['ics', 'csv', 'txt', 'json'],
      );
      
      if (result != null) {
        setState(() {
          _calendarFile = File(result.files.single.path!);
        });
      }
    } catch (e) {
      print('选择文件失败: $e');
    }
  }
  
  Future<void> _pickStudentCardImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      
      if (pickedFile != null) {
        setState(() {
          _studentCardImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      print('选择图片失败: $e');
    }
  }
  
  Future<void> _verifyWithCalendar() async {
    if (_calendarFile == null || _userId == null) return;
    
    setState(() {
      _isVerifying = true;
      _verificationMessage = null;
    });
    
    try {
      final controller = Provider.of<CommunityController>(context, listen: false);
      
      // 解析日历文件
      final calendarData = await controller.parseCalendar(_calendarFile!);
      
      if (calendarData == null) {
        setState(() {
          _verificationMessage = '无法解析课表文件，请尝试上传学生证照片';
          _isVerifying = false;
          _verificationSuccess = false;
        });
        return;
      }
      
      // 验证课表
      final result = await controller.verifyWithCalendar(_userId!, calendarData);
      
      setState(() {
        _verificationMessage = result['message'];
        _isVerifying = false;
        _verificationSuccess = result['success'];
      });
      
    } catch (e) {
      setState(() {
        _verificationMessage = '验证过程中发生错误: $e';
        _isVerifying = false;
        _verificationSuccess = false;
      });
    }
  }
  
  Future<void> _uploadStudentCard() async {
    if (_studentCardImage == null || _userId == null) return;
    
    setState(() {
      _isVerifying = true;
      _verificationMessage = null;
    });
    
    try {
      final controller = Provider.of<CommunityController>(context, listen: false);
      
      final result = await controller.uploadStudentCard(_userId!, _studentCardImage!);
      
      setState(() {
        _verificationMessage = result['message'];
        _isVerifying = false;
        _verificationSuccess = result['success'];
      });
      
    } catch (e) {
      setState(() {
        _verificationMessage = '上传过程中发生错误: $e';
        _isVerifying = false;
        _verificationSuccess = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('注册'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: _showVerification ? _buildVerificationForm() : _buildSignupForm(),
      ),
    );
  }

  Widget _buildSignupForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 头像部分可以添加
          
          SizedBox(height: 24),
          
          // 姓名
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: '姓名',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '请输入姓名';
              }
              return null;
            },
          ),
          
          SizedBox(height: 16),
          
          // 登录方式选择
          Row(
            children: [
              Expanded(
                child: RadioListTile<bool>(
                  title: Text('邮箱注册'),
                  value: false,
                  groupValue: _usePhone,
                  onChanged: (bool? value) {
                    setState(() {
                      _usePhone = value ?? false;
                    });
                  },
                ),
              ),
              Expanded(
                child: RadioListTile<bool>(
                  title: Text('手机号注册'),
                  value: true,
                  groupValue: _usePhone,
                  onChanged: (bool? value) {
                    setState(() {
                      _usePhone = value ?? false;
                    });
                  },
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          // 邮箱/手机号
          if (!_usePhone)
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: '邮箱',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入邮箱';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return '请输入有效的邮箱地址';
                }
                return null;
              },
            )
          else
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: '手机号',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入手机号';
                }
                if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(value)) {
                  return '请输入有效的手机号码';
                }
                return null;
              },
            ),
          
          SizedBox(height: 16),
          
          // 密码
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: '密码',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock),
            ),
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '请输入密码';
              }
              if (value.length < 6) {
                return '密码长度至少为6位';
              }
              return null;
            },
          ),
          
          SizedBox(height: 16),
          
          // 确认密码
          TextFormField(
            controller: _confirmPasswordController,
            decoration: InputDecoration(
              labelText: '确认密码',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock_outline),
            ),
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '请确认密码';
              }
              if (value != _passwordController.text) {
                return '两次输入的密码不匹配';
              }
              return null;
            },
          ),
          
          SizedBox(height: 16),
          
          // 院系
          TextFormField(
            controller: _departmentController,
            decoration: InputDecoration(
              labelText: '院系',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.school),
            ),
          ),
          
          SizedBox(height: 16),
          
          // 年级
          TextFormField(
            controller: _gradeController,
            decoration: InputDecoration(
              labelText: '年级',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.grade),
              hintText: '例如：2023级',
            ),
          ),
          
          if (_errorMessage != null) ...[
            SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red),
            ),
          ],
          
          SizedBox(height: 24),
          
          // 注册按钮
          ElevatedButton(
            onPressed: _isLoading ? null : _signup,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: _isLoading 
                ? CircularProgressIndicator(color: Colors.white)
                : Text('注册'),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
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
    );
  }

  Widget _buildVerificationForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '验证学生身份',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        SizedBox(height: 16),
        
        Text(
          '为了确保您是本校学生，我们需要验证您的学生身份。您可以：',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[700],
          ),
        ),
        
        SizedBox(height: 24),
        
        // 验证方式1：上传课表
        Card(
          elevation: 2,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today, color: Theme.of(context).primaryColor),
                    SizedBox(width: 12),
                    Text(
                      '方式一：上传课表文件',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 12),
                
                Text(
                  '请上传您的课表文件，系统将自动解析确认您的学生身份。',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                
                SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: Icon(Icons.upload_file),
                        label: Text(_calendarFile == null ? '选择文件' : '更换文件'),
                        onPressed: _pickCalendarFile,
                      ),
                    ),
                    SizedBox(width: 12),
                    if (_calendarFile != null)
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.check),
                          label: Text('验证'),
                          onPressed: _verifyWithCalendar,
                        ),
                      ),
                  ],
                ),
                
                if (_calendarFile != null) ...[
                  SizedBox(height: 8),
                  Text(
                    '已选择: ${_calendarFile!.path.split('/').last}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        
        SizedBox(height: 16),
        
        // 验证方式2：上传学生证
        Card(
          elevation: 2,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.badge, color: Theme.of(context).primaryColor),
                    SizedBox(width: 12),
                    Text(
                      '方式二：上传学生证照片',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 12),
                
                Text(
                  '请上传您的学生证照片，我们将在24小时内完成审核。审核通过后，照片将被删除。',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                
                SizedBox(height: 16),
                
                if (_studentCardImage == null)
                  OutlinedButton.icon(
                    icon: Icon(Icons.add_a_photo),
                    label: Text('选择学生证照片'),
                    onPressed: _pickStudentCardImage,
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size(double.infinity, 48),
                    ),
                  )
                else
                  Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _studentCardImage!,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: Icon(Icons.refresh),
                              label: Text('更换照片'),
                              onPressed: _pickStudentCardImage,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: Icon(Icons.upload),
                              label: Text('上传审核'),
                              onPressed: _uploadStudentCard,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        
        if (_isVerifying) ...[
          SizedBox(height: 24),
          Center(child: CircularProgressIndicator()),
        ],
        
        if (_verificationMessage != null) ...[
          SizedBox(height: 24),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _verificationSuccess ? Colors.green[50] : Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _verificationSuccess ? Colors.green : Colors.red,
              ),
            ),
            child: Text(
              _verificationMessage!,
              style: TextStyle(
                color: _verificationSuccess ? Colors.green[800] : Colors.red[800],
              ),
            ),
          ),
        ],
        
        SizedBox(height: 24),
        
        ElevatedButton(
          onPressed: () {
            if (_verificationSuccess) {
              // 验证成功，返回登录页
              Navigator.of(context).pop();
            } else {
              // 返回注册表单
              setState(() {
                _showVerification = false;
              });
            }
          },
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(_verificationSuccess ? '前往登录' : '返回修改注册信息'),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _verificationSuccess ? Colors.green : Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }
}