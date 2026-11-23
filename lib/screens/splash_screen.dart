import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/mascot_view.dart';
import '../utils/app_router.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // Mengendalikan gerakan gelombang (berulang terus, mulus tanpa putus).
  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  void _continue(BuildContext context) {
    final next = AuthService.instance.isLoggedIn
        ? AppRouter.afterAuth()
        : const OnboardingScreen();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => next,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _continue(context),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(gradient: AppColors.navyGradient),
          child: Stack(
            children: [
              // Konten tengah
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Cincin & tanda + berpusat di lingkaran maskot,
                    // jadi posisinya selalu presisi di semua ukuran layar.
                    SizedBox(
                      width: 210,
                      height: 210,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          const Positioned.fill(
                            child: CustomPaint(painter: _RingsPainter()),
                          ),
                          Container(
                            width: 210,
                            height: 210,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.08),
                            ),
                            child: const Center(child: MascotView(size: 150)),
                          ),
                          // Tanda + (offset dari pusat lingkaran)
                          const Positioned(
                            left: 105 - 114 - 9,
                            top: 105 - 70 - 9,
                            child: Icon(Icons.add,
                                color: Colors.white54, size: 18),
                          ),
                          const Positioned(
                            left: 105 + 110 - 9,
                            top: 105 - 36 - 9,
                            child: Icon(Icons.add,
                                color: Colors.white54, size: 18),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      AppConstants.appName,
                      style: AppTheme.logo(size: 46, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      AppConstants.tagline,
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
              // Gelombang air bergerak di bagian bawah
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 150,
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _wave,
                    builder: (_, __) => CustomPaint(
                      painter: _WavePainter(_wave.value),
                    ),
                  ),
                ),
              ),
              // Teks bawah
              const Positioned(
                left: 0,
                right: 0,
                bottom: 48,
                child: Text(
                  'Ketuk untuk lanjut',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Gelombang air 3 lapis. [t] berjalan 0..1 lalu mengulang; kelipatan
/// bilangan bulat pada fase membuat loop-nya mulus.
class _WavePainter extends CustomPainter {
  final double t;
  const _WavePainter(this.t);

  // Satu lapis gelombang.
  void _layer(
    Canvas canvas,
    Size size, {
    required Color color,
    required double baseY, // posisi permukaan (0 = atas, 1 = bawah)
    required double amplitude,
    required double cycles, // jumlah gelombang selebar layar
    required double phase, // geser fase (radian)
  }) {
    final path = Path()..moveTo(0, size.height);
    for (double x = 0; x <= size.width; x += 2) {
      final y = size.height * baseY +
          amplitude * math.sin((x / size.width) * cycles * 2 * math.pi + phase);
      path.lineTo(x, y);
    }
    path
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final a = t * 2 * math.pi;

    // Lapis belakang: terang, transparan, bergerak ke kanan.
    _layer(canvas, size,
        color: const Color(0xFF3B82F6).withOpacity(0.35),
        baseY: 0.22,
        amplitude: 10,
        cycles: 1.5,
        phase: a);

    // Lapis tengah: bergerak ke kiri, lebih cepat.
    _layer(canvas, size,
        color: const Color(0xFF2563EB).withOpacity(0.55),
        baseY: 0.30,
        amplitude: 9,
        cycles: 2,
        phase: -2 * a + 1.5);

    // Lapis depan: biru solid seperti desain awal.
    _layer(canvas, size,
        color: const Color(0xFF1F55D3),
        baseY: 0.40,
        amplitude: 8,
        cycles: 1,
        phase: a + 3);
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) => old.t != t;
}

class _RingsPainter extends CustomPainter {
  const _RingsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Pusat = pusat lingkaran maskot (painter ini menggambar di area
    // lingkaran itu, tapi boleh melebar keluar sampai ke tepi layar).
    final center = size.center(Offset.zero);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withOpacity(0.10);

    for (final r in [140.0, 190.0, 245.0, 310.0, 395.0]) {
      canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}