import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../models/finance_models.dart';
import '../utils/constants.dart';
import 'app_data.dart';
import 'budget_store.dart';
import 'finance_store.dart';
import 'notification_store.dart';

/// Daftar kategori yang bisa ditambah, diubah, dan dihapus pengguna.
///
/// Kategori bawaan (user_id kosong di database) milik bersama: namanya tidak
/// bisa diubah dan tidak bisa dihapus, tapi warnanya boleh diganti (disimpan
/// per akun di perangkat). Kategori buatan pengguna bebas diubah nama dan
/// warnanya, dan bisa dihapus.
/// Isi awalnya dari [TxCategory.defaults] hanya sebagai cadangan sampai
/// data dari Supabase selesai dimuat.
class CategoryStore extends ChangeNotifier {
  CategoryStore._();
  static final CategoryStore instance = CategoryStore._();

  final List<TxCategory> _items = List.of(TxCategory.defaults);

  /// Id baris di database untuk tiap kategori (bisa belum selesai disimpan).
  final Map<TxCategory, Future<String?>> _ids = {};

  /// Kategori bawaan (milik bersama, nama terkunci, tidak bisa dihapus).
  final Set<TxCategory> _builtIn = {};

  /// Warna pilihan pengguna untuk kategori bawaan: 'tipe:nama' -> ARGB.
  final Map<String, int> _colorOverrides = {};

  /// Pencarian cepat id database -> kategori (dipakai saat memuat transaksi).
  final Map<String, TxCategory> _byRemote = {};

  List<TxCategory> get all => List.unmodifiable(_items);

  List<TxCategory> byType(TxType t) =>
      _items.where((c) => c.type == t).toList();

  /// Kategori bawaan: namanya terkunci dan tidak bisa dihapus; warnanya
  /// masih bisa diganti.
  static bool isFallback(TxCategory c) => instance._builtIn.contains(c);

  /// Id database kategori [c]; null kalau belum/tidak tersimpan.
  Future<String?> idOf(TxCategory c) => _ids[c] ?? Future<String?>.value(null);

  /// Kategori dari id database (untuk memuat transaksi).
  TxCategory byRemoteId(String? id, TxType type) =>
      (id != null ? _byRemote[id] : null) ??
      TxCategory('Tanpa kategori', const Color(0xFF64748B), type);

  bool exists(String name, TxType type, {TxCategory? except}) {
    final n = name.trim().toLowerCase();
    return _items.any(
      (c) => c != except && c.type == type && c.name.toLowerCase() == n,
    );
  }

  static String _overrideKey(TxCategory c) =>
      '${c.type.name}:${c.name.trim().toLowerCase()}';

  static Future<File?> _overrideFile() async {
    final id = AppData.uid;
    if (id == null) return null;
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/category_colors_$id.json');
  }

  Future<Map<String, int>> _readOverrides() async {
    try {
      final f = await _overrideFile();
      if (f == null || !await f.exists()) return {};
      final raw = jsonDecode(await f.readAsString()) as Map;
      return {
        for (final e in raw.entries) e.key as String: (e.value as num).toInt(),
      };
    } catch (e) {
      debugPrint('Gagal membaca warna kategori: $e');
      return {};
    }
  }

  Future<void> _writeOverrides() async {
    try {
      final f = await _overrideFile();
      if (f == null) return;
      await f.writeAsString(jsonEncode(_colorOverrides));
    } catch (e) {
      debugPrint('Gagal menyimpan warna kategori: $e');
    }
  }

  static String _table(TxType t) =>
      t == TxType.expense ? 'expense_categories' : 'income_categories';

  static String _hex(Color c) =>
      '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  static Color _colorOf(String? hex, String name) {
    if (hex != null && hex.trim().isNotEmpty) {
      final h = hex.trim().replaceAll('#', '').replaceAll('0x', '');
      final v = int.tryParse(h.length == 6 ? 'FF$h' : h, radix: 16);
      if (v != null) return Color(v);
    }
    for (final d in TxCategory.defaults) {
      if (d.name.toLowerCase() == name.toLowerCase()) return d.color;
    }
    return const Color(0xFF64748B);
  }

  // ---------------------------------------------------------- Supabase

  void reset() {
    _items
      ..clear()
      ..addAll(TxCategory.defaults);
    _ids.clear();
    _builtIn.clear();
    _byRemote.clear();
    _colorOverrides.clear();
    notifyListeners();
  }

  Future<void> loadRemote() async {
    final exp = await AppData.fetchAll('expense_categories');
    final inc = await AppData.fetchAll('income_categories');

    _colorOverrides
      ..clear()
      ..addAll(await _readOverrides());

    final rows = <(Map<String, dynamic>, TxType)>[
      for (final r in exp) (r, TxType.expense),
      for (final r in inc) (r, TxType.income),
    ];

    int rank(TxCategory c, bool builtIn, int index) {
      if (!builtIn) return 2000 + index;
      final i = TxCategory.defaults.indexWhere((d) =>
          d.type == c.type && d.name.toLowerCase() == c.name.toLowerCase());
      return i < 0 ? 1000 + index : i;
    }

    final built = <({TxCategory c, String id, bool builtIn, int rank})>[];
    for (var i = 0; i < rows.length; i++) {
      final r = rows[i].$1;
      final type = rows[i].$2;
      final name = (r['name'] as String).trim();
      final isBuiltIn = r['user_id'] == null;
      var color = _colorOf(r['color'] as String?, name);
      if (isBuiltIn) {
        final saved = _colorOverrides['${type.name}:${name.toLowerCase()}'];
        if (saved != null) color = Color(saved);
      }
      final c = TxCategory(name, color, type);
      built.add((
        c: c,
        id: r['id'] as String,
        builtIn: isBuiltIn,
        rank: rank(c, isBuiltIn, i),
      ));
    }
    built.sort((a, b) => a.rank.compareTo(b.rank));

    _items.clear();
    _ids.clear();
    _builtIn.clear();
    _byRemote.clear();
    for (final b in built) {
      _items.add(b.c);
      _ids[b.c] = Future<String?>.value(b.id);
      _byRemote[b.id] = b.c;
      if (b.builtIn) _builtIn.add(b.c);
    }
    notifyListeners();
  }

  // ------------------------------------------------------------- aksi

  /// false kalau nama kosong atau sudah dipakai kategori lain (tipe sama).
  bool add(String name, Color color, TxType type) {
    final n = name.trim();
    if (n.isEmpty || exists(n, type)) return false;
    final c = TxCategory(n, color, type);
    _items.add(c);
    NotificationStore.instance.push(
      title: 'Kategori ditambahkan',
      body: 'Kategori "$n" (${type == TxType.income ? 'pemasukan' : 'pengeluaran'}) berhasil ditambahkan.',
      action: NotificationAction.openCategories,
      mood: MascotExpression.happy,
    );

    final fut = AppData.guard<String>(() async {
      final row = await AppData.db
          .from(_table(type))
          .insert({
            'user_id': AppData.uid,
            'code': 'u_${DateTime.now().microsecondsSinceEpoch}',
            'name': n,
            'color': _hex(color),
          })
          .select('id')
          .single();
      return row['id'] as String;
    }, message: 'Kategori gagal disimpan, jadi dibatalkan. Coba lagi.');
    _ids[c] = fut;
    fut.then((id) {
      if (id == null) {
        _items.remove(c);
        _ids.remove(c);
        notifyListeners();
      } else {
        _byRemote[id] = c;
      }
    });

    notifyListeners();
    return true;
  }

  /// Ubah nama/warna. Transaksi lama ikut diperbarui.
  bool update(TxCategory old, String name, Color color) {
    final i = _items.indexOf(old);
    if (i < 0) return false;
    if (isFallback(old)) return _recolorBuiltIn(i, old, color); // nama terkunci
    final n = name.trim();
    if (n.isEmpty || exists(n, old.type, except: old)) return false;
    final fresh = TxCategory(n, color, old.type);
    _items[i] = fresh;
    NotificationStore.instance.push(
      title: 'Kategori diperbarui',
      body: 'Kategori "$n" berhasil diubah.',
      action: NotificationAction.openCategories,
      mood: MascotExpression.wink,
    );

    final idFut = _ids.remove(old);
    if (idFut != null) {
      _ids[fresh] = idFut;
      idFut.then((id) async {
        if (id == null) return;
        await AppData.run(
          () => AppData.db
              .from(_table(old.type))
              .update({'name': n, 'color': _hex(color)}).eq('id', id),
          message: 'Perubahan kategori gagal disimpan.',
        );
      });
    }

    FinanceStore.instance.replaceCategory(old, fresh);
    BudgetStore.instance.replaceCategory(old, fresh);
    notifyListeners();
    return true;
  }

  /// Kategori bawaan: hanya warna yang berubah (disimpan per akun di perangkat).
  bool _recolorBuiltIn(int i, TxCategory old, Color color) {
    if (old.color == color) return true;
    final fresh = TxCategory(old.name, color, old.type);
    _items[i] = fresh;
    NotificationStore.instance.push(
      title: 'Kategori diperbarui',
      body: 'Warna kategori "${old.name}" berhasil diubah.',
      action: NotificationAction.openCategories,
      mood: MascotExpression.wink,
    );

    final idFut = _ids.remove(old);
    if (idFut != null) _ids[fresh] = idFut;
    _byRemote.updateAll((_, v) => identical(v, old) ? fresh : v);
    _builtIn
      ..remove(old)
      ..add(fresh);

    _colorOverrides[_overrideKey(old)] = color.toARGB32();
    _writeOverrides();

    FinanceStore.instance.replaceCategory(old, fresh);
    BudgetStore.instance.replaceCategory(old, fresh);
    notifyListeners();
    return true;
  }

  /// false kalau kategori masih dipakai transaksi atau kategori bawaan.
  bool remove(TxCategory c) {
    if (isFallback(c) || FinanceStore.instance.categoryInUse(c)) return false;
    final ok = _items.remove(c);
    if (ok) {
      NotificationStore.instance.push(
        title: 'Kategori dihapus',
        body: 'Kategori "${c.name}" sudah dihapus.',
        action: NotificationAction.openCategories,
      );
      // Anggaran kategori ini ikut hilang (di server lewat ON DELETE CASCADE).
      BudgetStore.instance.dropForCategory(c);
      final idFut = _ids.remove(c);
      idFut?.then((id) async {
        if (id == null) return;
        await AppData.run(
          () => AppData.db.from(_table(c.type)).delete().eq('id', id),
          message: 'Kategori gagal dihapus di server.',
        );
      });
      notifyListeners();
    }
    return ok;
  }
}