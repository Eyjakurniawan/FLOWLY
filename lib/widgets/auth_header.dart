import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import 'flowly_logo.dart';

/// Logo Flowly di kiri atas halaman Masuk/Daftar.
/// Tombol kembali bulat hanya tampil kalau [showBack] true.
class AuthHeader extends StatelessWidget {
  final bool showBack;

  const AuthHeader({super.key, this.showBack = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showBack) ...[
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
        ],
        const FlowlyLogo(size: 22),
      ],
    );
  }
}