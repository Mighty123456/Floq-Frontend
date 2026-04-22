import '../entities/post_entity.dart';
import '../entities/comment_entity.dart';
import '../entities/story_entity.dart';

abstract class FeedRepository {
  Future<List<PostEntity>> getFeed({int page = 1});
  Future<List<PostEntity>> getUserPosts(String userId);
  Future<PostEntity> createPost({required String caption, required List<String> mediaPaths});
  Future<void> likePost(String postId);
  Future<void> unlikePost(String postId);
  Future<void> addComment(String postId, String content, {String? parentId});
  Future<List<CommentEntity>> getComments(String postId, {String? parentId});
  Future<List<PostEntity>> getHashtagFeed(String hashtag);
  Future<void> repost(String postId, {String? caption});
  Future<void> savePost(String postId);

  // Stories
  Future<List<StoryGroupEntity>> getStoryFeed();
  Future<void> uploadStory({required String mediaPath, String? caption});
  Future<void> markStoryAsSeen(String storyId);
}



