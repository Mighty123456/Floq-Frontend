import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/users_bloc.dart';
import '../bloc/users_event.dart';
import '../../domain/entities/user_entity.dart';
import '../../../../core/presentation/widgets/bubble_notification.dart';
import '../../../../core/presentation/widgets/floq_avatar.dart';

class EditProfilePage extends StatefulWidget {
  final UserEntity user;

  const EditProfilePage({super.key, required this.user});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _webController;
  final TextEditingController _phoneController = TextEditingController();
  late List<MapEntry<String, String>> _dynamicLinks;
  File? _image;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _bioController = TextEditingController(text: widget.user.bio);
    _webController = TextEditingController(text: "");
    _dynamicLinks = widget.user.links.entries.toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _webController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  void _addLinkDialog() {
    final titleController = TextEditingController();
    final urlController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text("Add Link", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(hintText: "Label (e.g. Portfolio)"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(hintText: "URL"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty && urlController.text.isNotEmpty) {
                setState(() {
                  _dynamicLinks.add(MapEntry(titleController.text, urlController.text));
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      if (_image != null) {
        context.read<UsersBloc>().add(UploadAvatarRequested(_image!.path));
      }
      
      // Update metadata logic would go here
      // context.read<UsersBloc>().add(UpdateProfileRequested(...));
      
      BubbleNotification.show(
        context,
        "Profile update started...",
        type: NotificationType.info,
      );
      Navigator.pop(context);
    }
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Edit Profile",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: Text(
              "Done",
              style: GoogleFonts.poppins(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                
                // Profile Image Section
                GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.primary,
                              colorScheme.secondary,
                              colorScheme.tertiary,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withValues(alpha: 0.3),
                              blurRadius: 16,
                              spreadRadius: 2,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                          child: _image != null 
                            ? CircleAvatar(
                                radius: 51,
                                backgroundImage: FileImage(_image!),
                              )
                            : FloqAvatar(
                                radius: 51,
                                name: widget.user.name,
                                imageUrl: widget.user.profileUrl,
                                fontSize: 32,
                              ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [colorScheme.primary, colorScheme.secondary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(color: isDark ? const Color(0xFF121212) : Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _pickImage,
                  child: Text(
                    "Change profile photo",
                    style: GoogleFonts.poppins(
                      color: colorScheme.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Fields Section
                _buildField(
                  label: "Name",
                  controller: _nameController,
                  icon: Icons.person_outline_rounded,
                  isDark: isDark,
                ),
                _buildField(
                  label: "Username",
                  initialValue: widget.user.name.toLowerCase().replaceAll(' ', '_'),
                  icon: Icons.alternate_email_rounded,
                  isDark: isDark,
                ),
                _buildField(
                  label: "Bio",
                  controller: _bioController,
                  icon: Icons.notes_rounded,
                  maxLines: 3,
                  isDark: isDark,
                ),
                _buildField(
                  label: "Website",
                  controller: _webController,
                  icon: Icons.link_rounded,
                  isDark: isDark,
                ),

                const SizedBox(height: 16),
                
                // Dynamic Links Section
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Links",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _addLinkDialog,
                        icon: const Icon(Icons.add_link_rounded, size: 18),
                        label: Text("Add Link", style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          foregroundColor: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                
                ..._dynamicLinks.asMap().entries.map((entry) {
                   int index = entry.key;
                   var link = entry.value;
                   return Container(
                     margin: const EdgeInsets.only(bottom: 12),
                     padding: const EdgeInsets.all(12),
                     decoration: BoxDecoration(
                       color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.05),
                       borderRadius: BorderRadius.circular(12),
                       border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                     ),
                     child: Row(
                       children: [
                         Icon(Icons.link_rounded, size: 18, color: colorScheme.primary),
                         const SizedBox(width: 12),
                         Expanded(
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Text(link.key, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold)),
                               Text(link.value, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey)),
                             ],
                           ),
                         ),
                         IconButton(
                           icon: const Icon(Icons.remove_circle_outline, size: 20, color: Colors.redAccent),
                           onPressed: () {
                             setState(() {
                               _dynamicLinks.removeAt(index);
                             });
                           },
                         ),
                       ],
                     ),
                   );
                }),
                
                const SizedBox(height: 32),
                
                // Professional Info Section
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Private Information",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                _buildField(
                  label: "Email Address",
                  initialValue: widget.user.email,
                  icon: Icons.email_outlined,
                  isDark: isDark,
                ),
                _buildField(
                  label: "Phone Number",
                  controller: _phoneController,
                  icon: Icons.phone_android_rounded,
                  isDark: isDark,
                ),
                
                const SizedBox(height: 48),
                
                // Switch to Professional Account
                TextButton(
                  onPressed: () {},
                  child: Text(
                    "Switch to professional account",
                    style: GoogleFonts.poppins(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    TextEditingController? controller,
    String? initialValue,
    required IconData icon,
    int maxLines = 1,
    required bool isDark,
  }) {
    return _PremiumInputField(
      label: label,
      controller: controller,
      initialValue: initialValue,
      icon: icon,
      maxLines: maxLines,
      isDark: isDark,
    );
  }
}

class _PremiumInputField extends StatefulWidget {
  final String label;
  final TextEditingController? controller;
  final String? initialValue;
  final IconData icon;
  final int maxLines;
  final bool isDark;

  const _PremiumInputField({
    required this.label,
    this.controller,
    this.initialValue,
    required this.icon,
    this.maxLines = 1,
    required this.isDark,
  });

  @override
  State<_PremiumInputField> createState() => _PremiumInputFieldState();
}

class _PremiumInputFieldState extends State<_PremiumInputField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: GoogleFonts.poppins(
              fontSize: _isFocused ? 13 : 12,
              fontWeight: FontWeight.w600,
              color: _isFocused 
                  ? colorScheme.primary 
                  : (widget.isDark ? Colors.white54 : Colors.black54),
            ),
            child: Text(widget.label),
          ),
          const SizedBox(height: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: widget.isDark 
                  ? (_isFocused ? colorScheme.primary.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.03))
                  : (_isFocused ? colorScheme.primary.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.05)),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isFocused ? colorScheme.primary.withValues(alpha: 0.5) : Colors.transparent,
                width: 1.5,
              ),
              boxShadow: _isFocused ? [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.2),
                  blurRadius: 12,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                )
              ] : [],
            ),
            child: TextFormField(
              controller: widget.controller,
              initialValue: widget.initialValue,
              maxLines: widget.maxLines,
              focusNode: _focusNode,
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: widget.isDark ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                prefixIcon: Icon(
                  widget.icon, 
                  size: 20, 
                  color: _isFocused ? colorScheme.primary : (widget.isDark ? Colors.white24 : Colors.black26),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
