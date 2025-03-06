// lib/routes/app_router.dart
import 'package:StoneU_Hood/features/community/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../features/calendar/screens/calendar_screen.dart';
import '../features/community/screens/home_screen.dart';
import '../features/community/screens/profile_screen.dart' as profile;
import '../features/community/controllers/community_controller.dart';
import '../features/calendar/services/calendar_sync_service.dart';
import '../features/auth/providers/user_provider.dart';
import '../features/community/screens/chatscreen.dart';

class AppRouter {
  // Singleton pattern
  static final AppRouter _instance = AppRouter._internal();

  factory AppRouter() {
    return _instance;
  }

  AppRouter._internal();

  // Initialize services
  Future<void> initialize() async {
    await CalendarSyncService().initialize();
  }

  // Root widgets
  Widget getMainApp() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CommunityController()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: MaterialApp(
        title: '石大时光圈',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.black87),
            titleTextStyle: TextStyle(
              color: Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          textTheme: TextTheme(
            bodyLarge: TextStyle(color: Colors.black),
            bodyMedium: TextStyle(color: Colors.black87),
            bodySmall: TextStyle(color: Colors.black54),
          ),
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Color(0xFF303030),
          appBarTheme: AppBarTheme(
            backgroundColor: Color(0xFF303030),
            elevation: 0,
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          textTheme: TextTheme(
            bodyLarge: TextStyle(color: Colors.white),
            bodyMedium: TextStyle(color: Colors.white70),
            bodySmall: TextStyle(color: Colors.white54),
          ),
        ),
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [const Locale('zh', 'CN')],
        home: MainTabScreen(),
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => _buildScreen(settings),
            settings: settings,
          );
        },
      ),
    );
  }

  // Route generation
  Widget _buildScreen(RouteSettings settings) {
    switch (settings.name) {
      case '/calendar-verification':
        final args = settings.arguments as Map<String, dynamic>;
        return CalendarScreen(isVerification: true, userId: args['userId']);
      default:
        return MainTabScreen();
    }
  }
}

class MainTabScreen extends StatefulWidget {
  @override
  _MainTabScreenState createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    HomeScreen(),
    CalendarScreen(userId: UserModel.phoneNumber),
    ChatScreen(),
    profile.ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Initialize the community controller
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CommunityController>(context, listen: false).initialize();

      // Check user verification status
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.isLoggedIn && !userProvider.isVerified) {
        showVerificationDialog();
      }
    });
  }

  void showVerificationDialog() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Text('需要验证'),
            content: Text('您需要导入学校日历以验证您的学生身份，才能发布内容。'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('稍后'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(
                    context,
                    '/calendar-verification',
                    arguments: {'userId': userProvider.userId},
                  );
                },
                child: Text('立即验证'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
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
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }
}
