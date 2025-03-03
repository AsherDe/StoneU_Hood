// lib/features/community/screens/chat_screen.dart
import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatConversation> _conversations = [
    ChatConversation(
      userName: '张三',
      lastMessage: '请问这个东西还卖吗？',
      timestamp: DateTime.now().subtract(Duration(minutes: 5)),
      unreadCount: 1,
      userAvatar: null,
    ),
    ChatConversation(
      userName: '李四',
      lastMessage: '好的，明天给你带过去',
      timestamp: DateTime.now().subtract(Duration(hours: 2)),
      unreadCount: 0,
      userAvatar: null,
    ),
    ChatConversation(
      userName: '王五',
      lastMessage: '这本书什么时候能还给我？',
      timestamp: DateTime.now().subtract(Duration(days: 1)),
      unreadCount: 3,
      userAvatar: null,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '聊天',
          style: TextStyle(color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _conversations.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              itemCount: _conversations.length,
              itemBuilder: (context, index) {
                return _buildConversationTile(_conversations[index]);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            '暂无聊天记录',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '您可以通过查看商品或学习资料来联系用户',
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationTile(ChatConversation conversation) {
    return ListTile(
      leading: CircleAvatar(
        child: conversation.userAvatar != null
            ? Image.network(conversation.userAvatar!)
            : Text(conversation.userName.substring(0, 1)),
      ),
      title: Text(
        conversation.userName,
        style: TextStyle(
          fontWeight: conversation.unreadCount > 0
              ? FontWeight.bold
              : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        conversation.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: conversation.unreadCount > 0
              ? FontWeight.w500
              : FontWeight.normal,
          color: conversation.unreadCount > 0
              ? Colors.black87
              : Colors.grey.shade600,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatTimestamp(conversation.timestamp),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 4),
          if (conversation.unreadCount > 0)
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              child: Text(
                conversation.unreadCount.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailScreen(
              userName: conversation.userName,
            ),
          ),
        );
      },
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays == 0) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
      return weekdays[timestamp.weekday - 1];
    } else {
      return '${timestamp.month}/${timestamp.day}';
    }
  }
}

class ChatDetailScreen extends StatefulWidget {
  final String userName;

  const ChatDetailScreen({
    Key? key,
    required this.userName,
  }) : super(key: key);

  @override
  _ChatDetailScreenState createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Initialize with dummy messages
    _messages.addAll([
      ChatMessage(
        text: '你好，请问这个东西还卖吗？',
        isMe: false,
        timestamp: DateTime.now().subtract(Duration(minutes: 30)),
      ),
      ChatMessage(
        text: '是的，还在卖',
        isMe: true,
        timestamp: DateTime.now().subtract(Duration(minutes: 25)),
      ),
      ChatMessage(
        text: '价格可以便宜一点吗？',
        isMe: false,
        timestamp: DateTime.now().subtract(Duration(minutes: 20)),
      ),
      ChatMessage(
        text: '可以，你打算什么时候过来拿？',
        isMe: true,
        timestamp: DateTime.now().subtract(Duration(minutes: 15)),
      ),
      ChatMessage(
        text: '我明天有空，下午可以吗？',
        isMe: false,
        timestamp: DateTime.now().subtract(Duration(minutes: 10)),
      ),
    ]);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    
    setState(() {
      _messages.add(
        ChatMessage(
          text: _messageController.text.trim(),
          isMe: true,
          timestamp: DateTime.now(),
        ),
      );
      _messageController.clear();
    });
    
    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.userName,
          style: TextStyle(color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: () {
              // TODO: Show chat options
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.add_photo_alternate),
                    onPressed: () {
                      // TODO: Implement image sending
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: '输入消息...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade200,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (value) => _sendMessage(),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send),
                    color: Theme.of(context).primaryColor,
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            message.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isMe)
            CircleAvatar(
              radius: 16,
              child: Text(widget.userName.substring(0, 1)),
            ),
          if (!message.isMe) SizedBox(width: 8),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: message.isMe ? Theme.of(context).primaryColor : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.text,
                  style: TextStyle(
                    color: message.isMe ? Colors.white : Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _formatMessageTime(message.timestamp),
                  style: TextStyle(
                    fontSize: 10,
                    color: message.isMe ? Colors.white70 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          if (message.isMe) SizedBox(width: 8),
          if (message.isMe)
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                'Me',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatMessageTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}

class ChatConversation {
  final String userName;
  final String lastMessage;
  final DateTime timestamp;
  final int unreadCount;
  final String? userAvatar;

  ChatConversation({
    required this.userName,
    required this.lastMessage,
    required this.timestamp,
    required this.unreadCount,
    this.userAvatar,
  });
}

class ChatMessage {
  final String text;
  final bool isMe;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isMe,
    required this.timestamp,
  });
}

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile header with user info
            Container(
              padding: EdgeInsets.only(top: 48, bottom: 24),
              color: Theme.of(context).primaryColor,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Text(
                      '张',
                      style: TextStyle(
                        fontSize: 36,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '张同学',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '计算机科学与技术 2023级',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStatItem('5', '发布'),
                      Container(
                        height: 24,
                        width: 1,
                        color: Colors.white.withOpacity(0.3),
                        margin: EdgeInsets.symmetric(horizontal: 16),
                      ),
                      _buildStatItem('12', '收藏'),
                      Container(
                        height: 24,
                        width: 1,
                        color: Colors.white.withOpacity(0.3),
                        margin: EdgeInsets.symmetric(horizontal: 16),
                      ),
                      _buildStatItem('8', '关注'),
                    ],
                  ),
                ],
              ),
            ),
            
            // Action buttons
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Navigate to profile edit
                      },
                      icon: Icon(Icons.edit),
                      label: Text('编辑资料'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.grey.shade400),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Navigate to settings
                      },
                      icon: Icon(Icons.settings),
                      label: Text('设置'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // My items section
            _buildSection(
              title: '我的物品',
              icon: Icons.shopping_bag,
              onTap: () {
                // TODO: Navigate to my marketplace items
              },
            ),
            
            // My materials section
            _buildSection(
              title: '我的资料',
              icon: Icons.book,
              onTap: () {
                // TODO: Navigate to my study materials
              },
            ),
            
            // Favorites section
            _buildSection(
              title: '我的收藏',
              icon: Icons.favorite,
              onTap: () {
                // TODO: Navigate to favorites
              },
            ),
            
            // Messages section
            _buildSection(
              title: '我的消息',
              icon: Icons.mail,
              onTap: () {
                // TODO: Navigate to messages
              },
            ),
            
            // Calendar sync
            _buildSection(
              title: '日历同步',
              icon: Icons.calendar_today,
              subtitle: '同步社区活动到您的日历',
              onTap: () {
                // TODO: Open calendar sync settings
              },
            ),
            
            // Help and feedback
            _buildSection(
              title: '帮助与反馈',
              icon: Icons.help_outline,
              onTap: () {
                // TODO: Open help and feedback
              },
            ),
            
            // About
            _buildSection(
              title: '关于应用',
              icon: Icons.info_outline,
              onTap: () {
                // TODO: Open about dialog
              },
            ),
            
            SizedBox(height: 24),
            
            // Sign out button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: OutlinedButton(
                onPressed: () {
                  // TODO: Implement sign out
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
                  side: BorderSide(color: Colors.red.shade300),
                ),
              ),
            ),
            
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}