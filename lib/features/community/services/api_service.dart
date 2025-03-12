// lib/services/api_service.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  final String baseUrl = 'http://localhost:8080/api';
  final storage = FlutterSecureStorage();

  Future<String?> _getToken() async {
    return await storage.read(key: 'token');
  }

  Future<Map<String, dynamic>> get(String endpoint, [String? token]) async {
    final authToken = token ?? await _getToken();
    final headers = <String, String>{'Content-Type': 'application/json'};

    if (authToken != null) {
      headers['Authorization'] = 'Bearer $authToken';
    }

    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data, [
    String? token,
  ]) async {
    final authToken = token ?? await _getToken();
    final headers = <String, String>{'Content-Type': 'application/json'};

    if (authToken != null) {
      headers['Authorization'] = 'Bearer $authToken';
    }

    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: json.encode(data),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> data, [
    String? token,
  ]) async {
    final authToken = token ?? await _getToken();
    final headers = <String, String>{'Content-Type': 'application/json'};

    if (authToken != null) {
      headers['Authorization'] = 'Bearer $authToken';
    }

    final response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: json.encode(data),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> delete(String endpoint, [String? token]) async {
    final authToken = token ?? await _getToken();
    final headers = <String, String>{'Content-Type': 'application/json'};

    if (authToken != null) {
      headers['Authorization'] = 'Bearer $authToken';
    }

    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );

    return _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      Map<String, dynamic> errorData;
      try {
        errorData = json.decode(response.body);
      } catch (e) {
        throw Exception('服务器错误: ${response.statusCode}');
      }

      throw Exception(errorData['message'] ?? '未知错误');
    }
  }

  Future<Map<String, dynamic>> verifyUser() async {
    final response = await post('/user/verify', {});
    return response;
  }

  // 检查token是否正常的测试类，仅开发中使用
  Future<void> checkToken() async {
    final token = await _getToken();
    print('当前token: ${token ?? "未找到token"}');

    if (token == null) {
      print('警告: token为空，请检查登录状态');
    } else {
      // 解析JWT token (可选，如果您想检查payload)
      final parts = token.split('.');
      if (parts.length != 3) {
        print('警告: token格式不正确');
      } else {
        try {
          // 解码JWT payload (base64)
          final payload = parts[1];
          final normalized = base64Url.normalize(payload);
          final decoded = utf8.decode(base64Url.decode(normalized));
          print('Token payload: $decoded');
          // 查看是否包含userID
          final Map<String, dynamic> data = json.decode(decoded);
          print('Token中的userID: ${data['userID'] ?? "未找到userID"}');
        } catch (e) {
          print('解析token失败: $e');
        }
      }
    }
  }
}
