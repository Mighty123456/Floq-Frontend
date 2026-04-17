import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/presentation/pages/home_page.dart'; // Navigation destination
import 'register_page.dart';
import 'forgot_password_page.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'verify_otp_page.dart';
import '../../../../core/presentation/widgets/bubble_loader.dart';
import '../../../../core/presentation/widgets/bubble_notification.dart';
import '../../data/repositories/auth_repository_impl.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthBloc(repository: AuthRepositoryImpl()),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isFormValid = false;
  bool _isOTPLogin = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
  }

  void _validateForm() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    
    bool isValid;
    if (_isOTPLogin) {
      isValid = email.contains('@');
    } else {
      isValid = email.contains('@') && password.length >= 6;
    }

    if (isValid != _isFormValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }


  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      if (_isOTPLogin) {
        context.read<AuthBloc>().add(AuthLoginOTPRequested(_emailController.text.trim()));
      } else {
        context.read<AuthBloc>().add(
            AuthLoginRequested(_emailController.text.trim(), _passwordController.text.trim()));
      }
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
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: BlocConsumer<AuthBloc, AuthState>(
                listener: (context, state) {
                  if (state is AuthAuthenticated) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const HomePage()),
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
                  } else if (state is AuthLoginOTPSent) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: context.read<AuthBloc>(),
                          child: VerifyOTPPage(
                            email: state.email,
                            isLoginOTP: true,
                          ),
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
                            size: 80,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Welcome Back",
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : colorScheme.onSurface,
                        ),
                      ),

                      Text(
                        "Log in to continue chatting",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Form Section
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Email",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: GoogleFonts.poppins(),
                              onChanged: (_) => _validateForm(),
                              decoration: InputDecoration(
                                hintText: "Enter your email",
                                prefixIcon: const Icon(Icons.email_outlined),
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 16, horizontal: 20),
                              ),
                              validator: (value) {
                                if (value == null || !value.trim().contains('@')) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            if (!_isOTPLogin) ...[
                              Text(
                                "Password",
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
                                  hintText: "Enter your password",
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
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const ForgotPasswordPage()),
                                    );
                                  },
                                  child: Text(
                                    "Forgot Password?",
                                    style: GoogleFonts.poppins(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],

                            // OTP Login Toggle
                            Row(
                              children: [
                                Expanded(child: Divider(color: Colors.grey.withValues(alpha: 0.2))),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    "OR",
                                    style: GoogleFonts.poppins(
                                      color: Colors.grey,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Expanded(child: Divider(color: Colors.grey.withValues(alpha: 0.2))),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _isOTPLogin = !_isOTPLogin;
                                    _validateForm();
                                  });
                                },
                                icon: Icon(
                                  _isOTPLogin ? Icons.lock_outline : Icons.phone_android_outlined,
                                  size: 20,
                                ),
                                label: Text(
                                  _isOTPLogin ? "Login with Password" : "Login via OTP",
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Login Button
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
                                  onTap: (_isFormValid && state is! AuthLoading) ? _handleLogin : null,
                                  borderRadius: BorderRadius.circular(16),
                                  child: Center(
                                    child: (state is AuthLoading)
                                        ? const BubbleLoader(size: 24, color: Colors.white)
                                        : Text(
                                            _isOTPLogin ? "Send Login OTP" : "Login",
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
                                  "Don't have an account? ",
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => const RegisterPage()),
                                    );
                                  },
                                  child: Text(
                                    "Register",
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
}

