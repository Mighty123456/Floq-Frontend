import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../../../core/presentation/widgets/bubble_loader.dart';
import '../../../../core/presentation/widgets/bubble_notification.dart';
import 'login_page.dart';

class ResetPasswordPage extends StatelessWidget {
  final String email;
  const ResetPasswordPage({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return _ResetPasswordView(email: email);
  }
}

class _ResetPasswordView extends StatefulWidget {
  final String email;
  const _ResetPasswordView({required this.email});

  @override
  State<_ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<_ResetPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _otpController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
    _confirmPasswordController.addListener(_validateForm);
  }

  void _validateForm() {
    final otp = _otpController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();
    final isValid = otp.length == 6 && password.length >= 6 && password == confirm;
    
    if (isValid != _isFormValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(AuthResetPasswordRequested(
            email: widget.email,
            otp: _otpController.text.trim(),
            newPassword: _passwordController.text.trim(),
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text("Reset Password", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [colorScheme.surface, Theme.of(context).scaffoldBackgroundColor]
                : [colorScheme.primary.withValues(alpha: 0.1), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: BlocConsumer<AuthBloc, AuthState>(
                listener: (context, state) {
                  if (state is AuthResetPasswordSuccess) {
                    BubbleNotification.show(
                      context,
                      'Password has been reset successfully!',
                      type: NotificationType.success,
                    );
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                      (route) => false,
                    );
                  } else if (state is AuthError) {
                    BubbleNotification.show(
                      context,
                      state.message,
                      type: NotificationType.error,
                    );
                  }
                },
                builder: (context, state) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Hero(
                        tag: 'logo',
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorScheme.primary.withValues(alpha: 0.1),
                          ),
                          child: Icon(
                            Icons.vpn_key_rounded,
                            size: 80,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "Set New Password",
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Please enter your new password below",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 48),
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Verification Code (OTP)",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _otpController,
                              keyboardType: TextInputType.number,
                              style: GoogleFonts.poppins(letterSpacing: 8, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                              maxLength: 6,
                              decoration: const InputDecoration(
                                hintText: "000000",
                                hintStyle: TextStyle(letterSpacing: 8, color: Colors.grey),
                                prefixIcon: Icon(Icons.pin_rounded),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().length != 6) {
                                  return 'Please enter 6-digit OTP';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            Text(
                              "New Password",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              style: GoogleFonts.poppins(),
                              onChanged: (_) => _validateForm(),
                              decoration: InputDecoration(
                                hintText: "Enter new password",
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            Text(
                              "Confirm Password",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: !_isPasswordVisible,
                              style: GoogleFonts.poppins(),
                              onChanged: (_) => _validateForm(),
                              decoration: const InputDecoration(
                                hintText: "Confirm new password",
                                prefixIcon: Icon(Icons.lock_clock_outlined),
                              ),
                              validator: (value) {
                                if (value?.trim() != _passwordController.text.trim()) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 32),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: double.infinity,
                              height: 56,
                              decoration: BoxDecoration(
                                color: (state is AuthLoading)
                                    ? colorScheme.primary
                                    : (_isFormValid ? colorScheme.primary : colorScheme.primary.withValues(alpha: 0.15)),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [],

                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: (_isFormValid && state is! AuthLoading) ? _handleSubmit : null,
                                  borderRadius: BorderRadius.circular(16),
                                  child: Center(
                                    child: (state is AuthLoading)
                                        ? const BubbleLoader(size: 24, color: Colors.white)
                                        : Text(
                                            "Reset Password",
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: _isFormValid ? Colors.white : Colors.grey.withValues(alpha: 0.7),
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
