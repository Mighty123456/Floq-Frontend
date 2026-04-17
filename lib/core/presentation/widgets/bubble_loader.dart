import 'package:flutter/material.dart';

class BubbleLoader extends StatefulWidget {
  final double size;
  final Color? color;

  const BubbleLoader({
    super.key,
    this.size = 50.0,
    this.color,
  });

  @override
  State<BubbleLoader> createState() => _BubbleLoaderState();
}

class _BubbleLoaderState extends State<BubbleLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final delay = index * 0.2;
              final value = ( (_controller.value + delay) % 1.0);
              final yOffset = -20 * (1.0 - (2.0 * value - 1.0).abs());
              final scale = 0.8 + 0.4 * (1.0 - (2.0 * value - 1.0).abs());

              return Transform.translate(
                offset: Offset(0, yOffset),
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: widget.size * 0.2,
                    height: widget.size * 0.2,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 1.0 - (index * 0.2)),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
