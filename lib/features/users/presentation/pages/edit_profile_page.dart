import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../domain/entities/user_entity.dart';
import '../../../../core/presentation/widgets/bubble_notification.dart';

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
  late TextEditingController _phoneController;
  File? _image;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _bioController = TextEditingController(text: widget.user.bio);
    _webController = TextEditingController(text: widget.user.links.values.isNotEmpty ? widget.user.links.values.first : "");
    _phoneController = TextEditingController(text: "+1 234 567 8900");
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

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      // Simulate saving
      BubbleNotification.show(
        context,
        "Profile updated successfully!",
        type: NotificationType.success,
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
                          border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3), width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 54,
                          backgroundColor: isDark ? Colors.white10 : Colors.grey[100],
                          backgroundImage: _image != null 
                              ? FileImage(_image!) 
                              : NetworkImage(widget.user.profileUrl) as ImageProvider,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: isDark ? const Color(0xFF121212) : Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
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
                  initialValue: "alex.design@floq.me",
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            initialValue: initialValue,
            maxLines: maxLines,
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: isDark ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, size: 20, color: isDark ? Colors.white24 : Colors.black26),
              filled: true,
              fillColor: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }
}
