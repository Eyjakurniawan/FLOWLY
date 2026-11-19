import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

/// "Sudah punya akun? Masuk" / "Belum punya akun? Daftar".
class AuthSwitchText extends StatelessWidget {
  final String question;
  final String action;
  final VoidCallback onTap;

  const AuthSwitchText({
    super.key,
    required this.question,
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$question ',
          style: const TextStyle(fontSize: 14, color: AppColors.textGrey),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            action,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.link,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
