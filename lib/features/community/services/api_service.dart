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
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    
    if (authToken != null) {
      headers['Authorization'] = 'Bearer $authToken';
    }
    
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );
    
    return _handleResponse(response);
  }
  
  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data, [String? token]) async {
    final authToken = token ?? await _getToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    
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
  
  Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> data, [String? token]) async {
    final authToken = token ?? await _getToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    
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
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    
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
}