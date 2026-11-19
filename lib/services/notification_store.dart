import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/constants.dart';
import 'supabase_service.dart';

/// Aksi yang dijalankan saat sebuah notifikasi diketuk.
enum NotificationAction {
  none,
  addTransaction, // buka form catat transaksi (sama seperti tombol +)
  dailyReminderSetting, // scroll ke pengaturan "Pengingat catat harian"
}

class AppNotification {
  final int id;
  final String title;
  final String body;
  final DateTime time;
  final bool read;
  final NotificationAction action;

  /// Ekspresi maskot Floy yang tampil di samping notifikasi.
  final MascotExpression mood;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    this.read = false,
    this.action = NotificationAction.none,
    this.mood = MascotExpression.normal,
  });

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        title: title,
        body: body,
        time: time,
        read: read ?? this.read,
        action: action,
        mood: mood,
      );
}

/// Daftar notifikasi + pengaturan pengingat.
///
/// Daftar notifikasi disimpan di memori (hilang saat aplikasi ditutup).
/// Pengaturan pengingat ikut disimpan di user metadata Supabase, sama
/// seperti jawaban setup, supaya tetap ada saat aplikasi dibuka lagi.
class NotificationStore extends ChangeNotifier {
  NotificationStore._() {
    _loadSettings();
    _seed();
  }
  static final NotificationStore instance = NotificationStore._();

  final List<AppNotification> _items = [];
  int _nextId = 1;

  bool _dailyOn = true;
  int _hour = 20;
  int _minute = 0;
  bool _planningOn = true;
  bool _weeklyOn = false;

  // ---------------------------------------------------------------- daftar

  List<AppNotification> get items => List.unmodifiable(_items);
  bool get isEmpty => _items.isEmpty;
  bool get hasUnread => _items.any((n) => !n.read);

  void markRead(int id) {
    final i = _items.indexWhere((n) => n.id == id);
    if (i < 0 || _items[i].read) return;
    _items[i] = _items[i].copyWith(read: true);
    notifyListeners();
  }

  void markAllRead() {
    if (!hasUnread) return;
    for (var i = 0; i < _items.length; i++) {
      _items[i] = _items[i].copyWith(read: true);
    }
    notifyListeners();
  }

  void remove(int id) {
    _items.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  void clear() {
    if (_items.isEmpty) return;
    _items.clear();
    notifyListeners();
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
    notifyListeners();
    _persist();
  }

  void setReminderTime(int hour, int minute) {
    _hour = hour;
    _minute = minute;
    _dailyOn = true; // memilih jam berarti pengingat dinyalakan
    notifyListeners();
    _persist();
  }

  void setPlanningOn(bool v) {
    _planningOn = v;
    notifyListeners();
    _persist();
  }

  void setWeeklyOn(bool v) {
    _weeklyOn = v;
    notifyListeners();
    _persist();
  }

  // ---------------------------------------------------------------- intern

  void _loadSettings() {
    try {
      final meta = SupabaseService.client.auth.currentUser?.userMetadata ?? {};
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
    } catch (_) {
      // pakai nilai bawaan
    }
  }

  void _seed() {
    final now = DateTime.now();
    _items.add(AppNotification(
      id: _nextId++,
      title: 'Selamat datang di Flowly',
      body: 'Catat transaksi pertama Anda dengan tombol + di bawah.',
      time: now,
      action: NotificationAction.addTransaction,
      mood: MascotExpression.happy,
    ));
    if (_dailyOn) {
      _items.add(AppNotification(
        id: _nextId++,
        title: 'Pengingat harian aktif',
        body: 'Kami akan mengingatkan Anda setiap hari pukul $timeLabel.',
        time: now,
        read: true,
        action: NotificationAction.dailyReminderSetting,
        mood: MascotExpression.wink,
      ));
    }
  }

  Future<void> _persist() async {
    try {
      await SupabaseService.client.auth.updateUser(UserAttributes(data: {
        'reminder_enabled': _dailyOn,
        'reminder_time': timeLabel,
        'notif_planning': _planningOn,
        'notif_weekly': _weeklyOn,
      }));
    } catch (_) {
      // gagal menyimpan: pengaturan tetap berlaku sampai aplikasi ditutup
    }
  }
}