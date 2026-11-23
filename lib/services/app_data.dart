import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'budget_store.dart';
import 'category_store.dart';
import 'connectivity_service.dart';
import 'finance_store.dart';
import 'notification_store.dart';
import 'planning_store.dart';
import 'supabase_service.dart';

/// Penghubung data keuangan ke Supabase.
///
/// - [ensureLoaded] memuat kategori, dompet, transaksi, dan rencana milik
///   user yang sedang login (dipanggil saat Beranda dibuka).
/// - [clear] mengosongkan semua store saat logout, supaya data akun lain
///   tidak terbawa di HP yang sama.
/// - Fungsi static dipakai store untuk menulis ke database.
class AppData {
  AppData._();
  static final AppData instance = AppData._();

  /// Dipasang di main.dart untuk menampilkan pesan gagal simpan/muat.
  static void Function(String message)? onError;

  static SupabaseClient get db => SupabaseService.client;
  static String? get uid => db.auth.currentUser?.id;

  String? _loadedFor;
  Future<void>? _loading;

  Future<void> ensureLoaded() {
    final id = uid;
    if (id == null || _loadedFor == id) return Future.value();
    return _loading ??= _load(id).whenComplete(() => _loading = null);
  }

  /// Muat ulang semua data dari server (dipanggil saat internet kembali).
  Future<void> reload() {
    final id = uid;
    if (id == null) return Future.value();
    _loadedFor = null;
    return _loading ??= _load(id, keepNotifications: true)
        .whenComplete(() => _loading = null);
  }

  Future<void> _load(String id, {bool keepNotifications = false}) async {
    try {
      FinanceStore.instance.reset();
      CategoryStore.instance.reset();
      PlanningStore.instance.reset();
      BudgetStore.instance.reset();
      if (!keepNotifications) {
        await NotificationStore.instance.loadFor(id);
      } else {
        // Internet kembali: kirim/ambil pengaturan pengingat.
        unawaited(NotificationStore.instance.syncSettings());
      }
      await CategoryStore.instance.loadRemote();
      await FinanceStore.instance.loadRemote();
      await PlanningStore.instance.loadRemote();
      await BudgetStore.instance.loadRemote();
      _loadedFor = id;
    } catch (e) {
      debugPrint('Gagal memuat data: $e');
      report('Gagal memuat data. Periksa koneksi lalu coba lagi.');
    }
  }

  /// Kosongkan semua data lokal (dipanggil saat logout).
  void clear() {
    _loadedFor = null;
    FinanceStore.instance.reset();
    CategoryStore.instance.reset();
    PlanningStore.instance.reset();
    BudgetStore.instance.reset();
    NotificationStore.instance.reset();
    _refreshTimer?.cancel();
    _deleteCache();
  }

  // ------------------------------------------------------------- helpers

  static void report(String message) => onError?.call(message);

  /// Jalankan [fn]; kalau gagal tampilkan pesan dan kembalikan null.
  static Future<T?> guard<T>(Future<T> Function() fn,
      {String? message}) async {
    try {
      final result = await fn();
      _scheduleCacheRefresh();
      return result;
    } catch (e) {
      debugPrint('Supabase error: $e');
      report(message ?? 'Gagal menyimpan. Periksa koneksi lalu coba lagi.');
      return null;
    }
  }

  /// Seperti [guard] tapi untuk operasi tanpa hasil. true kalau berhasil.
  static Future<bool> run(Future<dynamic> Function() fn,
      {String? message}) async {
    try {
      await fn();
      _scheduleCacheRefresh();
      return true;
    } catch (e) {
      debugPrint('Supabase error: $e');
      report(message ?? 'Gagal menyimpan. Periksa koneksi lalu coba lagi.');
      return false;
    }
  }

  /// Ambil semua baris dari server. Kalau berhasil, salinannya disimpan di
  /// HP. Kalau gagal (offline), pakai salinan terakhir kalau ada.
  static Future<List<Map<String, dynamic>>> fetchAll(String table,
      {bool useCache = true}) async {
    try {
      final rows = await _fetchRemote(table);
      await _cacheWrite(table, rows);
      return rows;
    } catch (e) {
      if (!useCache) rethrow;
      final cached = await _cacheRead(table);
      if (cached == null) rethrow;
      debugPrint('Offline, pakai data tersimpan untuk $table: $e');
      ConnectivityService.instance.setOnline(false);
      return cached;
    }
  }

  /// Ambil semua baris (PostgREST membatasi 1000 baris per permintaan).
  static Future<List<Map<String, dynamic>>> _fetchRemote(String table) async {
    const page = 1000;
    final out = <Map<String, dynamic>>[];
    var from = 0;
    while (true) {
      final rows = await db
          .from(table)
          .select()
          .order('created_at', ascending: true)
          .order('id', ascending: true)
          .range(from, from + page - 1)
          .timeout(const Duration(seconds: 10));
      final list = List<Map<String, dynamic>>.from(rows);
      out.addAll(list);
      if (list.length < page) break;
      from += page;
    }
    return out;
  }

  // ------------------------------------------------- salinan data offline

  static const _tables = [
    'expense_categories',
    'income_categories',
    'wallets',
    'expenses',
    'incomes',
    'planning',
    'planning_deposits',
    'budgets',
  ];

  static Map<String, dynamic>? _cache;
  static String? _cacheUid;
  static Timer? _refreshTimer;

  static Future<File?> _cacheFile([String? forUid]) async {
    final id = forUid ?? uid;
    if (id == null) return null;
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/flowly_cache_$id.json');
  }

  static Future<Map<String, dynamic>> _cacheLoad() async {
    final id = uid;
    if (_cache != null && _cacheUid == id) return _cache!;
    _cacheUid = id;
    _cache = {};
    try {
      final f = await _cacheFile();
      if (f != null && await f.exists()) {
        final decoded = jsonDecode(await f.readAsString());
        if (decoded is Map<String, dynamic>) _cache = decoded;
      }
    } catch (_) {
      _cache = {};
    }
    return _cache!;
  }

  static Future<List<Map<String, dynamic>>?> _cacheRead(String table) async {
    final data = (await _cacheLoad())[table];
    if (data is! List) return null;
    return [for (final r in data) Map<String, dynamic>.from(r as Map)];
  }

  static Future<void> _cacheWrite(
      String table, List<Map<String, dynamic>> rows) async {
    try {
      final data = await _cacheLoad();
      data[table] = rows;
      final f = await _cacheFile();
      if (f != null) await f.writeAsString(jsonEncode(data), flush: true);
    } catch (e) {
      debugPrint('Gagal menyimpan salinan data: $e');
    }
  }

  static Future<void> _deleteCache() async {
    final id = _cacheUid;
    _cache = null;
    _cacheUid = null;
    try {
      final f = await _cacheFile(id);
      if (f != null && await f.exists()) await f.delete();
    } catch (_) {}
  }

  /// Setelah ada perubahan yang berhasil tersimpan di server, perbarui
  /// salinan di HP (ditunda 3 detik supaya beberapa perubahan sekaligus
  /// hanya memicu satu kali penyegaran).
  static void _scheduleCacheRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer(const Duration(seconds: 3), () async {
      if (uid == null || !ConnectivityService.instance.isOnline) return;
      for (final t in _tables) {
        try {
          await fetchAll(t, useCache: false);
        } catch (_) {
          return;
        }
      }
    });
  }

  static int toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.round();
    return (double.tryParse('$v') ?? 0).round();
  }

  /// Baca kolom tanggal ('YYYY-MM-DD') jadi DateTime tanpa jam.
  static DateTime? parseDate(dynamic v) {
    if (v == null) return null;
    final d = DateTime.tryParse('$v');
    if (d == null) return null;
    return DateTime(d.year, d.month, d.day);
  }

  static String dateStr(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}