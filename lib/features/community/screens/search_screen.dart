// lib/screens/search_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/post_provider.dart';
import '../widgets/post_card.dart';
import '../../../core/constants/app_theme.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _debouncer = Debouncer(milliseconds: 500);
  bool _isSearching = false;
  String _selectedCategory = '全部';
  
  final List<String> _categories = [
    '全部',
    '二手交易',
    '兼职/需求',
    '活动组队',
    '畅言/其他',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() async {
    final query = _searchController.text.trim();
    
    if (query.isEmpty && _selectedCategory == '全部') {
      return;
    }
    
    setState(() {
      _isSearching = true;
    });
    
    try {
      await Provider.of<PostProvider>(context, listen: false).searchPosts(
        query: query,
        category: _selectedCategory == '全部' ? null : _selectedCategory,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('搜索失败: $e')),
      );
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = Provider.of<PostProvider>(context).searchResults;
    final hasPerformedSearch = Provider.of<PostProvider>(context).hasPerformedSearch;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('搜索'),
        backgroundColor: AppTheme.primaryColor,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 搜索栏
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '搜索帖子...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 0),
                  ),
                  onChanged: (value) {
                    _debouncer.run(() {
                      _performSearch();
                    });
                  },
                ),
                SizedBox(height: 10),
                
                // 分类筛选
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((category) {
                      final isSelected = _selectedCategory == category;
                      final color = category == '全部'
                          ? AppTheme.primaryColor
                          : AppTheme.categoryColors[category] ?? AppTheme.primaryColor;
                      
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(category),
                          selected: isSelected,
                          selectedColor: color,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedCategory = category;
                              });
                              _performSearch();
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          
          // 搜索结果
          Expanded(
            child: _isSearching
                ? Center(child: CircularProgressIndicator())
                : !hasPerformedSearch
                    ? Center(child: Text('输入关键词搜索帖子'))
                    : searchResults.isEmpty
                        ? Center(child: Text('未找到匹配的帖子'))
                        : ListView.builder(
                            padding: EdgeInsets.all(10),
                            itemCount: searchResults.length,
                            itemBuilder: (ctx, index) {
                              final post = searchResults[index];
                              return PostCard(post: post);
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

// 防抖类
class Debouncer {
  final int milliseconds;
  VoidCallback? action;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  run(VoidCallback action) {
    if (_timer != null) {
      _timer!.cancel();
    }
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
}