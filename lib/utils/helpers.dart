import 'package:flutter/material.dart';

import 'app_colors.dart';

class Helpers {
  Helpers._();

  /// Tinggi area sistem di bawah layar (tombol back/home/recent atau garis
  /// gesture). 0 kalau HP tidak punya bar sistem.
  static double systemBottom(BuildContext context) {
    final mq = MediaQuery.of(context);
    return mq.padding.bottom > mq.viewPadding.bottom
        ? mq.padding.bottom
        : mq.viewPadding.bottom;
  }

  /// Jarak kosong di bawah isi halaman yang bisa digulir supaya kartu
  /// terakhir tidak tertutup navbar tab (68 + 12 + area sistem) dan masih
  /// ada jarak lega di atasnya.
  static double navClearance(BuildContext context) =>
      140 + systemBottom(context);

  static void showSnack(BuildContext context, String message,
      {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError ? AppColors.primary : AppColors.textDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
  }

  static OverlayEntry? _topAlert;

  /// Alert kecil berbentuk pil (ikon tetes air + teks tebal) di tengah atas
  /// layar. Dipakai untuk konfirmasi singkat, mis. "Ukuran huruf: 105%".
  static void showPillAlert(
    BuildContext context,
    String message, {
    IconData icon = Icons.water_drop_rounded,
    Duration duration = const Duration(milliseconds: 1800),
  }) {
    _show(context, message, duration, pillIcon: icon);
  }

  /// Alert navy yang turun dari bagian atas layar (teks putih, rata tengah),
  /// hilang sendiri setelah [duration]. Dipakai untuk info singkat seperti
  /// "Tautan reset dikirim ke ...". Pakai \n untuk pindah baris.
  static void showTopAlert(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(context, message, duration);
  }

  static void _show(
    BuildContext context,
    String message,
    Duration duration, {
    IconData? pillIcon,
  }) {
    _topAlert?.remove();
    _topAlert = null;

    final overlay = Overlay.of(context, rootOverlay: true);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _TopAlert(
        message: message,
        duration: duration,
        pillIcon: pillIcon,
        onDone: () {
          if (entry.mounted) entry.remove();
          if (_topAlert == entry) _topAlert = null;
        },
      ),
    );
    _topAlert = entry;
    overlay.insert(entry);
  }
}

class _TopAlert extends StatefulWidget {
  final String message;
  final Duration duration;
  final VoidCallback onDone;

  /// Tidak null = tampil sebagai pil kecil dengan ikon ini.
  final IconData? pillIcon;

  const _TopAlert({
    required this.message,
    required this.duration,
    required this.onDone,
    this.pillIcon,
  });

  @override
  State<_TopAlert> createState() => _TopAlertState();
}

class _TopAlertState extends State<_TopAlert>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  );

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    await _c.forward();
    await Future.delayed(widget.duration);
    if (!mounted) return;
    await _c.reverse();
    widget.onDone();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top + 12;
    final pill = widget.pillIcon;
    return Positioned(
      top: top,
      left: 20,
      right: 20,
      child: IgnorePointer(
        child: FadeTransition(
          opacity: _c,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.6),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut)),
            child: Material(
              color: Colors.transparent,
              child: pill != null
                  ? Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 11),
                        decoration: BoxDecoration(
                          color: AppColors.navyBottom,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(pill, size: 20, color: AppColors.mascotBlue),
                            const SizedBox(width: 8),
                            Text(
                              widget.message,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.navyBottom,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  widget.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}