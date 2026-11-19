import 'package:flutter/material.dart';

/// Mencari ukuran font terbesar (<= [maxFont]) supaya SEMUA teks di
/// [texts] muat dalam [maxWidth] satu baris. Dipakai untuk nominal uang
/// supaya font mengecil otomatis saat angkanya panjang, tanpa
/// mendorong atau menyempitkan jarak elemen lain.
///
/// Kalau pada [minFont] masih belum muat, [minFont] yang dikembalikan
/// (pakai FittedBox sebagai pengaman terakhir).
double fitFontSize(
  BuildContext context, {
  required List<String> texts,
  required double maxWidth,
  required double maxFont,
  double minFont = 9,
  FontWeight weight = FontWeight.w800,
  double step = 0.5,
}) {
  final base = DefaultTextStyle.of(context).style;
  final scaler = MediaQuery.textScalerOf(context);
  for (var size = maxFont; size >= minFont; size -= step) {
    var fits = true;
    for (final t in texts) {
      final tp = TextPainter(
        text: TextSpan(
          text: t,
          style: base.merge(TextStyle(fontSize: size, fontWeight: weight)),
        ),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      if (tp.width > maxWidth) {
        fits = false;
        break;
      }
    }
    if (fits) return size;
  }
  return minFont;
}