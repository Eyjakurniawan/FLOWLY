import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/mascot_view.dart';
import '../utils/app_router.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

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
              // Lingkaran konsentris
              const Positioned.fill(child: CustomPaint(painter: _RingsPainter())),
              // Bintang kecil
              const Positioned(
                left: 52,
                top: 175,
                child: Icon(Icons.add, color: Colors.white54, size: 18),
              ),
              const Positioned(
                right: 52,
                top: 195,
                child: Icon(Icons.add, color: Colors.white54, size: 18),
              ),
              // Konten tengah
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 210,
                      height: 210,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.08),
                      ),
                      child: const Center(child: MascotView(size: 150)),
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

class _RingsPainter extends CustomPainter {
  const _RingsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.4);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withOpacity(0.10);

    for (final r in [150.0, 215.0, 290.0, 380.0, 480.0]) {
      canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
