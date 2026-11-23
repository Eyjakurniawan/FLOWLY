import 'package:flutter/material.dart';

/// Kotak dengan garis putus-putus di sekelilingnya.
///
/// Garis digambar di dalam batas kotak dan keliling dibagi rata, jadi tebal
/// dan jarak garisnya selalu rapi di ukuran berapa pun.
class DashedBox extends StatelessWidget {
  final Widget child;
  final Color color;
  final double radius;
  final double strokeWidth;
  final double dash;
  final double gap;

  const DashedBox({
    super.key,
    required this.child,
    this.color = const Color(0xFFD3DBEE),
    this.radius = 18,
    this.strokeWidth = 1.2,
    this.dash = 4,
    this.gap = 3,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBoxPainter(color, radius, strokeWidth, dash, gap),
      child: child,
    );
  }
}

class _DashedBoxPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double strokeWidth;
  final double dash;
  final double gap;

  const _DashedBoxPainter(
      this.color, this.radius, this.strokeWidth, this.dash, this.gap);

  @override
  void paint(Canvas canvas, Size size) {
    final inset = strokeWidth / 2;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(
            inset, inset, size.width - strokeWidth, size.height - strokeWidth),
        Radius.circular(radius - inset),
      ));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..isAntiAlias = true;

    final pattern = dash + gap;
    for (final metric in path.computeMetrics()) {
      final count = (metric.length / pattern).round().clamp(1, 1 << 20);
      final k = metric.length / (count * pattern);
      for (var i = 0; i < count; i++) {
        final d = i * pattern * k;
        canvas.drawPath(metric.extractPath(d, d + dash * k), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBoxPainter old) =>
      old.color != color ||
      old.radius != radius ||
      old.strokeWidth != strokeWidth ||
      old.dash != dash ||
      old.gap != gap;
}