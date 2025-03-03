// lib/routes/app_router.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../features/calendar/screens/calendar_screen.dart';
import '../features/community/screens/home_screen.dart';
import '../features/community/screens/marketplace_screen.dart';
import '../features/community/screens/study_materials_screen.dart';
import '../features/community/screens/chat_screen.dart';
import '../features/community/screens/profile_screen.dart' as profile;
import '../features/community/screens/create_item_screen.dart';
import '../features/community/community_controller.dart';

class AppRouter {
  // Singleton pattern
  static final AppRouter _instance = AppRouter._internal();
  
  factory AppRouter() {
    return _instance;
  }
  
  AppRouter._internal();
  
  // Root widgets
  Widget getMainApp() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CommunityController()),
      ],
      child: MaterialApp(
        title: '石大日历',
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
      case '/marketplace':
        return MarketplaceScreen();
      case '/study-materials':
        return StudyMaterialsScreen();
      case '/create-item':
        return CreateItemScreen();
      case '/edit-item':
        final args = settings.arguments as Map<String, dynamic>;
        return CreateItemScreen(itemToEdit: args['item']);
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
    CalendarScreen(),
    ChatScreen(),
    profile.ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Initialize the community controller
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CommunityController>(context, listen: false).initialize();
    });
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