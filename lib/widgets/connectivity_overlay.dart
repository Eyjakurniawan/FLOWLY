import 'dart:async';

import 'package:flutter/material.dart';

import '../services/connectivity_service.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';

/// Lapisan status koneksi di atas layar (tidak menggeser isi halaman):
/// - banner "Kamu sedang offline ..." tetap ada selama HP offline,
/// - pill "Kamu sedang offline" dan "Kembali online" hanya muncul
///   sebentar lalu hilang sendiri.
///
/// Cara pakai: bungkus isi HomeScreen, mis.
///   ConnectivityOverlay(child: Stack(...))
class ConnectivityOverlay extends StatefulWidget {
  final Widget child;

  /// Berapa lama pill "Kamu sedang offline" tampil.
  final Duration offlineDuration;

  /// Berapa lama pill "Kembali online" tampil.
  final Duration onlineDuration;

  const ConnectivityOverlay({
    super.key,
    required this.child,
    this.offlineDuration = const Duration(seconds: 3),
    this.onlineDuration = const Duration(seconds: 3),
  });

  @override
  State<ConnectivityOverlay> createState() => _ConnectivityOverlayState();
}

enum _Pill { hidden, offline, backOnline }

class _ConnectivityOverlayState extends State<ConnectivityOverlay> {
  /// Tinggi ruang pill; banner diletakkan tepat di bawahnya supaya posisinya
  /// tidak bergeser saat pill muncul atau hilang.
  static const _pillSlot = 40.0;

  final _service = ConnectivityService.instance;

  late bool _wasOnline = _service.isOnline;

  /// Banner penjelasan: tampil selama offline.
  late bool _offline = !_service.isOnline;

  /// Pill: tampil sebentar lalu hilang.
  late _Pill _pill = _service.isOnline ? _Pill.hidden : _Pill.offline;

  // Isi pill terakhir yang ditampilkan, supaya saat animasi keluar
  // teksnya tidak berubah mendadak.
  late _Pill _shown = _pill == _Pill.hidden ? _Pill.offline : _pill;
  Timer? _pillTimer;

  @override
  void initState() {
    super.initState();
    // Buka aplikasi dalam keadaan offline: pill juga hilang sendiri.
    if (_pill != _Pill.hidden) {
      _pillTimer = Timer(widget.offlineDuration, () => _setPill(_Pill.hidden));
    }
    _service.addListener(_onChanged);
  }

  @override
  void dispose() {
    _service.removeListener(_onChanged);
    _pillTimer?.cancel();
    super.dispose();
  }

  void _onChanged() {
    final online = _service.isOnline;
    if (online == _wasOnline) return;
    _wasOnline = online;

    if (!mounted) return;
    setState(() => _offline = !online);
    _flashPill(
      online ? _Pill.backOnline : _Pill.offline,
      online ? widget.onlineDuration : widget.offlineDuration,
    );
  }

  void _flashPill(_Pill p, Duration duration) {
    _pillTimer?.cancel();
    _setPill(p);
    _pillTimer = Timer(duration, () => _setPill(_Pill.hidden));
  }

  void _setPill(_Pill p) {
    if (!mounted) return;
    setState(() {
      _pill = p;
      if (p != _Pill.hidden) _shown = p;
    });
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final pillVisible = _pill != _Pill.hidden;

    return Stack(
      children: [
        widget.child,
        // Banner: tetap ada selama offline.
        Positioned(
          top: top + 8 + _pillSlot + 6,
          left: 0,
          right: 0,
          child: IgnorePointer(
            ignoring: !_offline,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              offset: _offline ? Offset.zero : const Offset(0, -0.6),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                opacity: _offline ? 1 : 0,
                child: const _OfflineBanner(),
              ),
            ),
          ),
        ),
        // Pill: muncul sebentar lalu hilang.
        Positioned(
          top: top + 8,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              offset: pillVisible ? Offset.zero : const Offset(0, -0.6),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                opacity: pillVisible ? 1 : 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _StatusPill(
                      text: _shown == _Pill.offline
                          ? 'Kamu sedang offline'
                          : 'Kembali online',
                      expression: _shown == _Pill.offline
                          ? MascotExpression.normal
                          : MascotExpression.happy,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Pill gelap berisi maskot kecil + teks.
class _StatusPill extends StatelessWidget {
  final String text;
  final MascotExpression expression;

  const _StatusPill({required this.text, required this.expression});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 18, 8),
      decoration: BoxDecoration(
        color: AppColors.navyBottom,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            expression.path,
            width: 24,
            height: 24,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.water_drop_rounded,
              size: 22,
              color: AppColors.mascotBlue,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Banner lebar penuh di bawah ruang pill, tampil selama offline.
class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      color: AppColors.navyBottom,
      child: const Text(
        'Kamu sedang offline. Kamu hanya bisa melihat tampilan terakhir, '
        'perubahan belum bisa disimpan.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: 11.5,
          height: 1.35,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}