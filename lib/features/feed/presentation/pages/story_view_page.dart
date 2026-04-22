import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/entities/story_entity.dart';
import '../../../../core/presentation/widgets/bubble_notification.dart';

class StoryViewPage extends StatefulWidget {
  final String userName;
  final String profileUrl;
  final List<StoryEntity> stories;
  final int initialIndex;
  final VoidCallback? onAllStoriesComplete;
  final VoidCallback? onClose;

  const StoryViewPage({
    super.key,
    required this.userName,
    required this.profileUrl,
    required this.stories,
    this.initialIndex = 0,
    this.onAllStoriesComplete,
    this.onClose,
  });


  @override
  State<StoryViewPage> createState() => _StoryViewPageState();
}

class _StoryViewPageState extends State<StoryViewPage> with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  final TextEditingController _messageController = TextEditingController();
  int _currentIndex = 0;
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    
    _progressController = AnimationController(
      vsync: this,
    );

    _loadStory();

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _nextStory();
      }
    });
  }

  void _loadStory() {
    _progressController.stop();
    _progressController.reset();
    _progressController.duration = const Duration(seconds: 5); // Default for now
    _progressController.forward();
  }


  void _nextStory() {
    if (_currentIndex < widget.stories.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _loadStory();
    } else {
      if (widget.onAllStoriesComplete != null) {
        widget.onAllStoriesComplete!();
      } else {
        Navigator.pop(context);
      }
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _loadStory();
    } else {
      _loadStory(); // Restart current if at beginning
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _handleSend() {
    if (_messageController.text.trim().isEmpty) return;
    
    _messageController.clear();
    FocusScope.of(context).unfocus();
    
    BubbleNotification.show(
      context,
      "Message sent!",
      type: NotificationType.success,
    );
    
    _progressController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        onVerticalDragUpdate: (details) {
          if (details.delta.dy > 10) {
            Navigator.pop(context);
          }
        },
        onTapDown: (details) {
          _progressController.stop();
        },
        onTapUp: (details) {
          if (FocusScope.of(context).hasFocus) {
            FocusScope.of(context).unfocus();
            _progressController.forward();
            return;
          }

          final screenWidth = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < screenWidth * 0.3) {
            _previousStory();
          } else {
            _nextStory();
          }
        },
        child: Stack(
          children: [
            // Story Image
            Positioned.fill(
              child: Image.network(
                widget.stories[_currentIndex].mediaUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                },
              ),
            ),

            // Deep Gradient Bottom
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.3),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.75),
                    ],
                    stops: const [0.0, 0.2, 0.7, 1.0],
                  ),
                ),
              ),
            ),

            // Header with Segmented Clips
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    Row(
                      children: List.generate(widget.stories.length, (index) {
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: AnimatedBuilder(
                              animation: _progressController,
                              builder: (context, child) {
                                double value = 0.0;
                                if (index < _currentIndex) {
                                  value = 1.0;
                                } else if (index == _currentIndex) {
                                  value = _progressController.value;
                                }
                                
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value: value,
                                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                    minHeight: 2,
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundImage: NetworkImage(widget.profileUrl),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          widget.userName,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 28),
                          onPressed: widget.onClose ?? () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Single Oval Interaction Bar
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom > 0 
                  ? MediaQuery.of(context).viewInsets.bottom + 20 
                  : MediaQuery.of(context).padding.bottom + 20,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                      onTap: () => _progressController.stop(),
                      cursorColor: Colors.white,
                      decoration: InputDecoration(
                        hintText: "Reply to ${widget.userName.split(' ')[0]}...",
                        hintStyle: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.5), 
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.1),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3), width: 1.0),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3), width: 1.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3), width: 1.0),
                        ),
                      ),
                      onSubmitted: (_) => _handleSend(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildActionButton(
                    _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: _isLiked ? Colors.redAccent : Colors.white,
                    onTap: () {
                      setState(() {
                        _isLiked = !_isLiked;
                      });
                    },
                  ),
                  const SizedBox(width: 12),
                  _buildActionButton(
                    Icons.send_rounded,
                    onTap: _handleSend,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, {Color color = Colors.white, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        width: 50,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.0),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}
