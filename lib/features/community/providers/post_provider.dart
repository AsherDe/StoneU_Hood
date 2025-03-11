// lib/providers/post_provider.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/post.dart';
import '../models/comment.dart';

class PostProvider with ChangeNotifier {
  final ApiService apiService = ApiService();
  List<Post> _posts = [];
  List<Post> _searchResults = [];
  bool _hasMorePosts = true;
  int _page = 1;
  bool _hasPerformedSearch = false;
  
  List<Post> get posts => [..._posts];
  List<Post> get searchResults => [..._searchResults];
  bool get hasMorePosts => _hasMorePosts;
  bool get hasPerformedSearch => _hasPerformedSearch;
  
  Future<void> fetchPosts() async {
    _page = 1;
    final response = await apiService.get('/posts?page=$_page&limit=10');
    
    _posts = (response['posts'] as List)
        .map((post) => Post.fromJson(post))
        .toList();
        
    _hasMorePosts = _posts.length >= 10;
    notifyListeners();
  }
  
  Future<void> refreshPosts() async {
    await fetchPosts();
  }
  
  Future<void> loadMorePosts() async {
    if (!_hasMorePosts) return;
    
    _page++;
    final response = await apiService.get('/posts?page=$_page&limit=10');
    
    final newPosts = (response['posts'] as List)
        .map((post) => Post.fromJson(post))
        .toList();
        
    _posts.addAll(newPosts);
    _hasMorePosts = newPosts.length >= 10;
    notifyListeners();
  }
  
  Future<void> searchPosts({String? query, String? category}) async {
    final queryParams = <String, String>{};
    
    if (query != null && query.isNotEmpty) {
      queryParams['query'] = query;
    }
    
    if (category != null && category.isNotEmpty) {
      queryParams['category'] = category;
    }
    
    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
        
    final response = await apiService.get('/posts/search?$queryString');
    
    _searchResults = (response['posts'] as List)
        .map((post) => Post.fromJson(post))
        .toList();
        
    _hasPerformedSearch = true;
    notifyListeners();
  }
  
  Future<void> createPost({
    required String title,
    required String content,
    required String category,
  }) async {
    final response = await apiService.post(
      '/posts',
      {
        'title': title,
        'content': content,
        'category': category,
      },
    );
    
    final newPost = Post.fromJson(response);
    _posts.insert(0, newPost);
    notifyListeners();
  }
  
  Future<void> toggleLike(String postId) async {
    await apiService.post('/posts/$postId/like', {});
    
    // 更新状态
    final index = _posts.indexWhere((post) => post.id == postId);
    if (index >= 0) {
      final post = _posts[index];
      final isLiked = !post.isLiked;
      
      _posts[index] = post.copyWith(
        isLiked: isLiked,
        likeCount: isLiked ? post.likeCount + 1 : post.likeCount - 1,
      );
      
      notifyListeners();
    }
    
    // 同时更新搜索结果中的帖子状态
    final searchIndex = _searchResults.indexWhere((post) => post.id == postId);
    if (searchIndex >= 0) {
      final post = _searchResults[searchIndex];
      final isLiked = !post.isLiked;
      
      _searchResults[searchIndex] = post.copyWith(
        isLiked: isLiked,
        likeCount: isLiked ? post.likeCount + 1 : post.likeCount - 1,
      );
    }
  }
  
  Future<List<Comment>> fetchComments(String postId) async {
    final response = await apiService.get('/posts/$postId/comments');
    
    return (response['comments'] as List)
        .map((comment) => Comment.fromJson(comment))
        .toList();
  }
  
  Future<Comment> addComment(String postId, String content) async {
    final response = await apiService.post(
      '/posts/$postId/comments',
      {'content': content},
    );
    
    // 更新评论数
    final index = _posts.indexWhere((post) => post.id == postId);
    if (index >= 0) {
      _posts[index] = _posts[index].copyWith(
        commentCount: _posts[index].commentCount + 1,
      );
      
      notifyListeners();
    }
    
    // 更新搜索结果中的评论数
    final searchIndex = _searchResults.indexWhere((post) => post.id == postId);
    if (searchIndex >= 0) {
      _searchResults[searchIndex] = _searchResults[searchIndex].copyWith(
        commentCount: _searchResults[searchIndex].commentCount + 1,
      );
    }
    
    return Comment.fromJson(response);
  }
}
