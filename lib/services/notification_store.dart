import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/constants.dart';
import 'connectivity_service.dart';
import 'supabase_service.dart';

/// Aksi yang dijalankan saat sebuah notifikasi diketuk.
enum NotificationAction {
  none,
  addTransaction, // buka form catat transaksi (sama seperti tombol +)
  dailyReminderSetting, // scroll ke pengaturan "Pengingat catat harian"
  openWallets, // tab Dompet
  openWallet, // detail satu dompet (refName = nama dompet)
  openTransactions, // halaman riwayat transaksi
  openCategories, // Pengaturan -> Kelola kategori dan dompet
  openPlanning, // halaman Rencana
  openProfile, // tab Profil
  openBudget, // halaman Anggaran
  openSettings, // halaman Pengaturan
}

class AppNotification {
  final int id;
  final String title;
  final String body;
  final DateTime time;
  final bool read;
  final NotificationAction action;

  /// Data tambahan untuk [action] (mis. nama dompet yang dibuka).
  final String? refName;

  /// Ekspresi maskot Floy yang tampil di samping notifikasi.
  final MascotExpression mood;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    this.read = false,
    this.action = NotificationAction.none,
    this.refName,
    this.mood = MascotExpression.normal,
  });

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        title: title,
        body: body,
        time: time,
        read: read ?? this.read,
        action: action,
        refName: refName,
        mood: mood,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'time': time.toIso8601String(),
        'read': read,
        'action': action.name,
        'refName': refName,
        'mood': mood.name,
      };

  static AppNotification? fromJson(dynamic j) {
    if (j is! Map) return null;
    final id = j['id'];
    final time = DateTime.tryParse('${j['time']}');
    if (id is! int || time == null) return null;
    return AppNotification(
      id: id,
      title: '${j['title'] ?? ''}',
      body: '${j['body'] ?? ''}',
      time: time,
      read: j['read'] == true,
      action: NotificationAction.values.firstWhere(
        (a) => a.name == j['action'],
        orElse: () => NotificationAction.none,
      ),
      refName: j['refName'] as String?,
      mood: MascotExpression.values.firstWhere(
        (m) => m.name == j['mood'],
        orElse: () => MascotExpression.normal,
      ),
    );
  }
}

/// Daftar notifikasi + pengaturan pengingat.
///
/// Dua jenis data, dua tempat simpan:
/// - **Daftar notifikasi**: hanya di HP (satu file JSON per akun di folder
///   dokumen aplikasi). Isinya dibuat aplikasi sendiri dan bisa dibuat
///   ulang, jadi tidak perlu ke server.
/// - **Pengaturan pengingat** (jam + 3 toggle): disimpan di user metadata
///   Supabase supaya ikut ke HP baru, dengan salinan di HP. Perubahan
///   langsung tersimpan di HP (jalan tanpa internet), lalu dikirim ke
///   Supabase; kalau sedang offline, dikirim otomatis begitu internet
///   kembali ([syncSettings]).
///
/// Alur: [loadFor] dipanggil AppData saat Beranda dibuka. [reset] hanya
/// mengosongkan memori (logout); file akun tetap ada.
class NotificationStore extends ChangeNotifier {
  NotificationStore._();
  static final NotificationStore instance = NotificationStore._();

  static const _maxItems = 50;

  final List<AppNotification> _items = [];
  int _nextId = 1;

  /// Akun yang datanya sedang dimuat. null = belum ada akun (tidak menyimpan).
  String? _uid;

  bool _dailyOn = true;
  int _hour = 20;
  int _minute = 0;
  bool _planningOn = true;
  bool _weeklyOn = false;

  /// true = ada perubahan pengaturan yang belum terkirim ke Supabase.
  bool _dirty = false;
  int _version = 0; // naik tiap pengaturan berubah (deteksi ubah saat kirim)
  bool _syncing = false;

  // ---------------------------------------------------------------- daftar

  List<AppNotification> get items => List.unmodifiable(_items);
  bool get isEmpty => _items.isEmpty;
  bool get hasUnread => _items.any((n) => !n.read);

  void markRead(int id) {
    final i = _items.indexWhere((n) => n.id == id);
    if (i < 0 || _items[i].read) return;
    _items[i] = _items[i].copyWith(read: true);
    notifyListeners();
    _persist();
  }

  void markAllRead() {
    if (!hasUnread) return;
    for (var i = 0; i < _items.length; i++) {
      _items[i] = _items[i].copyWith(read: true);
    }
    notifyListeners();
    _persist();
  }

  void remove(int id) {
    _items.removeWhere((n) => n.id == id);
    notifyListeners();
    _persist();
  }

  void clear() {
    if (_items.isEmpty) return;
    _items.clear();
    notifyListeners();
    _persist();
  }

  /// Tambah notifikasi baru di paling atas (maksimal 50 disimpan).
  /// Titik masuk tunggal untuk semua kejadian (dompet, transaksi, dst.).
  void push({
    required String title,
    required String body,
    NotificationAction action = NotificationAction.none,
    String? refName,
    MascotExpression mood = MascotExpression.normal,
  }) {
    _items.insert(
      0,
      AppNotification(
        id: _nextId++,
        title: title,
        body: body,
        time: DateTime.now(),
        action: action,
        refName: refName,
        mood: mood,
      ),
    );
    if (_items.length > _maxItems) _items.removeRange(_maxItems, _items.length);
    notifyListeners();
    _persist();
  }

  // ------------------------------------------------------------ pengaturan

  bool get dailyOn => _dailyOn;
  bool get planningOn => _planningOn;
  bool get weeklyOn => _weeklyOn;
  int get hour => _hour;
  int get minute => _minute;

  /// "20.00"
  String get timeLabel =>
      '${_hour.toString().padLeft(2, '0')}.${_minute.toString().padLeft(2, '0')}';

  void setDailyOn(bool v) {
    _dailyOn = v;
    _settingsChanged();
  }

  void setReminderTime(int hour, int minute) {
    _hour = hour;
    _minute = minute;
    _dailyOn = true; // memilih jam berarti pengingat dinyalakan
    _version++;
    _dirty = true;
    push(
      title: 'Jam pengingat diatur',
      body: 'Kami akan mengingatkan kamu setiap hari pukul $timeLabel.',
      action: NotificationAction.dailyReminderSetting,
      mood: MascotExpression.wink,
    ); // push() sudah menyimpan ke file
    unawaited(syncSettings());
  }

  void setPlanningOn(bool v) {
    _planningOn = v;
    _settingsChanged();
  }

  void setWeeklyOn(bool v) {
    _weeklyOn = v;
    _settingsChanged();
  }

  /// Simpan ke HP dulu (selalu berhasil), lalu coba kirim ke Supabase.
  void _settingsChanged() {
    _version++;
    _dirty = true;
    notifyListeners();
    _persist();
    unawaited(syncSettings());
  }

  /// Sinkronkan pengaturan dengan Supabase (kalau online):
  /// - ada perubahan yang belum terkirim -> kirim (HP yang menang),
  /// - tidak ada -> ambil nilai terbaru dari server (mis. diubah di HP lain).
  /// Dipanggil setelah perubahan, saat Beranda dibuka, dan saat internet kembali.
  Future<void> syncSettings() async {
    if (_uid == null || !ConnectivityService.instance.isOnline) return;
    if (_dirty) {
      await _pushSettings();
    } else {
      await _pullSettings();
    }
  }

  // ------------------------------------------------------ siklus akun/file

  /// Muat notifikasi + pengaturan milik [uid] dari penyimpanan HP.
  /// Kalau akun ini belum punya file di HP ini (pertama kali), pengaturan
  /// dari Supabase dipakai sebagai nilai awal. Setelah itu pengaturan
  /// disinkronkan di latar belakang lewat [syncSettings].
  Future<void> loadFor(String uid) async {
    _resetMemory();
    var found = false;
    try {
      final f = await _file(uid);
      if (await f.exists()) {
        found = _decode(jsonDecode(await f.readAsString()));
      }
    } catch (e) {
      debugPrint('Gagal membaca notifikasi lokal: $e');
    }
    _uid = uid;
    if (!found) {
      _resetMemory();
      _uid = uid;
      _applyMeta(SupabaseService.client.auth.currentUser?.userMetadata);
      _seed();
      _persist();
    }
    notifyListeners();
    unawaited(syncSettings());
  }

  /// Kosongkan memori (dipanggil saat logout / ganti akun). File di HP
  /// TIDAK dihapus, supaya akun yang sama melihat notifikasinya lagi.
  void reset() {
    _resetMemory();
    notifyListeners();
  }

  /// Hapus file notifikasi akun ini dari HP (dipanggil saat akun dihapus).
  Future<void> deleteLocal() async {
    final id = _uid;
    _uid = null; // cegah penulisan ulang
    _resetMemory();
    if (id == null) return;
    try {
      final f = await _file(id);
      if (await f.exists()) await f.delete();
    } catch (_) {}
    notifyListeners();
  }

  // ---------------------------------------------------------------- intern

  void _resetMemory() {
    _items.clear();
    _nextId = 1;
    _uid = null;
    _dailyOn = true;
    _hour = 20;
    _minute = 0;
    _planningOn = true;
    _weeklyOn = false;
    _dirty = false;
    _version = 0;
  }

  Future<File> _file(String uid) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/flowly_notif_$uid.json');
  }

  Map<String, dynamic> _encode() => {
        'v': 1,
        'nextId': _nextId,
        'settings': {
          'dailyOn': _dailyOn,
          'hour': _hour,
          'minute': _minute,
          'planningOn': _planningOn,
          'weeklyOn': _weeklyOn,
          'pending': _dirty,
        },
        'items': [for (final n in _items) n.toJson()],
      };

  bool _decode(dynamic data) {
    if (data is! Map) return false;
    final s = data['settings'];
    if (s is Map) {
      _dailyOn = s['dailyOn'] != false;
      final h = s['hour'];
      final m = s['minute'];
      if (h is int && m is int && h >= 0 && h < 24 && m >= 0 && m < 60) {
        _hour = h;
        _minute = m;
      }
      _planningOn = s['planningOn'] != false;
      _weeklyOn = s['weeklyOn'] == true;
      _dirty = s['pending'] == true;
    }
    final list = data['items'];
    if (list is List) {
      for (final j in list) {
        final n = AppNotification.fromJson(j);
        if (n != null) _items.add(n);
      }
    }
    var next = data['nextId'] is int ? data['nextId'] as int : 1;
    for (final n in _items) {
      if (n.id >= next) next = n.id + 1;
    }
    _nextId = next;
    return true;
  }

  // Penulisan diantre supaya beberapa perubahan beruntun tidak saling timpa.
  Future<void> _writing = Future.value();

  void _persist() {
    final id = _uid;
    if (id == null) return;
    final json = jsonEncode(_encode()); // salin kondisi saat ini
    _writing = _writing.then((_) async {
      try {
        final f = await _file(id);
        await f.writeAsString(json, flush: true);
      } catch (e) {
        debugPrint('Gagal menyimpan notifikasi lokal: $e');
      }
    });
  }

  String get _signature => '$_dailyOn|$_hour|$_minute|$_planningOn|$_weeklyOn';

  /// Terapkan pengaturan dari user metadata Supabase. false kalau metadata
  /// belum memuat pengaturan sama sekali (akun baru) -> nilai bawaan dipakai.
  bool _applyMeta(Map<String, dynamic>? meta) {
    if (meta == null) return false;
    const keys = [
      'reminder_enabled',
      'reminder_time',
      'notif_planning',
      'notif_weekly',
    ];
    if (!keys.any(meta.containsKey)) return false;
    _dailyOn = meta['reminder_enabled'] != false;
    final t = meta['reminder_time'];
    if (t is String) {
      final parts = t.split(RegExp(r'[.:]'));
      if (parts.length == 2) {
        final h = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        if (h != null && m != null && h >= 0 && h < 24 && m >= 0 && m < 60) {
          _hour = h;
          _minute = m;
        }
      }
    }
    _planningOn = meta['notif_planning'] != false;
    _weeklyOn = meta['notif_weekly'] == true;
    return true;
  }

  /// Kirim pengaturan ke Supabase. Gagal (offline dsb.) -> tetap "belum
  /// terkirim" dan dicoba lagi nanti.
  Future<void> _pushSettings() async {
    if (_syncing) return;
    _syncing = true;
    try {
      var again = true;
      while (again) {
        again = false;
        final uid = _uid;
        if (uid == null) return;
        final sent = _version;
        try {
          await SupabaseService.client.auth.updateUser(UserAttributes(data: {
            'reminder_enabled': _dailyOn,
            'reminder_time': timeLabel,
            'notif_planning': _planningOn,
            'notif_weekly': _weeklyOn,
          }));
        } catch (e) {
          debugPrint('Pengaturan notifikasi belum terkirim: $e');
          return; // tetap _dirty, dicoba lagi saat online/dibuka lagi
        }
        if (_uid != uid) return; // akun sudah berganti
        if (_version == sent) {
          _dirty = false;
          _persist();
        } else {
          again = true; // berubah lagi saat mengirim -> kirim versi terbaru
        }
      }
    } finally {
      _syncing = false;
    }
  }

  /// Ambil pengaturan terbaru dari server (mis. diubah di HP lain).
  Future<void> _pullSettings() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final res = await SupabaseService.client.auth.getUser();
      if (_uid != uid || _dirty) return; // ada perubahan baru di HP: jangan timpa
      final before = _signature;
      if (_applyMeta(res.user?.userMetadata) && _signature != before) {
        notifyListeners();
        _persist();
      }
    } catch (e) {
      debugPrint('Gagal mengambil pengaturan notifikasi: $e');
    }
  }

  void _seed() {
    final now = DateTime.now();
    _items.add(AppNotification(
      id: _nextId++,
      title: 'Selamat datang di Flowly',
      body: 'Catat transaksi pertama kamu dengan tombol + di bawah.',
      time: now,
      action: NotificationAction.addTransaction,
      mood: MascotExpression.happy,
    ));
    if (_dailyOn) {
      _items.add(AppNotification(
        id: _nextId++,
        title: 'Pengingat harian aktif',
        body: 'Kami akan mengingatkan kamu setiap hari pukul $timeLabel.',
        time: now,
        read: true,
        action: NotificationAction.dailyReminderSetting,
        mood: MascotExpression.wink,
      ));
    }
  }
}