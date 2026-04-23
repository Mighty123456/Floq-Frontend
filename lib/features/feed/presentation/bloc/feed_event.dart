import 'package:equatable/equatable.dart';

abstract class FeedEvent extends Equatable {
  const FeedEvent();
  @override
  List<Object> get props => [];
}

class LoadFeedRequested extends FeedEvent {}

class RefreshFeedRequested extends FeedEvent {}

class LoadReelsRequested extends FeedEvent {}

class LoadMoreFeedRequested extends FeedEvent {}

class CreatePostRequested extends FeedEvent {
  final String caption;
  final List<String> mediaPaths;
  final String? type;
  final Map<String, dynamic>? location;
  final Map<String, dynamic>? audioData;
  final Map<String, dynamic>? metadata;

  const CreatePostRequested(
    this.caption, 
    this.mediaPaths, {
    this.type, 
    this.location, 
    this.audioData, 
    this.metadata
  });
}

class LikePostRequested extends FeedEvent {
  final String postId;
  const LikePostRequested(this.postId);
}

class CommentPostRequested extends FeedEvent {
  final String postId;
  final String content;
  final String? parentId;
  const CommentPostRequested(this.postId, this.content, {this.parentId});
}


class SavePostRequested extends FeedEvent {
  final String postId;
  const SavePostRequested(this.postId);
}

class RepostRequested extends FeedEvent {
  final String postId;
  final String? caption;
  const RepostRequested(this.postId, {this.caption});
}

class FetchHashtagFeedRequested extends FeedEvent {
  final String hashtag;
  const FetchHashtagFeedRequested(this.hashtag);
}

class FetchCommentsRequested extends FeedEvent {
  final String postId;
  final String? parentId;
  const FetchCommentsRequested(this.postId, {this.parentId});
}

class LoadStoriesRequested extends FeedEvent {}

class UploadStoryRequested extends FeedEvent {
  final String mediaPath;
  final String? caption;
  const UploadStoryRequested(this.mediaPath, {this.caption});
}


