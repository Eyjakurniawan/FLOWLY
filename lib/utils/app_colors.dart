import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Latar gelap (splash & kartu onboarding)
  static const Color navyTop = Color(0xFF12306B);
  static const Color navyBottom = Color(0xFF0A1330);

  static const LinearGradient navyGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [navyTop, navyBottom],
  );

  // Latar terang (onboarding & auth)
  static const Color background = Color(0xFFE8EEFB);
  static const Color surface = Colors.white;

  // Aksen
  static const Color primary = Color(0xFFE8472B); // tombol utama (oranye)
  static const Color link = Color(0xFF2563EB); // tautan biru
  static const Color mascotBlue = Color(0xFF3B82F6);

  // Teks
  static const Color textDark = Color(0xFF0A0A0A);
  static const Color textGrey = Color(0xFF6B7280);
  static const Color hint = Color(0xFF9CA3C7);

  // Lain-lain
  static const Color border = Color(0xFF0A0A0A);
  static const Color divider = Color(0xFFCBD3E6);
  static const Color strengthEmpty = Color(0xFFD3DAEC);
  static const Color weak = Color(0xFFE8472B);

  // Pesan error form (teks + garis tepi kolom). Lebih gelap dari oranye tombol.
  static const Color error = Color(0xFFC0341A);
  static const Color medium = Color(0xFFF59E0B);
  static const Color strong = Color(0xFF22C55E);
}