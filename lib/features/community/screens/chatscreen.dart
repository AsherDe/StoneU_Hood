// lib/features/community/screens/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_model.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late ChatModel _chatModel;
  types.Room? _selectedRoom;
  final String _selfUserId = const Uuid().v4(); // 临时用户ID，实际应使用登录用户ID

  @override
  void initState() {
    super.initState();
    
    // 初始化聊天模型
    _chatModel = ChatModel(_selfUserId);
    
    // 添加一些测试聊天室
    _addDemoRooms();
  }

  void _addDemoRooms() {
    // 添加几个演示聊天室
    _chatModel.createOrGetRoom('user1', '张同学', null);
    _chatModel.createOrGetRoom('user2', '李同学', null);
    _chatModel.createOrGetRoom('user3', '王老师', null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('消息'),
      ),
      body: Row(
        children: [
          // 聊天室列表
          Expanded(
            flex: 1,
            child: _buildRoomList(),
          ),
          
          // 分隔线
          VerticalDivider(width: 1, thickness: 1, color: Colors.grey[300]),
          
          // 聊天区域
          Expanded(
            flex: 2,
            child: _selectedRoom == null
                ? Center(child: Text('选择一个聊天开始交流'))
                : _buildChatArea(),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomList() {
    return ListView.builder(
      itemCount: _chatModel.rooms.length,
      itemBuilder: (context, index) {
        final room = _chatModel.rooms[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blue,
            child: Text(room.name?[0] ?? '?'),
          ),
          title: Text(room.name ?? '未命名'),
          subtitle: room.lastMessages?.isNotEmpty == true
              ? Text(
                  (room.lastMessages!.first as types.TextMessage).text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          selected: _selectedRoom?.id == room.id,
          onTap: () {
            setState(() {
              _selectedRoom = room;
            });
          },
        );
      },
    );
  }

  Widget _buildChatArea() {
    if (_selectedRoom == null) return Container();
    
    final messages = _chatModel.getMessages(_selectedRoom!.id);
    
    return Column(
      children: [
        // 聊天头部
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue,
                child: Text(_selectedRoom!.name?[0] ?? '?'),
              ),
              SizedBox(width: 12),
              Text(
                _selectedRoom!.name ?? '未命名',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        
        // 聊天消息列表区域
        Expanded(
          child: Chat(
            messages: messages,
            onSendPressed: _handleSendPressed,
            user: types.User(id: _selfUserId),
            theme: DefaultChatTheme(
              inputBackgroundColor: Colors.grey[200]!,
              primaryColor: Theme.of(context).primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  void _handleSendPressed(types.PartialText message) {
    if (_selectedRoom == null) return;
    
    _chatModel.sendMessage(_selectedRoom!.id, message.text);
    setState(() {}); // 刷新UI
  }
}