// lib/features/community/screens/post_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/post_model.dart';
import '../../../core/constants/app_theme.dart';
import '../models/comment_model.dart'; // Add this line to import the Comment model

class PostDetailScreen extends StatefulWidget {
  final Post post;

  const PostDetailScreen({Key? key, required this.post}) : super(key: key);

  @override
  _PostDetailScreenState createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  late List<Comment> _comments;

  @override
  void initState() {
    super.initState();
    _comments = widget.post.comments;
  }

  void _addComment() {
    if (_commentController.text.trim().isNotEmpty) {
      final newComment = Comment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        postId: widget.post.id,
        userId: 'current_user_id', // 替换为实际用户ID
        username: 'current_username', // 替换为实际用户名
        commentTime: DateTime.now(),
        content: _commentController.text.trim(),
        likes: 0,
      );

      setState(() {
        _comments.insert(0, newComment);
        _commentController.clear();
      });
    }
  }

  void _toggleCommentLike(int index) {
    setState(() {
      final comment = _comments[index];
      _comments[index] = comment.copyWith(
        likes: comment.isLiked ? comment.likes - 1 : comment.likes + 1,
        isLiked: !comment.isLiked,
      );
    });
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy年MM月dd日 HH:mm').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryColor = AppTheme.categoryColors[widget.post.category] ?? theme.primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: Text('帖子详情'),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              // 分享功能
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 帖子主体内容（可以复用PostCard的部分组件）
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundImage: widget.post.userAvatar != null 
                                  ? AssetImage(widget.post.userAvatar!) 
                                  : null,
                              backgroundColor: Colors.grey.shade200,
                            ),
                            SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.post.username,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _formatDateTime(widget.post.postTime),
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          widget.post.content,
                          style: theme.textTheme.bodyLarge,
                        ),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: categoryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: categoryColor),
                              ),
                              child: Text(
                                widget.post.category,
                                style: TextStyle(
                                  color: categoryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            ...widget.post.tags.map((tag) => _buildTagChip(tag)).toList(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Divider(thickness: 1, height: 1),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      '评论 (${_comments.length})',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final comment = _comments[index];
                      return _buildCommentItem(comment, index);
                    },
                    childCount: _comments.length,
                  ),
                ),
              ],
            ),
          ),
          _buildCommentInputArea(),
        ],
      ),
    );
  }

  Widget _buildCommentItem(Comment comment, int index) {
    final theme = Theme.of(context);
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: comment.userAvatar != null 
            ? AssetImage(comment.userAvatar!) 
            : null,
        backgroundColor: Colors.grey.shade200,
        child: comment.userAvatar == null 
            ? Icon(Icons.person, size: 20, color: Colors.grey) 
            : null,
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            comment.username,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            comment.content,
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Row(
          children: [
            Text(
              _formatDateTime(comment.commentTime),
              style: theme.textTheme.bodySmall,
            ),
            Spacer(),
            IconButton(
              icon: Icon(
                comment.isLiked ? Icons.favorite : Icons.favorite_border,
                color: comment.isLiked ? Colors.red : null,
                size: 18,
              ),
              onPressed: () => _toggleCommentLike(index),
            ),
            Text(
              comment.likes.toString(),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentInputArea() {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              offset: Offset(0, -2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: '发表你的评论...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                maxLines: null,
              ),
            ),
            SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.send, color: Theme.of(context).primaryColor),
              onPressed: _addComment,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagChip(String tag) {
    return Container(
      margin: EdgeInsets.only(right: 4),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '#$tag',
        style: TextStyle(
          color: Colors.grey.shade700,
          fontSize: 12,
        ),
      ),
    );
  }
}