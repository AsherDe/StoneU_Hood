// screens/home_screen.dart - 主页面
import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../widgets/post_card.dart';
import '../widgets/category_selector.dart';
import '../widgets/create_post_button.dart';
import '../controllers/community_controller.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _selectedCategory = '推荐';
  List<Post> _posts = [];
  
  final List<String> _categories = [
    '推荐',
    '二手交易',
    '提问区',
    '工作交流区',
    '游戏交流区',
    '交友交流区',
  ];

  @override
  void initState() {
    super.initState();
    // 获取帖子
    _loadPosts();
  }

  void _loadPosts() {
    // 模拟从服务器加载帖子
    setState(() {
      _posts = PostService.getDummyPosts();
      
      // 根据分类筛选
      if (_selectedCategory != '推荐') {
        _posts = _posts.where((post) => post.category == _selectedCategory).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('校园社区'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              // 搜索功能
            },
          ),
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {
              // 通知功能
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 分类选择器
          CategorySelector(
            categories: _categories,
            selectedCategory: _selectedCategory,
            onCategorySelected: (category) {
              setState(() {
                _selectedCategory = category;
                _loadPosts();
              });
            },
          ),
          
          // 帖子列表
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                // 刷新帖子
                _loadPosts();
              },
              child: _posts.isEmpty
                  ? Center(child: Text('暂无内容'))
                  : ListView.builder(
                      itemCount: _posts.length,
                      itemBuilder: (context, index) {
                        return PostCard(post: _posts[index]);
                      },
                    ),
            ),
          ),
        ],
      ),
      // 底部导航栏
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          
          // 切换页面
          if (index == 0) {
            // 已经在首页
          } else if (index == 1) {
            // 消息页面
          } else if (index == 2) {
            // 个人页面
            Navigator.pushNamed(context, '/profile');
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '首页',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: '消息',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
      // 悬浮按钮 - 发布新帖子
      floatingActionButton: CreatePostButton(),
    );
  }
}
