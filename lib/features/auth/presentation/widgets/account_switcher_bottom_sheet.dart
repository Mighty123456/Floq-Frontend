import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/presentation/widgets/floq_avatar.dart';
import '../../../../core/presentation/widgets/bouncy_button.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../pages/login_page.dart';

class AccountSwitcherBottomSheet extends StatelessWidget {
  const AccountSwitcherBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final storage = SecureStorageService();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: storage.getAccounts(),
            builder: (context, snapshot) {
              final accounts = snapshot.data ?? [];
              
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  Text(
                    "Switch Account",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  if (accounts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        "No recent accounts found",
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: accounts.length,
                        itemBuilder: (context, index) {
                          final account = accounts[index];
                          return _buildAccountTile(context, account, isDark, colorScheme);
                        },
                      ),
                    ),
                  
                  const Divider(height: 32),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: BouncyButton(
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage(isAddingAccount: true)),
                        );
                      },
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: colorScheme.primary, width: 1.5),
                            ),
                            child: Icon(Icons.add_rounded, color: colorScheme.primary, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            "Add Account",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAccountTile(BuildContext context, Map<String, dynamic> account, bool isDark, ColorScheme colorScheme) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final bool isCurrent = state is AuthAuthenticated && state.user.email == account['email'];

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          leading: FloqAvatar(
            radius: 24,
            name: account['name'] ?? '',
            imageUrl: account['avatar'],
          ),
          title: Text(
            account['name'] ?? '',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          subtitle: Text(
            account['email'] ?? '',
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
          trailing: isCurrent 
            ? Icon(Icons.check_circle_rounded, color: colorScheme.primary)
            : IconButton(
                icon: const Icon(Icons.close_rounded, size: 20, color: Colors.grey),
                onPressed: () {
                  // Remove account
                  SecureStorageService().removeAccount(account['id']);
                  // Trigger rebuild would be nice, but simple pop and reopen works or just use a stateful widget
                  Navigator.pop(context);
                },
              ),
          onTap: isCurrent ? null : () {
            context.read<AuthBloc>().add(AuthSwitchAccountRequested(account));
            Navigator.pop(context);
          },
        );
      },
    );
  }
}
