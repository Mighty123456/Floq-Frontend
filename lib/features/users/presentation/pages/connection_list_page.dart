import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/entities/user_entity.dart';
import '../bloc/users_bloc.dart';
import '../bloc/users_event.dart';
import '../bloc/users_state.dart';
import 'user_profile_page.dart';
import '../../../../core/presentation/widgets/bubble_loader.dart';
import '../../../../core/presentation/widgets/floq_avatar.dart';

enum ConnectionListType { followers, following }

class ConnectionListPage extends StatefulWidget {
  final String userId;
  final String userName;
  final ConnectionListType type;

  const ConnectionListPage({
    super.key,
    required this.userId,
    required this.userName,
    required this.type,
  });

  @override
  State<ConnectionListPage> createState() => _ConnectionListPageState();
}

class _ConnectionListPageState extends State<ConnectionListPage> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    if (widget.type == ConnectionListType.followers) {
      context.read<UsersBloc>().add(LoadFollowersRequested(widget.userId));
    } else {
      context.read<UsersBloc>().add(LoadFollowingRequested(widget.userId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              widget.type == ConnectionListType.followers ? "Followers" : "Following",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              widget.userName,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: BlocBuilder<UsersBloc, UsersState>(
        builder: (context, state) {
          final isLoading = widget.type == ConnectionListType.followers 
              ? state.isLoadingFollowers 
              : state.isLoadingFollowing;
          
          final users = widget.type == ConnectionListType.followers 
              ? state.followers 
              : state.following;

          if (isLoading && users.isEmpty) {
            return const Center(child: BubbleLoader());
          }

          if (users.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.type == ConnectionListType.followers 
                        ? Icons.person_add_disabled_rounded 
                        : Icons.person_off_rounded,
                    size: 64,
                    color: Colors.grey.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.type == ConnectionListType.followers 
                        ? "No followers yet" 
                        : "Not following anyone yet",
                    style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _loadData(),
            color: colorScheme.primary,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                      ),
                    ),
                    child: ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UserProfilePage(user: user),
                          ),
                        );
                      },
                      leading: FloqAvatar(
                        radius: 24,
                        name: user.name,
                        imageUrl: user.profileUrl,
                      ),
                      title: Text(
                        user.name,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      subtitle: Text(
                        user.bio.isNotEmpty ? user.bio : "Connect via Floq",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      trailing: _buildRelationButton(user, colorScheme),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildRelationButton(UserEntity user, ColorScheme colorScheme) {
     if (user.id == 'me') return const SizedBox.shrink();

     final bool isFollowing = user.relation == UserRelation.accepted;
     final bool isPending = user.relation == UserRelation.pending;

     return ElevatedButton(
       onPressed: () {
         if (!isFollowing && !isPending) {
           context.read<UsersBloc>().add(SendRequest(user.id));
         }
       },
       style: ElevatedButton.styleFrom(
         backgroundColor: (isFollowing || isPending) ? Colors.transparent : colorScheme.primary,
         foregroundColor: (isFollowing || isPending) ? Colors.grey : Colors.white,
         elevation: 0,
         side: (isFollowing || isPending) ? const BorderSide(color: Colors.grey, width: 1) : null,
         padding: const EdgeInsets.symmetric(horizontal: 16),
         minimumSize: const Size(80, 32),
         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
       ),
       child: Text(
         isFollowing ? "Following" : (isPending ? "Pending" : "Follow"),
         style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold),
       ),
     );
  }
}
