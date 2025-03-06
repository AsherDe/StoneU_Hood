// lib/features/auth/services/auth_service.dart
import 'package:dio/dio.dart';
import '../providers/user_provider.dart';

class AuthService {
  final Dio _dio = Dio();
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal() {
    _dio.options.baseUrl = 'https://your-api-endpoint.com/api';
    _dio.options.connectTimeout = Duration(seconds: 5);
    _dio.options.receiveTimeout = Duration(seconds: 3);
  }

  // 用户登录
  Future<bool> login(String phoneNumber, String password) async {
    try {
      final response = await _dio.post('/login', data: {
        'phoneNumber': phoneNumber,
        'password': password,
      });

      if (response.statusCode == 200 && response.data['success']) {
        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  // 用户注册
  Future<bool> register(String phoneNumber, String password, String college, String className, {String? gender}) async {
    try {
      final response = await _dio.post('/register', data: {
        'phoneNumber': phoneNumber,
        'password': password,
        'college': college,
        'class': className,
        'gender': gender,
      });

      if (response.statusCode == 201 && response.data['success']) {
        return true;
      }
      return false;
    } catch (e) {
      print('Register error: $e');
      return false;
    }
  }

  // 设置用户验证状态
  Future<bool> setVerified(String userId) async {
    try {
      final response = await _dio.post('/users/$userId/verify');

      if (response.statusCode == 200 && response.data['success']) {
        return true;
      }
      return false;
    } catch (e) {
      print('Set verified error: $e');
      return false;
    }
  }

  // 检查用户验证状态
  Future<bool> checkVerificationStatus(String userId) async {
    try {
      final response = await _dio.get('/users/$userId');

      if (response.statusCode == 200) {
        return response.data['verified'] ?? false;
      }
      return false;
    } catch (e) {
      print('Check verification error: $e');
      return false;
    }
  }

  // 添加离线模式支持
  // 当无法连接服务器时，可以使用本地存储的验证状态
  Future<bool> setVerifiedOffline(UserProvider userProvider) async {
    try {
      // 尝试与服务器通信
      final success = await setVerified(userProvider.userId!);
      if (success) {
        // 更新本地状态
        await userProvider.setVerified(true);
        return true;
      }
      return false;
    } catch (e) {
      print('Set verified offline error: $e');
      // 仅在离线模式下更新本地状态
      await userProvider.setVerified(true);
      return true;
    }
  }
}