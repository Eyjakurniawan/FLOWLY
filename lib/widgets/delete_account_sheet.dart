import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import 'finance/common.dart';
import 'mascot_view.dart';

/// Pop-up konfirmasi hapus akun. User harus mengetik HAPUS dulu sebelum
/// tombol "Hapus akun saya" aktif.
///
/// Mengembalikan true kalau user menekan "Hapus akun saya", dan false kalau
/// Batal atau sheet ditutup. Sheet ini hanya meminta konfirmasi; penghapusan
/// sebenarnya dikerjakan pemanggil lewat `AuthService.deleteAccount()`.
Future<bool> showDeleteAccountSheet(BuildContext context) async {
  final ok = await showFlowlySheet<bool>(
    context,
    (_) => const _DeleteAccountSheet(),
  );
  return ok == true;
}

class _DeleteAccountSheet extends StatefulWidget {
  const _DeleteAccountSheet();

  @override
  State<_DeleteAccountSheet> createState() => _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends State<_DeleteAccountSheet> {
  static const _keyword = 'HAPUS';
  static const _disabledRed = Color(0xFFE6ADA2);

  final _ctrl = TextEditingController();

  /// Tidak membedakan huruf besar/kecil supaya keyboard HP tidak menyulitkan.
  bool get _valid => _ctrl.text.trim().toUpperCase() == _keyword;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide(color: color, width: 1.5),
      );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Garis tarik di puncak sheet.
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD7DCE8),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Center(
              child: SizedBox(
                width: 120,
                height: 110,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Center(child: MascotView(size: 100)),
                    Positioned(
                      top: 0,
                      right: 14,
                      child: Text('?',
                          style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: AppColors.mascotBlue)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text('Hapus akun?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text(
              'Semua transaksi, dompet, rencana, dan profilmu akan dihapus '
              'permanen dan tidak bisa dikembalikan.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, color: AppColors.textGrey, height: 1.45),
            ),
            const SizedBox(height: 18),
            const Text.rich(
              TextSpan(
                text: 'Ketik ',
                children: [
                  TextSpan(
                      text: _keyword,
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark)),
                  TextSpan(text: ' untuk melanjutkan'),
                ],
              ),
              style: TextStyle(fontSize: 13, color: AppColors.textGrey),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _ctrl,
              onChanged: (_) => setState(() {}),
              textCapitalization: TextCapitalization.characters,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.done,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                hintText: _keyword,
                hintStyle: const TextStyle(
                    color: AppColors.textGrey, fontWeight: FontWeight.w500),
                filled: true,
                fillColor: AppColors.background,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
                border: _border(AppColors.divider),
                enabledBorder: _border(AppColors.divider),
                focusedBorder: _border(AppColors.link),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _valid ? () => Navigator.pop(context, true) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _disabledRed,
                  disabledForegroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22)),
                ),
                child: const Text('Hapus akun saya',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 54,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textDark,
                  side: const BorderSide(color: AppColors.textDark, width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22)),
                ),
                child: const Text('Batal',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}