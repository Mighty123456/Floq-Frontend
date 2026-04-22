import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/socket_service.dart';
import 'bubble_notification.dart';

class RealTimeStatusIndicator extends StatefulWidget {
  const RealTimeStatusIndicator({super.key});

  @override
  State<RealTimeStatusIndicator> createState() => _RealTimeStatusIndicatorState();
}

class _RealTimeStatusIndicatorState extends State<RealTimeStatusIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final socketService = SocketService();

    return StreamBuilder<bool>(
      stream: socketService.connectionStream,
      initialData: socketService.isConnected,
      builder: (context, snapshot) {
        final isConnected = snapshot.data ?? false;

        return GestureDetector(
          onTap: () {
            socketService.init();
            BubbleNotification.show(context, "Refreshing connection...", type: NotificationType.info);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isConnected 
                  ? Colors.green.withValues(alpha: 0.1) 
                  : Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isConnected 
                    ? Colors.green.withValues(alpha: 0.5) 
                    : Colors.red.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _animation.value,
                      child: Opacity(
                        opacity: _animation.value,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isConnected ? Colors.green : Colors.red,
                            boxShadow: [
                              BoxShadow(
                                color: (isConnected ? Colors.green : Colors.red).withValues(alpha: 0.5),
                                blurRadius: 4,
                                spreadRadius: 2 * _animation.value,
                              )
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                Text(
                  isConnected ? "Real-time Data: Live" : "Real-time Data: Offline",
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isConnected ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
