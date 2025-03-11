// lib/screens/create_post_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/post_provider.dart';
import '../../../core/constants/app_theme.dart';

class CreatePostScreen extends StatefulWidget {
  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedCategory = '二手交易';
  bool _isLoading = false;
  
  final List<String> _categories = [
    '二手交易',
    '兼职/需求',
    '活动组队',
    '畅言/其他',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _submitPost() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('请输入标题')),
      );
      return;
    }
    
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('请输入内容')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await Provider.of<PostProvider>(context, listen: false).createPost(
        title: title,
        content: content,
        category: _selectedCategory,
      );
      
      Navigator.of(context).pop(); // 返回上一页
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('发布失败: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('发布新帖'),
        backgroundColor: AppTheme.primaryColor,
        centerTitle: true,
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _submitPost,
              child: Text(
                '发布',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 选择分类
                  Text(
                    '选择分类',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _categories.map((category) {
                      final isSelected = _selectedCategory == category;
                      final color = AppTheme.categoryColors[category] ?? AppTheme.primaryColor;
                      
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? color : color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: color,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              color: isSelected ? Colors.white : color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 25),
                  
                  // 标题输入
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: '标题',
                      hintText: '请输入帖子标题(不超过30字)',
                      border: OutlineInputBorder(),
                    ),
                    maxLength: 30,
                  ),
                  SizedBox(height: 20),
                  
                  // 内容输入
                  TextField(
                    controller: _contentController,
                    decoration: InputDecoration(
                      labelText: '内容',
                      hintText: '请输入帖子内容(不超过500字)',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 10,
                    maxLength: 500,
                  ),
                  
                  SizedBox(height: 20),
                  
                  // 提示
                  Card(
                    color: Colors.amber.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.amber.shade800,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '发布后，系统会为您生成随机马甲名，确保您的隐私安全',
                              style: TextStyle(
                                color: Colors.amber.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

