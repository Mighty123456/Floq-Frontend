import 'package:flutter/material.dart';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FloqAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double radius;
  final Color? backgroundColor;
  final Color? textColor;
  final double? fontSize;
  final Widget? overlay;

  const FloqAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.radius = 24,
    this.backgroundColor,
    this.textColor,
    this.fontSize,
    this.overlay,
  });

  String _getInitials(String name) {
    if (name.isEmpty || name == 'Unknown') return "?";
    return name.trim()[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    final isPlaceholder = imageUrl != null && (
      imageUrl!.contains('pravatar.cc') || 
      imageUrl!.contains('robohash.org') || 
      imageUrl!.contains('ui-avatars.com') ||
      imageUrl!.contains('placeholder')
    );

    final hasImage = imageUrl != null && imageUrl!.isNotEmpty && !isPlaceholder;
    final isLocal = hasImage && !imageUrl!.startsWith('http');
    
    return CircularOverlay(
      radius: radius,
      overlay: overlay,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? (isDark ? Colors.white12 : Colors.grey[200]),
        child: hasImage 
          ? ClipOval(
              child: isLocal 
                ? Image.file(
                    File(imageUrl!),
                    fit: BoxFit.cover,
                    width: radius * 2,
                    height: radius * 2,
                    errorBuilder: (context, error, stackTrace) => _buildInitials(colorScheme),
                  )
                : CachedNetworkImage(
                    imageUrl: imageUrl!,
                    fit: BoxFit.cover,
                    width: radius * 2,
                    height: radius * 2,
                    placeholder: (context, url) => Center(
                      child: Text(
                        _getInitials(name),
                        style: GoogleFonts.poppins(
                          fontSize: fontSize ?? (radius * 0.8),
                          fontWeight: FontWeight.bold,
                          color: textColor ?? colorScheme.primary.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => _buildInitials(colorScheme),
                  ),
            )
          : _buildInitials(colorScheme),
      ),
    );
  }

  Widget _buildInitials(ColorScheme colorScheme) {
    return Text(
      _getInitials(name),
      style: GoogleFonts.poppins(
        fontSize: fontSize ?? (radius * 0.8),
        fontWeight: FontWeight.bold,
        color: textColor ?? colorScheme.primary,
      ),
    );
  }
}

class CircularOverlay extends StatelessWidget {
  final double radius;
  final Widget child;
  final Widget? overlay;

  const CircularOverlay({
    super.key,
    required this.radius,
    required this.child,
    this.overlay,
  });

  @override
  Widget build(BuildContext context) {
    if (overlay == null) return child;
    return Stack(
      children: [
        child,
        Positioned(
          right: 0,
          bottom: 0,
          child: overlay!,
        ),
      ],
    );
  }
}
