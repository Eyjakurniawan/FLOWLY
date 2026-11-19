import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'category_store.dart';
import 'finance_store.dart';
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

  Future<void> _load(String id) async {
    try {
      FinanceStore.instance.reset();
      CategoryStore.instance.reset();
      PlanningStore.instance.reset();
      await CategoryStore.instance.loadRemote();
      await FinanceStore.instance.loadRemote();
      await PlanningStore.instance.loadRemote();
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
  }

  // ------------------------------------------------------------- helpers

  static void report(String message) => onError?.call(message);

  /// Jalankan [fn]; kalau gagal tampilkan pesan dan kembalikan null.
  static Future<T?> guard<T>(Future<T> Function() fn,
      {String? message}) async {
    try {
      return await fn();
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
      return true;
    } catch (e) {
      debugPrint('Supabase error: $e');
      report(message ?? 'Gagal menyimpan. Periksa koneksi lalu coba lagi.');
      return false;
    }
  }

  /// Ambil semua baris (PostgREST membatasi 1000 baris per permintaan).
  static Future<List<Map<String, dynamic>>> fetchAll(String table) async {
    const page = 1000;
    final out = <Map<String, dynamic>>[];
    var from = 0;
    while (true) {
      final rows = await db
          .from(table)
          .select()
          .order('created_at', ascending: true)
          .order('id', ascending: true)
          .range(from, from + page - 1);
      final list = List<Map<String, dynamic>>.from(rows);
      out.addAll(list);
      if (list.length < page) break;
      from += page;
    }
    return out;
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