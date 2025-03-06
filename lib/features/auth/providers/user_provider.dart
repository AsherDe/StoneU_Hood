// lib/features/auth/providers/user_provider.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isVerified = false;
  String? _userId;
  String? _username;
  String? _avatar;
  
  bool get isLoggedIn => _isLoggedIn;
  bool get isVerified => _isVerified;
  String? get userId => _userId;
  String? get username => _username;
  String? get avatar => _avatar;
  
  UserProvider() {
    _loadUserData();
  }
  
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    _isVerified = prefs.getBool('isVerified') ?? false;
    _userId = prefs.getString('userId');
    _username = prefs.getString('username');
    _avatar = prefs.getString('avatar');
    notifyListeners();
  }
  
  Future<void> setUserData({
    required String userId,
    required String username,
    String? avatar,
  }) async {
    _isLoggedIn = true;
    _userId = userId;
    _username = username;
    _avatar = avatar;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('userId', userId);
    await prefs.setString('username', username);
    if (avatar != null) {
      await prefs.setString('avatar', avatar);
    }
    
    notifyListeners();
  }
  
  Future<void> setVerified(bool verified) async {
    _isVerified = verified;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isVerified', verified);
    
    notifyListeners();
  }
  
  Future<void> logout() async {
    _isLoggedIn = false;
    _isVerified = false;
    _userId = null;
    _username = null;
    _avatar = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    notifyListeners();
  }
}