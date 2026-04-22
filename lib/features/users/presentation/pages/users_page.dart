import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/users_bloc.dart';
import '../bloc/users_event.dart';
import '../bloc/users_state.dart';
import '../../domain/entities/user_entity.dart';
import '../../../../features/feed/domain/entities/post_entity.dart';

import '../../../../core/presentation/widgets/bubble_loader.dart';
import '../../../../core/presentation/widgets/bouncy_button.dart';
import '../../../../core/presentation/widgets/bubble_notification.dart';

import 'user_profile_page.dart';



class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _UsersView();
  }
}

class _UsersView extends StatefulWidget {
  const _UsersView();

  @override
  State<_UsersView> createState() => _UsersViewState();
}

class _UsersViewState extends State<_UsersView> {
  final List<String> _categories = ["All", "Tech", "Design", "Gaming", "Music", "Nature", "Art"];
  int _selectedCategoryIndex = 0;
  Timer? _debounce;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        setState(() => _isSearching = true);
        context.read<UsersBloc>().add(SearchUsersRequested(query));
      } else {
        setState(() => _isSearching = false);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      body: SafeArea(
        child: BlocConsumer<UsersBloc, UsersState>(
          listener: (context, state) {
            if (state.errorMessage != null) {
              BubbleNotification.show(
                context,
                state.errorMessage!,
                type: NotificationType.error,
              );
            }
          },
          builder: (context, state) {
            final displayUsers = _isSearching ? state.searchResults : state.users;

            if (state.isLoadingUsers || (state.isLoadingSearch && _isSearching)) {
              return const Center(child: BubbleLoader());
            }

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Minimal Header with Back Button
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: Row(
                      children: [
                        if (Navigator.canPop(context))
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                            onPressed: () => Navigator.pop(context),
                          ),
                        const SizedBox(width: 8),
                        Text(
                          _isSearching ? "Search Results" : "Explore",
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Search Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: "Search people...",
                          hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                          prefixIcon: const Icon(Icons.search_rounded, size: 20),
                          suffixIcon: _isSearching ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _isSearching = false);
                            },
                          ) : null,
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                ),
                
                if (!_isSearching) ...[
                  // Categories
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final isSelected = _selectedCategoryIndex == index;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: BouncyButton(
                              onTap: () => setState(() => _selectedCategoryIndex = index),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: isSelected ? colorScheme.primary : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected ? Colors.transparent : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    _categories[index],
                                    style: GoogleFonts.poppins(
                                      color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Suggested People Title
                  _buildSectionTitle("People you may know", isDark),

                  // Suggested People Horizontal List
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 180,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: state.users.length > 5 ? 5 : state.users.length,
                        itemBuilder: (context, index) {
                          final user = state.users[index];
                          return _buildSuggestedPersonCard(context, user, isDark, colorScheme);
                        },
                      ),
                    ),
                  ),

                  // Trending Channels Title
                  _buildSectionTitle("Trending Channels", isDark),

                  // Channels Carousel
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 140,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: 4,
                        itemBuilder: (context, index) {
                          return _buildChannelCard(index, isDark, colorScheme);
                        },
                      ),
                    ),
                  ),

                  // Discovery Grid (Trending Media)
                  _buildSectionTitle("Explore Media", isDark),

                  if (state.isLoadingExplore && state.explorePosts.isEmpty)
                    const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(32), child: BubbleLoader())))
                  else if (state.explorePosts.isEmpty)
                    const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(32), child: Text("No trending media yet", style: TextStyle(color: Colors.grey)))))
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.8,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final post = state.explorePosts[index];
                            return _buildMediaDiscoveryCard(index, post, isDark);
                          },
                          childCount: state.explorePosts.length,
                        ),
                      ),
                    ),
                ] else ...[
                   // Search Results
                   SliverPadding(
                     padding: const EdgeInsets.symmetric(horizontal: 16),
                     sliver: SliverList(
                       delegate: SliverChildBuilderDelegate(
                         (context, index) {
                           final user = displayUsers[index];
                           return ListTile(
                             contentPadding: const EdgeInsets.symmetric(vertical: 8),
                             leading: CircleAvatar(
                               radius: 24,
                               backgroundImage: NetworkImage(user.profileUrl),
                             ),
                             title: Text(user.name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                             subtitle: Text(user.bio, maxLines: 1, overflow: TextOverflow.ellipsis),
                             onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfilePage(user: user))),
                           );
                         },
                         childCount: state.searchResults.length,
                       ),
                     ),
                   ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
        child: Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestedPersonCard(BuildContext context, UserEntity user, bool isDark, ColorScheme colorScheme) {
    return BouncyButton(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfilePage(user: user))),
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 12, bottom: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Hero(
              tag: 'user_image_${user.id}',
              child: CircleAvatar(
                radius: 30,
                backgroundImage: user.profileUrl.isNotEmpty ? NetworkImage(user.profileUrl) : null,
                child: user.profileUrl.isEmpty ? const Icon(Icons.person) : null,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              user.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            BouncyButton(
              onTap: () {
                context.read<UsersBloc>().add(SendRequest(user.id));

                BubbleNotification.show(
                  context,
                  "Invitation sent to ${user.name}",
                  type: NotificationType.success,
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colorScheme.primary.withValues(alpha: 0.1)),
                ),
                child: Text(
                  "Connect",
                  style: GoogleFonts.poppins(
                    color: colorScheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildChannelCard(int index, bool isDark, ColorScheme colorScheme) {
    final channelNames = ["Flutter Devs", "Nature Lovers", "Crypto World", "Design Hub"];
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12, bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          image: NetworkImage("https://picsum.photos/seed/channel$index/400/200"),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.4), BlendMode.darken),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              channelNames[index],
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            Text(
              "${(index + 1) * 2}k Members",
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaDiscoveryCard(int index, PostEntity post, bool isDark) {
    final hasMedia = post.mediaUrls.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
        image: hasMedia ? DecorationImage(
          image: NetworkImage(post.mediaUrls[0]),
          fit: BoxFit.cover,
        ) : null,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.6),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              bottom: 12,
              left: 12,
              child: Row(
                children: [
                  const Icon(Icons.favorite_rounded, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    "${post.likesCount}",
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            if (!hasMedia)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    post.caption,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
