// lib/screens/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../models/message.dart';
import '../../../core/constants/app_theme.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String receiverVestName;
  final String postId;
  
  const ChatScreen({super.key, 
    required this.chatId,
    required this.receiverVestName,
    required this.postId,
  });
  
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoading = false;
  bool _isSending = false;
  List<Message> _messages = [];
  
  @override
  void initState() {
    super.initState();
    _loadMessages();
    // 添加实时消息监听
    Provider.of<ChatProvider>(context, listen: false)
        .startMessageListener(widget.chatId, _onNewMessage);
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    // 移除实时消息监听
    Provider.of<ChatProvider>(context, listen: false)
        .stopMessageListener();
    super.dispose();
  }
  
  void _onNewMessage(Message message) {
    setState(() {
      _messages.insert(0, message);
    });
    _scrollToBottom();
  }
  
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
  
  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final messages = await Provider.of<ChatProvider>(context, listen: false)
          .fetchMessages(widget.chatId);
          
      setState(() {
        _messages = messages;
      });
      
      _scrollToBottom();
    } catch (e) {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('获取消息失败: $e')),
      // );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    
    if (content.isEmpty) {
      return;
    }
    
    setState(() {
      _isSending = true;
    });
    
    try {
      await Provider.of<ChatProvider>(context, listen: false)
          .sendMessage(widget.chatId, content);
          
      _messageController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('发送消息失败: $e')),
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
    _loadMessages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receiverVestName),
        backgroundColor: AppTheme.primaryColor,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 消息列表
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(child: Text('暂无消息，开始聊天吧'))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.all(10),
                        reverse: true, // 从底部开始显示
                        itemCount: _messages.length,
                        itemBuilder: (ctx, index) {
                          final message = _messages[index];
                          return _buildMessageItem(message);
                        },
                      ),
          ),
          
          // 消息输入框
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
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: '发送消息...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 10,
                      ),
                    ),
                    maxLength: 500,
                    buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
                      return null; // 隐藏字数统计
                    },
                  ),
                ),
                SizedBox(width: 10),
                _isSending
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
                        onPressed: _sendMessage,
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMessageItem(Message message) {
    final isSentByMe = message.isSentByMe;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: isSentByMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isSentByMe) ...[
            CircleAvatar(
              backgroundColor: AppTheme.secondaryColor,
              radius: 16,
              child: Text(
                widget.receiverVestName.characters.first,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            SizedBox(width: 10),
          ],
          
          Flexible(
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSentByMe
                    ? AppTheme.primaryColor
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isSentByMe ? Colors.white : Colors.black,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    _formatTimestamp(message.createdAt),
                    style: TextStyle(
                      color: isSentByMe
                          ? Colors.white.withOpacity(0.7)
                          : Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (isSentByMe) ...[
            SizedBox(width: 10),
            CircleAvatar(
              backgroundColor: AppTheme.primaryColor,
              radius: 16,
              child: Text(
                '我',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}