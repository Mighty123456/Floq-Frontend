import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/entities/user_entity.dart';
import '../bloc/users_bloc.dart';
import '../bloc/users_event.dart';
import '../bloc/users_state.dart';
import '../../../../core/presentation/widgets/bubble_loader.dart';
import '../../../../core/presentation/widgets/floq_avatar.dart';

enum ConnectionListType { followers, following }

class ConnectionListPage extends StatefulWidget {
  final UserEntity user;
  final ConnectionListType type;

  const ConnectionListPage({
    super.key,
    required this.user,
    required this.type,
  });

  @override
  State<ConnectionListPage> createState() => _ConnectionListPageState();
}

class _ConnectionListPageState extends State<ConnectionListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    context.read<UsersBloc>().add(LoadFollowersRequested(widget.user.id));
    context.read<UsersBloc>().add(LoadFollowingRequested(widget.user.id));
    context.read<UsersBloc>().add(LoadConnectionCategoriesRequested());
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: widget.type == ConnectionListType.followers ? 0 : 1,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            widget.user.name.toLowerCase().replaceAll(' ', '_'),
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          actions: [
            IconButton(onPressed: () {}, icon: const Icon(Icons.person_add_outlined, color: Colors.white)),
          ],
          bottom: TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 1,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: [
              Tab(text: "${widget.user.followersCount} Followers"),
              Tab(text: "${widget.user.followingCount} Following"),
              const Tab(text: "0 Subscriptions"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildList(ConnectionListType.followers),
            _buildList(ConnectionListType.following),
            const Center(child: Text("No subscriptions yet", style: TextStyle(color: Colors.grey))),
          ],
        ),
      ),
    );
  }

  Widget _buildList(ConnectionListType type) {
    return BlocBuilder<UsersBloc, UsersState>(
      builder: (context, state) {
        final isLoading = type == ConnectionListType.followers 
            ? state.isLoadingFollowers 
            : state.isLoadingFollowing;
        
        final allFollowers = state.followers;
        
        final activeUsers = type == ConnectionListType.followers ? allFollowers : state.following;
        final filteredUsers = activeUsers.where((u) => 
          u.name.toLowerCase().contains(_searchQuery.toLowerCase())
        ).toList();

        if (isLoading && activeUsers.isEmpty) {
          return const Center(child: BubbleLoader());
        }

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: "Search",
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                      prefixIcon: Icon(Icons.search, color: Colors.grey, size: 20),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ),
            ),
            if (type == ConnectionListType.followers && _searchQuery.isEmpty)
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text("Categories", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    if (state.isLoadingCategories)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                      )
                    else ...[
                      if (state.dontFollowBack.isNotEmpty)
                        _buildCategoryItem(
                          "People you don't follow back", 
                          "${state.dontFollowBack.first.name.toLowerCase().replaceAll(' ', '_')} and ${state.dontFollowBack.length - 1} others",
                          state.dontFollowBack.take(2).toList(),
                        ),
                      _buildCategoryItem(
                        "New Followers", 
                        state.newFollowers.isNotEmpty ? "${state.newFollowers.first.name.toLowerCase()} and others" : "None recently",
                        state.newFollowers.take(2).toList(),
                      ),
                    ],
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                      child: Text("All followers", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ],
                ),
              ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final user = filteredUsers[index];
                  return _buildUserListItem(user, type);
                },
                childCount: filteredUsers.length,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryItem(String title, String subtitle, List<UserEntity> sampleUsers) {
    return ListTile(
      leading: SizedBox(
        width: 60,
        child: Stack(
          children: [
            if (sampleUsers.isNotEmpty)
              CircleAvatar(
                radius: 18, 
                backgroundColor: Colors.black,
                child: FloqAvatar(radius: 17, name: sampleUsers[0].name, imageUrl: sampleUsers[0].profileUrl),
              ),
            if (sampleUsers.length > 1)
              Positioned(
                left: 14, 
                child: CircleAvatar(
                  radius: 18, 
                  backgroundColor: Colors.black,
                  child: FloqAvatar(radius: 17, name: sampleUsers[1].name, imageUrl: sampleUsers[1].profileUrl),
                ),
              ),
          ],
        ),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
    );
  }

  Widget _buildUserListItem(UserEntity user, ConnectionListType type) {
    final bool isFollowing = user.relation == UserRelation.accepted;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.pinkAccent, width: 1.5),
            ),
            child: FloqAvatar(
              radius: 28,
              name: user.name,
              imageUrl: user.profileUrl,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name.toLowerCase().replaceAll(' ', '_'),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  user.name,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
          if (isFollowing)
            _buildSmallButton("Message", Colors.white12, Colors.white)
          else
            _buildSmallButton("Follow back", Colors.blueAccent, Colors.white),
          const SizedBox(width: 12),
          const Icon(Icons.close, color: Colors.white54, size: 20),
        ],
      ),
    );
  }

  Widget _buildSmallButton(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }
}

