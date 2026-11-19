import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

/// Header setup: tombol kembali, indikator langkah (garis/titik), "n dari 4".
class SetupHeader extends StatelessWidget {
  /// Indeks langkah aktif, mulai dari 0.
  final int step;
  final int total;
  final bool showBack;
  final bool showCounter;
  final VoidCallback? onBack;

  const SetupHeader({
    super.key,
    required this.step,
    this.total = 4,
    this.showBack = true,
    this.showCounter = true,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          if (showBack) ...[
            Material(
              color: AppColors.surface,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onBack,
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(Icons.chevron_left_rounded, size: 26),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Row(
            children: List.generate(total, (i) {
              final active = i <= step;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: active ? 28 : 6,
                height: active ? 5 : 6,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: active ? AppColors.textDark : AppColors.divider,
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            }),
          ),
          const Spacer(),
          if (showCounter)
            Text(
              '${step + 1} dari $total',
              style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
            ),
        ],
      ),
    );
  }
}