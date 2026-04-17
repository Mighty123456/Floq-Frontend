import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import '../../../features/auth/presentation/pages/login_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _floatController;
  late AnimationController _pulseController;
  late AnimationController _particleController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _floatController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _goToLogin();
    }
  }

  void _goToLogin() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      body: Stack(
        children: [
          // Ambient floating particles
          ...List.generate(12, (i) => _AmbientParticle(
            controller: _particleController,
            index: i,
            color: colorScheme.primary,
          )),

          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Progress dots
                      Row(
                        children: List.generate(4, (i) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                            margin: const EdgeInsets.only(right: 6),
                            width: _currentPage == i ? 28 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentPage == i
                                  ? colorScheme.primary
                                  : colorScheme.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                      TextButton(
                        onPressed: _goToLogin,
                        child: Text(
                          "Skip",
                          style: GoogleFonts.poppins(
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Pages
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    children: [
                      _buildDiscoverPage(colorScheme, isDark),
                      _buildConnectPage(colorScheme, isDark),
                      _buildSharePage(colorScheme, isDark),
                      _buildExperiencePage(colorScheme, isDark),
                    ],
                  ),
                ),

                // Bottom action
                Padding(
                  padding: const EdgeInsets.fromLTRB(40, 0, 40, 40),
                  child: GestureDetector(
                    onTap: _nextPage,
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final pulse = _pulseController.value;
                        return Container(
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                colorScheme.primary,
                                colorScheme.primary.withValues(alpha: 0.8 + pulse * 0.2),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.primary.withValues(alpha: 0.2 + pulse * 0.1),
                                blurRadius: 20 + pulse * 10,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _currentPage == 3 ? "Let's Go!" : "Continue",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  _currentPage == 3
                                      ? Icons.rocket_launch_rounded
                                      : Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
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

  // ─── PAGE 1: DISCOVER ────────────────────────────────────────────────
  Widget _buildDiscoverPage(ColorScheme cs, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Interactive mock feed
          AnimatedBuilder(
            animation: _floatController,
            builder: (context, child) {
              final floatY = sin(_floatController.value * pi) * 8;
              return Transform.translate(
                offset: Offset(0, floatY),
                child: child,
              );
            },
            child: Container(
              height: 320,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[50],
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                ),
              ),
              child: Column(
                children: [
                  // Mock search bar
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          Icon(Icons.search, size: 18, color: Colors.grey[500]),
                          const SizedBox(width: 8),
                          Text("Explore trending...", style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                  // Mock category chips
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: ["🔥 Trending", "🎨 Design", "💻 Tech"].map((label) {
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(label, style: TextStyle(fontSize: 11, color: cs.primary, fontWeight: FontWeight.bold)),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Mock grid
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GridView.count(
                        crossAxisCount: 3,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        physics: const NeverScrollableScrollPhysics(),
                        children: List.generate(6, (i) {
                          final colors = [
                            cs.primary.withValues(alpha: 0.2),
                            cs.secondary.withValues(alpha: 0.2),
                            Colors.orangeAccent.withValues(alpha: 0.2),
                            cs.primary.withValues(alpha: 0.15),
                            Colors.purpleAccent.withValues(alpha: 0.2),
                            cs.secondary.withValues(alpha: 0.15),
                          ];
                          return Container(
                            decoration: BoxDecoration(
                              color: colors[i],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              [Icons.image, Icons.play_circle_fill, Icons.music_note, Icons.photo_camera, Icons.favorite, Icons.star][i],
                              color: cs.primary.withValues(alpha: 0.5),
                              size: 24,
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 48),
          Text(
            "Discover Your World",
            style: GoogleFonts.poppins(
              fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Explore trending content, channels, and people curated just for you",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey, height: 1.6),
          ),
        ],
      ),
    );
  }

  // ─── PAGE 2: CONNECT ─────────────────────────────────────────────────
  Widget _buildConnectPage(ColorScheme cs, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _floatController,
            builder: (context, child) {
              final floatY = sin(_floatController.value * pi) * 6;
              return Transform.translate(
                offset: Offset(0, floatY),
                child: child,
              );
            },
            child: SizedBox(
              height: 320,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Orbit ring
                  AnimatedBuilder(
                    animation: _particleController,
                    builder: (context, child) {
                      return CustomPaint(
                        size: const Size(260, 260),
                        painter: _ConnectionOrbitPainter(
                          progress: _particleController.value,
                          color: cs.primary,
                          isDark: isDark,
                        ),
                      );
                    },
                  ),
                  // Center avatar
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [cs.primary, cs.secondary],
                      ),
                    ),
                    child: const Icon(Icons.person, color: Colors.white, size: 40),
                  ),
                  // Orbiting avatars
                  ...List.generate(5, (i) {
                    return AnimatedBuilder(
                      animation: _particleController,
                      builder: (context, child) {
                        final angle = (_particleController.value * 2 * pi) + (i * 2 * pi / 5);
                        final radius = 110.0;
                        final x = radius * cos(angle);
                        final y = radius * sin(angle);
                        return Transform.translate(
                          offset: Offset(x, y),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                              border: Border.all(color: cs.primary.withValues(alpha: 0.3), width: 2),
                            ),
                            child: CircleAvatar(
                              radius: 20,
                              backgroundImage: NetworkImage("https://i.pravatar.cc/80?u=orbit_$i"),
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 48),
          Text(
            "Build Your Flock",
            style: GoogleFonts.poppins(
              fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Connect with like-minded people who orbit around the same energy as you",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey, height: 1.6),
          ),
        ],
      ),
    );
  }

  // ─── PAGE 3: SHARE ───────────────────────────────────────────────────
  Widget _buildSharePage(ColorScheme cs, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _floatController,
            builder: (context, child) {
              final floatY = sin(_floatController.value * pi) * 8;
              return Transform.translate(
                offset: Offset(0, floatY),
                child: child,
              );
            },
            child: Container(
              height: 320,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[50],
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                ),
              ),
              child: Column(
                children: [
                  // Mock stories bar
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: List.generate(4, (i) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Column(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: i == 0
                                      ? null
                                      : LinearGradient(colors: [cs.primary, Colors.orangeAccent]),
                                  color: i == 0 ? Colors.grey.withValues(alpha: 0.2) : null,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(3),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[50],
                                    ),
                                    padding: const EdgeInsets.all(2),
                                    child: CircleAvatar(
                                      radius: 22,
                                      backgroundColor: cs.primary.withValues(alpha: 0.1),
                                      backgroundImage: i == 0 ? null : NetworkImage("https://i.pravatar.cc/80?u=story_ob_$i"),
                                      child: i == 0
                                          ? Icon(Icons.add, color: cs.primary, size: 20)
                                          : null,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                i == 0 ? "You" : "User $i",
                                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                  const Divider(height: 1),
                  // Mock post
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: cs.primary.withValues(alpha: 0.1),
                                child: Icon(Icons.person, size: 16, color: cs.primary),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("You", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12)),
                                  Text("Just now", style: TextStyle(color: Colors.grey, fontSize: 9)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  colors: [cs.primary.withValues(alpha: 0.15), cs.secondary.withValues(alpha: 0.1)],
                                ),
                              ),
                              child: Center(
                                child: Icon(Icons.photo_library_rounded, size: 48, color: cs.primary.withValues(alpha: 0.4)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 18),
                              const SizedBox(width: 4),
                              Text("248", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 16),
                              Icon(Icons.chat_bubble_outline_rounded, color: Colors.grey, size: 16),
                              const SizedBox(width: 4),
                              Text("32", style: TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 48),
          Text(
            "Share Every Moment",
            style: GoogleFonts.poppins(
              fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Post stories, share updates, and let your flock see the world through your eyes",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey, height: 1.6),
          ),
        ],
      ),
    );
  }

  // ─── PAGE 4: EXPERIENCE ──────────────────────────────────────────────
  Widget _buildExperiencePage(ColorScheme cs, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _floatController,
            builder: (context, child) {
              final floatY = sin(_floatController.value * pi) * 6;
              return Transform.translate(
                offset: Offset(0, floatY),
                child: child,
              );
            },
            child: SizedBox(
              height: 320,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Central Anchor (The "Floq" Core)
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cs.primary.withValues(alpha: 0.1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [cs.primary, cs.secondary],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: cs.primary.withValues(alpha: 0.4),
                              blurRadius: 30,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                  // Floating feature icons
                  ...List.generate(4, (i) {
                    return AnimatedBuilder(
                      animation: _particleController,
                      builder: (context, child) {
                        final angle = (_particleController.value * 2 * pi) + (i * pi / 2);
                        final radius = 140.0;
                        final x = radius * cos(angle);
                        final y = radius * sin(angle);
                        final icons = [
                          Icons.chat_rounded,
                          Icons.explore_rounded,
                          Icons.people_rounded,
                          Icons.photo_camera_rounded,
                        ];
                        return Transform.translate(
                          offset: Offset(x, y),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
                            ),
                            child: Icon(icons[i], color: cs.primary, size: 22),
                          ),
                        );
                      },
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 48),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [cs.primary, cs.secondary],
            ).createShader(bounds),
            child: Text(
              "Welcome to Floq",
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Your social flock awaits. Chat, share, discover, and grow together.",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey, height: 1.6),
          ),
        ],
      ),
    );
  }
}

// ─── CONNECTION ORBIT PAINTER ───────────────────────────────────────────
class _ConnectionOrbitPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isDark;

  _ConnectionOrbitPainter({
    required this.progress,
    required this.color,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Dashed orbit ring
    final paint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const dashCount = 60;
    for (int i = 0; i < dashCount; i++) {
      final angle = (i / dashCount) * 2 * pi;
      final nextAngle = ((i + 0.5) / dashCount) * 2 * pi;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        angle,
        nextAngle - angle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ConnectionOrbitPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ─── AMBIENT PARTICLE ───────────────────────────────────────────────────
class _AmbientParticle extends StatelessWidget {
  final AnimationController controller;
  final int index;
  final Color color;

  const _AmbientParticle({
    required this.controller,
    required this.index,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    final rng = Random(index * 42);
    final startX = rng.nextDouble() * screenW;
    final startY = rng.nextDouble() * screenH;
    final size = 4.0 + rng.nextDouble() * 6;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final t = (controller.value + index * 0.08) % 1.0;
        final dx = sin(t * 2 * pi) * 20;
        final dy = cos(t * 2 * pi + index) * 20;
        final opacity = (sin(t * pi) * 0.4).clamp(0.05, 0.3);

        return Positioned(
          left: startX + dx,
          top: startY + dy,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: opacity),
            ),
          ),
        );
      },
    );
  }
}
