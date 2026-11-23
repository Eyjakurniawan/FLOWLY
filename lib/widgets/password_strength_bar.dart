import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../utils/validators.dart';

/// 4 segmen indikator kekuatan kata sandi + teks bantuan.
class PasswordStrengthBar extends StatelessWidget {
  final String password;

  const PasswordStrengthBar({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    final score = Validators.passwordStrength(password);
    final color = score <= 1
        ? AppColors.weak
        : score <= 2
            ? AppColors.medium
            : AppColors.strong;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (i) {
            final filled = i < score;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 4,
                margin: EdgeInsets.only(right: i == 3 ? 0 : 4),
                decoration: BoxDecoration(
                  color: filled ? color : const Color(0xFFCCD4E2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 5),
        const Text(
          'Minimal 8 karakter. Campurkan huruf besar, angka, dan simbol.',
          style: TextStyle(fontSize: 11, color: AppColors.textGrey),
        ),
      ],
    );
  }
}