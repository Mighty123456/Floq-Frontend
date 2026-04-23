import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/presentation/widgets/bouncy_button.dart';
import '../../../../core/presentation/widgets/bubble_notification.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/feed_bloc.dart';
import '../bloc/feed_event.dart';
import '../../../../core/presentation/widgets/floq_avatar.dart';
import '../../../../core/services/secure_storage_service.dart';
import 'dart:convert';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController _contentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<File> _selectedImages = [];
  bool _isPosting = false;
  String _userName = "User";
  String _userAvatar = "";

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final storage = SecureStorageService();
    final userJson = await storage.getUser();
    if (userJson != null) {
      final map = jsonDecode(userJson);
      if (mounted) {
        setState(() {
          final email = map['email'] ?? '';
          _userName = (map['fullName'] != null && map['fullName'].toString().isNotEmpty && map['fullName'] != 'Unknown') 
              ? map['fullName'] 
              : (email.isNotEmpty ? email.split('@')[0] : 'Floq User');
          _userAvatar = (map['avatar'] is Map) ? map['avatar']['url'] : (map['avatar'] ?? "");
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Create Post",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: BouncyButton(
              onTap: () {
                if (!_isPosting) _handlePost();
              },

              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: _isPosting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          "Post",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FloqAvatar(
                    radius: 20,
                    name: _userName,
                    imageUrl: _userAvatar,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _contentController,
                          maxLines: null,
                          autofocus: true,
                          style: GoogleFonts.poppins(fontSize: 16),
                          decoration: InputDecoration(
                            hintText: "What's on your mind?",
                            hintStyle: TextStyle(color: Colors.grey[500]),
                            border: InputBorder.none,
                          ),
                        ),
                        if (_selectedImages.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 200,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _selectedImages.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Image.file(
                                          _selectedImages[index],
                                          width: 150,
                                          height: 200,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _selectedImages.removeAt(index);
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Colors.black54,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.close, color: Colors.white, size: 16),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Tool bar for adding media
          Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              left: 16,
              right: 16,
              top: 16,
            ),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.white10 : Colors.black12,
                ),
              ),
            ),
            child: Row(
              children: [
                _buildToolIcon(Icons.image_outlined, "Photo", colorScheme, onTap: _pickImages),
                _buildToolIcon(Icons.videocam_outlined, "Video", colorScheme),
                _buildToolIcon(Icons.location_on_outlined, "Location", colorScheme),
                _buildToolIcon(Icons.emoji_emotions_outlined, "Emoji", colorScheme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolIcon(IconData icon, String label, ColorScheme colorScheme, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(right: 24),
      child: GestureDetector(
        onTap: onTap,
        child: Icon(icon, color: colorScheme.primary, size: 28),
      ),
    );
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images.map((img) => File(img.path)));
      });
    }
  }

  void _handlePost() async {
    if (_contentController.text.trim().isEmpty && _selectedImages.isEmpty) return;

    setState(() {
      _isPosting = true;
    });

    try {
      context.read<FeedBloc>().add(CreatePostRequested(
        _contentController.text.trim(),
        _selectedImages.map((f) => f.path).toList(),
      ));
      
      // Wait for state change if needed, or assume optimistic success
      // In Bloc, we should ideally listen for success state.
      // But for now we just pop.
      
      if (!mounted) return;
      BubbleNotification.show(context, "Post published successfully!");
      Navigator.pop(context);
    } catch (e) {
      setState(() => _isPosting = false);
      if (!mounted) return;
      BubbleNotification.show(context, "Failed to publish post: $e", type: NotificationType.error);
    }
  }

}
