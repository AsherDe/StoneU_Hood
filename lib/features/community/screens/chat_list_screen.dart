// lib/screens/chat_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../models/chat.dart';
import '../../../core/constants/app_theme.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _loadChats();
  }
  
  Future<void> _loadChats() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await Provider.of<ChatProvider>(context, listen: false).fetchChats();
    } catch (e) {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('获取聊天列表失败: $e')),
      // );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _refreshChats() async {
    await Provider.of<ChatProvider>(context, listen: false).fetchChats();
  }

  @override
  Widget build(BuildContext context) {
    final chatList = Provider.of<ChatProvider>(context).chats;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('我的私信'),
        backgroundColor: AppTheme.primaryColor,
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshChats,
              child: chatList.isEmpty
                  ? Center(child: Text('暂无私信'))
                  : ListView.builder(
                      padding: EdgeInsets.all(10),
                      itemCount: chatList.length,
                      itemBuilder: (ctx, index) {
                        final chat = chatList[index];
                        return _buildChatItem(chat);
                      },
                    ),
            ),
    );
  }
  
  Widget _buildChatItem(Chat chat) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      margin: EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                chatId: chat.id,
                receiverVestName: chat.otherVestName,
                postId: chat.postId,
              ),
            ),
          ).then((_) => _refreshChats());
        },
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primaryColor,
                child: Text(
                  chat.otherVestName.characters.first,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          chat.otherVestName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          _formatTimestamp(chat.lastMessageTime),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    SizedBox(height: 5),
                    Text(
                      chat.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: chat.unreadCount > 0
                            ? Colors.black
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              if (chat.unreadCount > 0)
                Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    chat.unreadCount.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));
    final messageDate = DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
    );
    
    if (messageDate == today) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == yesterday) {
      return '昨天';
    } else {
      return '${timestamp.month}月${timestamp.day}日';
    }
  }
}

