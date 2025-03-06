// widgets/profile_header.dart - 个人资料头部
import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  final String? avatar;
  final String nickname;
  final String signature;
  final int following;
  final int followers;
  final int likes;

  const ProfileHeader({
    Key? key,
    this.avatar,
    required this.nickname,
    required this.signature,
    required this.following,
    required this.followers,
    required this.likes,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 头像
          GestureDetector(
            onTap: () {
              // 查看大图或修改头像
            },
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: avatar != null ? AssetImage(avatar!) : null,
              child: avatar == null
                  ? Icon(Icons.person, size: 40, color: Colors.grey)
                  : null,
            ),
          ),
          
          SizedBox(height: 12),
          
          // 昵称
          Text(
            nickname,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          SizedBox(height: 4),
          
          // 个性签名
          Text(
            signature,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: 16),
          
          // 关注/粉丝/获赞统计
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem('关注', following),
              _buildDivider(),
              _buildStatItem('粉丝', followers),
              _buildDivider(),
              _buildStatItem('获赞', likes),
            ],
          ),
          
          SizedBox(height: 16),
          
          // 编辑资料按钮
          OutlinedButton.icon(
            onPressed: () {
              // 编辑资料
            },
            icon: Icon(Icons.edit),
            label: Text('编辑资料'),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int value) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.grey.shade300,
    );
  }
}