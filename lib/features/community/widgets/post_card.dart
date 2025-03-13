// lib/widgets/post_card.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/post.dart';
import '../providers/post_provider.dart';
import '../providers/chat_provider.dart';
import '../screens/comment_screen.dart';
import '../../../core/constants/app_theme.dart';
import '../screens/chat_screen.dart';

class PostCard extends StatelessWidget {
  final Post post;

  PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: EdgeInsets.only(bottom: 15),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 分类标签
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.categoryColors[post.category] ?? AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                post.category,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 10),
            
            // 帖子标题
            Text(
              post.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 10),
            
            // 帖子内容
            Text(
              post.content,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            SizedBox(height: 15),
            
            // 发帖人马甲名和发布时间
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '来自：${post.vestName}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  _formatTimestamp(post.createdAt),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            
            Divider(height: 25),
            
            // 交互按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(
                  context, 
                  icon: Icons.thumb_up_outlined,
                  label: '点赞',
                  isActive: post.isLiked,
                  onPressed: () => _handleLike(context),
                ),
                _buildActionButton(
                  context, 
                  icon: Icons.comment_outlined,
                  label: '评论',
                  onPressed: () => _navigateToComments(context),
                ),
                _buildActionButton(
                  context, 
                  icon: Icons.chat_outlined,
                  label: '私聊',
                  onPressed: () => _startPrivateChat(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? AppTheme.primaryColor : Colors.grey,
            ),
            SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppTheme.primaryColor : Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _handleLike(BuildContext context) async {
    try {
      await Provider.of<PostProvider>(context, listen: false).toggleLike(post.id);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('操作失败: $e')),
      );
    }
  }
  
  void _navigateToComments(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CommentScreen(postId: post.id),
      ),
    );
  }
  
  void _startPrivateChat(BuildContext context) async {
    try {
      final chatId = await Provider.of<ChatProvider>(context, listen: false)
          .createPrivateChat(post.userId, post.vestName);
          
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatId: chatId,
            receiverVestName: post.vestName,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('创建私聊失败: $e')),
      );
    }
  }
  
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }
}