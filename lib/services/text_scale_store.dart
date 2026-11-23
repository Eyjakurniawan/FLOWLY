import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../utils/constants.dart';
import 'notification_store.dart';

/// Ukuran huruf aplikasi (Pengaturan -> Ukuran huruf).
///
/// Nilainya pengali ukuran teks: 0.85 (85%) sampai 1.05 (105%), bawaan 1.0.
/// Disimpan di HP (satu file untuk semua akun) dan dipasang ke seluruh
/// aplikasi lewat `MaterialApp.builder` di main.dart.
class TextScaleStore extends ChangeNotifier {
  TextScaleStore._();
  static final TextScaleStore instance = TextScaleStore._();

  static const double min = 0.85;
  static const double max = 1.05;
  static const double normal = 1.0;

  double _scale = normal;

  /// Nilai sebelum rangkaian perubahan terakhir (untuk notifikasi).
  double? _baseline;
  Timer? _noticeTimer;

  double get scale => _scale;
  int get percent => (_scale * 100).round();
  bool get isNormal => percent == 100;

  /// Bulatkan ke kelipatan 1% dan batasi ke rentang yang diizinkan.
  static double snap(double v) {
    final c = v < min ? min : (v > max ? max : v);
    return (c * 100).round() / 100;
  }

  static Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/text_scale.json');
  }

  /// Dipanggil sekali di main() sebelum runApp.
  Future<void> load() async {
    try {
      final f = await _file();
      if (!await f.exists()) return;
      final raw = jsonDecode(await f.readAsString());
      final v = raw is Map ? raw['scale'] : null;
      if (v is num) _scale = snap(v.toDouble());
    } catch (e) {
      debugPrint('Gagal membaca ukuran huruf: $e');
    }
  }

  Future<void> _save() async {
    try {
      final f = await _file();
      await f.writeAsString(jsonEncode({'scale': _scale}));
    } catch (e) {
      debugPrint('Gagal menyimpan ukuran huruf: $e');
    }
  }

  /// Pasang ukuran baru ke seluruh aplikasi. true kalau nilainya berubah.
  bool set(double v) {
    final next = snap(v);
    if (next == _scale) return false;
    _baseline ??= _scale;
    _scale = next;
    notifyListeners();
    _save();
    _scheduleNotice();
    return true;
  }

  void reset() => set(normal);

  /// Notifikasi di daftar Notifikasi dikirim setelah pengguna berhenti
  /// menggeser sebentar, supaya satu kali atur tidak jadi banyak notifikasi.
  void _scheduleNotice() {
    _noticeTimer?.cancel();
    _noticeTimer = Timer(const Duration(seconds: 2), _announce);
  }

  void _announce() {
    final before = _baseline;
    _baseline = null;
    // Kembali ke nilai awal sebelum timer habis: tidak ada yang berubah.
    if (before == null || before == _scale) return;

    final reset = isNormal;
    NotificationStore.instance.push(
      title: reset ? 'Ukuran huruf dikembalikan' : 'Ukuran huruf diubah',
      body: reset
          ? 'Ukuran huruf kembali ke 100%.'
          : 'Ukuran huruf sekarang $percent%. Bisa diatur lagi kapan saja di Pengaturan.',
      action: NotificationAction.openSettings,
      mood: MascotExpression.happy,
    );
  }
}