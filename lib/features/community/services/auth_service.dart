import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService {
  // API基础URL - 替换为您的服务器地址
  final String baseUrl = 'http://127.0.0.1:3000/api';
  
  // 单例模式
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();
  
  // 用户注册
  Future<Map<String, dynamic>> signup(String phone, String name, String password, 
      {String? department, String? grade}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/signup'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'phone': phone,
          'name': name,
          'password': password,
          'department': department,
          'grade': grade,
        }),
      );
      
      final data = json.decode(response.body);
      
      if (response.statusCode == 201) {
        return {
          'success': true,
          'userId': data['userId'],
          'message': data['message'] ?? '注册成功',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? '注册失败',
        };
      }
    } catch (e) {
      print('注册失败: $e');
      return {
        'success': false,
        'message': '网络错误，请检查网络连接',
      };
    }
  }
  
  // 更新用户验证状态
  Future<bool> setVerified(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verify'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'verified': true,
        }),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('设置验证状态失败: $e');
      return false;
    }
  }
  
  // 登录
  Future<Map<String, dynamic>> login(String phone, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'phone': phone,
          'password': password,
        }),
      );
      
      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        // 保存用户信息到本地
        final user = User.fromJson(data['user']);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', json.encode(user.toJson()));
        await prefs.setString('token', data['token']);
        
        return {
          'success': true,
          'user': user,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? '登录失败',
        };
      }
    } catch (e) {
      print('登录失败: $e');
      return {
        'success': false,
        'message': '网络错误，请检查网络连接',
      };
    }
  }
  
  // 获取当前登录的用户
  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user');
    
    if (userString != null) {
      return User.fromJson(json.decode(userString));
    }
    
    return null;
  }
  
  // 退出登录
  Future<bool> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    await prefs.remove('token');
    return true;
  }
}