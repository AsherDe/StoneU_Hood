// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  User? _currentUser;
  bool _isLoading = false;
  bool _authenticated = false; // Cached authentication state
  bool _verified = false; // Cached verification state

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get authenticated => _authenticated; // Synchronous getter
  bool get verified => _verified; // Synchronous getter

  // 检测token是否存在，辅助检测登陆
  Future<bool> _checkAuthenticated() async {
    final token = await _authService.storage.read(key: 'token');
    return token != null && token.isNotEmpty;
  }

  // 检查用户是否已经登录
  Future<bool> isAuthenticated() async {
    _authenticated = await _checkAuthenticated();
    notifyListeners();
    return _authenticated;
  }

  // 直接设置verified
  Future<void> setVerified(bool value) async {
    // 在 AuthService 中保存状态
    if (value) {
      await _authService.storage.write(
        key: 'timetable_verified',
        value: 'true',
      );
    } else {
      await _authService.storage.write(
        key: 'timetable_verified',
        value: 'false',
      );
    }

    // 更新本地状态
    _verified = value;
    notifyListeners();
  }

  // 检查timetable验证状态
  Future<bool> checkTimetableVerification() async {
    return await _authService.isTimetableVerified();
  }

  // 发送OTP前先检查timetable验证
  Future<bool> sendOtp(String phone, String sceneId) async {
    // 先检查timetable验证状态
    // bool isTimetableVerified = await _authService.isTimetableVerified();
    // if (!isTimetableVerified) {
    //   throw Exception('请先通过课表验证身份');
    // }

    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.post('/auth/send-otp', {
        'phone': phone,
        'sceneId': sceneId,
      });
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception(e);
    }
  }

  // 验证OTP
  Future<bool> verifyOtp(String phone, String otp) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post('/auth/verify-otp', {
        'phone': phone,
        'otp': otp,
      });

      // 保存token
      await _authService.storage.write(key: 'token', value: response['token']);

      // 获取用户信息
      _currentUser = await _authService.getCurrentUser();
      if (_currentUser != null) {
        await _authService.storage.write(
          key: 'user_data',
          value: _currentUser?.toJson().toString() ?? '',
        );
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception(e);
    }
  }

  // 登出
  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    notifyListeners();
  }

  // 刷新用户信息
  Future<void> refreshUser() async {
    _currentUser = await _authService.getCurrentUser();
    notifyListeners();
  }

  // 在UserProvider类中添加
  Future<bool> verifyCurrentUser() async {
    try {
      final response = await _apiService.verifyUser();
      if (response.containsKey('verified') && response['verified'] == true) {
        // 可能需要更新本地用户状态
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('验证用户失败: $e');
      return false;
    }
  }

  Future<void> checkLoginStatus() async {
    _authenticated = await _checkAuthenticated();

    if (_authenticated) {
      // 如果认证有效，获取用户信息
      _currentUser = await _authService.getCurrentUser();
      // 检查验证状态
      _verified = await _authService.isVerified();
    } else {
      // 如果未认证，清除可能存在的过期数据
      _currentUser = null;
      _verified = false;
    }

    notifyListeners();
  }
}
