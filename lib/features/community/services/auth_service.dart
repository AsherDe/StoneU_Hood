// lib/services/auth_service.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';
import '../models/user.dart';

class AuthService {
  final ApiService _apiService = ApiService();
  final storage = FlutterSecureStorage();
  
  // 获取当前用户信息
  Future<User?> getCurrentUser() async {
    try {
      final token = await storage.read(key: 'token');
      if (token == null) return null;
      
      final userData = await _apiService.get('/user/me', token);
      return User.fromJson(userData);
    } catch (e) {
      print('获取用户信息失败: $e');
      return null;
    }
  }
  
  // 设置用户为已验证状态
  Future<bool> setVerified(String userId, {bool fromTimetableImport = false}) async {
    try {
      final token = await storage.read(key: 'token');
      if (token == null) return false;
      
      await _apiService.post('/user/verify', {
        'userId': userId,
        'fromTimetableImport': fromTimetableImport,
      }, token);
      
      return true;
    } catch (e) {
      print('设置用户验证状态失败: $e');
      return false;
    }
  }
  
  // 保存timetable验证状态到本地存储
  Future<bool> setLocalTimetableVerification(bool verified) async {
    try {
      await storage.write(key: 'timetable_verified', value: verified.toString());
      return true;
    } catch (e) {
      print('保存timetable验证状态失败: $e');
      return false;
    }
  }
  
  // 检查timetable是否已经验证
  Future<bool> isTimetableVerified() async {
    try {
      final verifiedString = await storage.read(key: 'timetable_verified');
      return verifiedString == 'true';
    } catch (e) {
      print('获取timetable验证状态失败: $e');
      return false;
    }
  }
  
  // 登出
  Future<bool> logout() async {
    try {
      await storage.delete(key: 'token');
      await storage.delete(key: 'timetable_verified'); // 清除timetable验证状态
      return true;
    } catch (e) {
      print('登出失败: $e');
      return false;
    }
  }
  
  // 检查用户是否已登录
  Future<bool> isLoggedIn() async {
    final token = await storage.read(key: 'token');
    return token != null;
  }
  
  // 检查用户是否已验证
  Future<bool> isVerified() async {
    try {
      final user = await getCurrentUser();
      return user?.verified ?? false;
    } catch (e) {
      return false;
    }
  }
}