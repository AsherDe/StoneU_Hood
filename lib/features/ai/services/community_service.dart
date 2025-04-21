import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/post.dart';

class CommunityService {
  static const String baseUrl = 'http://127.0.0.1:8081/api';
  
  // 获取最新帖子列表
  Future<List<Post>> getRecentPosts({int limit = 5}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/posts?limit=$limit'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['posts'] as List)
            .map((post) => Post.fromJson(post))
            .toList();
      } else {
        throw Exception('获取帖子失败: ${response.statusCode}');
      }
    } catch (e) {
      print('获取最新帖子错误: $e');
      // 模拟数据，用于开发测试
      return _getSimulatedPosts(limit);
    }
  }

  // 创建新帖子
  Future<Post> createPost({
    required String title,
    required String content,
    required String category,
    List<String> tags = const [],
    String? imageUrl,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? 'anonymous';
      final userName = prefs.getString('user_name') ?? '匿名用户';
      
      final postData = {
        'title': title,
        'content': content,
        'category': category,
        'tags': tags,
        'authorId': userId,
        'authorName': userName,
      };
      
      if (imageUrl != null) {
        postData['imageUrl'] = imageUrl;
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/posts'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(postData),
      );

      if (response.statusCode == 201) {
        return Post.fromJson(json.decode(response.body));
      } else {
        throw Exception('创建帖子失败: ${response.statusCode}');
      }
    } catch (e) {
      print('创建帖子错误: $e');
      // 创建模拟帖子
      return _createSimulatedPost(
        title: title, 
        content: content, 
        category: category,
        tags: tags,
        imageUrl: imageUrl,
      );
    }
  }

  // 搜索帖子
  Future<List<Post>> searchPosts({
    String? query,
    String? category,
    int limit = 10,
  }) async {
    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
      };
      
      if (query != null && query.isNotEmpty) {
        queryParams['query'] = query;
      }
      
      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }
      
      final queryString = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');
          
      final response = await http.get(
        Uri.parse('$baseUrl/posts/search?$queryString'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['posts'] as List)
            .map((post) => Post.fromJson(post))
            .toList();
      } else {
        throw Exception('搜索帖子失败: ${response.statusCode}');
      }
    } catch (e) {
      print('搜索帖子错误: $e');
      // 返回模拟的搜索结果
      return _getSimulatedPosts(limit).where((post) {
        bool matches = true;
        
        if (query != null && query.isNotEmpty) {
          matches = post.title.toLowerCase().contains(query.toLowerCase()) ||
                    post.content.toLowerCase().contains(query.toLowerCase());
        }
        
        if (matches && category != null && category.isNotEmpty) {
          matches = post.category.toLowerCase() == category.toLowerCase();
        }
        
        return matches;
      }).toList();
    }
  }

  // 获取推荐帖子
  Future<List<Post>> getRecommendedPosts({
    required List<String> userInterests,
    int limit = 5,
  }) async {
    try {
      final queryParams = {
        'limit': limit.toString(),
        'interests': userInterests.join(','),
      };
      
      final queryString = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');
          
      final response = await http.get(
        Uri.parse('$baseUrl/posts/recommended?$queryString'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['posts'] as List)
            .map((post) => Post.fromJson(post))
            .toList();
      } else {
        throw Exception('获取推荐帖子失败: ${response.statusCode}');
      }
    } catch (e) {
      print('获取推荐帖子错误: $e');
      // 根据用户兴趣生成模拟推荐
      return _getSimulatedPosts(limit * 2).where((post) {
        return userInterests.any((interest) => 
          post.tags.any((tag) => tag.toLowerCase().contains(interest.toLowerCase())) ||
          post.category.toLowerCase().contains(interest.toLowerCase()) ||
          post.title.toLowerCase().contains(interest.toLowerCase())
        );
      }).take(limit).toList();
    }
  }

  // 获取用户的历史帖子
  Future<List<Post>> getUserPosts({int limit = 10}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? 'anonymous';
      
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId/posts?limit=$limit'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['posts'] as List)
            .map((post) => Post.fromJson(post))
            .toList();
      } else {
        throw Exception('获取用户帖子失败: ${response.statusCode}');
      }
    } catch (e) {
      print('获取用户帖子错误: $e');
      // 返回模拟的用户帖子
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString('user_name') ?? '匿名用户';
      
      return _getSimulatedPosts(limit * 2)
          .where((post) => post.authorName == userName)
          .take(limit)
          .toList();
    }
  }

  // ======== 辅助方法: 生成模拟数据 ========
  
  // 生成模拟帖子列表
  List<Post> _getSimulatedPosts(int count) {
    final List<Post> posts = [];
    final random = DateTime.now().millisecondsSinceEpoch;
    final categories = ['学习', '生活', '活动', '求助', '分享', '闲聊'];
    final authors = ['张三', '李四', '王五', '赵六', '钱七', '孙八'];
    
    for (int i = 0; i < count; i++) {
      final category = categories[i % categories.length];
      final authorName = authors[i % authors.length];
      
      posts.add(Post(
        id: 'post_${random}_$i',
        title: '${category}主题的帖子 #$i',
        content: '这是一条${category}相关的帖子内容，序号$i。包含详细信息和讨论内容。',
        authorId: 'user_$i',
        authorName: authorName,
        createdAt: DateTime.now().subtract(Duration(hours: i * 5)),
        category: category,
        likeCount: (i * 3) % 20,
        commentCount: (i * 2) % 15,
        isLiked: i % 3 == 0,
        tags: ['标签$i', category, '校园生活'],
        imageUrl: i % 4 == 0 ? 'https://picsum.photos/200/300?random=$i' : null,
      ));
    }
    
    return posts;
  }
  
  // 创建模拟帖子
  Future<Post> _createSimulatedPost({
    required String title,
    required String content,
    required String category,
    List<String> tags = const [],
    String? imageUrl,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString('user_name') ?? '匿名用户';
    
    return Post(
      id: 'post_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      content: content,
      authorId: 'local_user',
      authorName: userName,
      createdAt: DateTime.now(),
      category: category,
      likeCount: 0,
      commentCount: 0,
      isLiked: false,
      tags: tags,
      imageUrl: imageUrl,
    );
  }
  
  // 将帖子格式化为易读文本
  static String formatPostsToText(List<Post> posts) {
    if (posts.isEmpty) {
      return "没有找到相关帖子。";
    }
    
    final buffer = StringBuffer();
    buffer.writeln("找到 ${posts.length} 个帖子：\n");
    
    final dateFormat = DateFormat('MM月dd日 HH:mm');
    
    for (var i = 0; i < posts.length; i++) {
      final post = posts[i];
      final date = dateFormat.format(post.createdAt);
      
      buffer.writeln("${i + 1}. 【${post.category}】${post.title}");
      buffer.writeln("   作者: ${post.authorName} | 发布于: $date");
      
      // 截断内容，仅显示前60个字符
      String shortContent = post.content;
      if (shortContent.length > 60) {
        shortContent = shortContent.substring(0, 60) + "...";
      }
      buffer.writeln("   内容: $shortContent");
      
      if (post.tags.isNotEmpty) {
        buffer.writeln("   标签: ${post.tags.join(', ')}");
      }
      
      buffer.writeln("   👍 ${post.likeCount} | 💬 ${post.commentCount}\n");
    }
    
    return buffer.toString();
  }
}