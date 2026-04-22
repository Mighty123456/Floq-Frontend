import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../features/recent_chats/presentation/pages/recent_chats_page.dart';
import '../../../features/users/presentation/pages/contacts_page.dart';
import '../../../features/users/presentation/pages/users_page.dart';
import '../../../features/users/presentation/pages/requests_page.dart';
import '../../../features/settings/presentation/pages/notifications_page.dart';
import '../../../features/feed/domain/entities/story_entity.dart';
import '../../../features/feed/presentation/pages/feed_page.dart';
import '../../../features/feed/presentation/pages/create_post_page.dart';
import '../../../features/feed/presentation/pages/story_view_page.dart';

import '../../../features/users/presentation/pages/user_profile_page.dart';
import '../../../features/users/domain/entities/user_entity.dart';
import '../../../core/services/secure_storage_service.dart';
import 'dart:convert';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class NotificationItem {
  final String name;
  final String message;
  final String imageUrl;

  NotificationItem({
    required this.name,
    required this.message,
    required this.imageUrl,
  });
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late List<Widget> _pages;
  List<NotificationItem> notifications = [];

  @override
  void initState() {
    super.initState();
    _pages = [
      const FeedPage(),      // 0 -> Home
      const UsersPage(),     // 1 -> Explore
      const RecentChatsPage(),// 2 -> Messages
      const ContactsPage(),  // 3 -> Network
      RequestsPage(onRequestAccepted: _addNotification), // 4 -> Requests
      UserProfilePage(user: UserEntity(
        id: "me",
        name: "My Profile",
        profileUrl: "https://i.pravatar.cc/150?u=my_current_user",
        relation: UserRelation.accepted,
      )), // 5 -> Profile
    ];

    _loadUser();
  }

  Future<void> _loadUser() async {
    final storage = SecureStorageService();
    final userJson = await storage.getUser();
    if (userJson != null) {
      final map = jsonDecode(userJson);
      final id = map['id'] ?? map['_id'] ?? 'me';
      final name = map['fullName'] ?? map['username'] ?? map['name'] ?? 'My Profile';
      final avatar = map['avatar'] ?? "https://i.pravatar.cc/150?u=$id";
      
      if (mounted) {
        setState(() {
          _pages[5] = UserProfilePage(user: UserEntity(
            id: 'me', // Keeping 'me' as id to maintain `_isMe` logic in UserProfilePage
            name: name,
            profileUrl: avatar,
            relation: UserRelation.accepted,
          ));
        });
      }
    }
  }



  void _addNotification(String name) {
    setState(() {
      notifications.add(
        NotificationItem(
          name: name,
          message: "Request accepted",
          imageUrl: "https://i.pravatar.cc/150?u=$name",
        ),
      );
    });
  }

  void clearNotifications() {
    setState(() {
      notifications.clear();
    });
  }

  void _showCreationSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
            Text(
              "Create New",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCreationOption(
                  context,
                  icon: Icons.grid_view_rounded,
                  label: "Post",
                  color: Colors.blueAccent,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatePostPage()));
                  },
                ),
                _buildCreationOption(
                  context,
                  icon: Icons.camera_rounded,
                  label: "Story",
                  color: Colors.purpleAccent,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StoryViewPage(
                          userName: "Your Story",
                          profileUrl: "https://i.pravatar.cc/150?u=my_current_user",
                          stories: [
                            StoryEntity(
                              id: "my_temp_story",
                              mediaUrl: "https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=800&q=80",
                              caption: "",
                              type: "image",
                              createdAt: DateTime.now(),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                _buildCreationOption(
                  context,
                  icon: Icons.play_circle_fill_rounded,
                  label: "Reel",
                  color: Colors.orangeAccent,
                  onTap: () {
                    Navigator.pop(context);
                    // Reel creation logic
                  },
                ),
                _buildCreationOption(
                  context,
                  icon: Icons.video_call_rounded,
                  label: "Live",
                  color: Colors.redAccent,
                  onTap: () {
                    Navigator.pop(context);
                    // Live logic
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCreationOption(BuildContext context, {required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
        title: Hero(
          tag: 'bubble_title',
          child: DefaultTextStyle(
            style: GoogleFonts.pacifico(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
            child: AnimatedTextKit(
              repeatForever: true,
              animatedTexts: [
                WavyAnimatedText('Floq'),
              ],
            ),
          ),
        ),
        centerTitle: false,
        elevation: 0,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications_none_rounded, 
                  color: isDark ? Colors.white70 : Colors.black87),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationsPage()),
                  );
                },
              ),
              if (notifications.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: isDark ? const Color(0xFF121212) : Colors.white, width: 1.5),
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Center(
                      child: Text(
                        notifications.length.toString(),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.favorite_border_rounded, 
              color: isDark ? Colors.white70 : Colors.black87),
            onPressed: () {
              // Future: Navigate to activity feed
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? Colors.white10 : Colors.black12,
              width: 0.5,
            ),
          ),
        ),
        child: NavigationBar(
          height: 65,
          elevation: 0,
          backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
          selectedIndex: _selectedIndex >= 3 ? _selectedIndex + 1 : _selectedIndex,
          onDestinationSelected: (index) {
            if (index == 3) {
              _showCreationSheet();
            } else {
              setState(() {
                _selectedIndex = index > 3 ? index - 1 : index;
              });
            }
          },

          indicatorColor: colorScheme.primary.withValues(alpha: 0.15),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: "Home",
            ),
            const NavigationDestination(
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore),
              label: "Explore",
            ),
            const NavigationDestination(
              icon: Badge(
                label: Text("3"),
                child: Icon(Icons.forum_outlined),
              ),
              selectedIcon: Badge(
                label: Text("3"),
                child: Icon(Icons.forum),
              ),
              label: "Messages",
            ),
            NavigationDestination(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
              ),
              label: "Create",
            ),
            const NavigationDestination(
              icon: Icon(Icons.contacts_outlined),
              selectedIcon: Icon(Icons.contacts),
              label: "Network",
            ),
            NavigationDestination(
              icon: Badge(
                label: Text(notifications.length.toString()),
                isLabelVisible: notifications.isNotEmpty,
                child: const Icon(Icons.mail_outline_rounded),
              ),
              selectedIcon: Badge(
                label: Text(notifications.length.toString()),
                isLabelVisible: notifications.isNotEmpty,
                child: const Icon(Icons.mail_rounded),
              ),
              label: "Requests",
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: "Profile",
            ),
          ],
        ),
      ),
    );
  }



}

class UserSearchDelegate extends SearchDelegate<String> {
  final List<String> users;
  UserSearchDelegate({required this.users});

  @override
  List<Widget>? buildActions(BuildContext context) => [
    IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
  ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => close(context, ''),
  );

  @override
  Widget buildResults(BuildContext context) {
    final results = users.where((user) => user.toLowerCase().contains(query.toLowerCase())).toList();
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) => ListTile(
        title: Text(results[index]),
        onTap: () => close(context, results[index]),
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = users.where((user) => user.toLowerCase().contains(query.toLowerCase())).toList();
    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) => ListTile(
        title: Text(suggestions[index]),
        onTap: () {
          query = suggestions[index];
          showResults(context);
        },
      ),
    );
  }
}
