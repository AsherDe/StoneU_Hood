// models/user_model.dart - 用户模型
import 'package:flutter/foundation.dart';

class UserModel extends ChangeNotifier {
  String? phoneNumber;
  String? nickname;
  String? college;
  String? className;
  String? gender;
  String? avatar;
  String? signature;
  int likes = 0;
  int following = 0;
  int followers = 0;
  List<String> interests = [];
  List<String> courses = []; // 解析的课程列表

  bool isLoggedIn = false;

  void login(String phone, String password) {
    // 模拟登录逻辑
    phoneNumber = phone;
    isLoggedIn = true;
    // 假设从后端获取用户资料
    nickname = "用户${phone.substring(7)}";
    college = "计算机科学学院";
    signature = "这个人很懒，什么都没留下";
    likes = 42;
    following = 15;
    followers = 8;
    notifyListeners();
  }

  void register(String phone, String password, String collegeValue, String? genderValue) {
    // 模拟注册逻辑
    phoneNumber = phone;
    college = collegeValue;
    gender = genderValue;
    isLoggedIn = true;
    nickname = "用户${phone.substring(7)}";
    signature = "这个人很懒，什么都没留下";
    notifyListeners();
  }

  void logout() {
    isLoggedIn = false;
    phoneNumber = null;
    notifyListeners();
  }

  void updateProfile({String? newNickname, String? newSignature, String? newCollege, String? newClass, String? newGender}) {
    if (newNickname != null) nickname = newNickname;
    if (newSignature != null) signature = newSignature;
    if (newCollege != null) college = newCollege;
    if (newClass != null) className = newClass;
    if (newGender != null) gender = newGender;
    notifyListeners();
  }

  void addCourse(String course) {
    if (!courses.contains(course)) {
      courses.add(course);
      notifyListeners();
    }
  }

  void addInterest(String interest) {
    if (!interests.contains(interest)) {
      interests.add(interest);
      notifyListeners();
    }
  }
}