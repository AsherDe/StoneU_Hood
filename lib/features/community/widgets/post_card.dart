// widgets/post_card.dart - 帖子卡片
import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../theme/app_theme.dart';
import 'package:timeago/timeago.dart' as timeago;

class PostCard extends StatefulWidget {
  final Post post;

  const PostCard({Key? key, required this.post}) : super(key: key);

  @override
  _PostCardState createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _isLiked = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 获取分类对应的颜色
    final categoryColor = AppTheme.categoryColors[widget.post.category] ?? 
        theme.primaryColor;
        
    // 格式化发布时间
    final postTimeStr = timeago.format(widget.post.postTime, locale: 'zh');
    
    // 富文本处理内容中的标签
    final contentWidgets = _buildRichText(widget.post.content);

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 用户信息和发布时间
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.post.username,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        postTimeStr,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                // 问题奖励
                if (widget.post.rewardAmount != null)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.amber),
                    ),
                    child: Text(
                      '¥${widget.post.rewardAmount}',
                      style: TextStyle(
                        color: Colors.amber.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            
            SizedBox(height: 12),
            
            // 帖子内容
            ...contentWidgets,
            
            SizedBox(height: 12),
            
            // 分类标签
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
            
            SizedBox(height: 12),
            
            // 帖子交互按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(
                  icon: _isLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                  label: widget.post.likes.toString(),
                  color: _isLiked ? theme.primaryColor : null,
                  onTap: () {
                    setState(() {
                      _isLiked = !_isLiked;
                      widget.post.likes += _isLiked ? 1 : -1;
                    });
                  },
                ),
                _buildActionButton(
                  icon: Icons.chat_bubble_outline,
                  label: widget.post.comments.toString(),
                  onTap: () {
                    // 打开评论区
                  },
                ),
                _buildActionButton(
                  icon: Icons.share_outlined,
                  label: widget.post.shares.toString(),
                  onTap: () {
                    // 分享功能
                    setState(() {
                      widget.post.shares += 1;
                    });
                  },
                ),
              ],
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

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    Color? color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color ?? Colors.grey.shade700),
            SizedBox(width: 4),
            Text(label, style: TextStyle(color: color ?? Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRichText(String content) {
    // 分析内容中的标签和链接
    List<Widget> widgets = [];
    
    // 简单的解析内容
    String plainText = content;
    
    // 替换#标签为蓝色文本
    final tagRegex = RegExp(r'#(\w+)');
    final tagMatches = tagRegex.allMatches(content);
    
    // 如果没有标签，直接返回普通文本
    if (tagMatches.isEmpty) {
      widgets.add(Text(
        plainText,
        style: TextStyle(fontSize: 16),
      ));
      return widgets;
    }
    
    // 拆分并处理带有标签的文本
    int lastIndex = 0;
    for (final match in tagMatches) {
      // 添加标签前的普通文本
      if (match.start > lastIndex) {
        widgets.add(Text(
          content.substring(lastIndex, match.start),
          style: TextStyle(fontSize: 16),
        ));
      }
      
      // 添加带颜色的标签
      widgets.add(Text(
        content.substring(match.start, match.end),
        style: TextStyle(
          color: Colors.blue,
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ));
      
      lastIndex = match.end;
    }
    
    // 添加最后部分的普通文本
    if (lastIndex < content.length) {
      widgets.add(Text(
        content.substring(lastIndex),
        style: TextStyle(fontSize: 16),
      ));
    }
    
    return widgets;
  }
}
