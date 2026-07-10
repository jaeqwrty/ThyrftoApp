import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double fontSize;
  final String? subtitle;

  const AppLogo({
    super.key,
    this.fontSize = 32,
    this.subtitle,
    required String fontFamily,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Thryfto',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF17131F),
            letterSpacing: 0,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B6475),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

