import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'story_group_view.dart';
import '../../../../core/services/secure_storage_service.dart';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/feed_bloc.dart';
import '../bloc/feed_event.dart';
import '../bloc/feed_state.dart';
import '../../domain/entities/story_entity.dart';
import '../../domain/entities/post_entity.dart';
import '../../../../core/presentation/widgets/bubble_loader.dart';
import '../../../../core/presentation/widgets/floq_avatar.dart';
import '../../../../core/presentation/widgets/bubble_notification.dart';
import 'comments_bottom_sheet.dart';

class FeedPage extends StatefulWidget {

  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  String _currentUserAvatar = "";
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadUser();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<FeedBloc>().add(LoadMoreFeedRequested());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showZoomedImage(BuildContext context, String imageUrl, String heroTag) {
    if (imageUrl.isEmpty) return;
    
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.9),
        barrierDismissible: true,
        pageBuilder: (context, animation, secondaryAnimation) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Hero(
                  tag: heroTag,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      body: BlocConsumer<FeedBloc, FeedState>(
        listener: (context, state) {
          if (state.error != null) {
            BubbleNotification.show(
              context,
              state.error!,
              type: NotificationType.error,
            );
          }
        },
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () async {
              context.read<FeedBloc>().add(RefreshFeedRequested());
              await Future.delayed(const Duration(seconds: 1)); // Visual padding
            },
            color: colorScheme.primary,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              slivers: [
                SliverToBoxAdapter(child: _buildStorySection(state, isDark, colorScheme)),
                _buildSuggestedNetwork(isDark, colorScheme),
                
                if (state.isLoading && state.posts.isEmpty)
                  const SliverFillRemaining(
                    child: Center(child: BubbleLoader()),
                  )
                else if (state.posts.isEmpty)
                   SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.feed_outlined, size: 64, color: Colors.grey.withValues(alpha: 0.3)),
                          const SizedBox(height: 16),
                          const Text("Your feed is empty. Follow people to see posts!", style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final post = state.posts[index];
                          return _buildUniquePostCard(post, isDark, colorScheme);
                        },
                        childCount: state.posts.length,
                      ),
                    ),
                  ),
                if (!state.hasReachedMax && state.posts.isNotEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: BubbleLoader()),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _loadUser() async {

    final storage = SecureStorageService();
    final userJson = await storage.getUser();
    if (userJson != null) {
      final map = jsonDecode(userJson);
      if (mounted) {
        setState(() {
          _currentUserAvatar = map['avatar']?['url'] ?? "";
        });
      }
    }
    // Load real stories
    if (mounted) {
      context.read<FeedBloc>().add(LoadStoriesRequested());
    }
  }

  Future<void> _pickAndUploadStory() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null && mounted) {
      context.read<FeedBloc>().add(UploadStoryRequested(image.path));
      BubbleNotification.show(context, "Uploading story...", type: NotificationType.info);
    }
  }

  void _showPostOptions(BuildContext context, PostEntity post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (bContext) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share_rounded),
              title: const Text("Share to..."),
              onTap: () => Navigator.pop(bContext),
            ),
            ListTile(
              leading: const Icon(Icons.report_problem_rounded, color: Colors.orange),
              title: const Text("Report Post", style: TextStyle(color: Colors.orange)),
              onTap: () {
                Navigator.pop(bContext);
                BubbleNotification.show(context, "Post reported", type: NotificationType.info);
              },
            ),
            // Example of delete option (assuming UI is just visual for now, or add FeedEvent.DeletePostRequested if available)
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              title: const Text("Delete Post", style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(bContext);
                BubbleNotification.show(context, "Post deleted", type: NotificationType.success);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showHashtagFeed(String hashtag) {
    // Navigate to a new Hashtag Feed Page or show a bottom sheet
    // We will use a bottom sheet for a seamless experience
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bContext) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text(hashtag, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
            const Divider(),
            Expanded(
              child: BlocProvider(
                create: (context) => FeedBloc(repository: context.read())..add(FetchHashtagFeedRequested(hashtag)),
                child: BlocBuilder<FeedBloc, FeedState>(
                  builder: (context, state) {
                    if (state.isLoading) return const Center(child: BubbleLoader());
                    if (state.posts.isEmpty) return const Center(child: Text("No posts found for this hashtag.", style: TextStyle(color: Colors.grey)));
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: state.posts.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: _buildUniquePostCard(state.posts[index], Theme.of(context).brightness == Brightness.dark, Theme.of(context).colorScheme),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openStories(BuildContext context, int index, List<StoryGroupEntity> stories) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoryGroupView(
          storyGroups: stories,
          initialGroupIndex: index,
        ),
      ),
    );
  }

  Widget _buildStorySection(FeedState state, bool isDark, ColorScheme colorScheme) {
    final stories = state.stories;
    
    return Container(
      height: 110,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: stories.length + 1, // +1 for "Add Story" button
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: _pickAndUploadStory,
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 65,
                          height: 65,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.2), width: 2),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(3),
                          child: FloqAvatar(
                            radius: 30,
                            name: "Me",
                            imageUrl: _currentUserAvatar,
                          ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: isDark ? const Color(0xFF121212) : Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.add, color: Colors.white, size: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text("Your Story", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            );
          }

          final group = stories[index - 1];
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => _openStories(context, index - 1, stories),
              child: Column(
                children: [
                  Container(
                    width: 65,
                    height: 65,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [colorScheme.primary, colorScheme.secondary, Colors.orangeAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: isDark ? const Color(0xFF121212) : Colors.white, width: 2),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: FloqAvatar(
                            radius: 28,
                            name: group.userName,
                            imageUrl: group.userAvatar,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(group.userName, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }


  Widget _buildSuggestedNetwork(bool isDark, ColorScheme colorScheme) {
    return const SliverToBoxAdapter(child: SizedBox.shrink());
  }

  Widget _buildUniquePostCard(PostEntity post, bool isDark, ColorScheme colorScheme) {
    final hasImage = post.mediaUrls.isNotEmpty;
    final isRepost = post.repostOf != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              FloqAvatar(
                radius: 18,
                name: post.userName,
                imageUrl: post.userAvatar,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.userName,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    isRepost ? "shared a post" : "2h",
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.more_vert_rounded, size: 20),
                onPressed: () => _showPostOptions(context, post),
              )
            ],
          ),

          const SizedBox(height: 12),

          // Main Content Layer
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    if (!isDark)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: Column(
                    children: [
                      if (hasImage)
                        GestureDetector(
                          onTap: () => _showZoomedImage(context, post.mediaUrls[0], 'feed_image_${post.id}'),
                          child: Hero(
                            tag: 'feed_image_${post.id}',
                            child: Image.network(
                              post.mediaUrls[0],
                              width: double.infinity,
                              fit: BoxFit.cover,
                              height: 350,
                            ),
                          ),
                        ),
                      if (isRepost && post.repostOf != null)
                        Container(
                          margin: const EdgeInsets.all(12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  FloqAvatar(radius: 12, name: post.repostOf!.userName, imageUrl: post.repostOf!.userAvatar),
                                  const SizedBox(width: 8),
                                  Text(post.repostOf!.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(post.repostOf!.caption, style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(20, hasImage ? 20 : 24, 65, 24),
                        child: _buildCaptionWithHashtags(post.caption, isDark, colorScheme),
                      ),
                    ],
                  ),
                ),
              ),

              Positioned(
                right: 12,
                bottom: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildActionIcon(
                        icon: post.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: post.isLiked ? Colors.redAccent : null,
                        count: post.likesCount.toString(),
                        onTap: () {
                          context.read<FeedBloc>().add(LikePostRequested(post.id));
                        },
                      ),
                      const Divider(height: 1),
                      _buildActionIcon(
                        icon: Icons.chat_bubble_outline_rounded,
                        count: post.commentsCount.toString(),
                        onTap: () => _showCommentsBottomSheet(post),
                      ),
                      const Divider(height: 1),
                      _buildActionIcon(
                        icon: Icons.repeat_rounded,
                        count: post.repostsCount.toString(),
                        onTap: () {
                          context.read<FeedBloc>().add(RepostRequested(post.id));
                        },
                      ),
                      const Divider(height: 1),
                      _buildActionIcon(
                        icon: post.isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                        color: post.isSaved ? colorScheme.primary : null,
                        onTap: () {
                          context.read<FeedBloc>().add(SavePostRequested(post.id));
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCaptionWithHashtags(String caption, bool isDark, ColorScheme colorScheme) {
    if (caption.isEmpty) return const SizedBox.shrink();
    
    final List<TextSpan> children = [];
    final List<String> words = caption.split(' ');

    for (var word in words) {
      if (word.startsWith('#')) {
        children.add(
          TextSpan(
            text: '$word ',
            style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
            recognizer: TapGestureRecognizer()
              ..onTap = () => _showHashtagFeed(word),
          ),
        );
      } else {
        children.add(TextSpan(text: '$word '));
      }
    }

    return RichText(
      text: TextSpan(
        style: GoogleFonts.poppins(
          fontSize: 15,
          height: 1.6,
          color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black.withValues(alpha: 0.8),
        ),
        children: children,
      ),
    );
  }

  void _showCommentsBottomSheet(PostEntity post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsBottomSheet(post: post),
    );
  }


  Widget _buildActionIcon({required IconData icon, Color? color, String? count, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          children: [
            Icon(icon, size: 22, color: color),
            if (count != null)
              Text(
                count,
                style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }
}

