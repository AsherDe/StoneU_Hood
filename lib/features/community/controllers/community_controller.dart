// lib/features/community/controllers/community_controller.dart
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../../auth/providers/user_provider.dart';
import '../../auth/services/auth_service.dart';

class CommunityController extends ChangeNotifier {
  final Dio _dio = Dio();
  List<Post> _posts = [];
  bool _isLoading = false;
  String? _error;

  List<Post> get posts => _posts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  UserProvider? _userProvider;
  UserProvider? get currentUser => _userProvider;
  final AuthService _authService = AuthService();

  CommunityController() {
    _dio.options.baseUrl = 'https://your-api-endpoint.com/api';
    _dio.options.connectTimeout = Duration(seconds: 5);
    _dio.options.receiveTimeout = Duration(seconds: 3);
  }

  Future<void> initialize([UserProvider? userProvider]) async {
    _userProvider = userProvider;
    await fetchPosts();
  }

  Future<bool> checkUserVerification() async {
    if (_userProvider == null || _userProvider!.userId == null) {
      return false;
    }

    try {
      return await _authService.checkVerificationStatus(_userProvider!.userId!);
    } catch (e) {
      _setError('验证检查失败: $e');
      return false;
    }
  }

  Future<void> fetchPosts() async {
    _setLoading(true);

    try {
      final response = await _dio.get('/posts');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        _posts = data.map((json) => Post.fromJson(json)).toList();
        _setError(null);
      } else {
        _setError('Failed to load posts');
      }
    } catch (e) {
      _setError('Network error: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createPost(
    String content,
    String category,
    List<String> tags,
    UserProvider userProvider, {
    double? rewardAmount,
  }) async {
    // 检查用户是否已验证
    if (!userProvider.isVerified) {
      _setError('您需要通过日历验证才能发布内容。');
      return false;
    }

    _setLoading(true);

    try {
      final response = await _dio.post(
        '/posts',
        data: {
          'userId': userProvider.userId,
          'content': content,
          'category': category,
          'tags': tags,
          'rewardAmount': rewardAmount,
        },
      );

      _setLoading(false);

      if (response.statusCode == 201) {
        // 刷新帖子列表
        await fetchPosts();
        return true;
      } else {
        _setError('Failed to create post');
        return false;
      }
    } catch (e) {
      _setLoading(false);
      _setError('Network error: $e');
      return false;
    }
  }

  Future<bool> likePost(String postId, UserProvider userProvider) async {
    try {
      final response = await _dio.post(
        '/posts/$postId/like',
        data: {'userId': userProvider.userId},
      );

      if (response.statusCode == 200) {
        // 更新本地帖子状态
        final index = _posts.indexWhere((post) => post.id == postId);
        if (index != -1) {
          final post = _posts[index];
          _posts[index] = post.copyWith(likes: post.likes + 1, isLiked: true);
          notifyListeners();
        }
        return true;
      } else {
        return false;
      }
    } catch (e) {
      _setError('Network error: $e');
      return false;
    }
  }

  Future<bool> commentPost(
    String postId,
    String content,
    UserProvider userProvider,
  ) async {
    // 检查用户是否已验证
    if (!userProvider.isVerified) {
      _setError('您需要通过日历验证才能发表评论。');
      return false;
    }

    try {
      final response = await _dio.post(
        '/posts/$postId/comments',
        data: {'userId': userProvider.userId, 'content': content},
      );

      if (response.statusCode == 201) {
        // 更新本地帖子状态
        final index = _posts.indexWhere((post) => post.id == postId);
        if (index != -1) {
          final post = _posts[index];
          final newComment = Comment.fromJson(response.data);
          final updatedComments = List<Comment>.from(post.comments)
            ..add(newComment);

          _posts[index] = post.copyWith(
            comments: updatedComments,
            commentCount: post.commentCount + 1,
          );
          notifyListeners();
        }
        return true;
      } else {
        return false;
      }
    } catch (e) {
      _setError('Network error: $e');
      return false;
    }
  }

  // 辅助方法
  void _setLoading(bool isLoading) {
    _isLoading = isLoading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }
}
