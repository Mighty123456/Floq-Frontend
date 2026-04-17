import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/entities/user_entity.dart';
import '../../../../core/presentation/widgets/bouncy_button.dart';
import '../../../../core/presentation/widgets/bubble_notification.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../../feed/presentation/pages/story_view_page.dart';
import '../../../feed/presentation/pages/story_group_view.dart';
import 'edit_profile_page.dart';



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
    _tabController = TabController(length: _isMe ? 3 : 2, vsync: this);
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

  void _showPostDetails(BuildContext context, int index, String imageUrl) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder( // Use StatefulBuilder for interactive icons
        builder: (context, setSheetState) {
          bool isLiked = false;
          bool isBookmarked = false;

          return DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (context, scrollController) => Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
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
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        // Header
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            radius: 20,
                            backgroundImage: NetworkImage(widget.user.profileUrl),
                          ),
                          title: Text(widget.user.name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
                          subtitle: Text("2 hours ago", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                          trailing: IconButton(
                            icon: const Icon(Icons.more_vert_rounded),
                            onPressed: () {},
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Main Post Image
                        GestureDetector(
                          onDoubleTap: () {
                            setSheetState(() => isLiked = true);
                            BubbleNotification.show(context, "Liked!", type: NotificationType.success);
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.network(imageUrl, fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Interaction Bar (NOW ALL CLICKABLE)
                        Row(
                          children: [
                            _buildInteractionIconButton(
                              icon: isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded, 
                              label: isLiked ? "1,201" : "1,200", 
                              color: isLiked ? Colors.redAccent : (isDark ? Colors.white : Colors.black87),
                              onTap: () => setSheetState(() => isLiked = !isLiked),
                            ),
                            _buildInteractionIconButton(
                              icon: Icons.chat_bubble_outline_rounded, 
                              label: "85", 
                              color: isDark ? Colors.white : Colors.black87,
                              onTap: () => BubbleNotification.show(context, "Opening comments thread..."),
                            ),
                            _buildInteractionIconButton(
                              icon: Icons.repeat_rounded, 
                              label: "24", 
                              color: Colors.greenAccent,
                              onTap: () => BubbleNotification.show(context, "Recapping post to your feed"),
                            ),
                            const Spacer(),
                            BouncyButton(
                              onTap: () => setSheetState(() => isBookmarked = !isBookmarked),
                              child: Icon(
                                isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                                color: isBookmarked ? Colors.orangeAccent : (isDark ? Colors.white : Colors.black87),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        Text(
                          "Exploring the hidden gems of the city today. The vibe is just incredible! ✨ #Floq #CityLife #Adventures",
                          style: GoogleFonts.poppins(fontSize: 14, height: 1.5),
                        ),
                        const Divider(height: 48),
                        
                        // Comments Section
                        Text("Comments (85)", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 24),
                        _buildMockComment("alex_vibe", "Man this shot is amazing! 🔥"),
                        _buildMockComment("sara_n", "Love those colors!"),
                        _buildMockComment("creative_cat", "Need to visit this place soon."),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  Widget _buildInteractionIconButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: BouncyButton(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildMockComment(String user, String comment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 14, backgroundImage: NetworkImage("https://i.pravatar.cc/100?u=$user")),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(comment, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[400])),
              ],
            ),
          ),
          const Icon(Icons.favorite_border_rounded, size: 14, color: Colors.grey),
        ],
      ),
    );
  }

  void _showReelDetails(BuildContext context, int index, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoryViewPage(
          userName: widget.user.name,
          profileUrl: widget.user.profileUrl,
          stories: [
            StoryItem(url: imageUrl),
          ],
        ),
      ),
    );
  }

  void _showAccountSwitcherSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
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
            
            // Current Account
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.primary, width: 2),
                ),
                child: CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(widget.user.profileUrl),
                ),
              ),
              title: Text(
                widget.user.name,
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              trailing: Icon(Icons.check_circle_rounded, color: colorScheme.primary),
              onTap: () => Navigator.pop(context),
            ),
            
            // Add Account
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add_rounded),
              ),
              title: Text(
                "Add New Account",
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              onTap: () {
                Navigator.pop(context);
                BubbleNotification.show(
                  context,
                  "Redirecting to secure login...",
                  type: NotificationType.info,
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
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
                _tabController.animateTo(2);
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
              Navigator.pop(context);
              BubbleNotification.show(context, "${widget.user.name} has been blocked.", type: NotificationType.info);
            }, 
            child: const Text("Block", style: TextStyle(color: Colors.redAccent))
          ),
        ],
      ),
    );
  }

  void _showShareProfileSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Share",
      barrierColor: Colors.black.withValues(alpha: 0.8),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) => const SizedBox(),
      transitionBuilder: (context, anim1, anim2, child) {
        final curve = Curves.elasticOut.transform(anim1.value);
        return Transform.scale(
          scale: curve,
          child: Opacity(
            opacity: anim1.value,
            child: Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.2),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Share Identity",
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Interactive QR
                      _buildInteractiveQr(context),
                      const SizedBox(height: 24),
                      
                      Text(
                        "floq.me/${widget.user.name.toLowerCase().replaceAll(' ', '')}",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 24),

                      
                      Text(
                        "Tap to share via",
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      
                  Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildShareIcon(Icons.chat_bubble_rounded, "WhatsApp", Colors.greenAccent, onTap: () => Navigator.pop(context)),
                          _buildShareIcon(Icons.camera_alt_rounded, "Stories", Colors.pinkAccent, onTap: () {
                            Navigator.pop(context);
                            BubbleNotification.show(
                              context,
                              "Shared to your stories!",
                              type: NotificationType.success,
                            );
                          }),
                          _buildShareIcon(Icons.copy_rounded, "Copy", Colors.grey, onTap: () => Navigator.pop(context)),
                          _buildShareIcon(Icons.more_horiz_rounded, "More", colorScheme.primary, onTap: () => Navigator.pop(context)),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
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
              CustomPaint(
                size: const Size(200, 200),
                painter: _QrPainter(
                  color: colorScheme.primary.withValues(alpha: 0.8 + (0.2 * value)),
                  dotColor: colorScheme.secondary.withValues(alpha: 0.3),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Icon(Icons.blur_on_rounded, color: colorScheme.primary, size: 32),
              ),
            ],
          ),
        );
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
                    _isMe ? "My Profile" : widget.user.name,
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
                              child: CircleAvatar(
                                radius: 43,
                                backgroundImage: NetworkImage(widget.user.profileUrl),
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
                            _buildCompactStat(context, "52", "Posts"),
                            _buildCompactStat(context, "12.4k", "Followers"),
                            _buildCompactStat(context, "850", "Following"),
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
                  Text(
                    "Digital Creator • New York",
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
                      : "Design enthusiast & tech explorer. Building the future of social interaction @Floq. Let's connect! 🚀",
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: isDark ? Colors.white.withValues(alpha: 0.8) : Colors.black54,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Links Carousel (Unique Scrollable Pills)
                  SizedBox(
                    height: 32,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      children: widget.user.links.isEmpty 
                        ? [
                            _buildMinimalLink(context, Icons.link_rounded, "Portfolio", Colors.blueAccent),
                            _buildMinimalLink(context, Icons.chat_bubble_rounded, "WhatsApp", Colors.greenAccent),
                            _buildMinimalLink(context, Icons.language_rounded, "blog.floq.me", Colors.purpleAccent),
                          ]
                        : widget.user.links.entries.map((e) {
                            IconData icon = Icons.link_rounded;
                            Color color = colorScheme.primary;
                            if (e.key.toLowerCase().contains('whatsapp')) {
                              icon = Icons.chat_bubble_rounded;
                              color = Colors.greenAccent;
                            } else if (e.key.toLowerCase().contains('portfolio')) {
                              icon = Icons.grid_view_rounded;
                              color = Colors.blueAccent;
                            }
                            return _buildMinimalLink(context, icon, e.value, color);
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
                            } else if (widget.user.relation != UserRelation.accepted) {
                               BubbleNotification.show(
                                context,
                                "Invitation sent to ${widget.user.name}",
                                type: NotificationType.success,
                              );
                            }
                          },
                          child: Container(
                            height: 42,
                            decoration: BoxDecoration(
                              color: (_isMe || widget.user.relation == UserRelation.accepted) ? (isDark ? Colors.white12 : Colors.grey[200]) : colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                _isMe 
                                  ? "Edit Profile" 
                                  : (widget.user.relation == UserRelation.accepted ? "Message" : "Connect"),
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: (_isMe || widget.user.relation == UserRelation.accepted) ? (isDark ? Colors.white : Colors.black) : Colors.white, 
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
                itemCount: 6,
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
                        final highlightGroups = List.generate(labels.length, (lIndex) => {
                          "userName": labels[lIndex],
                          "profileUrl": widget.user.profileUrl,
                          "stories": [
                            StoryItem(url: "https://picsum.photos/seed/highlight${widget.user.id}${lIndex}_1/800/1200"),
                            StoryItem(url: "https://picsum.photos/seed/highlight${widget.user.id}${lIndex}_2/800/1200"),
                            StoryItem(url: "https://picsum.photos/seed/highlight${widget.user.id}${lIndex}_3/800/1200"),
                          ],
                        });

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StoryGroupView(
                              userStories: highlightGroups,
                              initialUserIndex: index - 1,
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
                if (_isMe) _buildSavedGrid(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStat(BuildContext context, String value, String label) {
    return BouncyButton(
      onTap: () => BubbleNotification.show(context, "Viewing $label history..."),
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

  Widget _buildMinimalLink(BuildContext context, IconData icon, String label, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: BouncyButton(
        onTap: () => BubbleNotification.show(context, "Opening link: $label"),
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
    return GridView.builder(
      padding: const EdgeInsets.all(1),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 1.5,
        crossAxisSpacing: 1.5,
        childAspectRatio: 1,
      ),
      itemCount: 15,
      itemBuilder: (context, index) {
        final imageUrl = "https://picsum.photos/seed/post${widget.user.id}$index/300/300";
        return GestureDetector(
          onTap: () => _showPostDetails(context, index, imageUrl),
          child: Container(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[200],
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }

  Widget _buildReelsGrid(bool isDark) {
    return GridView.builder(
      padding: const EdgeInsets.all(1),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 1.5,
        crossAxisSpacing: 1.5,
        childAspectRatio: 0.6,
      ),
      itemCount: 9,
      itemBuilder: (context, index) {
        final imageUrl = "https://picsum.photos/seed/reel${widget.user.id}$index/400/700";
        return GestureDetector(
          onTap: () => _showReelDetails(context, index, imageUrl),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
              ),
              Positioned(
                bottom: 8,
                left: 8,
                child: Row(
                  children: [
                    const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 16),
                    const SizedBox(width: 2),
                    Text(
                      "${(index + 1) * 2}k",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSavedGrid(bool isDark) {
    return GridView.builder(
      padding: const EdgeInsets.all(1),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 1.5,
        crossAxisSpacing: 1.5,
        childAspectRatio: 1,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        final imageUrl = "https://picsum.photos/seed/saved$index/300/300";
        return GestureDetector(
          onTap: () {
            if (index % 3 == 0) {
              _showReelDetails(context, index, imageUrl);
            } else {
              _showPostDetails(context, index, imageUrl);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[200],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                ),
                if (index % 3 == 0) // Mock reels in saved
                  const Positioned(
                    top: 8,
                    right: 8,
                    child: Icon(Icons.play_circle_outline_rounded, color: Colors.white, size: 20),
                  ),
              ],
            ),
          ),
        );
      },
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

class _QrPainter extends CustomPainter {
  final Color color;
  final Color dotColor;

  _QrPainter({required this.color, required this.dotColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final bgPaint = Paint()..color = dotColor;
    
    const double padding = 2;
    const int count = 12;
    final double cellSize = size.width / count;

    for (int i = 0; i < count; i++) {
      for (int j = 0; j < count; j++) {
        // Skip central area for logo
        if (i >= 5 && i <= 6 && j >= 5 && j <= 6) continue;
        
        final rect = Rect.fromLTWH(
          i * cellSize + padding,
          j * cellSize + padding,
          cellSize - (padding * 2),
          cellSize - (padding * 2),
        );

        // Pattern logic
        if ((i + j) % 3 == 0 || (i * j) % 5 == 0) {
          canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), paint);
        } else {
          canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), bgPaint);
        }
      }
    }

    // Draw Corner squares (QR style)
    _drawCorner(canvas, Offset.zero, cellSize, paint);
    _drawCorner(canvas, Offset(size.width - (cellSize * 3), 0), cellSize, paint);
    _drawCorner(canvas, Offset(0, size.height - (cellSize * 3)), cellSize, paint);
  }

  void _drawCorner(Canvas canvas, Offset offset, double cellSize, Paint paint) {
    final rect = Rect.fromLTWH(offset.dx, offset.dy, cellSize * 3, cellSize * 3);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      Paint()..color = color.withValues(alpha: 0.2),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(offset.dx + cellSize, offset.dy + cellSize, cellSize, cellSize),
        const Radius.circular(4),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _QrPainter oldDelegate) => oldDelegate.color != color;
}

