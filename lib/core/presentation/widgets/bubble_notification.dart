import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum NotificationType { success, error, info }

class BubbleNotification extends StatefulWidget {
  final String message;
  final NotificationType type;
  final VoidCallback onDismiss;

  const BubbleNotification({
    super.key,
    required this.message,
    this.type = NotificationType.info,
    required this.onDismiss,
  });

  static void show(BuildContext context, String message, {NotificationType type = NotificationType.info}) {
    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 20,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: BubbleNotification(
            message: message,
            type: type,
            onDismiss: () => overlayEntry.remove(),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(overlayEntry);
  }

  @override
  State<BubbleNotification> createState() => _BubbleNotificationState();
}

class _BubbleNotificationState extends State<BubbleNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _opacityAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    ));

    _controller.forward();

    _timer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        _controller.reverse().then((_) => widget.onDismiss());
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    IconData icon;
    Color iconColor;

    switch (widget.type) {
      case NotificationType.success:
        bgColor = const Color(0xFFE8F5E9).withValues(alpha: 0.95);
        icon = Icons.check_circle_rounded;
        iconColor = Colors.green;
        break;
      case NotificationType.error:
        bgColor = const Color(0xFFFFEBEE).withValues(alpha: 0.95);
        icon = Icons.error_rounded;
        iconColor = Colors.redAccent;
        break;
      case NotificationType.info:
        bgColor = const Color(0xFFE3F2FD).withValues(alpha: 0.95);
        icon = Icons.info_rounded;
        iconColor = Colors.blue;
        break;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      bgColor = Colors.grey[900]!.withValues(alpha: 0.9);
    }

    return FadeTransition(
      opacity: _opacityAnimation,
      child: SlideTransition(
        position: _offsetAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(
              color: iconColor.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  widget.message,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.blueGrey[900],
                  ),
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(Icons.close_rounded, size: 20, color: isDark ? Colors.white54 : Colors.grey),
                onPressed: () {
                  _timer?.cancel();
                  _controller.reverse().then((_) => widget.onDismiss());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
