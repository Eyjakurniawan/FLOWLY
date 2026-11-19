import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';

/// Nav bawah berbentuk pil dengan tombol + oranye di tengah.
/// Indeks tab: 0 Home, 1 Wallet, 2 Reports, 3 Profile.
class FlowlyBottomNav extends StatelessWidget {
  final int current;
  final ValueChanged<int> onTab;
  final VoidCallback onAdd;

  const FlowlyBottomNav({
    super.key,
    required this.current,
    required this.onTab,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 12 + bottom),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
            height: 68,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(34),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x26122B5E),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                _Item(
                  label: 'Beranda',
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  active: current == 0,
                  onTap: () => onTab(0),
                ),
                _Item(
                  label: 'Dompet',
                  icon: Icons.wallet_outlined,
                  activeIcon: Icons.wallet_outlined,
                  active: current == 1,
                  onTap: () => onTab(1),
                ),
                const SizedBox(width: 76), // ruang untuk tombol +
                _Item(
                  label: 'Laporan',
                  icon: Icons.bar_chart_rounded,
                  activeIcon: Icons.bar_chart_rounded,
                  active: current == 2,
                  onTap: () => onTab(2),
                ),
                _Item(
                  label: 'Profil',
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  active: current == 3,
                  onTap: () => onTab(3),
                ),
              ],
            ),
          ),
          Positioned(
            top: -16,
            child: GestureDetector(
              onTap: onAdd,
              child: Container(
                width: 62,
                height: 62,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x66E8472B),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.add_rounded,
                    size: 32, color: AppColors.textDark),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool active;
  final VoidCallback onTap;

  const _Item({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.textDark : AppColors.textGrey;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(active ? activeIcon : icon, size: 23, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: active ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}