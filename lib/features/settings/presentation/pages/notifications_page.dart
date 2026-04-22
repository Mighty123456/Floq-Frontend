import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/presentation/widgets/bouncy_button.dart';
import '../../../../core/presentation/widgets/bubble_notification.dart';
import '../bloc/notifications_bloc.dart';
import '../bloc/notifications_event.dart';
import '../bloc/notifications_state.dart';
import '../../domain/entities/notification_entity.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {

  void _markAsRead(String id) {
    context.read<NotificationsBloc>().add(MarkNotificationAsRead(id));
  }

  void _deleteNotification(String id) {
    context.read<NotificationsBloc>().add(DeleteNotificationRequested(id));
    BubbleNotification.show(
      context,
      "Notification deleted",
      type: NotificationType.info,
    );
  }

  void _clearAll() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
        title: const Text("Clear All"),
        content: const Text("Are you sure you want to mark all as read?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
               context.read<NotificationsBloc>().add(MarkAllNotificationsAsRead());
               Navigator.pop(ctx);
               BubbleNotification.show(context, "All marked as read", type: NotificationType.success);
            },
            child: const Text("Mark All Read", style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  IconData _getIcon(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.like: return Icons.favorite_rounded;
      case AppNotificationType.comment: return Icons.comment_rounded;
      case AppNotificationType.follow: return Icons.person_add_rounded;
      case AppNotificationType.mention: return Icons.alternate_email_rounded;
      case AppNotificationType.repost: return Icons.repeat_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  Color _getColor(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.like: return Colors.redAccent;
      case AppNotificationType.comment: return Colors.blueAccent;
      case AppNotificationType.follow: return Colors.greenAccent;
      case AppNotificationType.mention: return Colors.orangeAccent;
      case AppNotificationType.repost: return Colors.purpleAccent;
      default: return Colors.grey;
    }
  }

  String _getTimeString(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      body: BlocBuilder<NotificationsBloc, NotificationsState>(
        builder: (context, state) {
          final notifications = state.notifications;
          
          return RefreshIndicator(
            onRefresh: () async {
              context.read<NotificationsBloc>().add(LoadNotificationsRequested());
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              slivers: [
                SliverAppBar(
                  floating: true,
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  title: Text(
                    "Notifications",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                  actions: [
                    if (notifications.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.done_all_rounded, color: Colors.blueAccent),
                        onPressed: _clearAll,
                        tooltip: "Mark all as read",
                      ),
                    const SizedBox(width: 8),
                  ],
                ),
                if (state.isLoading && notifications.isEmpty)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (notifications.isEmpty)
                  SliverFillRemaining(child: _buildEmptyState())
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = notifications[index];
                          final itemColor = _getColor(item.type);
                          final bool isRead = item.isRead;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Dismissible(
                              key: Key(item.id),
                              direction: DismissDirection.endToStart,
                              onDismissed: (_) => _deleteNotification(item.id),
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
                                onTap: () => _markAsRead(item.id),
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
                                            child: Icon(_getIcon(item.type), color: itemColor, size: 24),
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
                                                  item.senderName,
                                                  style: GoogleFonts.poppins(
                                                    fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                                    fontSize: 15,
                                                    color: isRead ? Colors.grey : (isDark ? Colors.white : Colors.black87),
                                                  ),
                                                ),
                                                Text(
                                                  _getTimeString(item.createdAt),
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.grey,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              item.content,
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
                            ),
                          );
                        },
                        childCount: notifications.length,
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
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

