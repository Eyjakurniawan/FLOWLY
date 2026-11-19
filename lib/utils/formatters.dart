import 'package:flutter/services.dart';

class Fmt {
  Fmt._();

  static const _months = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];
  static const _short = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];
  static const _days = [
    'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu',
  ];
  static const _daysShort = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  static String monthName(int month) => _months[month - 1];
  static String monthShort(int month) => _short[month - 1];
  static String dayName(int weekday) => _days[weekday - 1];
  static String dayShort(int weekday) => _daysShort[weekday - 1];

  static String monthYear(DateTime d) => '${_months[d.month - 1]} ${d.year}';
  static String dayMonth(DateTime d) => '${d.day} ${_short[d.month - 1]}';
  static String fullDate(DateTime d) =>
      '${d.day} ${_short[d.month - 1]} ${d.year}';

  static bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// "Hari ini", "Kemarin", atau tanggal.
  static String dayLabel(DateTime d, [DateTime? now]) {
    final n = now ?? DateTime.now();
    if (sameDay(d, n)) return 'Hari ini';
    if (sameDay(d, n.subtract(const Duration(days: 1)))) return 'Kemarin';
    return fullDate(d);
  }

  /// 25/10/2026
  static String slashDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  /// "1250000" -> "1.250.000" (hanya digit yang diterima).
  static String groupDigits(String digits) {
    final b = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) b.write('.');
      b.write(digits[i]);
    }
    return b.toString();
  }

  /// "1.250.000" -> 1250000 (kosong/tidak valid -> 0)
  static int parseAmount(String s) =>
      int.tryParse(s.replaceAll('.', '').trim()) ?? 0;

  /// 483000 -> "Rp483.000", -58000 -> "-Rp58.000"
  static String rupiah(int v) {
    final digits = v.abs().toString();
    final b = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) b.write('.');
      b.write(digits[i]);
    }
    return '${v < 0 ? '-' : ''}Rp$b';
  }

  /// Format bertanda: 250000 -> "+Rp250.000", -58000 -> "-Rp58.000", 0 -> "Rp0"
  static String signedRupiah(int v) {
    if (v == 0) return 'Rp0';
    final prefix = v > 0 ? '+' : '-';
    final digits = v.abs().toString();
    final b = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) b.write('.');
      b.write(digits[i]);
    }
    return '${prefix}Rp$b';
  }

  /// Ringkas: 250000 -> "Rp0,3jt", 25000 -> "Rp25rb", 0 -> "Rp0"
  static String compact(int v) {
    if (v <= 0) return 'Rp0';
    if (v >= 1000000000) return 'Rp${_dec(v / 1e9)}M';
    if (v >= 100000) return 'Rp${_dec(v / 1e6)}jt';
    if (v >= 1000) return 'Rp${(v / 1000).round()}rb';
    return 'Rp$v';
  }

  static String _dec(double x) {
    var s = x.toStringAsFixed(1);
    if (s.endsWith('.0')) s = s.substring(0, s.length - 2);
    return s.replaceAll('.', ',');
  }
}

/// Isian angka dengan titik ribuan: 1250000 -> "1.250.000".
class ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue();
    digits = digits.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    final b = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) b.write('.');
      b.write(digits[i]);
    }
    final text = b.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}