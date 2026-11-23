import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/profile_photo_service.dart';
import '../services/text_scale_store.dart';
import '../utils/app_colors.dart';
import '../utils/helpers.dart';
import '../widgets/delete_account_sheet.dart';
import '../widgets/finance/common.dart';
import '../widgets/finance/home_header.dart';
import 'category_wallet_screen.dart';
import 'splash_screen.dart';

/// Halaman Pengaturan (dibuka dari menu Profile).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _divider = Divider(height: 1, color: Color(0xFFE6EBF7));
  static const _danger = Color(0xFFC0392B);

  /// Alur hapus akun: sheet konfirmasi (ketik HAPUS) -> hapus di server ->
  /// bersihkan sesi dan foto lokal -> kembali ke layar awal.
  Future<void> _deleteAccount(BuildContext context) async {
    final confirmed = await showDeleteAccountSheet(context);
    if (!confirmed || !context.mounted) return;

    final navigator = Navigator.of(context, rootNavigator: true);
    final messenger = ScaffoldMessenger.of(context);

    // Loading yang tidak bisa ditutup selama proses berjalan.
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      ),
    );

    final result = await AuthService.instance.deleteAccount();
    if (result.success) {
      // Foto profil disimpan lokal per akun, jadi hapus sebelum sesi ditutup.
      try {
        await ProfilePhotoService.instance.remove();
      } catch (_) {}
      try {
        await AuthService.instance.signOut();
      } catch (_) {}
    }

    navigator.pop(); // tutup loading

    if (result.success) {
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SplashScreen()),
        (_) => false,
      );
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Akunmu sudah dihapus.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.textDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else if (context.mounted) {
      Helpers.showSnack(
        context,
        result.message ?? 'Gagal menghapus akun. Coba lagi.',
        isError: true,
      );
    }
  }

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
                padding: EdgeInsets.fromLTRB(16, 10, 16, Helpers.navClearance(context)),
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
                          subtitle: 'Tambah, ubah nama dan warna, atau hapus',
                          trailing: const Icon(Icons.chevron_right_rounded,
                              size: 22, color: AppColors.textGrey),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const CategoryWalletScreen()),
                          ),
                        ),
                        _divider,
                        _SettingRow(
                          title: 'Mode gelap',
                          subtitle: 'Ganti tampilan terang atau gelap',
                          trailing: Switch(
                            value: false,
                            onChanged: (_) => Helpers.showSnack(
                                context, 'Mode gelap segera hadir.'),
                            activeThumbColor: AppColors.link,
                            inactiveTrackColor: const Color(0xFFD7E0F5),
                            inactiveThumbColor: Colors.white,
                          ),
                        ),
                        _divider,
                        const _FontSizeSection(),
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
                  const SizedBox(height: 14),
                  FlowlyCard(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Data dan akun',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        _SettingRow(
                          title: 'Hapus akun',
                          titleColor: _danger,
                          subtitle: 'Hapus akunmu dan semua datanya secara permanen',
                          trailing: const Icon(Icons.chevron_right_rounded,
                              size: 22, color: AppColors.textGrey),
                          onTap: () => _deleteAccount(context),
                        ),
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
  final Color? titleColor;
  const _SettingRow({
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
    this.titleColor,
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
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: titleColor)),
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

/// Pengaturan "Ukuran huruf": geser untuk memilih 85%-105%. Contoh tampilan
/// berubah saat digeser; ukuran baru dipasang ke seluruh aplikasi begitu
/// jari dilepas.
class _FontSizeSection extends StatefulWidget {
  const _FontSizeSection();

  @override
  State<_FontSizeSection> createState() => _FontSizeSectionState();
}

class _FontSizeSectionState extends State<_FontSizeSection> {
  static const _thumbRadius = 11.0;
  static const _chipWidth = 54.0;

  double _value = TextScaleStore.instance.scale;

  int get _percent => (_value * 100).round();

  void _commit(double v) {
    final store = TextScaleStore.instance;
    if (store.set(v)) {
      Helpers.showPillAlert(context, 'Ukuran huruf: ${store.percent}%');
    }
  }

  void _reset() {
    setState(() => _value = TextScaleStore.normal);
    _commit(TextScaleStore.normal);
  }

  Widget _slider() {
    const min = TextScaleStore.min;
    const max = TextScaleStore.max;
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final frac = (_value - min) / (max - min);
        final x = _thumbRadius + frac * (w - 2 * _thumbRadius);
        final chipLeft =
            (x - _chipWidth / 2).clamp(0.0, w - _chipWidth).toDouble();

        return SizedBox(
          height: 64,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: chipLeft,
                top: 0,
                child: Container(
                  width: _chipWidth,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.navyBottom,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Text('$_percent%',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 28,
                height: 36,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 6,
                    activeTrackColor: AppColors.link,
                    inactiveTrackColor: const Color(0xFFD7E0F5),
                    thumbColor: AppColors.navyBottom,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: _thumbRadius,
                      elevation: 0,
                      pressedElevation: 0,
                    ),
                    overlayShape: SliderComponentShape.noOverlay,
                    tickMarkShape: SliderTickMarkShape.noTickMark,
                  ),
                  child: Slider(
                    value: _value,
                    min: min,
                    max: max,
                    divisions: 20, // kelipatan 1%
                    onChanged: (v) => setState(() => _value = v),
                    onChangeEnd: _commit,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Contoh teks dengan ukuran yang sedang dipilih (belum dipasang).
  Widget _preview(BuildContext context) {
    final mq = MediaQuery.of(context);
    // Ukuran teks bawaan HP saja, tanpa ukuran huruf yang sudah terpasang.
    final device = mq.textScaler.scale(14) / 14 / TextScaleStore.instance.scale;
    return MediaQuery(
      data: mq.copyWith(textScaler: TextScaler.linear(device * _value)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFE3EAFB),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Contoh tampilan',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            SizedBox(height: 2),
            Text('Makan siang • Tunai • Rp45.000',
                style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canReset = _percent != 100;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ukuran huruf',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          const Text('Pilih ukuran teks yang nyaman dibaca',
              style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 9),
                child: Text('A',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 8),
              Expanded(child: _slider()),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(bottom: 5),
                child: Text('A',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('$_percent%',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textGrey)),
              const Spacer(),
              GestureDetector(
                onTap: canReset ? _reset : null,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    'Atur ulang',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: canReset ? AppColors.link : AppColors.textGrey,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _preview(context),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}