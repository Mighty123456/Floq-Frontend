import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/services/notification_service.dart';

import 'core/presentation/pages/onboarding_page.dart';
import 'core/presentation/widgets/floq_logo.dart';
import 'core/services/socket_service.dart';
import 'core/services/cache_service.dart';
import 'features/users/data/repositories/users_repository_impl.dart';
import 'features/chat/data/repositories/chat_repository_impl.dart';
import 'features/users/presentation/bloc/users_bloc.dart';
import 'features/chat/presentation/bloc/chat_bloc.dart';
import 'features/users/presentation/bloc/users_event.dart';
import 'features/recent_chats/data/repositories/recent_chats_repository_impl.dart';
import 'features/recent_chats/presentation/bloc/recent_chats_bloc.dart';
import 'features/recent_chats/presentation/bloc/recent_chats_event.dart';
import 'features/feed/data/repositories/feed_repository_impl.dart';
import 'features/feed/presentation/bloc/feed_bloc.dart';
import 'features/feed/presentation/bloc/feed_event.dart';
import 'features/settings/data/repositories/notifications_repository_impl.dart';
import 'features/settings/presentation/bloc/notifications_bloc.dart';
import 'features/settings/presentation/bloc/notifications_event.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';

import 'core/services/api_client.dart';
import 'core/presentation/pages/home_page.dart';


// Global theme notifier
ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

// Global Socket Service
final socketService = SocketService();

// Top-level background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await NotificationService.handleBackgroundMessage(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase (Required early for messaging)
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // We move heavy initializations to SplashScreen to improve perceived startup time
  runApp(const FloqApp());
}

class FloqApp extends StatelessWidget {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  const FloqApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => ApiClient()),
        RepositoryProvider(create: (context) => UsersRepositoryImpl(context.read<ApiClient>())),
        RepositoryProvider(create: (context) => ChatRepositoryImpl(context.read<ApiClient>(), socketService)),
        RepositoryProvider(create: (context) => RecentChatsRepositoryImpl(context.read<ApiClient>())),
        RepositoryProvider(create: (context) => FeedRepositoryImpl(context.read<ApiClient>())),
        RepositoryProvider(create: (context) => NotificationsRepositoryImpl(context.read<ApiClient>(), socketService)),
        RepositoryProvider<AuthRepositoryImpl>(create: (_) => AuthRepositoryImpl()),
      ],

      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => UsersBloc(
              repository: context.read<UsersRepositoryImpl>(),
              feedRepository: context.read<FeedRepositoryImpl>(),
            )..add(LoadUsersRequested())..add(LoadExploreFeedRequested()),
          ),
          BlocProvider(
            create: (context) => ChatBloc(
              repository: context.read<ChatRepositoryImpl>(),
            ),
          ),
          BlocProvider(
            create: (context) => RecentChatsBloc(
              repository: context.read<RecentChatsRepositoryImpl>(),
            )..add(LoadRecentChatsRequested()),
          ),
          BlocProvider(
            create: (context) => FeedBloc(
              repository: context.read<FeedRepositoryImpl>(),
            )..add(LoadFeedRequested()),
          ),
          BlocProvider(
            create: (context) => NotificationsBloc(
              repository: context.read<NotificationsRepositoryImpl>(),
            )..add(LoadNotificationsRequested()),
          ),
          BlocProvider(
            create: (context) => AuthBloc(
              repository: context.read<AuthRepositoryImpl>(),
            )..add(AuthCheckRequested()),
          ),
        ],
        child: ValueListenableBuilder<ThemeMode>(
          valueListenable: themeNotifier,
          builder: (context, currentMode, child) {
            return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'Floq',
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF8CC6FF),
              primary: const Color(0xFF8CC6FF),
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: const Color(0xFFF8FAFC),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
              centerTitle: true,
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.redAccent, width: 1),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: const Size(64, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: ZoomPageTransitionsBuilder(),
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              },
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
              surface: const Color(0xFF1E1E1E),
            ),
            scaffoldBackgroundColor: const Color(0xFF121212),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E1E1E),
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF1E1E1E),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade800),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade800),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.redAccent, width: 1),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: const Size(64, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: ZoomPageTransitionsBuilder(),
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              },
            ),
          ),
          themeMode: currentMode,
          builder: (context, child) {
            return BlocListener<AuthBloc, AuthState>(
              listener: (context, state) {
                if (state is AuthUnauthenticated) {
                  navigatorKey.currentState?.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const OnboardingPage()),
                    (route) => false,
                  );
                }
              },
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (child, animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: Container(
                  key: ValueKey(currentMode),
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: child!,
                ),
              ),
            );
          },
          home: const SplashScreen(),
            );
          },
        ),
      ),
    );
  }
}

// ─── SPLASH SCREEN ──────────────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoEntranceController;
  late AnimationController _orbitController;
  late AnimationController _pulseController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _logoRotation;
  late Animation<double> _taglineOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _letterSpacing;

  @override
  void initState() {
    super.initState();

    // Elegant Reveal Animation
    _logoEntranceController = AnimationController(
       vsync: this,
       duration: const Duration(milliseconds: 3000),
    );

    // Elastic Scale-in
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoEntranceController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    // Subtle Rotation
    _logoRotation = Tween<double>(begin: -0.15, end: 0.0).animate(
      CurvedAnimation(
        parent: _logoEntranceController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoEntranceController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    // Staggered Text Reveal
    _letterSpacing = Tween<double>(begin: 20.0, end: 8.0).animate(
      CurvedAnimation(
        parent: _logoEntranceController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOutQuint),
      ),
    );

    _textSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _logoEntranceController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOutQuint),
      ),
    );

    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoEntranceController,
        curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
      ),
    );

    // Orbiting particles
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // Pulsing ring
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _logoEntranceController.forward();

    _initializeAndNavigate();
  }

  Future<void> _initializeAndNavigate() async {
    final authBloc = context.read<AuthBloc>();

    // 1. Start Initializations in parallel
    final initFuture = _performInitializations();

    // 2. Wait for a minimum time to show the beautiful animation (2.5s)
    final delayFuture = Future.delayed(const Duration(milliseconds: 2500));

    // 3. Wait for Auth state to be ready
    final authFuture = _waitForAuthState(authBloc);

    // Wait for all three
    await Future.wait([initFuture, delayFuture, authFuture]);

    if (!mounted) return;

    // 4. Navigate based on the final state
    _handleNavigation(authBloc.state);
  }

  Future<void> _performInitializations() async {
    try {
      // Initialize Notification Service
      final notificationService = NotificationService();
      await notificationService.init();
      
      // Initialize Socket Service
      await socketService.init();

      // Initialize Cache Service
      await CacheService().init();
    } catch (e) {
      debugPrint("Initialization error: $e");
    }
  }

  Future<void> _waitForAuthState(AuthBloc authBloc) async {
    // Wait until AuthBloc is no longer in Initial or Loading state
    while (mounted) {
      final state = authBloc.state;
      if (state is! AuthInitial && state is! AuthLoading) {
        return;
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  void _handleNavigation(AuthState state) {
    if (!mounted) return;

    if (state is AuthAuthenticated) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, anim, secAnim) => const HomePage(),
          transitionsBuilder: (context, anim, secAnim, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 1000),
        ),
      );
    } else {
      // Default to onboarding for Unauthenticated or Error
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, anim, secAnim) => const OnboardingPage(),
          transitionsBuilder: (context, anim, secAnim, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 1000),
        ),
      );
    }
  }

  @override
  void dispose() {
    _logoEntranceController.dispose();
    _orbitController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background Glow
          Center(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 350 + (sin(_pulseController.value * pi) * 100),
                  height: 350 + (sin(_pulseController.value * pi) * 100),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        colorScheme.primary.withValues(alpha: 0.1),
                        colorScheme.primary.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Orbital Particles
          Center(
            child: FadeTransition(
              opacity: _logoOpacity,
              child: AnimatedBuilder(
                animation: _orbitController,
                builder: (context, child) {
                  return SizedBox(
                    width: 280,
                    height: 280,
                    child: CustomPaint(
                      painter: _OrbitPainter(
                        progress: _orbitController.value,
                        color: colorScheme.primary,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Main Logo Animation
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RotationTransition(
                  turns: _logoRotation,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: FadeTransition(
                      opacity: _logoOpacity,
                      child: const FloqLogo(
                        size: 140,
                        isInteractive: false,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                SlideTransition(
                  position: _textSlide,
                  child: FadeTransition(
                    opacity: _taglineOpacity,
                    child: Column(
                      children: [
                        AnimatedBuilder(
                          animation: _letterSpacing,
                          builder: (context, child) {
                            return Text(
                              'Floq',
                              style: GoogleFonts.poppins(
                                fontSize: 48,
                                fontWeight: FontWeight.w900,
                                color: colorScheme.primary,
                                letterSpacing: _letterSpacing.value,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Connect • Share • Vibe',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.primary.withValues(alpha: 0.6),
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── ORBIT PAINTER ──────────────────────────────────────────────────────
class _OrbitPainter extends CustomPainter {
  final double progress;
  final Color color;

  _OrbitPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw multiple orbit rings
    for (int ring = 0; ring < 2; ring++) {
      final ringRadius = radius * (1.0 - (ring * 0.2));
      final ringProgress = ring == 0 ? progress : (1.0 - progress);
      
      final orbitPaint = Paint()
        ..color = color.withValues(alpha: 0.05 + (ring * 0.03))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0 + ring;
      canvas.drawCircle(center, ringRadius, orbitPaint);

      // Draw orbiting particles for each ring
      final count = 3 + ring;
      for (int i = 0; i < count; i++) {
        final angle = (ringProgress * 2 * pi) + (i * 2 * pi / count);
        final particleRadius = 3.0 + (i * 1.5) + (ring * 2);
        final x = center.dx + ringRadius * cos(angle);
        final y = center.dy + ringRadius * sin(angle);

        final particlePaint = Paint()
          ..color = color.withValues(alpha: 0.2 + (i * 0.1) + (ring * 0.1))
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, y), particleRadius, particlePaint);

        // Glow effect
        final glowPaint = Paint()
          ..color = color.withValues(alpha: 0.08)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, y), particleRadius * 3, glowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
