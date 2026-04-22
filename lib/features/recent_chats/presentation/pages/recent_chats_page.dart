import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../chat/presentation/pages/chat_page.dart';
import '../../domain/entities/chat_session_entity.dart';
import '../bloc/recent_chats_bloc.dart';

import '../bloc/recent_chats_state.dart';

import '../../../../core/presentation/widgets/bouncy_button.dart';
import '../../../../core/presentation/widgets/bubble_loader.dart';
import '../../../../core/presentation/widgets/floq_avatar.dart';
import '../../../chat/presentation/pages/saved_items_page.dart';
import '../../../chat/presentation/pages/spam_inbox_page.dart';


class RecentChatsPage extends StatelessWidget {
  const RecentChatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _RecentChatsView();
  }
}

class _RecentChatsView extends StatefulWidget {
  const _RecentChatsView();

  @override
  State<_RecentChatsView> createState() => _RecentChatsViewState();
}

class _RecentChatsViewState extends State<_RecentChatsView> {
  void _openChat(ChatSessionEntity session) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPage(
          chatWith: session.name,
          profileUrl: session.profileUrl,
          userId: session.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BlocBuilder<RecentChatsBloc, RecentChatsState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: BubbleLoader());
          }

          final combinedChats = [...state.users, ...state.groups];
          combinedChats.sort((a, b) => (b.lastMessageTime ?? DateTime(0)).compareTo(a.lastMessageTime ?? DateTime(0)));

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Search and Quick Filter
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Search conversations...",
                        hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
              ),

              // Active Now Section
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: Text(
                        "Active Now",
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: state.users.length > 8 ? 8 : state.users.length,
                        itemBuilder: (context, index) {
                          final user = state.users[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: Column(
                              children: [
                                FloqAvatar(
                                  radius: 28,
                                  name: user.name,
                                  imageUrl: user.profileUrl,
                                  overlay: Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: isDark ? const Color(0xFF121212) : Colors.white, width: 2),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  user.name.split(' ')[0],
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Direct Messages Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Recent Chats",
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      Row(
                        children: [
                          // New Folder Dropdown
                          Theme(
                            data: Theme.of(context).copyWith(
                              hoverColor: Colors.transparent,
                              splashColor: Colors.transparent,
                            ),
                            child: PopupMenuButton<String>(
                              offset: const Offset(0, 45),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                              elevation: 8,
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: colorScheme.secondary.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.folder_copy_rounded, color: colorScheme.secondary, size: 20),
                              ),
                              onSelected: (value) {
                                if (value == 'saved') {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedItemsPage()));
                                } else if (value == 'spam') {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SpamInboxPage()));
                                }
                              },

                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'saved',
                                  child: Row(
                                    children: [
                                      Icon(Icons.bookmark_rounded, color: colorScheme.primary, size: 20),
                                      const SizedBox(width: 12),
                                      Text("Saved Items", style: GoogleFonts.poppins(fontSize: 14)),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'spam',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.security_rounded, color: Colors.amber, size: 20),
                                      const SizedBox(width: 12),
                                      Text("Spam Inbox", style: GoogleFonts.poppins(fontSize: 14)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.edit_note_rounded, color: colorScheme.primary, size: 20),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),



              // Chat List
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final chat = combinedChats[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: BouncyButton(
                          onTap: () {
                            if (chat.isGroup) {
                              // Group chat navigation can be added later
                              return;
                            }
                            _openChat(chat);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.fromLTRB(16, 8, 20, 8),
                                leading: FloqAvatar(
                                  radius: 28,
                                  name: chat.name,
                                  imageUrl: chat.profileUrl,
                                ),
                              title: Text(
                                chat.name,
                                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              subtitle: Text(
                                chat.lastMessage,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: index == 0 ? colorScheme.primary : Colors.grey,
                                  fontWeight: index == 0 ? FontWeight.w600 : FontWeight.normal,
                                  fontSize: 13,
                                ),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    index == 0 ? "Just now" : "${12 - index}m",
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: index == 0 ? colorScheme.primary : Colors.grey,
                                      fontWeight: index == 0 ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  if (index == 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text(
                                        "New",
                                        style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: combinedChats.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
