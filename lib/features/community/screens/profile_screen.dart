// lib/features/community/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../community_controller.dart';
import '../services/community_service.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<CommunityController>(
      builder: (context, controller, child) {
        final user = controller.currentUser ?? 
          UserProfile(
            id: 'guest',
            name: '未登录用户',
            email: '',
            department: '请登录以查看详细信息',
            grade: '',
          );
            
        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: Text(
              '个人中心',
              style: TextStyle(color: Colors.black87),
            ),
            elevation: 0,
            backgroundColor: Colors.white,
            actions: [
              IconButton(
                icon: Icon(Icons.settings_outlined),
                color: Colors.black87,
                onPressed: () {
                  // TODO: Navigate to settings
                },
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await controller.loadCurrentUser();
            },
            child: ListView(
              children: [
                // Profile header
                _buildProfileHeader(context, user),
                
                // Quick actions
                _buildQuickActions(context),
                
                // Menu items
                _buildMenuSection(context, 'Community', [
                  MenuItem(
                    icon: Icons.shopping_bag_outlined,
                    title: '我的物品',
                    onTap: () {
                      // TODO: Navigate to my items
                    },
                  ),
                  MenuItem(
                    icon: Icons.book_outlined,
                    title: '我的资料',
                    onTap: () {
                      // TODO: Navigate to my materials
                    },
                  ),
                  MenuItem(
                    icon: Icons.favorite_border,
                    title: '我的收藏',
                    onTap: () {
                      // TODO: Navigate to favorites
                    },
                  ),
                ]),
                
                _buildMenuSection(context, '我的帐户', [
                  MenuItem(
                    icon: Icons.person_outline,
                    title: '个人信息',
                    onTap: () {
                      // TODO: Navigate to profile edit
                    },
                  ),
                  MenuItem(
                    icon: Icons.notifications_outlined,
                    title: '消息通知',
                    onTap: () {
                      // TODO: Navigate to notifications
                    },
                  ),
                  MenuItem(
                    icon: Icons.help_outline,
                    title: '帮助与反馈',
                    onTap: () {
                      // TODO: Navigate to help and feedback
                    },
                  ),
                ]),
                
                // Logout button
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: OutlinedButton(
                    onPressed: user.id == 'guest' ? null : () async {
                      final result = await controller.logout();
                      if (result) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('已退出登录')),
                        );
                      }
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        '退出登录',
                        style: TextStyle(
                          color: Colors.red,
                        ),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.red[300]!),
                    ),
                  ),
                ),
                
                SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildProfileHeader(BuildContext context, UserProfile user) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        children: [
          // Avatar and info
          Row(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                  user.name.isNotEmpty ? user.name.substring(0, 1) : '?',
                  style: TextStyle(
                    fontSize: 32,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      user.department,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (user.grade.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Text(
                          user.grade,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              // Edit profile button
              if (user.id != 'guest')
                IconButton(
                  icon: Icon(Icons.edit_outlined),
                  onPressed: () {
                    // TODO: Navigate to profile edit
                  },
                ),
            ],
          ),
          
          // Stats
          if (user.id != 'guest')
            Padding(
              padding: EdgeInsets.only(top: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat('5', '已发布'),
                  _buildStat('12', '收藏'),
                  _buildStat('8', '关注'),
                ],
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildStat(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ],
    );
  }
  
  Widget _buildQuickActions(BuildContext context) {
    return Container(
      color: Colors.white,
      margin: EdgeInsets.only(top: 10),
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildQuickAction(
            context,
            Icons.add_circle_outline,
            '发布物品',
            () {
              Navigator.pushNamed(context, '/create-item');
            },
          ),
          _buildQuickAction(
            context,
            Icons.upload_file,
            '上传资料',
            () {
              // TODO: Navigate to create material screen
            },
          ),
          _buildQuickAction(
            context,
            Icons.calendar_today_outlined,
            '我的活动',
            () {
              // TODO: Navigate to my events
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuickAction(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(
            icon,
            color: Theme.of(context).primaryColor,
            size: 28,
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMenuSection(
    BuildContext context,
    String title,
    List<MenuItem> items,
  ) {
    return Container(
      color: Colors.white,
      margin: EdgeInsets.only(top: 10),
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ),
          ...items.map((item) => _buildMenuItem(context, item)).toList(),
        ],
      ),
    );
  }
  
  Widget _buildMenuItem(BuildContext context, MenuItem item) {
    return InkWell(
      onTap: item.onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              item.icon,
              color: Colors.grey[600],
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                item.title,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[800],
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}

class MenuItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  
  MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });
}