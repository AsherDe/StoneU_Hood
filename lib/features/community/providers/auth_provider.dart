// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  String? _token;
  final storage = FlutterSecureStorage();
  final apiService = ApiService();
  
  User? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _token != null;
  bool get isVerified => _user?.verified ?? false;
  
  Future<void> initFromToken(String token) async {
    _token = token;
    await _fetchUserInfo();
    notifyListeners();
  }
  
  Future<void> _fetchUserInfo() async {
    if (_token == null) return;
    
    try {
      final userData = await apiService.get('/user/me', _token!);
      _user = User.fromJson(userData);
    } catch (e) {
      await logout();
      throw e;
    }
  }
  
  Future<void> sendOtp(String phone) async {
    await apiService.post('/auth/send-otp', {'phone': phone});
  }
  
  Future<bool> verifyOtp(String phone, String otp) async {
    final response = await apiService.post('/auth/verify-otp', {
      'phone': phone,
      'otp': otp,
    });
    
    _token = response['token'];
    await storage.write(key: 'token', value: _token);
    await _fetchUserInfo();
    notifyListeners();
    return true;
  }
  
  Future<void> logout() async {
    _token = null;
    _user = null;
    await storage.delete(key: 'token');
    notifyListeners();
  }
  
  String _generateRandomVestName() {
    // 此函数用于生成随机马甲名
    // 实际上由后端实现，这里只是为了示例
    return '匿名用户';
  }
}


