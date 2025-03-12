import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

// Core
import 'core/constants/app_theme.dart';

// Community features
import 'features/community/screens/home_screen.dart';
import 'features/community/providers/auth_provider.dart';
import 'features/community/providers/post_provider.dart';
import 'features/community/providers/chat_provider.dart';
import 'features/community/screens/login_screen.dart';

// Calendar features
import 'features/calendar/screens/calendar_screen.dart';
import 'features/calendar/services/calendar_sync_service.dart';

// Chat Screen
import 'features/community/screens/chat_list_screen.dart'; // Assuming this exists

void main() async {
  // 确保Flutter绑定初始化
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化日历同步服务
  await CalendarSyncService().initialize();
  
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      ChangeNotifierProvider(create: (_) => PostProvider()),
      ChangeNotifierProvider(create: (_) => ChatProvider()),
    ],
    child: MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  final storage = FlutterSecureStorage();
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '石大校园助手',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('zh'),
        const Locale('en'),
      ],
      home: FutureBuilder<String?>(
        future: storage.read(key: 'token'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(body: Center(child: CircularProgressIndicator()));
          }
         
          return MainTabScreen();
        },
      ),
    );
  }
}

class MainTabScreen extends StatefulWidget {
  @override
  _MainTabScreenState createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  int _currentIndex = 1;
  
  // 定义所有标签页对应的屏幕
  final List<Widget> _screens = [
    HomeScreen(),    // 社区主页
    CalendarScreen(), // 日历页面
    ChatListScreen(), // 聊天列表页面
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 2 || index == 0) {
            // 获取 AuthProvider
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          
          // 检查是否已登录
          if (!authProvider.authenticated) {
            // 提示用户登录
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('请先登录后再使用聊天功能')),
            );
            
            // 跳转到登录页面
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => LoginScreen()),
            );
            return;
          }

          // 检查是否已验证
          if (!authProvider.verified) {
            // 提示用户需要先解析课程表
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('请先导入课程表完成验证')),
            );
            return;
          }
        }

          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: '主页',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: '日历',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_outlined),
            activeIcon: Icon(Icons.chat),
            label: '聊天',
          ),
        ],
      ),
    );
  }
}