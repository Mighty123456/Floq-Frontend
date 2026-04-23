import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/feed_bloc.dart';
import '../bloc/feed_state.dart';
import '../bloc/feed_event.dart';
import '../../domain/entities/post_entity.dart';
import '../../../../core/presentation/widgets/floq_avatar.dart';
import '../../../../core/presentation/widgets/bubble_loader.dart';

class ReelsPage extends StatefulWidget {
  const ReelsPage({super.key});

  @override
  State<ReelsPage> createState() => _ReelsPageState();
}

class _ReelsPageState extends State<ReelsPage> {
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    context.read<FeedBloc>().add(LoadReelsRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocBuilder<FeedBloc, FeedState>(
        builder: (context, state) {
          final reelPosts = state.posts.where((p) => p.type == 'reel').toList();
          
          if (reelPosts.isEmpty && !state.isLoading) {
            return const Center(
              child: Text("No Reels found", style: TextStyle(color: Colors.white)),
            );
          }

          if (state.isLoading && reelPosts.isEmpty) {
            return const Center(child: BubbleLoader());
          }

          return PageView.builder(
            scrollDirection: Axis.vertical,
            controller: _pageController,
            itemCount: reelPosts.length,
            itemBuilder: (context, index) {
              return ReelVideoItem(post: reelPosts[index]);
            },
          );
        },
      ),
    );
  }
}

class ReelVideoItem extends StatefulWidget {
  final PostEntity post;
  const ReelVideoItem({super.key, required this.post});

  @override
  State<ReelVideoItem> createState() => _ReelVideoItemState();
}

class _ReelVideoItemState extends State<ReelVideoItem> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    final videoUrl = widget.post.mediaUrls.isNotEmpty ? widget.post.mediaUrls[0] : "";
    if (videoUrl.isNotEmpty) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
        ..initialize().then((_) {
          setState(() {
            _initialized = true;
          });
          _controller.setLooping(true);
          _controller.play();
        });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Video
        if (_initialized)
          GestureDetector(
            onTap: () {
              if (_controller.value.isPlaying) {
                _controller.pause();
              } else {
                _controller.play();
              }
            },
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            ),
          )
        else
          const Center(child: BubbleLoader()),

        // Overlay Gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black54, Colors.transparent, Colors.transparent, Colors.black87],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.0, 0.2, 0.7, 1.0],
            ),
          ),
        ),

        // Content
        Positioned(
          left: 16,
          bottom: 24,
          right: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  FloqAvatar(
                    radius: 18,
                    name: widget.post.userName,
                    imageUrl: widget.post.userAvatar,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.post.userName,
                    style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text("Follow", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                widget.post.caption,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.music_note, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Original Audio - ${widget.post.userName}",
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Right Actions
        Positioned(
          right: 12,
          bottom: 40,
          child: Column(
            children: [
              _actionIcon(Icons.favorite, widget.post.likesCount.toString()),
              const SizedBox(height: 20),
              _actionIcon(Icons.chat_bubble_rounded, widget.post.commentsCount.toString()),
              const SizedBox(height: 20),
              _actionIcon(Icons.send_rounded, ""),
              const SizedBox(height: 20),
              _actionIcon(Icons.more_vert_rounded, ""),
              const SizedBox(height: 24),
              // Spinning record effect
              Container(
                width: 35, height: 35,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white38, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(widget.post.userAvatar, fit: BoxFit.cover, errorBuilder: (c,e,s) => Container(color: Colors.white24)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _actionIcon(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 32),
        if (label.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ],
    );
  }
}
