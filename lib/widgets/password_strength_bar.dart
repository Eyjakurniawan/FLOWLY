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
                margin: EdgeInsets.only(right: i == 3 ? 0 : 6),
                decoration: BoxDecoration(
                  color: filled ? color : AppColors.strengthEmpty,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        const Text(
          'Minimal 8 karakter. Campur huruf besar, angka, dan simbol.',
          style: TextStyle(fontSize: 10, color: AppColors.textGrey),
        ),
      ],
    );
  }
}
