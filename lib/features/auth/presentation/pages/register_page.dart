import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_page.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'verify_otp_page.dart';
import '../../../../core/presentation/widgets/bubble_loader.dart';
import '../../../../core/presentation/widgets/bubble_notification.dart';
import '../../data/repositories/auth_repository_impl.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthBloc(repository: AuthRepositoryImpl()),
      child: const _RegisterView(),
    );
  }
}

class _RegisterView extends StatefulWidget {
  const _RegisterView();

  @override
  State<_RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<_RegisterView> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_validateForm);
    _emailController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
    _confirmPasswordController.addListener(_validateForm);
  }

  void _validateForm() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    final isValid = name.isNotEmpty &&
        email.contains('@') &&
        password.length >= 6 &&
        password == confirm;
    
    if (isValid != _isFormValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(AuthRegisterRequested(
          _nameController.text.trim(), _emailController.text.trim(), _passwordController.text.trim()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
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
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
              child: BlocConsumer<AuthBloc, AuthState>(
                listener: (context, state) {
                  if (state is AuthAuthenticated) {
                    BubbleNotification.show(
                      context,
                      'Registration successful!',
                      type: NotificationType.success,
                    );
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    );
                  } else if (state is AuthNeedsVerification) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: context.read<AuthBloc>(),
                          child: VerifyOTPPage(email: state.email),
                        ),
                      ),
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
                      // Logo Section
                      Hero(
                        tag: 'logo',
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorScheme.primary.withValues(alpha: 0.1),
                          ),
                          child: Icon(
                            Icons.chat_bubble_rounded,
                            size: 60,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Create Account",
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        "Join Floq today!",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Form Section
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel("Full Name"),
                            TextFormField(
                              controller: _nameController,
                              style: GoogleFonts.poppins(),
                              onChanged: (_) => _validateForm(),
                              decoration: const InputDecoration(
                                hintText: "Enter your full name",
                                prefixIcon: Icon(Icons.person_outline),
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 16, horizontal: 20),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            _buildLabel("Email"),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: GoogleFonts.poppins(),
                              onChanged: (_) => _validateForm(),
                              decoration: const InputDecoration(
                                hintText: "Enter your email",
                                prefixIcon: Icon(Icons.email_outlined),
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 16, horizontal: 20),
                              ),
                              validator: (value) {
                                if (value == null || !value.trim().contains('@')) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            _buildLabel("Password"),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              style: GoogleFonts.poppins(),
                              onChanged: (_) => _validateForm(),
                              decoration: InputDecoration(
                                hintText: "Create a password",
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
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 16, horizontal: 20),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            _buildLabel("Confirm Password"),
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: !_isPasswordVisible,
                              style: GoogleFonts.poppins(),
                              onChanged: (_) => _validateForm(),
                              decoration: const InputDecoration(
                                hintText: "Confirm your password",
                                prefixIcon: Icon(Icons.lock_clock_outlined),
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 16, horizontal: 20),
                              ),
                              validator: (value) {
                                if (value?.trim() != _passwordController.text.trim()) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 32),

                            // Register Button
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
                                  onTap: (_isFormValid && state is! AuthLoading) ? _handleRegister : null,
                                  borderRadius: BorderRadius.circular(16),
                                  child: Center(
                                    child: (state is AuthLoading)
                                        ? const BubbleLoader(size: 24, color: Colors.white)
                                        : Text(
                                            "Register",
                                            style: GoogleFonts.poppins(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: _isFormValid ? Colors.white : Colors.grey.withValues(alpha: 0.7),
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Footer
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                               children: [
                                Text(
                                  "Already have an account? ",
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => const LoginPage()),
                                    );
                                  },
                                  child: Text(
                                    "Login",
                                    style: GoogleFonts.poppins(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
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

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }
}


