import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'chats_screen.dart';
import 'contacts_screen.dart';
import 'users_screen.dart';
import 'preferences_screen.dart';
import 'chat_screen.dart';
import 'requests_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// Model class for a notification
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

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  late List<Widget> _pages;

  List<NotificationItem> notifications = []; // Stores notifications

  @override
  void initState() {
    super.initState();
    // Initialize pages and pass callback to RequestsScreen
    _pages = [
      const UsersScreen(),
      const ChatsScreen(),
      const ContactsScreen(),
      RequestsScreen(onRequestAccepted: _addNotification),
      const PreferencesScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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

  @override
  Widget build(BuildContext context) {
    // Determine dark/light mode
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1C1C1C) : Colors.blue, // Very dark grey
        title: SizedBox(
          height: 40,
          child: AnimatedTextKit(
            repeatForever: true,
            animatedTexts: [
              WavyAnimatedText(
                'BubbleChat',
                textStyle: GoogleFonts.pacifico(
                  textStyle: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              // TODO: Replace with API call to fetch users for search
              List<String> users = [];
              showSearch(
                context: context,
                delegate: UserSearchDelegate(users: users),
              );
            },
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.white),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Notifications'),
                      content: SizedBox(
                        width: double.maxFinite,
                        child: notifications.isEmpty
                            ? const Text("No notifications yet.")
                            : ListView.builder(
                          shrinkWrap: true,
                          itemCount: notifications.length,
                          itemBuilder: (context, index) {
                            final notif = notifications[index];
                            return Dismissible(
                              key: Key(notif.name + index.toString()),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                color: Colors.red,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: const Icon(Icons.delete, color: Colors.white),
                              ),
                              onDismissed: (_) {
                                setState(() {
                                  notifications.removeAt(index);
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Notification dismissed")),
                                );
                              },
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: NetworkImage(notif.imageUrl),
                                ),
                                title: Text(notif.name),
                                subtitle: Text(notif.message),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChatScreen(chatWith: notif.name),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            clearNotifications();
                            Navigator.of(context).pop();
                          },
                          child: const Text("Clear All", style: TextStyle(color: Colors.blueAccent)),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text("Close", style: TextStyle(color: Colors.blueAccent)),
                        ),
                      ],
                    ),
                  );
                },
              ),
              if (notifications.isNotEmpty)
                Positioned(
                  right: 11,
                  top: 11,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '${notifications.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: isDark ? const Color(0xFF1C1C1C) : Colors.white, // Very dark grey
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Users"),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble), label: "Chats"),
          BottomNavigationBarItem(icon: Icon(Icons.contacts), label: "Contacts"),
          BottomNavigationBarItem(icon: Icon(Icons.person_add), label: "Requests"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
        ],
      ),
    );
  }
}

// ========================
// User Search Delegate
// ========================
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
