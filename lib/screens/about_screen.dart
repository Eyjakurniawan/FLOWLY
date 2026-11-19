import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../widgets/finance/common.dart';
import '../widgets/finance/home_header.dart';
import '../widgets/mascot_view.dart';
import 'legal_screen.dart';

/// Samakan dengan `version` di pubspec.yaml.
const _appVersion = '1.0.0';

/// Halaman Tentang Aplikasi (dibuka dari menu Profile).
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: HomeHeader(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 124),
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).maybePop(),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child:
                              const Icon(Icons.chevron_left_rounded, size: 28),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text('Tentang Aplikasi',
                          style: TextStyle(
                              fontSize: 26, fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const FlowlyCard(
                    padding: EdgeInsets.fromLTRB(24, 28, 24, 26),
                    child: SizedBox(
                      width: double.infinity,
                      child: Column(
                        children: [
                          MascotView(size: 150),
                          SizedBox(height: 14),
                          Text('Flowly',
                              style: TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.w800)),
                          SizedBox(height: 4),
                          Text('Versi $_appVersion',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.textGrey)),
                          SizedBox(height: 14),
                          Text(
                            'Uang mengalir, pikiran tetap tenang. Flowly membantu Anda mencatat, merencanakan, dan memahami keuangan sehari-hari.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textGrey,
                                height: 1.45),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  FlowlyCard(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                    child: Column(
                      children: [
                        _LinkRow(
                          label: 'Syarat Layanan',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const TermsScreen()),
                          ),
                        ),
                        const Divider(height: 1, color: Color(0xFFE6EBF7)),
                        _LinkRow(
                          label: 'Kebijakan Privasi',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const PrivacyScreen()),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      '© ${DateTime.now().year} Flowly. Hak cipta dilindungi.',
                      style: const TextStyle(
                          fontSize: 11.5, color: AppColors.textGrey),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _LinkRow({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700)),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 22, color: AppColors.textGrey),
          ],
        ),
      ),
    );
  }
}