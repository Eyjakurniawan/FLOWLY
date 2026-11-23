import 'package:flutter/material.dart';

import '../services/connectivity_service.dart';
import '../utils/app_colors.dart';
import 'mascot_view.dart';

/// Dialog konfirmasi hapus dengan maskot. Mengembalikan true kalau user
/// menekan tombol konfirmasi, false kalau Batal.
Future<bool> showDeleteConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Ya, hapus',
}) async {
  // Menghapus data butuh internet.
  if (!ConnectivityService.requireOnline(context)) return false;
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => DeleteConfirmDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
    ),
  );
  return ok == true;
}

class DeleteConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  const DeleteConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Ya, hapus',
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 100,
              height: 96,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Center(child: MascotView(size: 88)),
                  Positioned(
                    top: -2,
                    right: 6,
                    child: Text('?',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.mascotBlue)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(title,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 12.5, color: AppColors.textGrey, height: 1.4),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textDark,
                        side: const BorderSide(
                            color: AppColors.textDark, width: 1.2),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Batal',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(confirmLabel,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}