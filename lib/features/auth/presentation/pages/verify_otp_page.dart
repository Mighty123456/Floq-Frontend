import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../../../core/presentation/pages/home_page.dart';
import '../../../../core/presentation/widgets/bubble_loader.dart';
import '../../../../core/presentation/widgets/bubble_notification.dart';

class VerifyOTPPage extends StatefulWidget {
  final String email;
  final bool isLoginOTP;

  const VerifyOTPPage({super.key, required this.email, this.isLoginOTP = false});

  @override
  State<VerifyOTPPage> createState() => _VerifyOTPPageState();
}

class _VerifyOTPPageState extends State<VerifyOTPPage> with SingleTickerProviderStateMixin {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  
  late AnimationController _shakeController;
  int _resendTimer = 30;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _startResendTimer();
    // Auto focus first field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  void _startResendTimer() {
    setState(() {
      _resendTimer = 30;
      _canResend = false;
    });
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        _resendTimer--;
      });
      if (_resendTimer <= 0) {
        setState(() => _canResend = true);
        return false;
      }
      return true;
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onVerify() {
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length == 6) {
      if (widget.isLoginOTP) {
        context.read<AuthBloc>().add(AuthVerifyLoginOTPRequested(widget.email, otp));
      } else {
        context.read<AuthBloc>().add(AuthVerifyOTPRequested(widget.email, otp));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
            ),
            child: Icon(Icons.arrow_back_ios_new, size: 16, color: isDark ? Colors.white : Colors.black),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [colorScheme.surface, Theme.of(context).scaffoldBackgroundColor]
                : [colorScheme.primary.withValues(alpha: 0.05), Colors.white],
          ),
        ),
        child: SafeArea(
          child: BlocConsumer<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthAuthenticated) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const HomePage()),
                  (route) => false,
                );
              } else if (state is AuthError) {
                _shakeController.forward(from: 0);
                BubbleNotification.show(context, state.message, type: NotificationType.error);
              }
            },
            builder: (context, state) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.primary.withValues(alpha: 0.1),
                      ),
                      child: Icon(
                        widget.isLoginOTP ? Icons.security_outlined : Icons.mark_email_read_outlined,
                        size: 64,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      widget.isLoginOTP ? "Login Verification" : "Verify Email",
                      style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
                        children: [
                          const TextSpan(text: "We've sent a 6-digit code to\n"),
                          TextSpan(
                            text: widget.email,
                            style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),
                    
                    // Animated OTP Input
                    AnimatedBuilder(
                      animation: _shakeController,
                      builder: (context, child) {
                        final sineValue = math.sin(4 * math.pi * _shakeController.value);
                        return Transform.translate(
                          offset: Offset(sineValue * 10, 0),
                          child: child,
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(6, (index) {
                          return _buildDigitBox(index, colorScheme, isDark);
                        }),
                      ),
                    ),
                    
                    const SizedBox(height: 48),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: state is AuthLoading ? [] : [
                            BoxShadow(
                              color: colorScheme.primary.withValues(alpha: 0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            )
                          ],
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          onPressed: state is AuthLoading ? null : _onVerify,
                          child: state is AuthLoading
                              ? const BubbleLoader(size: 24, color: Colors.white)
                              : Text(
                                  "Confirm Code",
                                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Resend Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Didn't receive code? ",
                          style: GoogleFonts.poppins(color: Colors.grey),
                        ),
                        _canResend
                          ? TextButton(
                              onPressed: () {
                                context.read<AuthBloc>().add(AuthForgotPasswordRequested(widget.email));
                                _startResendTimer();
                                BubbleNotification.show(context, "Code resent successfully!");
                              },
                              child: Text(
                                "Resend",
                                style: GoogleFonts.poppins(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : Text(
                              "Wait ${_resendTimer}s",
                              style: GoogleFonts.poppins(
                                color: colorScheme.primary.withValues(alpha: 0.5),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDigitBox(int index, ColorScheme colorScheme, bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 48,
      height: 60,
      decoration: BoxDecoration(
        color: _controllers[index].text.isNotEmpty 
          ? colorScheme.primary.withValues(alpha: 0.05)
          : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.02)),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _focusNodes[index].hasFocus
            ? colorScheme.primary
            : (_controllers[index].text.isNotEmpty ? colorScheme.primary.withValues(alpha: 0.4) : Colors.grey.withValues(alpha: 0.2)),
          width: _focusNodes[index].hasFocus ? 2 : 1,
        ),
        boxShadow: _focusNodes[index].hasFocus ? [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.1),
            blurRadius: 8,
            spreadRadius: 1,
          )
        ] : [],
      ),
      child: Center(
        child: TextField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          showCursor: false,
          style: GoogleFonts.poppins(
            fontSize: 24, 
            fontWeight: FontWeight.bold,
            color: _controllers[index].text.isNotEmpty ? (isDark ? Colors.white : Colors.black) : Colors.transparent,
          ),
          decoration: const InputDecoration(
            counterText: "",
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (value) {
            setState(() {}); // Trigger rebuild for AnimatedContainer
            if (value.isNotEmpty && index < 5) {
              _focusNodes[index + 1].requestFocus();
            } else if (value.isEmpty && index > 0) {
              _focusNodes[index - 1].requestFocus();
            }
            if (_controllers.every((c) => c.text.isNotEmpty)) {
              _onVerify();
            }
          },
        ),
      ),
    );
  }
}
