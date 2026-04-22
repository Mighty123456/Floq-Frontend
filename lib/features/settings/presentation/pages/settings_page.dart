import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import '../bloc/settings_state.dart';
import '../../data/repositories/settings_repository_impl.dart';
import 'package:floq/main.dart'; // To access ThemeNotifier
import '../../../auth/presentation/pages/login_page.dart'; // Logout destination
import '../../../../core/presentation/widgets/bubble_loader.dart';
import '../../../../core/presentation/widgets/bubble_notification.dart';
import '../../../../core/presentation/widgets/bouncy_button.dart';
import 'notifications_page.dart';
import 'blocked_users_page.dart';
import '../../../../features/users/domain/entities/user_entity.dart';
import '../../../../features/users/presentation/pages/user_profile_page.dart';
import '../../../../features/users/presentation/bloc/users_bloc.dart';
import '../../../../features/users/data/repositories/users_repository_impl.dart';
import '../../../../features/feed/data/repositories/feed_repository_impl.dart';
import '../../../../core/services/api_client.dart';


class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SettingsBloc(repository: SettingsRepositoryImpl())..add(LoadProfileRequested()),
      child: const _SettingsView(),
    );
  }
}

class _SettingsView extends StatefulWidget {
  const _SettingsView();

  @override
  State<_SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<_SettingsView> {
  final ImagePicker _picker = ImagePicker();

  void _showEditProfileDialog(BuildContext bContext, String currentName, String currentEmail) {
    final TextEditingController nameController = TextEditingController(text: currentName);
    final TextEditingController emailController = TextEditingController(text: currentEmail);
    final TextEditingController bioController = TextEditingController(text: "Design enthusiast & tech explorer...");
    final TextEditingController linkController = TextEditingController(text: "https://portfolio.floq.me");

    showDialog(
      context: bContext,
      builder: (dialogContext) {
        final isDarkDialog = Theme.of(dialogContext).brightness == Brightness.dark;
        final colorScheme = Theme.of(dialogContext).colorScheme;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDarkDialog ? const Color(0xFF161616) : Colors.white,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: isDarkDialog ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 40, offset: const Offset(0, 10))
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Edit Profile",
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDarkDialog ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildDialogTextField(controller: nameController, labelText: "Name", isDark: isDarkDialog, icon: Icons.person_outline_rounded),
                  _buildDialogTextField(controller: emailController, labelText: "Email", isDark: isDarkDialog, icon: Icons.alternate_email_rounded),
                  _buildDialogTextField(controller: bioController, labelText: "Bio", isDark: isDarkDialog, maxLines: 3, icon: Icons.notes_rounded),
                  _buildDialogTextField(controller: linkController, labelText: "Portfolio / WhatsApp Link", isDark: isDarkDialog, icon: Icons.link_rounded),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: Text("Cancel", style: GoogleFonts.poppins(color: Colors.grey, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 8),
                      BouncyButton(
                        onTap: () {
                          bContext.read<SettingsBloc>().add(
                            UpdateProfileRequested(name: nameController.text, email: emailController.text)
                          );
                          Navigator.pop(dialogContext);
                          BubbleNotification.show(context, "Profile & Bio updated", type: NotificationType.success);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: colorScheme.primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: Text("Save", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }


  void _showChangePasswordDialog(BuildContext bContext) {
    final TextEditingController oldPassController = TextEditingController();
    final TextEditingController newPassController = TextEditingController();

    showDialog(
      context: bContext,
      builder: (dialogContext) {
        final isDarkDialog = Theme.of(dialogContext).brightness == Brightness.dark;
        final colorScheme = Theme.of(dialogContext).colorScheme;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDarkDialog ? const Color(0xFF161616) : Colors.white,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: isDarkDialog ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 40, offset: const Offset(0, 10))
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Change Password",
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkDialog ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),
                _buildDialogTextField(controller: oldPassController, labelText: "Current Password", isDark: isDarkDialog, obscureText: true, icon: Icons.lock_outline_rounded),
                _buildDialogTextField(controller: newPassController, labelText: "New Password", isDark: isDarkDialog, obscureText: true, icon: Icons.lock_reset_rounded),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: Text("Cancel", style: GoogleFonts.poppins(color: Colors.grey, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 8),
                    BouncyButton(
                      onTap: () {
                        bContext.read<SettingsBloc>().add(ChangePasswordRequested(newPassController.text));
                        Navigator.pop(dialogContext);
                        BubbleNotification.show(context, "Password updated", type: NotificationType.success);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: colorScheme.primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: Text("Update", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _pickProfileImage(BuildContext bContext) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null && bContext.mounted) {
      final state = bContext.read<SettingsBloc>().state;
      if (state.profile != null) {
        bContext.read<SettingsBloc>().add(
          UpdateProfileRequested(
            name: state.profile!.name,
            email: state.profile!.email,
            profileImagePath: image.path,
          )
        );
      }
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) {
        final isDarkDialog = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDarkDialog ? const Color(0xFF1E1E1E) : Colors.white,
          title: Text("Logout", 
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: isDarkDialog ? Colors.white : Colors.black87,
            ),
          ),
          content: Text("Are you sure you want to log out?", 
            style: TextStyle(color: isDarkDialog ? Colors.white70 : Colors.black54),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              },
              child: const Text("Logout", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: TextStyle(color: isDarkDialog ? Colors.white60 : Colors.grey)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BlocConsumer<SettingsBloc, SettingsState>(
        listener: (context, state) {
           if (state.error != null) {
            BubbleNotification.show(context, state.error!, type: NotificationType.error);
          }
        },
        builder: (context, state) {
          if (state.isLoading || state.profile == null) {
            return const Center(child: BubbleLoader());
          }

          final profile = state.profile!;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Visual Header
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 32, 16, 32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark 
                        ? [colorScheme.primary.withValues(alpha: 0.1), Colors.transparent]
                        : [colorScheme.primary.withValues(alpha: 0.05), Colors.transparent],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Column(
                    children: [
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 55,
                              backgroundColor: colorScheme.surfaceContainerHighest,
                              backgroundImage: profile.profileImagePath.isNotEmpty
                                  ? FileImage(File(profile.profileImagePath))
                                  : null,
                              child: profile.profileImagePath.isEmpty
                                  ? Icon(Icons.person_rounded, size: 55, color: colorScheme.primary)
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: BouncyButton(
                                onTap: () => _pickProfileImage(context),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: isDark ? const Color(0xFF121212) : Colors.white, width: 3),
                                  ),
                                  child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        profile.name,
                        style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildIdentityStat("${profile.postsCount}", "Posts"),
                          const SizedBox(width: 8),
                          _buildIdentityStat("${profile.followingCount}", "Following"),
                          const SizedBox(width: 8),
                          _buildIdentityStat("${profile.followersCount}", "Followers"),
                        ],
                      ),
                      const SizedBox(height: 20),
                      BouncyButton(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UserProfilePage(
                                user: UserEntity(
                                  id: 'me',
                                  name: profile.name,
                                  profileUrl: profile.profileImagePath.isNotEmpty ? profile.profileImagePath : 'assets/icon.png',
                                  relation: UserRelation.accepted,
                                  followersCount: profile.followersCount,
                                  followingCount: profile.followingCount,
                                  postsCount: profile.postsCount,
                                ),
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "View Public Profile",
                            style: GoogleFonts.poppins(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Reorganized Settings Sections
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    
                    _buildSectionHeader(context, "How you use Floq"),

                    _buildSettingsTile(context, icon: Icons.person_outline_rounded, title: "Edit Profile", onTap: () => _showEditProfileDialog(context, profile.name, profile.email)),
                    _buildSettingsTile(context, icon: Icons.key_outlined, title: "Change Password", onTap: () => _showChangePasswordDialog(context)),
                    _buildSettingsTile(context, icon: Icons.notifications_active_outlined, title: "Notifications", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage()))),

                    _buildSwitchTile(context, icon: Icons.dark_mode_outlined, title: "Dark Mode", subtitle: "Toggle appearance", value: profile.isDarkTheme, onChanged: (v) {
                       themeNotifier.value = v ? ThemeMode.dark : ThemeMode.light;
                       context.read<SettingsBloc>().add(ToggleThemeRequested(v));
                    }),

                    const SizedBox(height: 32),
                    _buildSectionHeader(context, "Who can see your content"),
                    _buildSwitchTile(context, icon: Icons.lock_outline_rounded, title: "Private Account", subtitle: "Strict visibility", value: false, onChanged: (v){}),
                    _buildSettingsTile(context, icon: Icons.stars_rounded, title: "Close Friends", onTap: (){}),

                    const SizedBox(height: 32),
                    _buildSectionHeader(context, "How others can interact with you"),
                    _buildSettingsTile(context, icon: Icons.chat_bubble_outline_rounded, title: "Messages & Replies", onTap: (){}),
                    _buildSettingsTile(context, icon: Icons.alternate_email_rounded, title: "Tags & Mentions", onTap: (){}),
                    _buildSettingsTile(context, icon: Icons.block_rounded, title: "Blocked Accounts", onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BlocProvider(
                            create: (context) => UsersBloc(
                              repository: UsersRepositoryImpl(context.read<ApiClient>()),
                              feedRepository: FeedRepositoryImpl(context.read<ApiClient>()),
                            ),
                            child: const BlockedUsersPage(),
                          ),
                        ),
                      );
                    }),


                    const SizedBox(height: 32),
                    _buildSectionHeader(context, "What you see"),
                    _buildSettingsTile(context, icon: Icons.favorite_border_rounded, title: "Favorites", onTap: (){}),
                    _buildSettingsTile(context, icon: Icons.volume_off_outlined, title: "Muted Accounts", onTap: (){}),

                    const SizedBox(height: 32),
                    _buildSectionHeader(context, "Your app and media"),
                    _buildSettingsTile(context, icon: Icons.archive_outlined, title: "Archiving & Downloads", onTap: (){}),
                    _buildSettingsTile(context, icon: Icons.data_usage_rounded, title: "Data Usage & Media Quality", onTap: (){}),

                    const SizedBox(height: 32),
                    _buildSectionHeader(context, "More info and support"),
                    _buildSettingsTile(context, icon: Icons.help_outline_rounded, title: "Help Center", onTap: (){}),
                    _buildSettingsTile(context, icon: Icons.privacy_tip_outlined, title: "Privacy Policy", onTap: (){}),
                    _buildSettingsTile(context, icon: Icons.info_outline_rounded, title: "About", onTap: (){}),

                    const SizedBox(height: 48),
                    BouncyButton(
                      onTap: _logout,
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text("Logout", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Center(
                      child: Text(
                        "Floq v1.0.0+1",

                        style: GoogleFonts.poppins(
                          color: Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }


  Widget _buildDialogTextField({
    required TextEditingController controller,
    required String labelText,
    required bool isDark,
    bool obscureText = false,
    int maxLines = 1,
    IconData? icon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
        ),
        child: TextField(
          controller: controller,
          obscureText: obscureText,
          maxLines: maxLines,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: isDark ? Colors.white : Colors.black87,
          ),
          decoration: InputDecoration(
            labelText: labelText,
            labelStyle: GoogleFonts.poppins(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54),
            prefixIcon: icon != null ? Icon(icon, size: 20, color: colorScheme.primary.withValues(alpha: 0.7)) : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            floatingLabelBehavior: FloatingLabelBehavior.auto,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: BouncyButton(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            leading: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
            title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14)),
            trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile(BuildContext context, {required IconData icon, required String title, required String subtitle, required bool value, required ValueChanged<bool> onChanged}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        secondary: Icon(icon, color: colorScheme.primary, size: 22),
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        activeThumbColor: colorScheme.primary,
        activeTrackColor: colorScheme.primary.withValues(alpha: 0.3),
        value: value,

        onChanged: onChanged,
      ),
    );
  }

  Widget _buildIdentityStat(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12)),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
