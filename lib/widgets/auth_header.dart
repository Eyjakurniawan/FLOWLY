import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import 'flowly_logo.dart';

/// Tombol kembali bulat + logo Flowly.
class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: AppColors.surface,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => Navigator.of(context).maybePop(),
            child: const SizedBox(
              width: 40,
              height: 40,
              child: Icon(Icons.chevron_left_rounded, size: 26),
            ),
          ),
        ),
        const SizedBox(width: 12),
        const FlowlyLogo(size: 22),
      ],
    );
  }
}
