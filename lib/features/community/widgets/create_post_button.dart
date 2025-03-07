// widgets/create_post_button.dart - 创建帖子按钮
import 'package:flutter/material.dart';

class CreatePostButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        _showCreatePostBottomSheet(context);
      },
      child: Icon(Icons.add),
      tooltip: '发布帖子',
    );
  }

  void _showCreatePostBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 标题
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '发布新帖子',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                
                SizedBox(height: 16),
                
                // 帖子分类选择
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: '选择分类',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    '二手交易',
                    '提问区',
                    '工作交流区',
                    '游戏交流区',
                    '交友交流区',
                  ].map((category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {},
                ),
                
                SizedBox(height: 16),
                
                // 内容输入框
                TextField(
                  decoration: InputDecoration(
                    hintText: '分享你的想法...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 5,
                ),
                
                SizedBox(height: 16),
                
                // 底部按钮
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.image),
                      onPressed: () {
                        // 添加图片
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.tag),
                      onPressed: () {
                        // 添加标签
                      },
                    ),
                    Spacer(),
                    ElevatedButton(
                      onPressed: () {
                        // 发布帖子逻辑
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('帖子发布成功')),
                        );
                      },
                      child: Text('发布'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}