import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bloc/feed_bloc.dart';
import '../bloc/feed_event.dart';
import '../bloc/feed_state.dart';
import '../../domain/entities/post_entity.dart';
import '../../domain/entities/comment_entity.dart';
import '../../../../core/presentation/widgets/floq_avatar.dart';
import '../../../../core/presentation/widgets/bubble_loader.dart';

class CommentsBottomSheet extends StatefulWidget {
  final PostEntity post;
  const CommentsBottomSheet({super.key, required this.post});

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  String? _replyingToId;
  String? _replyingToName;

  @override
  void initState() {
    super.initState();
    context.read<FeedBloc>().add(FetchCommentsRequested(widget.post.id));
  }

  void _submitComment() {
    if (_commentController.text.trim().isEmpty) return;
    
    final feedBloc = context.read<FeedBloc>();
    final postId = widget.post.id;

    feedBloc.add(CommentPostRequested(
      postId,
      _commentController.text.trim(),
      parentId: _replyingToId,
    ));
    
    _commentController.clear();
    setState(() {
      _replyingToId = null;
      _replyingToName = null;
    });
    
    // Smoothly refresh comments after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        feedBloc.add(FetchCommentsRequested(postId));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Comments",
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          
          Expanded(
            child: BlocBuilder<FeedBloc, FeedState>(
              builder: (context, state) {
                if (state.isLoadingComments && state.comments.isEmpty) {
                  return const Center(child: BubbleLoader());
                }
                
                if (state.comments.isEmpty) {
                  return Center(
                    child: Text("No comments yet. Be the first!", style: TextStyle(color: Colors.grey[500])),
                  );
                }

                // Filter top-level comments
                final topLevel = state.comments.where((c) => c.parentId == null).toList();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: topLevel.length,
                  itemBuilder: (context, index) {
                    final comment = topLevel[index];
                    final replies = state.comments.where((c) => c.parentId == comment.id).toList();
                    
                    return _buildCommentItem(comment, replies, isDark, colorScheme);
                  },
                );
              },
            ),
          ),

          // Input area
          _buildInputArea(isDark, colorScheme),
        ],
      ),
    );
  }

  Widget _buildCommentItem(CommentEntity comment, List<CommentEntity> replies, bool isDark, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FloqAvatar(radius: 16, name: comment.userName, imageUrl: comment.userAvatar),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(comment.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(comment.text, style: TextStyle(color: isDark ? Colors.white.withValues(alpha: 0.8) : Colors.black87)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text("2h", style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _replyingToId = comment.id;
                              _replyingToName = comment.userName;
                            });
                          },
                          child: const Text("Reply", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.favorite_border, size: 16),
                onPressed: () {},
              ),
            ],
          ),
        ),
        
        // Replies
        if (replies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 44),
            child: Column(
              children: replies.map((reply) => _buildReplyItem(reply, isDark)).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildReplyItem(CommentEntity reply, bool isDark) {
     return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FloqAvatar(radius: 12, name: reply.userName, imageUrl: reply.userAvatar),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reply.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 2),
                Text(reply.text, style: TextStyle(fontSize: 13, color: isDark ? Colors.white.withValues(alpha: 0.8) : Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(bool isDark, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
      ),
      child: Column(
        children: [
          if (_replyingToId != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Text("Replying to $_replyingToName", style: TextStyle(fontSize: 12, color: colorScheme.primary)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() { _replyingToId = null; _replyingToName = null; }),
                    child: const Icon(Icons.close, size: 14),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: "Add a comment...",
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send_rounded, color: colorScheme.primary),
                onPressed: _submitComment,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
