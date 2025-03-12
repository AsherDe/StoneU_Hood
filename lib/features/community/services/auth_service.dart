// lib/services/auth_service.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';
import '../models/user.dart';
import 'dart:convert';

class AuthService {
  final ApiService _apiService = ApiService();
  final storage = FlutterSecureStorage();

  // 获取当前用户信息
  Future<User?> getCurrentUser() async {
    try {
      final token = await storage.read(key: 'token');
      if (token == null) return null;

      // _apiService.get 已经返回解析过的 Map<String, dynamic>
      final Map<String, dynamic> userData = await _apiService.get(
        '/user/me',
        token,
      );

      return User.fromJson(userData);
    } catch (e) {
      print('获取用户信息失败: $e');
      return null;
    }
  }

  // 设置用户为已验证状态
  Future<bool> setVerified(
    String userId, {
    bool fromTimetableImport = false,
  }) async {
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
      await storage.write(
        key: 'timetable_verified',
        value: verified.toString(),
      );
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

  // 保存用户数据到安全存储
  Future<bool> saveUserData(User user) async {
    try {
      await storage.write(key: 'user_data', value: user.toJson().toString());
      return true;
    } catch (e) {
      print('保存用户数据失败: $e');
      return false;
    }
  }

  // 从安全存储中获取用户数据
  Future<User?> getUserData() async {
    try {
      final String? userDataString = await storage.read(key: 'user_data');
      if (userDataString == null) return null;

      // 将JSON字符串转换为Map
      final Map<String, dynamic> userData = json.decode(userDataString);
      return User.fromJson(userData);
    } catch (e) {
      print('获取用户数据失败: $e');
      return null;
    }
  }

  // 登出
  Future<bool> logout() async {
    try {
      // 删除token
      await storage.delete(key: 'token');
      // 删除timetable验证状态
      await storage.delete(key: 'timetable_verified');
      // 添加这行：删除存储的用户数据
      await storage.delete(key: 'user_data');
      // 可以添加其他需要清除的数据项
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
