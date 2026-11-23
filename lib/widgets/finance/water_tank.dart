import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/finance_models.dart';
import '../../services/finance_store.dart';

/// Tinggi air minimum. Saldo kosong pun tangki tidak kosong melompong:
/// masih ada sedikit air (sekitar 14% tinggi kartu) yang bergelombang.
const double tankMinLevel = 0.14;

/// Tinggi air tangki saldo, [tankMinLevel]..1.
///
/// = sisa uang dibanding seluruh uang yang pernah masuk (saldo awal semua
/// dompet + semua pemasukan). Pemasukan menaikkan air, pengeluaran
/// menurunkannya. Kalau saldo kosong (atau belum ada dompet/uang sama
/// sekali), air tetap setinggi [tankMinLevel].
double tankLevel(FinanceStore store) {
  var funded = 0;
  var balance = 0;
  for (final w in store.wallets) {
    funded += w.initialBalance;
    balance += store.balanceOf(w);
    for (final t in store.walletTransactions(w.name)) {
      if (t.type == TxType.income) funded += t.amount;
    }
  }
  if (funded <= 0 || balance <= 0) return tankMinLevel;
  return (balance / funded).clamp(tankMinLevel, 1.0).toDouble();
}

/// Lapisan air bergelombang. Taruh di belakang isi kartu (Positioned.fill);
/// kartunya yang memotong sudut membulat (clipBehavior).
///
/// - Gelombang bergerak terus (dua lapis, arah berlawanan).
/// - Saat [level] berubah, air naik/turun halus, dan gelombang sedikit
///   membesar selama bergerak lalu tenang lagi.
class WaterTank extends StatefulWidget {
  final double level; // 0..1
  const WaterTank({super.key, required this.level});

  @override
  State<WaterTank> createState() => _WaterTankState();
}

class _WaterTankState extends State<WaterTank>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Hormati pengaturan "kurangi animasi" di perangkat.
    if (MediaQuery.of(context).disableAnimations) {
      _wave.stop();
    } else if (!_wave.isAnimating) {
      _wave.repeat();
    }
  }

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: TweenAnimationBuilder<double>(
        // begin hanya dipakai saat pertama tampil (air terisi dari kosong);
        // setelah itu air bergerak dari tinggi sekarang ke yang baru.
        tween: Tween<double>(begin: 0, end: widget.level),
        duration: const Duration(milliseconds: 1100),
        curve: Curves.easeInOutCubic,
        builder: (context, shown, _) {
          final moving = (widget.level - shown).abs();
          final amp = (4 + moving * 40).clamp(4.0, 10.0).toDouble();
          return AnimatedBuilder(
            animation: _wave,
            builder: (context, _) => CustomPaint(
              size: Size.infinite,
              painter: _WavePainter(
                level: shown,
                phase: _wave.value * 2 * math.pi,
                amp: amp,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double level;
  final double phase;
  final double amp;
  const _WavePainter({
    required this.level,
    required this.phase,
    required this.amp,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (level <= 0.001) return;
    final w = size.width;
    final h = size.height;

    // Permukaan air bergerak dari di bawah kartu (kosong) sampai di atasnya
    // (penuh); selisih amp supaya puncak/lembah gelombang tidak menyisakan
    // celah saat kosong maupun penuh.
    final top = -amp;
    final bottom = h + amp;
    final y0 = bottom - (bottom - top) * level;

    double front(double x) =>
        y0 + amp * math.sin(x / w * 2 * math.pi + phase);
    double back(double x) =>
        y0 -
        amp * 0.4 +
        amp * 0.8 * math.sin(x / w * 2 * math.pi * 1.6 - phase + 1.5);

    Path fill(double Function(double) f) {
      final p = Path()..moveTo(0, h + 1);
      for (var x = 0.0; x <= w; x += 4) {
        p.lineTo(x, f(x));
      }
      p.lineTo(w, f(w));
      p.lineTo(w, h + 1);
      p.close();
      return p;
    }

    // Lapisan belakang (lebih pucat).
    canvas.drawPath(
      fill(back),
      Paint()..color = const Color(0x663B82F6),
    );

    // Lapisan depan (biru, makin dalam makin pekat).
    final frontRect = Rect.fromLTRB(0, y0 - amp, w, math.max(h, y0 + amp + 1));
    canvas.drawPath(
      fill(front),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xD94C8DFF), Color(0xF21E4FD6)],
        ).createShader(frontRect),
    );

    // Garis kilau tipis di permukaan.
    final line = Path()..moveTo(0, front(0));
    for (var x = 4.0; x <= w; x += 4) {
      line.lineTo(x, front(x));
    }
    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0x59FFFFFF),
    );
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) =>
      old.level != level || old.phase != phase || old.amp != amp;
}