import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../features/recent_chats/presentation/bloc/recent_chats_bloc.dart';
import '../../../features/recent_chats/presentation/bloc/recent_chats_state.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../features/recent_chats/presentation/pages/recent_chats_page.dart';
import '../../../features/users/presentation/pages/users_page.dart';
import '../../../features/users/presentation/pages/requests_page.dart';
import '../../../features/settings/presentation/pages/notifications_page.dart';
import '../../../features/feed/presentation/pages/feed_page.dart';
import '../../../features/feed/presentation/pages/post_creation_flow.dart';
import '../../../features/feed/presentation/pages/story_camera_flow.dart';
import '../../../features/feed/presentation/pages/reels_page.dart';

import '../../../features/users/presentation/pages/user_profile_page.dart';
import '../../../features/users/domain/entities/user_entity.dart';
import '../../../core/services/secure_storage_service.dart';
import '../../../core/services/api_client.dart';
import '../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../features/auth/presentation/bloc/auth_state.dart';
import '../../../features/feed/presentation/bloc/feed_bloc.dart';
import '../../../features/feed/presentation/bloc/feed_event.dart';
import '../../../features/users/presentation/bloc/users_bloc.dart';
import '../../../features/users/presentation/bloc/users_event.dart';
import '../../../features/recent_chats/presentation/bloc/recent_chats_event.dart';
import '../../services/notification_service.dart';
import '../../services/socket_service.dart';
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
      const FeedPage(key: ValueKey('feed_page')),         // 0
      const UsersPage(key: ValueKey('explore_page')),      // 1
      const ReelsPage(key: ValueKey('reels_page')),        // 2
      const SizedBox(),                                   // 3 (Create Placeholder)
      const RecentChatsPage(key: ValueKey('messages_page')), // 4
      RequestsPage(
        key: const ValueKey('requests_page'), 
        onRequestAccepted: _addNotification
      ),                                                  // 5
      UserProfilePage(
        key: const ValueKey('profile_page'),
        user: UserEntity(
          id: "me",
          name: "My Profile",
          profileUrl: "",
          relation: UserRelation.accepted,
        ),
      ),                                                  // 6
    ];

    _loadUser();
  }

  Future<void> _loadUser() async {
    // Step 1: Show cached data immediately from secure storage
    final storage = SecureStorageService();
    final userJson = await storage.getUser();
    if (userJson != null) {
      final map = jsonDecode(userJson);
      final name = (map['fullName'] != null && map['fullName'].toString().isNotEmpty && map['fullName'] != 'Unknown') 
          ? map['fullName'] 
          : (map['email'] != null && map['email'].toString().isNotEmpty ? map['email'].split('@')[0] : 'Floq User');
      final avatar = (map['avatar'] is Map) ? (map['avatar']['url'] ?? '') : (map['avatar'] ?? '');
      if (mounted) {
        setState(() {
          _pages[6] = UserProfilePage(
            key: const ValueKey('profile_page'),
            user: UserEntity(
              id: 'me',
              name: name,
              profileUrl: avatar,
              email: map['email'] ?? '',
              relation: UserRelation.accepted,
            ),
          );
        });
      }
    }

    // Step 2: Fetch fresh data from the server and update
    try {
      final apiClient = ApiClient();
      final response = await apiClient.dio.get('/auth/me');
      final data = response.data['data'];
      if (data != null && mounted) {
        final name = (data['fullName'] != null && data['fullName'].toString().isNotEmpty && data['fullName'] != 'Unknown')
            ? data['fullName']
            : (data['email'] != null ? data['email'].split('@')[0] : 'Floq User');
        final avatar = (data['avatar'] is Map) ? (data['avatar']['url'] ?? '') : (data['avatar'] ?? '');
        // Update secure storage with fresh data
        await storage.saveUser(jsonEncode({
          'id': data['_id'],
          'fullName': data['fullName'],
          'email': data['email'],
          'avatar': data['avatar'],
          'followersCount': data['followersCount'] ?? 0,
          'followingCount': data['followingCount'] ?? 0,
          'postsCount': data['postsCount'] ?? 0,
        }));
        setState(() {
          _pages[6] = UserProfilePage(
            key: const ValueKey('profile_page'),
            user: UserEntity(
              id: 'me',
              name: name,
              profileUrl: avatar,
              email: data['email'] ?? '',
              relation: UserRelation.accepted,
            ),
          );
        });
      }
    } catch (_) {
      // Silently fail — cached data is already shown
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

  /// Re-initializes all pages to a blank state.
  /// Called when the user switches accounts so stale data is flushed.
  void _reinitPages() {
    setState(() {
      _selectedIndex = 0;
      notifications.clear();
      _pages = [
        const FeedPage(key: ValueKey('feed_page')),
        const UsersPage(key: ValueKey('explore_page')),
        const ReelsPage(key: ValueKey('reels_page')),
        const SizedBox(),                                   // 3 (Create Placeholder)
        const RecentChatsPage(key: ValueKey('messages_page')),
        RequestsPage(
          key: const ValueKey('requests_page'),
          onRequestAccepted: _addNotification,
        ),
        UserProfilePage(
          key: const ValueKey('profile_page'),
          user: UserEntity(
            id: "me",
            name: "Loading...",
            profileUrl: "",
            relation: UserRelation.accepted,
          ),
        ),
      ];
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
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PostCreationFlow()));
                  },
                ),
                _buildCreationOption(
                  context,
                  icon: Icons.camera_rounded,
                  label: "Story",
                  color: Colors.purpleAccent,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const StoryCameraFlow()));
                  },
                ),
                _buildCreationOption(
                  context,
                  icon: Icons.play_circle_fill_rounded,
                  label: "Reel",
                  color: Colors.orangeAccent,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PostCreationFlow()));
                  },
                ),
                _buildCreationOption(
                  context,
                  icon: Icons.video_call_rounded,
                  label: "Live",
                  color: Colors.redAccent,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PostCreationFlow()));
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

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          // Account switched — reload user data and refresh all pages
          _reinitPages();
          _loadUser();
          
          // Step 1: Update persistent services with new tokens
          final storage = SecureStorageService();
          storage.getAccessToken().then((token) {
            if (token != null) {
              SocketService().updateToken(token);
              NotificationService().init(); // Sync FCM token with new user
            }
          });
          
          // Step 2: Refresh other Blocs for the new user
          context.read<FeedBloc>().add(LoadFeedRequested());
          context.read<RecentChatsBloc>().add(LoadRecentChatsRequested());
          context.read<UsersBloc>().add(LoadUsersRequested());
        }
      },
      child: Scaffold(
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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsPage()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeIn,
        switchOutCurve: Curves.easeOut,
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
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            if (index == 3) {
              _showCreationSheet();
            } else {
              setState(() {
                _selectedIndex = index;
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
              icon: Icon(Icons.play_circle_outline),
              selectedIcon: Icon(Icons.play_circle_fill),
              label: "Reels",
            ),
            NavigationDestination(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
              ),
              label: "Create",
            ),
            BlocBuilder<RecentChatsBloc, RecentChatsState>(
              builder: (context, state) {
                final unreadCount = state.users.fold<int>(0, (sum, chat) => sum + chat.unreadCount) +
                                    state.groups.fold<int>(0, (sum, chat) => sum + chat.unreadCount);
                return NavigationDestination(
                  icon: Badge(
                    label: Text(unreadCount.toString()),
                    isLabelVisible: unreadCount > 0,
                    child: const Icon(Icons.forum_outlined),
                  ),
                  selectedIcon: Badge(
                    label: Text(unreadCount.toString()),
                    isLabelVisible: unreadCount > 0,
                    child: const Icon(Icons.forum),
                  ),
                  label: "Messages",
                );
              },
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
      )
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
