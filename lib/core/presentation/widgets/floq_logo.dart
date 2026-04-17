import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FloqLogo extends StatefulWidget {
  final double size;
  final bool isInteractive;
  final bool showText;

  const FloqLogo({
    super.key,
    this.size = 120,
    this.isInteractive = true,
    this.showText = false,
  });

  @override
  State<FloqLogo> createState() => _FloqLogoState();
}

class _FloqLogoState extends State<FloqLogo> with TickerProviderStateMixin {
  late AnimationController _bounceController;
  
  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!widget.isInteractive) return;
    _bounceController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return GestureDetector(
      onTap: _handleTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Core Logo Plate (Now using the real brand asset)
                ScaleTransition(
                  scale: Tween<double>(begin: 1.0, end: 1.15).animate(
                    CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut)
                  ),
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(widget.size * 0.25),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(widget.size * 0.25),
                      child: Image.asset(
                        'assets/icon.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Icon(
                            Icons.flight_rounded,
                            size: widget.size * 0.6,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (widget.showText) ...[
            const SizedBox(height: 16),
            Text(
              "Floq",
              style: GoogleFonts.poppins(
                fontSize: widget.size * 0.25,
                fontWeight: FontWeight.w900,
                color: colorScheme.primary,
                letterSpacing: 2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
