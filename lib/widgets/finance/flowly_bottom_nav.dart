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
    // Tinggi area sistem di bawah (tombol back/home/recent atau garis gesture).
    // Dipakai max(padding, viewPadding) supaya tetap terbaca di semua HP,
    // dan 0 kalau HP tidak punya bar sistem.
    final mq = MediaQuery.of(context);
    final bottom =
        mq.padding.bottom > mq.viewPadding.bottom
            ? mq.padding.bottom
            : mq.viewPadding.bottom;
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
                  iconBuilder: (color) => _WalletIcon(color: color),
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

  /// Ikon gambar sendiri (menggantikan [icon]/[activeIcon] kalau diisi).
  final Widget Function(Color color)? iconBuilder;

  const _Item({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.active,
    required this.onTap,
    this.iconBuilder,
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
            if (iconBuilder != null)
              SizedBox(
                width: 23,
                height: 23,
                child: Center(child: iconBuilder!(color)),
              )
            else
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

/// Ikon Dompet: kartu bergaris dengan strip di atas dan tab kecil di kanan.
class _WalletIcon extends StatelessWidget {
  final Color color;
  const _WalletIcon({required this.color});

  @override
  Widget build(BuildContext context) {
    const w = 23.0;
    return SizedBox(
      width: w,
      height: w * _WalletIconPainter.h / _WalletIconPainter.w,
      child: CustomPaint(painter: _WalletIconPainter(color)),
    );
  }
}

class _WalletIconPainter extends CustomPainter {
  // Ukuran acuan gambar (satuan bebas), lalu diskalakan ke ukuran widget.
  static const double w = 460;
  static const double h = 370;
  static const double _stroke = 45;

  final Color color;
  const _WalletIconPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / w, size.height / h);
    const half = _stroke / 2;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..isAntiAlias = true;

    // Badan kartu.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(half, half, w - _stroke, h - _stroke),
        const Radius.circular(67.5),
      ),
      paint,
    );
    // Strip di atas.
    canvas.drawLine(
        const Offset(half, 117.5), const Offset(w - half, 117.5), paint);
    // Tab kecil di kanan.
    paint.strokeCap = StrokeCap.round;
    canvas.drawLine(
        const Offset(317.5, 232.5), const Offset(367.5, 232.5), paint);
  }

  @override
  bool shouldRepaint(covariant _WalletIconPainter old) => old.color != color;
}