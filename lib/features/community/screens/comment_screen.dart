// lib/screens/comment_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/post_provider.dart';
import '../models/comment.dart';
import '../../../core/constants/app_theme.dart';

class CommentScreen extends StatefulWidget {
  final String postId;
  
  const CommentScreen({super.key, required this.postId});
  
  @override
  _CommentScreenState createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final _commentController = TextEditingController();
  bool _isLoading = false;
  bool _isSubmitting = false;
  List<Comment> _comments = [];
  
  @override
  void initState() {
    super.initState();
    _loadComments();
  }
  
  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
  
  Future<void> _loadComments() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final comments = await Provider.of<PostProvider>(context, listen: false)
          .fetchComments(widget.postId);
          
      setState(() {
        _comments = comments;
      });
    } catch (e) {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('获取评论失败: $e')),
      // );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    
    if (content.isEmpty) {
      return;
    }
    
    setState(() {
      _isSubmitting = true;
    });
    
    try {
      final newComment = await Provider.of<PostProvider>(context, listen: false)
          .addComment(widget.postId, content);
          
      setState(() {
        _comments.insert(0, newComment);
        _commentController.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('发表评论失败: $e')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('评论'),
        backgroundColor: AppTheme.primaryColor,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 评论列表
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _comments.isEmpty
                    ? Center(child: Text('暂无评论，快来抢沙发吧~'))
                    : ListView.builder(
                        padding: EdgeInsets.all(10),
                        itemCount: _comments.length,
                        itemBuilder: (ctx, index) {
                          final comment = _comments[index];
                          return _buildCommentItem(comment);
                        },
                      ),
          ),
          
          // 评论输入框
          Container(
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 5,
                  offset: Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: '发表评论...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 10,
                      ),
                    ),
                    maxLength: 200,
                    buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
                      return null; // 隐藏字数统计
                    },
                  ),
                ),
                SizedBox(width: 10),
                _isSubmitting
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : IconButton(
                        icon: Icon(Icons.send),
                        color: AppTheme.primaryColor,
                        onPressed: _submitComment,
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCommentItem(Comment comment) {
    return Card(
      margin: EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  comment.vestName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                Text(
                  _formatTimestamp(comment.createdAt),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            SizedBox(height: 10),
            Text(
              comment.content,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
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