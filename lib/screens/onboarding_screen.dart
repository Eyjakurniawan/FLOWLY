import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../utils/constants.dart';
import '../widgets/auth_switch_text.dart';
import '../widgets/flowly_logo.dart';
import '../widgets/onboarding_card.dart';
import '../widgets/page_indicator.dart';
import '../widgets/primary_button.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class _OnboardingData {
  final String title;
  final String description;
  final ChipPosition chipPosition;
  final Widget chip;
  final bool sparkles;
  final MascotExpression expression;

  const _OnboardingData({
    required this.title,
    required this.description,
    required this.chipPosition,
    required this.chip,
    required this.expression,
    this.sparkles = false,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  static const List<_OnboardingData> _pages = [
    _OnboardingData(
      title: 'Kenalan dengan Floy',
      description:
          'Teman kecil yang menjaga uang kamu tetap mengalir. Tinggi air di tangki menunjukkan sisa saldo kamu.',
      chipPosition: ChipPosition.bottomLeft,
      expression: MascotExpression.normal,
      chip: InfoChip(caption: 'Aman dipakai hari ini', value: 'Rp120.000'),
    ),
    _OnboardingData(
      title: 'Catat dalam 5 detik',
      description:
          'Nominal, kategori, dompet. Floy bantu kamu selesai tanpa formulir panjang.',
      chipPosition: ChipPosition.topLeft,
      expression: MascotExpression.wink,
      chip: InfoChip(
        caption: 'Pengeluaran',
        value: 'Rp45.000',
        sub: 'Makan • GoPay',
      ),
    ),
    _OnboardingData(
      title: 'Floy mengingatkan dengan lembut',
      description:
          'Pilih sendiri jamnya, dan Floy akan menyapa tepat waktu agar mencatat jadi kebiasaan.',
      chipPosition: ChipPosition.bottomRight,
      expression: MascotExpression.happy,
      sparkles: true,
      chip: InfoChip(
        caption: 'Floy • 20.00',
        value: 'Sudah catat pengeluaran hari ini?',
        isMessage: true,
      ),
    ),
  ];

  // Tinggi area judul + deskripsi (cukup untuk judul 2 baris + deskripsi 4 baris).
  static const double _textAreaHeight = 180;

  bool get _isLast => _index == _pages.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_isLast) {
      _goRegister();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    }
  }

  void _skip() => _controller.animateToPage(
        _pages.length - 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );

  void _goRegister() => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const RegisterScreen()));

  void _goLogin() => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const LoginScreen()));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const FlowlyLogo(size: 18),
                  if (!_isLast)
                    GestureDetector(
                      onTap: _skip,
                      child: const Text(
                        'Lewati',
                        style: TextStyle(
                          color: AppColors.link,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              // Halaman
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (_, i) {
                    final p = _pages[i];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Kartu mengisi semua sisa ruang, sedangkan area teks
                        // di bawahnya punya tinggi TETAP, sehingga ukuran
                        // kartu biru sama di semua halaman walau panjang
                        // judul/deskripsinya berbeda.
                        Expanded(
                          child: SizedBox(
                            width: double.infinity,
                            child: OnboardingCard(
                              chipPosition: p.chipPosition,
                              chip: p.chip,
                              showSparkles: p.sparkles,
                              expression: p.expression,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          height: _textAreaHeight,
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.title,
                                style: const TextStyle(
                                  fontSize: 26,
                                  height: 1.2,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                p.description,
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.5,
                                  color: AppColors.textGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              PageIndicator(count: _pages.length, index: _index),
              const SizedBox(height: 18),
              PrimaryButton(
                label: _isLast ? 'Buat akun' : 'Lanjut',
                onPressed: _next,
              ),
              const SizedBox(height: 16),
              AuthSwitchText(
                question: 'Sudah punya akun?',
                action: 'Masuk',
                onTap: _goLogin,
              ),
            ],
          ),
        ),
      ),
    );
  }
}