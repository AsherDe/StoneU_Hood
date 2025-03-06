// screens/profile_screen.dart - 个人资料页面
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../widgets/post_card.dart';
import '../widgets/profile_header.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Post> _userPosts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserPosts();
  }

  void _loadUserPosts() {
    // 模拟加载用户发布的帖子
    final userModel = Provider.of<UserModel>(context, listen: false);
    final allPosts = PostService.getDummyPosts();
    
    // 筛选当前用户的帖子
    setState(() {
      _userPosts = allPosts.where((post) => post.userId == userModel.phoneNumber).toList();
      // 由于是模拟数据，这里直接使用所有帖子
      _userPosts = allPosts;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userModel = Provider.of<UserModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('个人中心'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              // 设置功能
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 个人资料头部
          ProfileHeader(
            avatar: userModel.avatar,
            nickname: userModel.nickname ?? '未设置昵称',
            signature: userModel.signature ?? '这个人很懒，什么都没留下',
            following: userModel.following,
            followers: userModel.followers,
            likes: userModel.likes,
          ),
          
          // 选项卡
          TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).primaryColor,
            tabs: [
              Tab(text: '发布'),
              Tab(text: '收藏'),
              Tab(text: '点赞'),
            ],
          ),
          
          // 选项卡内容
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 发布的帖子
                _userPosts.isEmpty
                    ? Center(child: Text('暂无发布内容'))
                    : ListView.builder(
                        itemCount: _userPosts.length,
                        itemBuilder: (context, index) {
                          return PostCard(post: _userPosts[index]);
                        },
                      ),
                
                // 收藏的帖子
                Center(child: Text('暂无收藏内容')),
                
                // 点赞的帖子
                Center(child: Text('暂无点赞内容')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
