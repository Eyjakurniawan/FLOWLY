import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../utils/constants.dart';
import 'mascot_view.dart';

/// Maskot kecil + balon ucapan (dipakai di halaman Daftar, Masuk & Setup).
class MascotBubble extends StatelessWidget {
  final String title;
  final String subtitle;
  final MascotExpression expression;

  /// Gaya halaman Masuk/Daftar: maskot lebih besar, padding balon lebih
  /// lega, dan ada ekor balon yang menunjuk ke maskot.
  final bool authStyle;

  const MascotBubble({
    super.key,
    required this.title,
    required this.subtitle,
    this.expression = MascotExpression.normal,
    this.authStyle = false,
  });

  @override
  Widget build(BuildContext context) {
    final mascotSize = authStyle ? 84.0 : 56.0;
    final vPad = authStyle ? 16.0 : 12.0;

    Widget bubble = Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: vPad),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
          ),
        ],
      ),
    );

    if (authStyle) {
      // Ekor balon: kotak putih kecil diputar 45° di tepi kiri, tengah vertikal.
      bubble = Stack(
        clipBehavior: Clip.none,
        children: [
          bubble,
          Positioned(
            left: -4,
            top: 0,
            bottom: 0,
            child: Center(
              child: Transform.rotate(
                angle: math.pi / 4,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        MascotView(size: mascotSize, expression: expression),
        const SizedBox(width: 12),
        Expanded(child: bubble),
      ],
    );
  }
}