import 'package:dio/dio.dart';
import '../../domain/entities/post_entity.dart';
import '../../domain/entities/comment_entity.dart';
import '../../domain/entities/story_entity.dart';
import '../../domain/repositories/feed_repository.dart';
import '../../../../core/services/api_client.dart';


class FeedRepositoryImpl implements FeedRepository {
  final ApiClient _apiClient;

  FeedRepositoryImpl(this._apiClient);


  @override
  Future<List<PostEntity>> getFeed({int page = 1}) async {
    final response = await _apiClient.dio.get('/posts/feed', queryParameters: {'page': page});
    if (response.data['success']) {
      final List data = response.data['data'];
      return data.map((json) => _parsePost(json)).toList();
    }
    return [];
  }

  @override
  Future<List<PostEntity>> getUserPosts(String userId) async {
    final response = await _apiClient.dio.get('/posts/user/$userId');
    if (response.data['success']) {
      final List data = response.data['data'];
      return data.map((json) => _parsePost(json)).toList();
    }
    return [];
  }

  @override
  Future<PostEntity> createPost({required String caption, required List<String> mediaPaths}) async {
    final formData = FormData.fromMap({
      'caption': caption,
    });

    for (var path in mediaPaths) {
      formData.files.add(MapEntry(
        'media',
        await MultipartFile.fromFile(path),
      ));
    }

    final response = await _apiClient.dio.post(
      '/posts/create',
      data: formData,
    );

    if (response.data['success']) {
      return _parsePost(response.data['data']);
    } else {
      throw Exception(response.data['message'] ?? 'Failed to create post');
    }
  }

  @override
  Future<void> likePost(String postId) async {
    await _apiClient.dio.post('/posts/$postId/like');
  }

  @override
  Future<void> unlikePost(String postId) async {
    // Backend toggleLike handles both, so we use the same endpoint
    await _apiClient.dio.post('/posts/$postId/like');
  }

  @override
  Future<void> addComment(String postId, String content, {String? parentId}) async {
    await _apiClient.dio.post('/posts/$postId/comment', data: {
      'text': content,
      // ignore: use_null_aware_elements
      if (parentId != null) 'parentId': parentId,
    });
  }

  @override
  Future<List<CommentEntity>> getComments(String postId, {String? parentId}) async {
    final response = await _apiClient.dio.get(
      '/posts/$postId/comments',
      queryParameters: parentId != null ? {'parentId': parentId} : null,
    );
    if (response.data['success']) {
      final List data = response.data['data'];
      return data.map((json) => _parseComment(json)).toList();
    }
    return [];
  }

  @override
  Future<List<PostEntity>> getHashtagFeed(String hashtag) async {
    final cleanTag = hashtag.startsWith('#') ? hashtag.substring(1) : hashtag;
    final response = await _apiClient.dio.get('/posts/hashtag/$cleanTag');
    if (response.data['success']) {
      final List data = response.data['data'];
      return data.map((json) => _parsePost(json)).toList();
    }
    return [];
  }

  @override
  Future<void> repost(String postId, {String? caption}) async {
    await _apiClient.dio.post('/posts/$postId/repost', data: {
      // ignore: use_null_aware_elements
      if (caption != null) 'caption': caption,
    });
  }

  @override
  Future<void> savePost(String postId) async {
    await _apiClient.dio.post('/posts/$postId/save');
  }

  // Stories
  @override
  Future<List<StoryGroupEntity>> getStoryFeed() async {
    final response = await _apiClient.dio.get('/stories/feed');
    final List data = response.data;
    return data.map((json) => _parseStoryGroup(json)).toList();
  }

  @override
  Future<void> uploadStory({required String mediaPath, String? caption}) async {
    final formData = FormData.fromMap({
      // ignore: use_null_aware_elements
      if (caption != null) 'caption': caption,
      'media': await MultipartFile.fromFile(mediaPath),
    });
    await _apiClient.dio.post('/stories/upload', data: formData);
  }

  @override
  Future<void> markStoryAsSeen(String storyId) async {
    await _apiClient.dio.post('/stories/$storyId/view');
  }

  StoryGroupEntity _parseStoryGroup(dynamic json) {
    final user = json['user'];
    final stories = json['stories'] as List;
    return StoryGroupEntity(
      userId: user['_id'],
      userName: user['fullName'] ?? user['username'] ?? 'Unknown',
      userAvatar: user['avatar']?['url'] ?? '',
      stories: stories.map((s) => _parseStory(s)).toList(),
    );
  }

  StoryEntity _parseStory(dynamic json) {
    return StoryEntity(
      id: json['_id'],
      mediaUrl: json['media']['url'],
      caption: json['caption'] ?? '',
      type: json['type'] ?? 'image',
      createdAt: DateTime.parse(json['createdAt']),
      viewers: List<String>.from(json['viewers'] ?? []),
    );
  }

  PostEntity _parsePost(dynamic json) {

    if (json == null) return null as dynamic; // Should not happen with well-formed JSON
    final user = json['user'];
    final media = json['media'] as List? ?? [];
    
    return PostEntity(
      id: json['_id'],
      userId: user['_id'],
      userName: user['fullName'] ?? user['username'] ?? 'Unknown',
      userAvatar: user['avatar']?['url'] ?? '',
      caption: json['caption'] ?? '',
      mediaUrls: media.map((m) => m['url'].toString()).toList(),
      likesCount: json['likesCount'] ?? 0,
      commentsCount: json['commentsCount'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      isLiked: json['isLiked'] ?? false,
      isSaved: json['isSaved'] ?? false,
      repostOf: json['repostOf'] != null ? _parsePost(json['repostOf']) : null,
      repostsCount: json['repostsCount'] ?? 0,
      hashtags: List<String>.from(json['hashtags'] ?? []),
    );
  }

  CommentEntity _parseComment(dynamic json) {
    final user = json['user'];
    return CommentEntity(
      id: json['_id'],
      userId: user['_id'],
      userName: user['fullName'] ?? user['username'] ?? 'Unknown',
      userAvatar: user['avatar']?['url'] ?? '',
      text: json['text'] ?? '',
      likesCount: json['likesCount'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      isLiked: json['isLiked'] ?? false,
      parentId: json['parentComment'],
    );
  }
}

