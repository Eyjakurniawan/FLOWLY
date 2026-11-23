import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../utils/app_colors.dart';
import '../../utils/formatters.dart';

/// Kode tombol khusus pada keypad.
class PadKey {
  PadKey._();
  static const backspace = 'back';
}

/// Maksimal digit nominal (999 miliar) supaya aman untuk int.
const int kMaxAmountDigits = 12;

/// Teks batas maksimal untuk notifikasi.
const String kMaxAmountText = '999.999.999.999';

/// True kalau [key] ditolak karena nominal sudah mencapai batas maksimal.
bool padKeyExceedsMax(TextEditingController controller, String key) {
  if (key == PadKey.backspace) return false;
  final digits = controller.text.replaceAll('.', '');
  if (digits.isEmpty && key.replaceAll('0', '').isEmpty) return false;
  return digits.length + key.length > kMaxAmountDigits;
}

/// Menerapkan satu tekanan tombol ke [controller] (format titik ribuan).
/// Mengembalikan true kalau teks berubah.
bool applyPadKey(TextEditingController controller, String key) {
  var digits = controller.text.replaceAll('.', '');
  if (key == PadKey.backspace) {
    if (digits.isEmpty) return false;
    digits = digits.substring(0, digits.length - 1);
  } else {
    // Hindari angka nol di depan: "0" / "000" saat kosong diabaikan.
    if (digits.isEmpty && key.replaceAll('0', '').isEmpty) return false;
    if (digits.length + key.length > kMaxAmountDigits) return false;
    digits += key;
  }
  final text = Fmt.groupDigits(digits);
  controller.value = TextEditingValue(
    text: text,
    selection: TextSelection.collapsed(offset: text.length),
  );
  return true;
}

/// Keypad angka: 1-9, 000, 0, hapus, plus tombol "Selesai".
class NumberPad extends StatelessWidget {
  final ValueChanged<String> onKey;
  final VoidCallback onDone;
  final VoidCallback? onClear; // tekan lama pada tombol hapus
  final bool doneEnabled;
  final String doneLabel;

  const NumberPad({
    super.key,
    required this.onKey,
    required this.onDone,
    this.onClear,
    this.doneEnabled = true,
    this.doneLabel = 'Selesai',
  });

  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['000', '0', PadKey.backspace],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in _rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                for (var i = 0; i < row.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(child: _Key(label: row[i], onKey: onKey, onClear: onClear)),
                ],
              ],
            ),
          ),
        const SizedBox(height: 2),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: doneEnabled ? onDone : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textDark,
              disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
              disabledForegroundColor: AppColors.textDark.withValues(alpha: 0.6),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            child: Text(doneLabel),
          ),
        ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  final String label;
  final ValueChanged<String> onKey;
  final VoidCallback? onClear;
  const _Key({required this.label, required this.onKey, this.onClear});

  @override
  Widget build(BuildContext context) {
    final isBack = label == PadKey.backspace;
    return Material(
      color: const Color(0xFFE3EAFB),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          HapticFeedback.selectionClick();
          onKey(label);
        },
        onLongPress: isBack && onClear != null
            ? () {
                HapticFeedback.mediumImpact();
                onClear!();
              }
            : null,
        child: SizedBox(
          height: 50,
          child: Center(
            child: isBack
                ? const Icon(Icons.backspace_outlined,
                    size: 22, color: AppColors.textDark)
                : Text(
                    label,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}