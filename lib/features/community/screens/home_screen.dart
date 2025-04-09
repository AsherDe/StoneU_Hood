// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/post_provider.dart';
import '../widgets/post_card.dart';
import '../widgets/create_post_button.dart';
import './create_post_screen.dart';
import './search_screen.dart';
import '../../../core/constants/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    _loadPosts();
    
    // 添加滚动监听，实现上拉加载更多
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        _loadMorePosts();
      }
    });
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await Provider.of<PostProvider>(context, listen: false).fetchPosts();
    } catch (e) {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('获取帖子失败: $e')),
      // );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _loadMorePosts() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await Provider.of<PostProvider>(context, listen: false).loadMorePosts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载更多帖子失败: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshPosts() async {
    await Provider.of<PostProvider>(context, listen: false).refreshPosts();
  }
  
  void _navigateToCreatePost() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreatePostScreen(),
      ),
    ).then((_) => _refreshPosts());
  }
  
  void _navigateToSearch() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SearchScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final posts = Provider.of<PostProvider>(context).posts;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('青春集市'),
        backgroundColor: AppTheme.primaryColor,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: _navigateToSearch,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPosts,
        child: posts.isEmpty && !_isLoading
            ? Center(child: Text('暂无帖子，下拉刷新或者发布新帖子'))
            : ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.all(10),
                itemCount: posts.length + (_isLoading ? 1 : 0),
                itemBuilder: (ctx, index) {
                  if (index == posts.length) {
                    return Center(child: CircularProgressIndicator());
                  }
                  return PostCard(post: posts[index]);
                },
              ),
      ),
      floatingActionButton: CreatePostButton(
        onPressed: _navigateToCreatePost,
      ),
    );
  }
}