import 'package:flutter/material.dart';

/// Titik indikator onboarding; halaman aktif berupa pil putih memanjang.
class PageIndicator extends StatelessWidget {
  final int count;
  final int index;

  const PageIndicator({super.key, required this.count, required this.index});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: active ? 26 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: active ? Colors.white : const Color(0xFF6B7280),
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }),
    );
  }
}
