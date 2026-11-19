import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../utils/helpers.dart';
import '../widgets/finance/common.dart';
import '../widgets/finance/home_header.dart';
import 'category_wallet_screen.dart';

/// Halaman Pengaturan (dibuka dari menu Profile).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _divider = Divider(height: 1, color: Color(0xFFE6EBF7));

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
                      const Text('Pengaturan',
                          style: TextStyle(
                              fontSize: 28, fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  FlowlyCard(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                    child: Column(
                      children: [
                        _SettingRow(
                          title: 'Kelola kategori dan dompet',
                          subtitle: 'Tambah, ubah nama, atau hapus',
                          trailing: const Icon(Icons.chevron_right_rounded,
                              size: 22, color: AppColors.textGrey),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const CategoryWalletScreen()),
                          ),
                        ),
                        _SettingRow(
                          title: 'Mode gelap',
                          subtitle: 'Ganti tampilan terang atau gelap',
                          trailing: Switch(
                            value: false,
                            onChanged: (_) => Helpers.showSnack(
                                context, 'Mode gelap segera hadir.'),
                            activeColor: AppColors.link,
                            inactiveTrackColor: const Color(0xFFD7E0F5),
                            inactiveThumbColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const FlowlyCard(
                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                    child: Column(
                      children: [
                        _ValueRow(label: 'Bahasa', value: 'Indonesia'),
                        _divider,
                        _ValueRow(label: 'Mata uang', value: 'Rupiah (IDR)'),
                      ],
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

class _SettingRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;
  const _SettingRow({
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textGrey)),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _ValueRow extends StatelessWidget {
  final String label;
  final String value;
  const _ValueRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          ),
          Text(value,
              style: const TextStyle(fontSize: 12.5, color: AppColors.textGrey)),
        ],
      ),
    );
  }
}