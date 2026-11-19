import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../utils/constants.dart';

/// Wadah maskot Floy.
///
/// Otomatis memakai `assets/images/maskot.png` kalau filenya sudah ada.
/// Kalau belum ada, tampil placeholder tetes air supaya layout tetap jadi.
class MascotView extends StatelessWidget {
  final double size;
  final MascotExpression expression;

  const MascotView({
    super.key,
    this.size = 160,
    this.expression = MascotExpression.normal,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        expression.path,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _Placeholder(size: size),
      ),
    );
  }
}


class _Placeholder extends StatelessWidget {
  final double size;
  const _Placeholder({required this.size});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.water_drop_rounded,
        size: size * 0.75,
        color: AppColors.mascotBlue,
      ),
    );
  }
}
