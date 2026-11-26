import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../utils/constants.dart';
import 'mascot_view.dart';

/// Kartu gradasi navy berisi maskot + kartu info mengambang.
enum ChipPosition { topLeft, bottomLeft, bottomRight }

class OnboardingCard extends StatelessWidget {
  final ChipPosition chipPosition;
  final Widget chip;
  final bool showSparkles;
  final MascotExpression expression;

  const OnboardingCard({
    super.key,
    required this.chipPosition,
    required this.chip,
    this.showSparkles = false,
    this.expression = MascotExpression.normal,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mascotSize = (constraints.maxWidth < constraints.maxHeight
                ? constraints.maxWidth * 0.58
                : constraints.maxHeight * 0.58)
            .clamp(112.0, 190.0)
            .toDouble();
        return ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(gradient: AppColors.navyGradient),
            child: Stack(
              children: [
                Center(
                  child: MascotView(
                    size: mascotSize,
                    expression: expression,
                  ),
                ),
                if (showSparkles) ...const [
                  Positioned(
                    left: 56,
                    top: 90,
                    child: Icon(
                      Icons.add,
                      color: AppColors.mascotBlue,
                      size: 22,
                    ),
                  ),
                  Positioned(
                    right: 60,
                    top: 64,
                    child: Icon(
                      Icons.add,
                      color: AppColors.mascotBlue,
                      size: 22,
                    ),
                  ),
                ],
                Positioned(
                  left: chipPosition == ChipPosition.topLeft ||
                          chipPosition == ChipPosition.bottomLeft
                      ? 12
                      : null,
                  right: chipPosition == ChipPosition.bottomRight ? 12 : null,
                  top: chipPosition == ChipPosition.topLeft ? 12 : null,
                  bottom: chipPosition == ChipPosition.topLeft ? null : 12,
                  child: chip,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Kartu putih kecil di atas ilustrasi.
class InfoChip extends StatelessWidget {
  final String caption;
  final String? value;
  final String? sub;
  final bool isMessage;

  const InfoChip({
    super.key,
    required this.caption,
    this.value,
    this.sub,
    this.isMessage = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: isMessage ? 190 : 160),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            caption,
            style: const TextStyle(fontSize: 10, color: AppColors.textGrey),
          ),
          if (value != null) ...[
            const SizedBox(height: 2),
            Text(
              value!,
              style: TextStyle(
                fontSize: isMessage ? 12 : 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          if (sub != null) ...[
            const SizedBox(height: 2),
            Text(
              sub!,
              style: const TextStyle(fontSize: 10, color: AppColors.textGrey),
            ),
          ],
        ],
      ),
    );
  }
}
