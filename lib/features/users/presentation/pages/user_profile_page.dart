import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/users_bloc.dart';
import '../bloc/users_state.dart';
import '../bloc/users_event.dart';
import '../../domain/entities/user_entity.dart';
import '../../../../core/presentation/widgets/bouncy_button.dart';
import '../../../../core/presentation/widgets/bubble_notification.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../../feed/domain/entities/story_entity.dart';
import '../../../feed/presentation/pages/story_group_view.dart';
import 'edit_profile_page.dart';
import 'connection_list_page.dart';
import '../../../../core/presentation/widgets/floq_avatar.dart';
import '../../../auth/presentation/widgets/account_switcher_bottom_sheet.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';

class UserProfilePage extends StatefulWidget {
  final UserEntity user;

  const UserProfilePage({super.key, required this.user});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late bool _isMe;

  @override
  void initState() {
    super.initState();
    _isMe = widget.user.id == 'me';
    _tabController = TabController(length: _isMe ? 4 : 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showZoomedProfileImage(BuildContext context) {
    if (widget.user.profileUrl.isEmpty) return;
    
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.95),
        barrierDismissible: true,
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              actions: [
                IconButton(
                  icon: const Icon(Icons.download_rounded),
                  onPressed: () => BubbleNotification.show(context, "Image saved to gallery"),
                ),
              ],
            ),
            body: GestureDetector(
              onVerticalDragUpdate: (details) {
                if (details.delta.dy > 10) Navigator.pop(context);
              },
              child: Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Hero(
                    tag: 'user_image_${widget.user.id}',
                    child: Image.network(
                      widget.user.profileUrl,
                      fit: BoxFit.contain,
                      width: double.infinity,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }



  void _showAccountSwitcherSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const AccountSwitcherBottomSheet(),
    );
  }

  void _showMoreMenu(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMe = widget.user.id == 'me';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            if (isMe) ...[
              _buildMenuItem(
                context,
                icon: Icons.settings_rounded,
                label: "Account Settings",
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
                },
              ),
              _buildMenuItem(
                context, 
                icon: Icons.history_rounded, 
                label: "Archive", 
                onTap: () {
                  Navigator.pop(context);
                  _showArchiveView(context);
                }
              ),
              _buildMenuItem(
                context, 
                icon: Icons.qr_code_scanner_rounded, 
                label: "QR Code", 
                onTap: () {
                  Navigator.pop(context);
                  _showShareProfileSheet();
                }
              ),
              _buildMenuItem(context, icon: Icons.bookmark_outline_rounded, label: "Saved Items", onTap: () {
                Navigator.pop(context);
                _tabController.animateTo(3);
              }),
            ] else ...[
              _buildMenuItem(
                context, 
                icon: Icons.report_gmailerrorred_rounded, 
                label: "Report", 
                color: Colors.redAccent, 
                onTap: () {
                  Navigator.pop(context);
                  _showReportDialog(context);
                }
              ),
              _buildMenuItem(
                context, 
                icon: Icons.block_flipped, 
                label: "Block", 
                color: Colors.redAccent, 
                onTap: () {
                  Navigator.pop(context);
                  _showBlockDialog(context);
                }
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showArchiveView(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text("Archive"),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_rounded, size: 80, color: Colors.grey.withValues(alpha: 0.3)),
                const SizedBox(height: 24),
                Text(
                  "Your Archive is Empty",
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Stories you share will appear here\nafter they disappear.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Report ${widget.user.name}"),
        content: const Text("Is there something wrong with this profile? Our team will review your report immediately."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              context.read<UsersBloc>().add(ReportUserRequested(widget.user.id, "Profile violation"));
              Navigator.pop(context);
              BubbleNotification.show(context, "Report submitted successfully.", type: NotificationType.success);
            }, 
            child: const Text("Report", style: TextStyle(color: Colors.redAccent))
          ),

        ],
      ),
    );
  }

  void _showBlockDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Block ${widget.user.name}?"),
        content: Text("They won't be able to find your profile, posts, or story on Floq. Floq won't let them know you blocked them."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              context.read<UsersBloc>().add(BlockUserRequested(widget.user.id));
              Navigator.pop(context);
              BubbleNotification.show(context, "${widget.user.name} has been blocked.", type: NotificationType.info);
              if (Navigator.canPop(context)) Navigator.pop(context); // Go back from profile
            }, 
            child: const Text("Block", style: TextStyle(color: Colors.redAccent))
          ),

        ],
      ),
    );
  }

  void _showShareProfileSheet() {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E).withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  Text(
                    "Share Identity",
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.5, curve: Curves.easeOutExpo),
                  const SizedBox(height: 24),
                  
                  // Interactive QR
                  _buildInteractiveQr(context),
                  const SizedBox(height: 32),
                  
                  Text(
                    "floq.me/${widget.user.name.toLowerCase().replaceAll(' ', '')}",
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                      letterSpacing: 0.5,
                    ),
                  ).animate().fadeIn(delay: 500.ms, duration: 700.ms).slideY(begin: 0.4, curve: Curves.easeOutExpo),
                  const SizedBox(height: 32),
                  
                  Text(
                    "Tap to share via",
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey, letterSpacing: 1),
                  ).animate().fadeIn(delay: 600.ms),
                  const SizedBox(height: 24),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildShareIcon(
                        Icons.chat_bubble_rounded, 
                        "WhatsApp", 
                        Colors.greenAccent, 
                        onTap: () async {
                          HapticFeedback.mediumImpact();
                          final profileLink = "https://floq.me/profile/${widget.user.name.toLowerCase().replaceAll(' ', '')}";
                          final url = Uri.parse("whatsapp://send?text=Check out my Floq profile: $profileLink");
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url);
                          } else {
                            if (context.mounted) BubbleNotification.show(context, "WhatsApp not installed", type: NotificationType.error);
                          }
                        }
                      ).animate().fadeIn(delay: 700.ms, duration: 600.ms).slideY(begin: 0.6, curve: Curves.easeOutExpo).scale(curve: Curves.easeOutBack),
                      _buildShareIcon(Icons.camera_alt_rounded, "Stories", Colors.pinkAccent, onTap: () {
                        HapticFeedback.mediumImpact();
                        Navigator.pop(context);
                        BubbleNotification.show(context, "Profile card generated for Stories!", type: NotificationType.success);
                      }).animate().fadeIn(delay: 800.ms, duration: 600.ms).slideY(begin: 0.6, curve: Curves.easeOutExpo).scale(curve: Curves.easeOutBack),
                      _buildShareIcon(Icons.copy_rounded, "Copy", Colors.grey, onTap: () {
                        HapticFeedback.mediumImpact();
                        final profileLink = "https://floq.me/profile/${widget.user.name.toLowerCase().replaceAll(' ', '')}";
                        Clipboard.setData(ClipboardData(text: profileLink));
                        Navigator.pop(context);
                        BubbleNotification.show(context, "Link copied to clipboard!", type: NotificationType.success);
                      }).animate().fadeIn(delay: 900.ms, duration: 600.ms).slideY(begin: 0.6, curve: Curves.easeOutExpo).scale(curve: Curves.easeOutBack),
                      _buildShareIcon(Icons.more_horiz_rounded, "More", Theme.of(context).colorScheme.primary, onTap: () async {
                        HapticFeedback.mediumImpact();
                        final profileLink = "https://floq.me/profile/${widget.user.name.toLowerCase().replaceAll(' ', '')}";
                        final url = Uri.parse("mailto:?subject=Connect with me on Floq&body=Check out my profile: $profileLink");
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        }
                      }).animate().fadeIn(delay: 1000.ms, duration: 600.ms).slideY(begin: 0.6, curve: Curves.easeOutExpo).scale(curve: Curves.easeOutBack),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInteractiveQr(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(seconds: 2),
      curve: Curves.easeInOutSine,
      builder: (context, double value, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer Pulse Glow
              AnimatedBuilder(
                animation: _tabController.animation!, // Reusing a controller for sync or just value
                builder: (context, child) {
                  return Container(
                    width: 210,
                    height: 210,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.2 * (1 + value)),
                          blurRadius: 20 * value,
                          spreadRadius: 5 * value,
                        ),
                      ],
                    ),
                  );
                },
              ),
              
              // QR Container
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3), width: 2),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        "https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=${Uri.encodeComponent("https://floq.me/profile/${widget.user.name.toLowerCase().trim().replaceAll(' ', '')}")}",
                        width: 180,
                        height: 180,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const SizedBox(
                            width: 180,
                            height: 180,
                            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.qr_code, size: 100),
                      ),
                    ),
                    
                    // Scanning Animation Line
                    Positioned(
                      top: 180 * value,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary,
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.primary.withValues(alpha: 0),
                              colorScheme.primary,
                              colorScheme.primary.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Center Logo
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.primary.withValues(alpha: 0.5), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.4),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Icon(Icons.blur_on_rounded, color: colorScheme.primary, size: 28),
              ),
            ],
          ),
        ).animate().scale(delay: 400.ms, curve: Curves.easeOutExpo, duration: 900.ms).fadeIn(duration: 700.ms).slideY(begin: 0.15, curve: Curves.easeOutExpo);
      },
    );
  }

  Widget _buildShareIcon(IconData icon, String label, Color color, {required VoidCallback onTap}) {
    return Column(
      children: [
        BouncyButton(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildMenuItem(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap, Color? color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Icon(icon, color: color ?? (isDark ? Colors.white70 : Colors.black87)),
      title: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: color ?? (isDark ? Colors.white : Colors.black87),
        ),
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<UsersBloc, UsersState>(
      builder: (context, state) {
        // Resolve latest user state for relations
        UserRelation relation = widget.user.relation;
        try {
          final updatedUser = state.users.firstWhere((u) => u.id == widget.user.id);
          relation = updatedUser.relation;
        } catch (_) {
          // Fallback to widget user
        }

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
          body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Sticky AppBar
          SliverAppBar(
            pinned: true,
            automaticallyImplyLeading: false, 
            backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: widget.user.id != 'me' ? IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, 
                color: isDark ? Colors.white : Colors.black87, size: 20),
              onPressed: () => Navigator.pop(context),
            ) : null,
            title: GestureDetector(
              onTap: _isMe ? () => _showAccountSwitcherSheet() : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.user.name,
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  if (_isMe) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down_rounded, 
                      color: isDark ? Colors.white54 : Colors.black54, size: 20),
                  ],
                ],
              ),
            ),

            actions: [
              IconButton(
                icon: Icon(Icons.more_horiz_rounded, color: isDark ? Colors.white : Colors.black87),
                onPressed: () => _showMoreMenu(context),
              )
            ],
          ),

          // Main Profile Identity Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Image & Stats
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _showZoomedProfileImage(context),
                        child: Hero(
                          tag: 'user_image_${widget.user.id}',
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [colorScheme.primary, colorScheme.secondary],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 46,
                              backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
                              child: FloqAvatar(
                              radius: 43,
                              name: widget.user.name,
                              imageUrl: widget.user.profileUrl,
                            ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 32),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildCompactStat(context, "${widget.user.postsCount}", "Posts", onTap: () {
                                _tabController.animateTo(0);
                            }),
                            _buildCompactStat(context, "${widget.user.followersCount}", "Followers", onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => ConnectionListPage(
                                  user: widget.user,
                                  type: ConnectionListType.followers,
                                )));
                            }),
                            _buildCompactStat(context, "${widget.user.followingCount}", "Following", onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => ConnectionListPage(
                                  user: widget.user,
                                  type: ConnectionListType.following,
                                )));
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Row 2: Name & Description
                  Text(
                    widget.user.name,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (widget.user.bio.isNotEmpty)
                    Text(
                      "Member since 2024", // Or more specific data if available
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.primary,
                        letterSpacing: 0.3,
                      ),
                    ),
                  const SizedBox(height: 12),
                  
                  // Bio
                  Text(
                    widget.user.bio.isNotEmpty 
                      ? widget.user.bio 
                      : (_isMe ? "Write something about yourself..." : "No bio yet."),
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: isDark ? Colors.white.withValues(alpha: 0.8) : Colors.black54,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Links Carousel (Unique Scrollable Pills)
                  if (widget.user.links.isNotEmpty || _isMe)
                    SizedBox(
                      height: 32,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        children: widget.user.links.isEmpty 
                          ? [
                              if (_isMe)
                                _buildMinimalLink(context, Icons.add_circle_outline_rounded, "Add Link", colorScheme.primary, onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfilePage(user: widget.user)));
                                }),
                            ]
                          : widget.user.links.entries.map((e) {
                              IconData icon = Icons.link_rounded;
                              Color color = colorScheme.primary;
                              final key = e.key.toLowerCase();
                              if (key.contains('whatsapp')) {
                                icon = Icons.chat_bubble_rounded;
                                color = Colors.greenAccent;
                              } else if (key.contains('portfolio')) {
                                icon = Icons.grid_view_rounded;
                                color = Colors.blueAccent;
                              } else if (key.contains('twitter') || key.contains('x.com')) {
                                icon = Icons.alternate_email_rounded;
                                color = Colors.lightBlueAccent;
                              }
                              return _buildMinimalLink(context, icon, e.key, color, subLabel: e.value);
                            }).toList(),
                      ),
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Row 3: Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: BouncyButton(
                          onTap: () {
                            if (_isMe) {
                              Navigator.push(
                                context, 
                                MaterialPageRoute(
                                  builder: (_) => EditProfilePage(user: widget.user)
                                )
                              );
                            } else {
                               if (relation == UserRelation.accepted) {
                                  // context.read<UsersBloc>().add(UnfollowUser(widget.user.id));
                                  BubbleNotification.show(context, "You are already connected.");
                               } else {
                                  context.read<UsersBloc>().add(SendRequest(widget.user.id));
                                  BubbleNotification.show(
                                    context,
                                    "Invitation sent to ${widget.user.name}",
                                    type: NotificationType.success,
                                  );
                               }
                            }
                          },
                          child: Container(
                            height: 42,
                            decoration: BoxDecoration(
                              color: (_isMe || relation == UserRelation.accepted) ? (isDark ? Colors.white12 : Colors.grey[200]) : colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                _isMe 
                                  ? "Edit Profile" 
                                  : (relation == UserRelation.accepted ? "Message" : "Connect"),
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: (_isMe || relation == UserRelation.accepted) ? (isDark ? Colors.white : Colors.black) : Colors.white, 
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: BouncyButton(
                          onTap: () => _showShareProfileSheet(),
                          child: Container(
                            height: 42,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                            ),
                            child: Center(
                              child: Text(
                                "Share Profile",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      BouncyButton(
                        onTap: () {},
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                          ),
                          child: Icon(_isMe ? Icons.person_search_outlined : Icons.person_add_outlined, size: 20),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Highlights
          SliverToBoxAdapter(
            child: Container(
              height: 110,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _isMe ? 1 : 0,
                itemBuilder: (context, index) {
                  final labels = ["Travel", "Vibes", "Food", "Tech", "Art", "Memories"];
                   if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 18),
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: isDark ? Colors.white12 : Colors.black12, width: 1.5),
                            ),
                            child: const Icon(Icons.add_rounded, size: 24, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Text("New", style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey)),
                        ],
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: 18),
                    child: GestureDetector(
                      onTap: () {
                        final highlightGroups = List.generate(labels.length, (lIndex) => StoryGroupEntity(
                          userId: widget.user.id,
                          userName: labels[lIndex],
                          userAvatar: widget.user.profileUrl,
                          stories: [
                            StoryEntity(
                              id: "h_${lIndex}_1",
                              mediaUrl: "https://picsum.photos/seed/highlight${widget.user.id}${lIndex}_1/800/1200",
                              caption: "",
                              type: "image",
                              createdAt: DateTime.now(),
                            ),
                          ],
                        ));

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StoryGroupView(
                              storyGroups: highlightGroups,
                              initialGroupIndex: index - 1,
                            ),
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
                            ),
                            child: ClipOval(
                              child: Image.network(
                                "https://picsum.photos/seed/highlight${widget.user.id}$index/150/150",
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(labels[index - 1], style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Tab Bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _tabController,
                indicatorColor: colorScheme.primary,
                indicatorWeight: 3,
                labelColor: isDark ? Colors.white : Colors.black,
                unselectedLabelColor: Colors.grey,
                padding: const EdgeInsets.symmetric(horizontal: 0),
                tabs: [
                  const Tab(icon: Icon(Icons.grid_on_rounded, size: 22)),
                  const Tab(icon: Icon(Icons.play_circle_outline_rounded, size: 22)),
                  const Tab(icon: Icon(Icons.account_box_outlined, size: 22)),
                  if (_isMe) const Tab(icon: Icon(Icons.bookmark_outline_rounded, size: 22)),
                ],
              ),
              isDark ? const Color(0xFF121212) : Colors.white,
            ),
          ),

          // Content
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPostsGrid(isDark),
                _buildReelsGrid(isDark),
                _buildTaggedGrid(isDark),
                if (_isMe) _buildSavedGrid(isDark),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

  Widget _buildCompactStat(BuildContext context, String value, String label, {VoidCallback? onTap}) {
    return BouncyButton(
      onTap: onTap ?? () => BubbleNotification.show(context, "Viewing $label history..."),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalLink(BuildContext context, IconData icon, String label, Color color, {VoidCallback? onTap, String? subLabel}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: BouncyButton(
        onTap: onTap ?? () => BubbleNotification.show(context, "Opening link: ${subLabel ?? label}"),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostsGrid(bool isDark) {
    return _buildEmptyTabState(isDark, Icons.grid_on_rounded, "No posts yet");
  }

  Widget _buildReelsGrid(bool isDark) {
    return _buildEmptyTabState(isDark, Icons.video_library_rounded, "No reels yet");
  }

  Widget _buildSavedGrid(bool isDark) {
    return _buildEmptyTabState(isDark, Icons.bookmark_border_rounded, "No saved items");
  }

  Widget _buildTaggedGrid(bool isDark) {
    return _buildEmptyTabState(isDark, Icons.account_box_outlined, "No tagged posts yet");
  }

  Widget _buildEmptyTabState(bool isDark, IconData icon, String message) {
    return Center(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(), // Centering works better if we don't allow scroll usually, but here we want to avoid crash
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 60, color: Colors.grey.withValues(alpha: 0.3)),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.grey,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar, this._backgroundColor);

  final TabBar _tabBar;
  final Color _backgroundColor;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: _backgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

