import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DioConfig {
  static Dio createDio() {
    final dio = Dio();
    
    dio.options.baseUrl = 'http://your-backend-ip:8080'; // 替换为您的后端服务器地址
    dio.options.connectTimeout = Duration(seconds: 5);
    dio.options.receiveTimeout = Duration(seconds: 3);

    // 添加拦截器处理token
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // 从SharedPreferences获取token
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        
        if (token != null) {
          options.headers['Authorization'] = token;
        }
        
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        // 处理token过期等错误
        if (e.response?.statusCode == 401) {
          // 清除token并跳转到登录页
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('auth_token');
          
          // 这里可以添加跳转到登录页的逻辑
        }
        return handler.next(e);
      },
    ));

    return dio;
  }
}