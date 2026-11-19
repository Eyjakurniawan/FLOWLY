import 'package:flutter/material.dart';

import '../../screens/notification_screen.dart';
import '../../services/finance_store.dart';
import '../../services/notification_store.dart';
import '../../utils/app_colors.dart';
import '../../utils/formatters.dart';
import '../flowly_logo.dart';

/// Baris atas: logo, pilih bulan, sembunyikan saldo, notifikasi.
class HomeHeader extends StatelessWidget {
  final bool showLogoIcon;

  /// false = ikon lonceng tidak membuka apa-apa
  /// (dipakai di halaman Notifikasi sendiri).
  final bool bellEnabled;

  const HomeHeader({
    super.key,
    this.showLogoIcon = false,
    this.bellEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final store = FinanceStore.instance;
    final notifs = NotificationStore.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([store, notifs]),
      builder: (context, _) {
        return Row(
          children: [
            if (showLogoIcon) ...[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.navyTop,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.water_drop_rounded,
                    size: 18, color: Colors.white),
              ),
              const SizedBox(width: 8),
            ],
            const FlowlyLogo(size: 24),
            // Sisa ruang dipakai pil bulan; kalau layar sempit, teksnya
            // mengecil otomatis (tidak lagi "RIGHT OVERFLOWED").
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                // Statis: bulan berjalan, tidak bisa diketuk/diubah.
                child: Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      Fmt.monthYear(store.month),
                      maxLines: 1,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            _RoundIcon(
              icon: store.hideAmounts
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              onTap: store.toggleHide,
            ),
            const SizedBox(width: 10),
            _RoundIcon(
              icon: Icons.notifications_none_rounded,
              dot: notifs.hasUnread,
              onTap: () {
                if (!bellEnabled) return;
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const NotificationScreen()),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _RoundIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool dot;
  const _RoundIcon({required this.icon, required this.onTap, this.dot = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, size: 21),
            if (dot)
              Positioned(
                top: 9,
                right: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}