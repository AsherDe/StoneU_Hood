// lib/features/community/services/post_service.dart
import '../models/post_model.dart';
import '../models/comment_model.dart';

class PostService {
  static List<Post> getDummyPosts() {
    return [
      Post(
        id: '1',
        userId: '101',
        username: '张同学',
        postTime: DateTime.now().subtract(Duration(hours: 2)),
        content: '有人对下周的数据结构考试有复习资料吗？#求助 #数据结构',
        category: '提问区',
        tags: ['求助', '数据结构'],
        likes: 15,
        commentCount: 3,
        shares: 2,
        comments: [
          Comment(
            id: 'c1',
            postId: '1',
            userId: '102',
            username: '李同学',
            commentTime: DateTime.now().subtract(Duration(hours: 1)),
            content: '我有，私聊给你发资料',
            likes: 2,
          ),
        ],
      ),
      Post(
        id: '2',
        userId: '103',
        username: '王同学',
        postTime: DateTime.now().subtract(Duration(days: 1)),
        content: '出二手自行车，九成新，有意私聊 #二手 #自行车',
        category: '二手交易',
        tags: ['二手', '自行车'],
        likes: 8,
        commentCount: 5,
        shares: 1,
        rewardAmount: 200.0,
      ),
      // 可以添加更多模拟数据
    ];
  }
}