import 'package:flutter_bloc/flutter_bloc.dart';
import 'feed_event.dart';
import 'feed_state.dart';
import '../../domain/repositories/feed_repository.dart';
import '../../../../core/services/cache_service.dart';
import '../../domain/entities/post_entity.dart';

class FeedBloc extends Bloc<FeedEvent, FeedState> {
  final FeedRepository repository;

  FeedBloc({required this.repository}) : super(const FeedState()) {
    on<LoadFeedRequested>(_onLoadFeed);
    on<RefreshFeedRequested>(_onRefreshFeed);
    on<LoadMoreFeedRequested>(_onLoadMoreFeed);
    on<CreatePostRequested>(_onCreatePost);
    on<LikePostRequested>(_onLikePost);
    on<CommentPostRequested>(_onCommentPost);
    on<SavePostRequested>(_onSavePost);
    on<RepostRequested>(_onRepost);
    on<FetchHashtagFeedRequested>(_onFetchHashtagFeed);
    on<FetchCommentsRequested>(_onFetchComments);
    on<LoadStoriesRequested>(_onLoadStories);
    on<UploadStoryRequested>(_onUploadStory);
  }

  Future<void> _onLoadFeed(LoadFeedRequested event, Emitter<FeedState> emit) async {
    // Try to load from cache first
    final cachedData = CacheService().getCachedFeed();
    if (cachedData.isNotEmpty) {
      final cachedPosts = cachedData.map((json) => PostEntity.fromJson(Map<String, dynamic>.from(json))).toList();
      emit(state.copyWith(posts: cachedPosts));
    }

    emit(state.copyWith(isLoading: true, currentPage: 1, hasReachedMax: false, error: null));
    try {
      final posts = await repository.getFeed(page: 1);
      
      // Update cache
      await CacheService().cacheFeed(posts);

      emit(state.copyWith(
        posts: posts, 
        isLoading: false, 
        hasReachedMax: posts.isEmpty,
      ));
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isLoading: false));
    }
  }

  Future<void> _onRefreshFeed(RefreshFeedRequested event, Emitter<FeedState> emit) async {
    try {
      final posts = await repository.getFeed(page: 1);
      
      // Update cache
      await CacheService().cacheFeed(posts);

      emit(state.copyWith(
        posts: posts, 
        currentPage: 1, 
        hasReachedMax: posts.isEmpty,
        error: null,
      ));
    } catch (e) {
      // Handle silently during refresh
    }
  }

  Future<void> _onLoadMoreFeed(LoadMoreFeedRequested event, Emitter<FeedState> emit) async {
    if (state.hasReachedMax || state.isLoading) return;
    
    final nextPage = state.currentPage + 1;
    try {
      final morePosts = await repository.getFeed(page: nextPage);
      if (morePosts.isEmpty) {
        emit(state.copyWith(hasReachedMax: true));
      } else {
        emit(state.copyWith(
          posts: [...state.posts, ...morePosts],
          currentPage: nextPage,
          hasReachedMax: false,
        ));
      }
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onCreatePost(CreatePostRequested event, Emitter<FeedState> emit) async {
    emit(state.copyWith(isCreating: true));
    try {
      final newPost = await repository.createPost(
        caption: event.caption,
        mediaPaths: event.mediaPaths,
      );
      emit(state.copyWith(
        posts: [newPost, ...state.posts],
        isCreating: false,
      ));
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isCreating: false));
    }
  }

  Future<void> _onLikePost(LikePostRequested event, Emitter<FeedState> emit) async {
    // Optimistic UI update
    final updatedPosts = state.posts.map((p) {
      if (p.id == event.postId) {
        final newIsLiked = !p.isLiked;
        return p.copyWith(
          isLiked: newIsLiked,
          likesCount: p.likesCount + (newIsLiked ? 1 : -1),
        );
      }
      return p;
    }).toList();
    emit(state.copyWith(posts: updatedPosts));
    try {
      await repository.likePost(event.postId);
    } catch (e) {
      // Revert on error - re-run optimistic again in reverse
    }
  }

  Future<void> _onCommentPost(CommentPostRequested event, Emitter<FeedState> emit) async {
    try {
      await repository.addComment(event.postId, event.content, parentId: event.parentId);
      final updatedPosts = state.posts.map((p) {
        if (p.id == event.postId) {
          return p.copyWith(commentsCount: p.commentsCount + 1);
        }
        return p;
      }).toList();
      emit(state.copyWith(posts: updatedPosts));
    } catch (e) {
      // Handle error
    }
  }


  Future<void> _onSavePost(SavePostRequested event, Emitter<FeedState> emit) async {
    // Optimistic UI update
    final updatedPosts = state.posts.map((p) {
      if (p.id == event.postId) {
        return p.copyWith(isSaved: !p.isSaved);
      }
      return p;
    }).toList();
    emit(state.copyWith(posts: updatedPosts));
    try {
      await repository.savePost(event.postId);
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _onRepost(RepostRequested event, Emitter<FeedState> emit) async {
    try {
      await repository.repost(event.postId, caption: event.caption);
      // Update repost count optimistically
      final updatedPosts = state.posts.map((p) {
        if (p.id == event.postId) {
          return p.copyWith(repostsCount: p.repostsCount + 1);
        }
        return p;
      }).toList();
      emit(state.copyWith(posts: updatedPosts));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onFetchHashtagFeed(FetchHashtagFeedRequested event, Emitter<FeedState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final posts = await repository.getHashtagFeed(event.hashtag);
      emit(state.copyWith(posts: posts, isLoading: false));
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isLoading: false));
    }
  }

  Future<void> _onFetchComments(FetchCommentsRequested event, Emitter<FeedState> emit) async {
    emit(state.copyWith(isLoadingComments: true));
    try {
      final comments = await repository.getComments(event.postId, parentId: event.parentId);
      emit(state.copyWith(comments: comments, isLoadingComments: false));
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isLoadingComments: false));
    }
  }

  Future<void> _onLoadStories(LoadStoriesRequested event, Emitter<FeedState> emit) async {
    try {
      final stories = await repository.getStoryFeed();
      emit(state.copyWith(stories: stories));
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _onUploadStory(UploadStoryRequested event, Emitter<FeedState> emit) async {
    try {
      await repository.uploadStory(mediaPath: event.mediaPath, caption: event.caption);
      add(LoadStoriesRequested());
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }
}


