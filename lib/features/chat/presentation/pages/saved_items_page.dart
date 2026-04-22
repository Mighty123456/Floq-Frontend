import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../../../core/presentation/widgets/bubble_loader.dart';

class SavedItemsPage extends StatelessWidget {
  const SavedItemsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider(
      create: (context) => ChatBloc(
        repository: context.read<ChatRepositoryImpl>(),
      )..add(const LoadSavedMessages()),
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: isDark ? Colors.white : Colors.black87),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                "Saved Collection",
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            
            BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                if (state.isLoading) {
                  return const SliverFillRemaining(child: Center(child: BubbleLoader()));
                }

                if (state.savedMessages.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bookmark_border_rounded, size: 64, color: Colors.grey.withValues(alpha: 0.3)),
                          const SizedBox(height: 16),
                          Text("No saved items yet", style: GoogleFonts.poppins(color: Colors.grey)),
                        ],
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final msg = state.savedMessages[index];
                        return _buildSavedItem(context, msg);
                      },
                      childCount: state.savedMessages.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedItem(BuildContext context, dynamic msg) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final time = DateFormat('MMM d, hh:mm a').format(msg.timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                "From Chat with ${msg.senderId}",
                style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              Text(time, style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            msg.content,
            style: GoogleFonts.poppins(fontSize: 14, color: isDark ? Colors.white : Colors.black87),
          ),
          if (msg.mediaUrl != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(msg.mediaUrl!, height: 150, width: double.infinity, fit: BoxFit.cover),
            ),
          ],
        ],
      ),
    );
  }
}
