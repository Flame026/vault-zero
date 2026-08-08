import 'package:flutter/material.dart';

enum ThemePreset {
  royalPurple(
    label: 'Royal Purple',
    description: 'The original Vault Zero look',
    seedColor: Color(0xFF6F35D3),
  ),
  oceanBlue(
    label: 'Ocean Blue',
    description: 'Cool, clear, and focused',
    seedColor: Color(0xFF1769AA),
  ),
  emeraldGreen(
    label: 'Emerald Green',
    description: 'Calm, natural, and balanced',
    seedColor: Color(0xFF16835B),
  ),
  sunsetOrange(
    label: 'Sunset Orange',
    description: 'Warm, energetic, and bold',
    seedColor: Color(0xFFD85B24),
  ),
  rosePink(
    label: 'Rose Pink',
    description: 'Soft, expressive, and vivid',
    seedColor: Color(0xFFC13D75),
  );

  const ThemePreset({
    required this.label,
    required this.description,
    required this.seedColor,
  });

  final String label;
  final String description;
  final Color seedColor;
}
