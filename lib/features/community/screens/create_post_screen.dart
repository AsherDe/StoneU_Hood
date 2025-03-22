// lib/screens/create_post_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/post_provider.dart';
import '../../../core/constants/app_theme.dart';
import '../../calendar/services/timetable_webview.dart';
import '../services/auth_service.dart';

class CreatePostScreen extends StatefulWidget {
  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _authService = AuthService();

  bool _timetableVerified = false; // 是否已验证身份
  bool _isLoading = false; // 是否正在加载

  String _selectedCategory = '二手交易';

  // 二手交易相关字段
  final _priceController = TextEditingController();
  final _conditionController = TextEditingController();
  final _usageYearsController = TextEditingController();
  final _tradeLinkController = TextEditingController();

  // 校园招聘相关字段
  final _talentTypeController = TextEditingController();
  final _skillsRequiredController = TextEditingController();
  final _salaryController = TextEditingController();

  // 活动组队相关字段
  final _activityNameController = TextEditingController();
  final _teamRequirementsController = TextEditingController();

  final List<String> _categories = ['二手交易', '校园招聘', '活动组队', '畅言/其他'];

  @override
  void initState() {
    super.initState();
    _checkTimetableVerification();
  }

  // 检查课表验证
  Future<void> _checkTimetableVerification() async {
    final isVerified = await _authService.isTimetableVerified();
    setState(() {
      _timetableVerified = isVerified;
    });
  }

  // 显示验证对话框
  void _showTimetableVerificationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Text('需要验证身份'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('为了确保您是本校学生，需要您先通过教务系统课表验证身份。'),
                SizedBox(height: 10),
                Text(
                  '点击"去验证"按钮，通过导入您的课程表来验证身份。',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),

            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('取消'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _navigateToTimetableVerification();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
                child: Text('去验证'),
              ),
            ],
          ),
    );
  }

  // 导航到课表验证页面
  void _navigateToTimetableVerification() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => TimetableWebView(
              onEventsImported: (events) async {
                if (events.isNotEmpty) {
                  await _checkTimetableVerification();
                  if (_timetableVerified) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('身份验证成功！您现在可以发布帖子')));
                  }
                }
              },
              isVerification: true,
            ),
      ),
    );
  }

  // 释放资源
  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();

    // 二手交易
    _priceController.dispose();
    _conditionController.dispose();
    _usageYearsController.dispose();
    _tradeLinkController.dispose();

    // 校园招聘
    _talentTypeController.dispose();
    _skillsRequiredController.dispose();
    _salaryController.dispose();

    // 活动组队
    _activityNameController.dispose();
    _teamRequirementsController.dispose();

    super.dispose();
  }

  // 根据选择的类别格式化内容
  String _formatContent() {
    String formattedContent = '';

    switch (_selectedCategory) {
      case '二手交易':
        formattedContent = '''
【商品简述】${_titleController.text}
【价格】${_priceController.text}
【物品状况】${_conditionController.text}
【使用年限】${_usageYearsController.text}
【详细描述】
${_contentController.text}
${_tradeLinkController.text.isNotEmpty ? "【交易链接】${_tradeLinkController.text}" : ""}
''';
        break;

      case '校园招聘':
        formattedContent = '''
【招聘需求】${_titleController.text}
【需要人才类别】${_talentTypeController.text}
【所需专业知识】${_skillsRequiredController.text}
【薪酬】${_salaryController.text}
【详细描述】
${_contentController.text}
''';
        break;

      case '活动组队':
        formattedContent = '''
【活动名称】${_activityNameController.text}
【搭档要求】${_teamRequirementsController.text}
【详细描述】
${_contentController.text}
''';
        break;

      case '畅言/其他':
      default:
        formattedContent = _contentController.text;
        break;
    }

    return formattedContent;
  }

  // 提交帖子
  void _submitPost() async {
    final title = _titleController.text.trim();
    // 检查身份验证
    if (!_timetableVerified) {
      _showTimetableVerificationDialog();
      return;
    }

    // 基本验证
    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('请输入标题')));
      return;
    }

    // 针对不同类别的表单验证
    if (_selectedCategory == '二手交易') {
      if (_priceController.text.trim().isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('请输入价格')));
        return;
      }
    } else if (_selectedCategory == '校园招聘') {
      if (_talentTypeController.text.trim().isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('请输入需要的人才类别')));
        return;
      }
    } else if (_selectedCategory == '活动组队') {
      if (_activityNameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('请输入活动名称')));
        return;
      }
    } else if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('请输入内容')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 格式化内容
      final formattedContent = _formatContent();

      await Provider.of<PostProvider>(context, listen: false).createPost(
        title: title,
        content: formattedContent,
        category: _selectedCategory,
      );

      Navigator.of(context).pop(); // 返回上一页
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('发布失败: $e')));
    }
  }

  // 根据选择的类别返回对应的表单字段
  Widget _buildCategoryFields() {
    switch (_selectedCategory) {
      case '二手交易':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题输入
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: '标题',
                hintText: '简短描述您需要出售的物品',
                border: OutlineInputBorder(),
              ),
              maxLength: 30,
            ),
            SizedBox(height: 15),

            // 价格输入
            TextField(
              controller: _priceController,
              decoration: InputDecoration(
                labelText: '价格',
                hintText: '请输入您的期望价格',
                border: OutlineInputBorder(),
                prefixText: '¥ ',
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 15),

            // 物品状况
            TextField(
              controller: _conditionController,
              decoration: InputDecoration(
                labelText: '物品状况',
                hintText: '例如：全新/9成新/有使用痕迹等',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 15),

            // 使用年限
            TextField(
              controller: _usageYearsController,
              decoration: InputDecoration(
                labelText: '使用年限',
                hintText: '例如：2个月/1年半等',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 15),

            // 详细描述
            TextField(
              controller: _contentController,
              decoration: InputDecoration(
                labelText: '详细描述',
                hintText: '详细描述物品情况，是否有损坏等',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              maxLength: 300,
            ),
            SizedBox(height: 15),

            // 交易链接（可选）
            TextField(
              controller: _tradeLinkController,
              decoration: InputDecoration(
                labelText: '交易链接（可选）',
                hintText: '其他平台链接等',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        );

      case '校园招聘':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题输入
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: '标题',
                hintText: '请输入招聘/需求标题',
                border: OutlineInputBorder(),
              ),
              maxLength: 30,
            ),
            SizedBox(height: 15),

            // 人才类别
            TextField(
              controller: _talentTypeController,
              decoration: InputDecoration(
                labelText: '需要人才类别',
                hintText: '例如：设计师/程序员/市场营销等',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 15),

            // 专业知识
            TextField(
              controller: _skillsRequiredController,
              decoration: InputDecoration(
                labelText: '所需专业知识',
                hintText: '例如：熟悉PhotoShop/Flutter开发等',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            SizedBox(height: 15),

            // 薪酬
            TextField(
              controller: _salaryController,
              decoration: InputDecoration(
                labelText: '薪酬',
                hintText: '例如：20元/小时，1000元/项目等',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 15),

            // 详细描述
            TextField(
              controller: _contentController,
              decoration: InputDecoration(
                labelText: '详细描述',
                hintText: '详细描述工作内容、要求、联系方式等',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              maxLength: 300,
            ),
          ],
        );

      case '活动组队':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题输入
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: '标题',
                hintText: '请输入组队标题',
                border: OutlineInputBorder(),
              ),
              maxLength: 30,
            ),
            SizedBox(height: 15),

            // 活动名称
            TextField(
              controller: _activityNameController,
              decoration: InputDecoration(
                labelText: '活动名称',
                hintText: '例如：篮球赛/团购/旅行等',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 15),

            // 搭档要求
            TextField(
              controller: _teamRequirementsController,
              decoration: InputDecoration(
                labelText: '搭档要求',
                hintText: '例如：会打篮球/有驾照/喜欢摄影等',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            SizedBox(height: 15),

            // 详细描述
            TextField(
              controller: _contentController,
              decoration: InputDecoration(
                labelText: '详细描述',
                hintText: '详细描述活动内容、时间地点、要求等',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              maxLength: 300,
            ),
          ],
        );

      case '畅言/其他':
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题输入
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: '标题',
                hintText: '请输入帖子标题',
                border: OutlineInputBorder(),
              ),
              maxLength: 30,
            ),
            SizedBox(height: 15),

            // 内容输入
            TextField(
              controller: _contentController,
              decoration: InputDecoration(
                labelText: '内容',
                hintText: '请输入帖子内容',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 10,
              maxLength: 500,
            ),
          ],
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
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      color: Colors.red.shade50,
                      margin: EdgeInsets.only(bottom: 20),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Row(
                          children: [
                            Icon(Icons.warning, color: Colors.red),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '发帖前需要验证您的学生身份',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                            TextButton(
                              onPressed: _navigateToTimetableVerification,
                              child: Text('去验证'),
                            ),
                          ],
                        ),
                      ),
                    ),
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
                      children:
                          _categories.map((category) {
                            final isSelected = _selectedCategory == category;
                            final color =
                                AppTheme.categoryColors[category] ??
                                AppTheme.primaryColor;

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
                                  color:
                                      isSelected
                                          ? color
                                          : color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: color, width: 1),
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

                    // 动态渲染不同类别的表单
                    _buildCategoryFields(),

                    SizedBox(height: 20),

                    // 预览帖子内容
                    if (_selectedCategory != '畅言/其他' &&
                        (_titleController.text.isNotEmpty ||
                            _contentController.text.isNotEmpty))
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Divider(),
                          Text(
                            '帖子预览',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Text(
                              _formatContent(),
                              style: TextStyle(fontSize: 14, height: 1.5),
                            ),
                          ),
                          SizedBox(height: 20),
                        ],
                      ),

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
                                style: TextStyle(color: Colors.amber.shade800),
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
