import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';

import '../utils/constants.dart';
import '../utils/helpers.dart';

/// Memantau apakah HP bisa menjangkau server (tanpa paket tambahan):
/// mencoba mencari alamat server tiap beberapa detik dan saat aplikasi
/// dibuka lagi dari latar belakang.
///
/// Dipakai untuk:
/// - menampilkan label "Offline" dan memblokir input saat tidak ada internet,
/// - memuat ulang data dari server begitu internet kembali ([onBackOnline]).
class ConnectivityService extends ChangeNotifier
    with WidgetsBindingObserver {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  static const offlineMessage =
      'Kamu sedang offline.\nHubungkan internet untuk menambah atau mengubah data.';

  bool _online = true;
  bool _checking = false;
  Timer? _timer;

  /// Dipanggil sekali setiap kali status berubah dari offline ke online.
  Future<void> Function()? onBackOnline;

  bool get isOnline => _online;

  void start() {
    if (_timer != null) return;
    WidgetsBinding.instance.addObserver(this);
    check();
    _timer = Timer.periodic(const Duration(seconds: 6), (_) => check());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) check();
  }

  Future<void> check() async {
    if (_checking) return;
    _checking = true;
    var ok = false;
    try {
      final host = Uri.parse(AppConstants.supabaseUrl).host;
      final r = await InternetAddress.lookup(host)
          .timeout(const Duration(seconds: 4));
      ok = r.isNotEmpty && r.first.rawAddress.isNotEmpty;
    } catch (_) {
      ok = false;
    }
    _checking = false;
    setOnline(ok);
  }

  /// Dipanggil juga oleh lapisan data saat sebuah permintaan jaringan gagal.
  void setOnline(bool value) {
    if (_online == value) return;
    _online = value;
    notifyListeners();
    if (value) onBackOnline?.call();
  }

  /// true kalau boleh lanjut. Kalau offline, tampilkan pesan dan kembalikan false.
  static bool requireOnline(BuildContext context) {
    if (instance.isOnline) return true;
    Helpers.showTopAlert(context, offlineMessage);
    return false;
  }
}