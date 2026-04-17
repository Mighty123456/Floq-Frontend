import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/presentation/widgets/bouncy_button.dart';

import '../../../../core/presentation/widgets/bubble_notification.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  // Mock notifications data with 'isRead' status
  late List<Map<String, dynamic>> notifications;

  @override
  void initState() {
    super.initState();
    notifications = [
      {
        'id': '1',
        'title': 'New Friend Request',
        'body': 'Alex Rivera sent you a friend request.',
        'time': '2 mins ago',
        'icon': Icons.person_add_rounded,
        'color': Colors.blue,
        'isRead': false,
      },
      {
        'id': '2',
        'title': 'Message Received',
        'body': 'Sarah Jenkins: Hey! Are we still meeting today?',
        'time': '15 mins ago',
        'icon': Icons.chat_bubble_rounded,
        'color': Colors.green,
        'isRead': false,
      },
      {
        'id': '3',
        'title': 'Emma Watson',
        'body': 'Accepted your chat request.',
        'time': '45 mins ago',
        'icon': Icons.check_circle_rounded,
        'color': Colors.teal,
        'isRead': false,
      },
      {
        'id': '4',
        'title': 'Security Alert',
        'body': 'Your password was changed successfully.',
        'time': '1 hour ago',
        'icon': Icons.security_rounded,
        'color': Colors.orange,
        'isRead': true,
      },
      {
        'id': '5',
        'title': 'System Update',
        'body': 'Floq v2.0 is now available! Enjoy new features.',
        'time': 'Yesterday',
        'icon': Icons.system_update_rounded,
        'color': Colors.purple,
        'isRead': true,
      },
      {
        'id': '6',
        'title': 'Marcus Chen',
        'body': 'Sent you a photo.',
        'time': 'Yesterday',
        'icon': Icons.image_rounded,
        'color': Colors.pink,
        'isRead': true,
      },
    ];

  }

  void _markAsRead(int index) {
    setState(() {
      notifications[index]['isRead'] = true;
    });
  }

  void _deleteNotification(int index) {

    setState(() {
      notifications.removeAt(index);
    });
    BubbleNotification.show(
      context,
      "Notification deleted",
      type: NotificationType.info,
    );
  }

  void _clearAll() {
    if (notifications.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
        title: const Text("Clear All"),
        content: const Text("Are you sure you want to delete all notifications?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              setState(() => notifications.clear());
              Navigator.pop(ctx);
              BubbleNotification.show(context, "All notifications cleared", type: NotificationType.success);
            },
            child: const Text("Clear All", style: TextStyle(color: Colors.red)),
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
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          "Notifications",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
              onPressed: _clearAll,
              tooltip: "Clear All",
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: notifications.isEmpty
          ? _buildEmptyState()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              physics: const BouncingScrollPhysics(),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = notifications[index];
                final itemColor = item['color'] as Color;
                final bool isRead = item['isRead'] as bool;

                return Dismissible(
                  key: Key(item['id'] as String),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => _deleteNotification(index),
                  background: Container(
                    padding: const EdgeInsets.only(right: 20),
                    alignment: Alignment.centerRight,
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                  ),
                  child: BouncyButton(
                    onTap: () => _markAsRead(index),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isRead 
                              ? (isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.1))
                              : colorScheme.primary.withValues(alpha: 0.3),
                          width: isRead ? 1 : 2,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: itemColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Icon(item['icon'] as IconData, color: itemColor, size: 24),
                              ),
                              if (!isRead)
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: isDark ? const Color(0xFF1E1E1E) : Colors.white, width: 2),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      item['title'] as String,
                                      style: GoogleFonts.poppins(
                                        fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                        fontSize: 16,
                                        color: isRead ? Colors.grey : (isDark ? Colors.white : Colors.black87),
                                      ),
                                    ),
                                    Text(
                                      item['time'] as String,
                                      style: GoogleFonts.poppins(
                                        color: Colors.grey,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item['body'] as String,
                                  style: GoogleFonts.poppins(
                                    color: isRead ? Colors.grey.withValues(alpha: 0.7) : Colors.grey[600],
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            "No notifications yet",
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            "We'll notify you when something comes up!",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

