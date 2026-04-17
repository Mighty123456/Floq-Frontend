import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/users_bloc.dart';
import '../bloc/users_event.dart';
import '../bloc/users_state.dart';
import '../../domain/entities/user_entity.dart';
import '../../data/repositories/users_repository_impl.dart';
import '../../../../core/presentation/widgets/bubble_loader.dart';
import '../../../../core/presentation/widgets/bouncy_button.dart';
import '../../../../core/presentation/widgets/bubble_notification.dart';
import 'user_profile_page.dart';

class RequestsPage extends StatelessWidget {
  final void Function(String name) onRequestAccepted;

  const RequestsPage({super.key, required this.onRequestAccepted});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => UsersBloc(repository: MockUsersRepository())..add(LoadRequestsRequested()),
      child: _RequestsView(onRequestAccepted: onRequestAccepted),
    );
  }
}

class _RequestsView extends StatefulWidget {
  final void Function(String name) onRequestAccepted;

  const _RequestsView({required this.onRequestAccepted});

  @override
  State<_RequestsView> createState() => _RequestsViewState();
}

class _RequestsViewState extends State<_RequestsView> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final List<UserEntity> _displayedRequests = [];


  void _acceptRequest(BuildContext context, String userId, String userName) {
    context.read<UsersBloc>().add(AcceptRequest(userId));
    widget.onRequestAccepted(userName);
    BubbleNotification.show(
      context,
      "Connection established with $userName",
      type: NotificationType.success,
    );
  }

  void _declineRequest(BuildContext context, String userId, String userName) {
    context.read<UsersBloc>().add(DeclineRequest(userId));
    BubbleNotification.show(
      context,
      "Request declined",
      type: NotificationType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BlocConsumer<UsersBloc, UsersState>(
        listener: (context, state) {
           if (!state.isLoadingRequests && state.requests.isNotEmpty && _displayedRequests.isEmpty) {
            _loadRequestsWithAnimation(state.requests);
          }
        },
        builder: (context, state) {
          if (state.isLoadingRequests && _displayedRequests.isEmpty) {
            return const Center(child: BubbleLoader());
          }

          if (state.requests.isEmpty && _displayedRequests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_add_disabled_rounded, size: 64, color: Colors.grey.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  const Text("No pending requests", style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }

          return AnimatedList(
            key: _listKey,
            initialItemCount: _displayedRequests.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index, animation) {
              final user = _displayedRequests[index];
              return _buildAnimatedRequestCard(context, user, index, animation, isDark, colorScheme);
            },
          );
        },
      ),
    );
  }

  void _loadRequestsWithAnimation(List<UserEntity> requests) async {
    for (var i = 0; i < requests.length; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      _displayedRequests.add(requests[i]);
      _listKey.currentState?.insertItem(i, duration: const Duration(milliseconds: 500));
    }
  }

  Widget _buildAnimatedRequestCard(BuildContext context, UserEntity user, int index, Animation<double> animation, bool isDark, ColorScheme colorScheme) {
    return SlideTransition(
      position: animation.drive(Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero).chain(CurveTween(curve: Curves.easeOutCubic))),
      child: FadeTransition(
        opacity: animation,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                width: 1,
              ),
            ),
            child: ListTile(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfilePage(user: user))),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfilePage(user: user))),
                child: Hero(
                  tag: 'user_image_${user.id}',
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: colorScheme.secondaryContainer,
                    backgroundImage: user.profileUrl.isNotEmpty ? NetworkImage(user.profileUrl) : null,
                    child: user.profileUrl.isEmpty ? Icon(Icons.person_rounded, color: colorScheme.onSecondaryContainer) : null,
                  ),
                ),
              ),
              title: Text(user.name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
              subtitle: const Text("Sent you a connection request", style: TextStyle(color: Colors.grey, fontSize: 12)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  BouncyButton(
                    onTap: () => _acceptRequest(context, user.id, user.name),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.check_rounded, color: Colors.green, size: 20),
                    ),
                  ),
                  const SizedBox(width: 8),
                  BouncyButton(
                    onTap: () => _declineRequest(context, user.id, user.name),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
