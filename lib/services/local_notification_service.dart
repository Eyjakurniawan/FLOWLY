import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/planning_models.dart';
import 'notification_store.dart';
import 'planning_store.dart';
import 'supabase_service.dart';

/// Notifikasi pengingat yang muncul di LUAR aplikasi (bilah notifikasi HP),
/// seperti Instagram/TikTok. Tampilannya mengikuti gaya bawaan Android:
///
///   [maskot]  Flowly • Rencana harian • 08.00
///             Yuk, setor hari ini untuk Liburan!
///
/// - Nama aplikasi + jam diisi otomatis oleh Android.
/// - "Rencana harian" = `subText`, kalimat tebal = `title`.
/// - Maskot di kiri = `largeIcon` (drawable `maskot_notif`).
///
/// Tidak perlu mengubah store lain: layanan ini mendengarkan
/// [NotificationStore] (pengaturan pengingat) dan [PlanningStore] (rencana),
/// lalu menjadwalkan ulang otomatis kalau ada yang berubah.
class LocalNotificationService {
  LocalNotificationService._();
  static final LocalNotificationService instance = LocalNotificationService._();

  // ---- Pengaturan yang mudah diubah --------------------------------------
  static const _planHour = 8, _planMinute = 0; // Rencana harian/mingguan/bulanan
  static const _summaryHour = 7, _summaryMinute = 0; // Ringkasan mingguan
  static const _planWeekday = DateTime.monday; // hari setoran mingguan
  static const _planMonthDay = 1; // tanggal setoran bulanan
  static const _summaryWeekday = DateTime.monday;
  static const _brandColor = Color(0xFF2F80ED);

  // ---- ID notifikasi (tetap, supaya bisa diganti/dibatalkan) --------------
  static const _idDailyLog = 1;
  static const _idWeeklySummary = 2;
  static const _idPlanDaily = 3;
  static const _idPlanWeekly = 4;
  static const _idPlanMonthly = 5;

  static const _channelId = 'flowly_reminder';
  static const _channelName = 'Pengingat Flowly';
  static const _channelDesc = 'Pengingat catat transaksi, setoran rencana, dan ringkasan.';

  final _plugin = FlutterLocalNotificationsPlugin();

  /// Dipasang di main.dart: dipanggil saat notifikasi diketuk (aplikasi
  /// sedang berjalan) untuk membuka halaman yang sesuai.
  void Function(NotificationAction action)? onTap;

  bool _ready = false;
  bool _askedPermission = false;
  String _lastSignature = '';
  Timer? _debounce;
  Future<void> _queue = Future.value();

  // ------------------------------------------------------------------ init

  /// Panggil sekali di main() setelah SupabaseService.init().
  Future<void> init() async {
    if (_ready) return;
    if (defaultTargetPlatform != TargetPlatform.android) return;

    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    }

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@drawable/ic_stat_flowly'),
      ),
      onDidReceiveNotificationResponse: _onResponse,
    );
    _ready = true;

    // Jadwalkan ulang otomatis saat pengaturan / rencana berubah.
    NotificationStore.instance.addListener(_onStoreChanged);
    PlanningStore.instance.addListener(_onStoreChanged);
    _onStoreChanged();
  }

  void _onResponse(NotificationResponse r) {
    final action = NotificationAction.values.firstWhere(
      (a) => a.name == r.payload,
      orElse: () => NotificationAction.none,
    );
    onTap?.call(action);
  }

  // ------------------------------------------------------------ penjadwalan

  void _onStoreChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      final sig = _signature();
      if (sig == _lastSignature) return; // perubahan lain (mis. tandai dibaca)
      _lastSignature = sig;
      _queue = _queue.then((_) => _apply());
    });
  }

  String _signature() {
    final s = NotificationStore.instance;
    final plans = [
      for (final p in PlanningStore.instance.plans)
        if (!p.isDone) '${p.frequency.name}:${p.name}',
    ]..sort();
    final signedIn = SupabaseService.client.auth.currentUser != null;
    return '$signedIn|${s.dailyOn}|${s.hour}|${s.minute}|${s.planningOn}|'
        '${s.weeklyOn}|${plans.join(',')}';
  }

  Future<void> _apply() async {
    try {
      for (final id in [
        _idDailyLog,
        _idWeeklySummary,
        _idPlanDaily,
        _idPlanWeekly,
        _idPlanMonthly,
      ]) {
        await _plugin.cancel(id: id);
      }
      // Belum login / sudah logout: jangan ada pengingat tersisa.
      if (SupabaseService.client.auth.currentUser == null) return;

      await _ensurePermission();
      final s = NotificationStore.instance;

      // 1. Pengingat catat pengeluaran (jam pilihan pengguna).
      if (s.dailyOn) {
        await _schedule(
          id: _idDailyLog,
          title: 'Catat pengeluaran kamu hari ini, yuk!',
          at: _nextTime(s.hour, s.minute),
          match: DateTimeComponents.time,
          action: NotificationAction.addTransaction,
        );
      }

      // 2. Pengingat setoran rencana (hanya rencana yang belum selesai).
      if (s.planningOn) {
        final active = PlanningStore.instance.plans.where((p) => !p.isDone);
        final daily = active.where((p) => p.frequency == PlanFrequency.daily).toList();
        final hasWeekly = active.any((p) => p.frequency == PlanFrequency.weekly);
        final hasMonthly = active.any((p) => p.frequency == PlanFrequency.monthly);

        if (daily.isNotEmpty) {
          final target =
              daily.length == 1 ? daily.first.name : 'rencanamu';
          await _schedule(
            id: _idPlanDaily,
            title: 'Yuk, setor hari ini untuk $target!',
            subText: 'Rencana harian',
            at: _nextTime(_planHour, _planMinute),
            match: DateTimeComponents.time,
            action: NotificationAction.openPlanning,
          );
        }
        if (hasWeekly) {
          await _schedule(
            id: _idPlanWeekly,
            title: 'Setoran minggu ini menunggu, yuk!',
            subText: 'Rencana mingguan',
            at: _nextWeekday(_planWeekday, _planHour, _planMinute),
            match: DateTimeComponents.dayOfWeekAndTime,
            action: NotificationAction.openPlanning,
          );
        }
        if (hasMonthly) {
          await _schedule(
            id: _idPlanMonthly,
            title: 'Setoran bulan ini menunggu, yuk!',
            subText: 'Rencana bulanan',
            at: _nextMonthDay(_planMonthDay, _planHour, _planMinute),
            match: DateTimeComponents.dayOfMonthAndTime,
            action: NotificationAction.openPlanning,
          );
        }
      }

      // 3. Ringkasan minggu lalu.
      if (s.weeklyOn) {
        await _schedule(
          id: _idWeeklySummary,
          title: 'Ringkasan minggu lalu sudah siap!',
          at: _nextWeekday(_summaryWeekday, _summaryHour, _summaryMinute),
          match: DateTimeComponents.dayOfWeekAndTime,
          action: NotificationAction.openTransactions,
        );
      }
    } catch (e) {
      debugPrint('Gagal menjadwalkan notifikasi: $e');
    }
  }

  Future<void> _schedule({
    required int id,
    required String title,
    required tz.TZDateTime at,
    required DateTimeComponents match,
    required NotificationAction action,
    String? subText,
  }) {
    return _plugin.zonedSchedule(
      id: id,
      title: title,
      body: null, // hanya satu baris tebal, seperti desain
      scheduledDate: at,
      notificationDetails: _details(subText),
      // Tidak butuh izin alarm "tepat waktu"; bisa meleset beberapa menit.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: match,
      payload: action.name,
    );
  }

  NotificationDetails _details(String? subText) => NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.reminder,
          icon: 'ic_stat_flowly', // ikon kecil putih (status bar)
          largeIcon: const DrawableResourceAndroidBitmap('maskot_notif'),
          color: _brandColor,
          subText: subText, // "Rencana harian" dst.
          showWhen: true, // jam di baris atas
        ),
      );

  // ---------------------------------------------------------------- izin

  /// Android 13+ meminta izin notifikasi lewat dialog sistem.
  Future<bool> _ensurePermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return true;
    if (await android.areNotificationsEnabled() ?? false) return true;
    if (_askedPermission) return false;
    _askedPermission = true;
    return await android.requestNotificationsPermission() ?? false;
  }

  /// Untuk tombol "Uji notifikasi" (opsional): tampilkan kelima contoh
  /// sekarang juga supaya bisa dibandingkan dengan desain.
  Future<void> showPreview() async {
    if (!_ready) await init();
    if (!await _ensurePermission()) return;
    final samples = <(String, String?)>[
      ('Catat pengeluaran kamu hari ini, yuk!', null),
      ('Yuk, setor hari ini untuk Liburan!', 'Rencana harian'),
      ('Setoran minggu ini menunggu, yuk!', 'Rencana mingguan'),
      ('Setoran bulan ini menunggu, yuk!', 'Rencana bulanan'),
      ('Ringkasan minggu lalu sudah siap!', null),
    ];
    for (var i = 0; i < samples.length; i++) {
      await _plugin.show(
        id: 900 + i,
        title: samples[i].$1,
        body: null,
        notificationDetails: _details(samples[i].$2),
      );
    }
  }

  // -------------------------------------------------------- waktu (lokal)

  tz.TZDateTime _nextTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var t = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!t.isAfter(now)) t = t.add(const Duration(days: 1));
    return t;
  }

  tz.TZDateTime _nextWeekday(int weekday, int hour, int minute) {
    var t = _nextTime(hour, minute);
    while (t.weekday != weekday) {
      t = t.add(const Duration(days: 1));
    }
    return t;
  }

  tz.TZDateTime _nextMonthDay(int day, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var t = tz.TZDateTime(tz.local, now.year, now.month, day, hour, minute);
    if (!t.isAfter(now)) {
      t = tz.TZDateTime(tz.local, now.year, now.month + 1, day, hour, minute);
    }
    return t;
  }
}