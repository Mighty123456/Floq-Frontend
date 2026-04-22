import 'package:equatable/equatable.dart';
import '../../domain/entities/story_entity.dart';
import '../../domain/entities/post_entity.dart';
import '../../domain/entities/comment_entity.dart';

class FeedState extends Equatable {
  final List<PostEntity> posts;
  final List<CommentEntity> comments;
  final List<StoryGroupEntity> stories;
  final bool isLoading;
  final bool isLoadingComments;
  final bool isCreating;
  final int currentPage;
  final bool hasReachedMax;
  final String? error;

  const FeedState({
    this.posts = const [],
    this.comments = const [],
    this.stories = const [],
    this.isLoading = false,
    this.isLoadingComments = false,
    this.isCreating = false,
    this.currentPage = 1,
    this.hasReachedMax = false,
    this.error,
  });

  FeedState copyWith({
    List<PostEntity>? posts,
    List<CommentEntity>? comments,
    List<StoryGroupEntity>? stories,
    bool? isLoading,
    bool? isLoadingComments,
    bool? isCreating,
    int? currentPage,
    bool? hasReachedMax,
    String? error,
  }) {
    return FeedState(
      posts: posts ?? this.posts,
      comments: comments ?? this.comments,
      stories: stories ?? this.stories,
      isLoading: isLoading ?? this.isLoading,
      isLoadingComments: isLoadingComments ?? this.isLoadingComments,
      isCreating: isCreating ?? this.isCreating,
      currentPage: currentPage ?? this.currentPage,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      error: error,
    );
  }


  @override
  List<Object?> get props => [
    posts, comments, isLoading, isLoadingComments, isCreating, error, currentPage, hasReachedMax
  ];
}

