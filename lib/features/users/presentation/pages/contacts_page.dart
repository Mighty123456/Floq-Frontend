import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/users_bloc.dart';
import '../bloc/users_event.dart';
import '../bloc/users_state.dart';
import '../../domain/entities/user_entity.dart';


import '../../../../core/presentation/widgets/bubble_loader.dart';
import '../../../../core/presentation/widgets/bouncy_button.dart';
import 'user_profile_page.dart';
import '../../../chat/presentation/pages/chat_page.dart';

class ContactsPage extends StatelessWidget {
  const ContactsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // We already have the Bloc provided globally, so we just trigger a load
    context.read<UsersBloc>().add(LoadContactsRequested());
    return const _ContactsView();
  }
}

class _ContactsView extends StatefulWidget {
  const _ContactsView();

  @override
  State<_ContactsView> createState() => _ContactsViewState();
}

class _ContactsViewState extends State<_ContactsView> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BlocBuilder<UsersBloc, UsersState>(
        builder: (context, state) {
          if (state.isLoadingContacts) {
            return const Center(child: BubbleLoader());
          }

          if (state.contacts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline_rounded, size: 64, color: Colors.grey.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  const Text("Your network is empty", style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }

          final filteredContacts = state.contacts.where((c) {
            return c.name.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Network Summary Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "My Network",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          Text(
                            "${state.contacts.length} Professional Connections",
                            style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ],
                      ),
                      const Spacer(),
                      BouncyButton(
                        onTap: () {},
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.person_add_rounded, color: colorScheme.primary, size: 22),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Search bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: "Search connections...",
                        hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
              ),

              // Favorites/Frequent Sections
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                      child: Text(
                        "Frequent Interactions",
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: state.contacts.length > 5 ? 5 : state.contacts.length,
                        itemBuilder: (context, index) {
                          final contact = state.contacts[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundImage: NetworkImage(contact.profileUrl),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  contact.name.split(' ')[0],
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

              // Main Contact List
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text(
                    "All Connections",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final contact = filteredContacts[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: BouncyButton(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UserProfilePage(
                                user: UserEntity(
                                  id: contact.id,
                                  name: contact.name,
                                  profileUrl: contact.profileUrl,
                                  relation: UserRelation.accepted,
                                ),
                              ),
                            ),
                          ),

                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              leading: CircleAvatar(
                                radius: 24,
                                backgroundImage: NetworkImage(contact.profileUrl),
                              ),
                              title: Text(
                                contact.name,
                                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              subtitle: Text(
                                contact.statusMessage,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.forum_outlined, color: colorScheme.primary, size: 20),
                                    onPressed: () {
                                       Navigator.push(
                                         context,
                                         MaterialPageRoute(
                                           builder: (_) => ChatPage(
                                             chatWith: contact.name,
                                             profileUrl: contact.profileUrl,
                                             userId: contact.id,
                                           ),
                                         ),
                                       );
                                    },
                                  ),
                                  const Icon(Icons.more_vert_rounded, color: Colors.grey, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: filteredContacts.length,
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
