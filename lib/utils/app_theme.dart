import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  /// Font judul/logo (serif italic seperti "Flowly").
  static TextStyle logo({double size = 22, Color color = AppColors.textDark}) {
    return GoogleFonts.playfairDisplay(
      fontSize: size,
      fontWeight: FontWeight.w800,
      fontStyle: FontStyle.italic,
      color: color,
    );
  }

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.background,
      ),
      scaffoldBackgroundColor: AppColors.background,
    );

    return base.copyWith(
      textTheme: GoogleFonts.dmSansTextTheme(base.textTheme).apply(
        bodyColor: AppColors.textDark,
        displayColor: AppColors.textDark,
      ),
      // Hilangkan garis tepi (stroke) pada track Switch, baik ON maupun OFF.
      // Bulatan (thumb) dibuat sama besar saat ON maupun OFF: di Material 3
      // thumb OFF otomatis mengecil, kecuali Switch punya thumbIcon.
      switchTheme: SwitchThemeData(
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
        trackOutlineWidth: const WidgetStatePropertyAll(0),
        thumbIcon: WidgetStateProperty.all(
          const Icon(Icons.circle, color: Colors.transparent),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: const BorderSide(color: AppColors.textDark, width: 1.4),
      ),
    );
  }
}