import 'package:flutter/foundation.dart';

import '../models/budget_models.dart';
import '../models/finance_models.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import 'app_data.dart';
import 'category_store.dart';
import 'finance_store.dart';
import 'notification_store.dart';

/// Sumber data anggaran, tersimpan di Supabase (tabel `budgets`).
/// Tampilan diperbarui langsung, lalu disimpan ke server di latar belakang.
class BudgetStore extends ChangeNotifier {
  BudgetStore._();
  static final BudgetStore instance = BudgetStore._();

  final List<Budget> _items = [];
  int _nextId = 1;

  /// Id database tiap anggaran (bisa belum selesai disimpan).
  final Map<int, Future<String?>> _ids = {};

  static DateTime _nowMonth() => monthStart(DateTime.now());
  static DateTime _prevMonth(DateTime m) => DateTime(m.year, m.month - 1);

  // ---------------------------------------------------------------- state

  /// Anggaran yang masih berjalan.
  List<Budget> get active => _items.where((b) => b.isActive).toList();

  bool get isEmpty => !_items.any((b) => b.isActive);

  Budget? byId(int id) {
    for (final b in _items) {
      if (b.id == id) return b;
    }
    return null;
  }

  static bool _sameCategory(TxCategory a, TxCategory b) =>
      a.type == b.type && a.name.toLowerCase() == b.name.toLowerCase();

  /// Anggaran berjalan untuk kategori [c]; null kalau belum ada.
  Budget? activeFor(TxCategory c) {
    for (final b in _items) {
      if (b.isActive && _sameCategory(b.category, c)) return b;
    }
    return null;
  }

  /// Kategori pengeluaran yang belum punya anggaran (isi dropdown).
  List<TxCategory> get availableCategories => CategoryStore.instance
      .byType(TxType.expense)
      .where((c) => activeFor(c) == null)
      .toList();

  /// Bulan-bulan yang bisa dilihat di riwayat: dari bulan anggaran pertama
  /// sampai bulan ini, terbaru dulu.
  List<DateTime> get months {
    final now = _nowMonth();
    var first = now;
    for (final b in _items) {
      if (b.startMonth.isBefore(first)) first = b.startMonth;
    }
    final out = <DateTime>[];
    var m = now;
    while (!m.isBefore(first)) {
      out.add(m);
      m = _prevMonth(m);
    }
    return out;
  }

  /// Pemakaian semua anggaran yang berlaku di [month]; yang paling
  /// mendekati batas ada di atas.
  BudgetMonthSummary summaryFor(DateTime month) {
    final m = monthStart(month);
    final fin = FinanceStore.instance;
    final items = <BudgetUsage>[
      for (final b in _items)
        if (b.appliesTo(m))
          BudgetUsage(b, fin.categoryExpenseInMonth(b.category, m)),
    ]..sort((a, b) {
        final c = b.ratio.compareTo(a.ratio);
        return c != 0 ? c : a.budget.id.compareTo(b.budget.id);
      });
    return BudgetMonthSummary(m, items);
  }

  // ---------------------------------------------------------- Supabase

  void reset() {
    _items.clear();
    _ids.clear();
    _nextId = 1;
    notifyListeners();
  }

  Future<void> loadRemote() async {
    final rows = await AppData.fetchAll('budgets');
    final cats = CategoryStore.instance;
    final now = _nowMonth();

    _items.clear();
    _ids.clear();
    _nextId = 1;
    for (final r in rows) {
      final id = _nextId++;
      final start = AppData.parseDate(r['start_month']);
      final end = AppData.parseDate(r['end_month']);
      _items.add(Budget(
        id: id,
        category: cats.byRemoteId(r['category_id'] as String?, TxType.expense),
        limit: AppData.toInt(r['limit_amount']),
        startMonth: start == null ? now : monthStart(start),
        endMonth: end == null ? null : monthStart(end),
      ));
      _ids[id] = Future<String?>.value(r['id'] as String);
    }
    notifyListeners();
  }

  Future<String?> _insert(Budget b) async {
    final catId = await CategoryStore.instance.idOf(b.category);
    return AppData.guard<String>(() async {
      if (catId == null) {
        throw StateError('kategori belum tersimpan di server');
      }
      final row = await AppData.db
          .from('budgets')
          .insert({
            'user_id': AppData.uid,
            'category_id': catId,
            'limit_amount': b.limit,
            'start_month': AppData.dateStr(b.startMonth),
          })
          .select('id')
          .single();
      return row['id'] as String;
    }, message: 'Anggaran gagal disimpan, jadi dibatalkan. Coba lagi.');
  }

  Future<void> _setEnd(int id, DateTime? end, String message) async {
    final rid = await (_ids[id] ?? Future<String?>.value(null));
    if (rid == null) return;
    await AppData.run(
      () => AppData.db
          .from('budgets')
          .update({'end_month': end == null ? null : AppData.dateStr(end)})
          .eq('id', rid),
      message: message,
    );
  }

  // ------------------------------------------------------------- aksi

  /// false kalau batas kosong atau kategori itu sudah punya anggaran.
  bool add(TxCategory category, int limit) {
    if (limit <= 0 || activeFor(category) != null) return false;
    final id = _nextId++;
    final b = Budget(
      id: id,
      category: category,
      limit: limit,
      startMonth: _nowMonth(),
    );
    _items.add(b);

    NotificationStore.instance.push(
      title: 'Anggaran dibuat',
      body: 'Anggaran ${category.name} ${Fmt.rupiah(limit)} per bulan '
          'berhasil dibuat.',
      action: NotificationAction.openBudget,
      mood: MascotExpression.happy,
    );

    final fut = _insert(b);
    _ids[id] = fut;
    fut.then((rid) {
      if (rid == null) {
        _items.removeWhere((x) => x.id == id);
        _ids.remove(id);
        notifyListeners();
      }
    });
    notifyListeners();
    return true;
  }

  /// Ubah batas anggaran. Kalau anggarannya sudah berjalan sejak bulan
  /// lalu, batas lama ditutup di akhir bulan lalu dan batas baru mulai
  /// bulan ini, supaya riwayat bulan lalu tidak ikut berubah.
  bool updateLimit(int id, int limit) {
    final i = _items.indexWhere((b) => b.id == id);
    if (i < 0 || limit <= 0) return false;
    final b = _items[i];
    if (b.limit == limit) return true;
    final now = _nowMonth();

    NotificationStore.instance.push(
      title: 'Anggaran diperbarui',
      body: 'Anggaran ${b.category.name} diubah menjadi '
          '${Fmt.rupiah(limit)} per bulan.',
      action: NotificationAction.openBudget,
      mood: MascotExpression.wink,
    );

    if (!b.startMonth.isBefore(now)) {
      // Baru mulai bulan ini: cukup ubah barisnya.
      _items[i] = b.copyWith(limit: limit);
      _ids[id]?.then((rid) async {
        if (rid == null) return;
        await AppData.run(
          () => AppData.db
              .from('budgets')
              .update({'limit_amount': limit}).eq('id', rid),
          message: 'Perubahan anggaran gagal disimpan.',
        );
      });
    } else {
      final prev = _prevMonth(now);
      _items[i] = b.copyWith(endMonth: prev);
      final fresh = Budget(
        id: _nextId++,
        category: b.category,
        limit: limit,
        startMonth: now,
      );
      _items.add(fresh);
      final fut = _rotate(b, fresh, prev);
      _ids[fresh.id] = fut;
      fut.then((rid) {
        if (rid == null) {
          final j = _items.indexWhere((x) => x.id == id);
          if (j >= 0) _items[j] = b;
          _items.removeWhere((x) => x.id == fresh.id);
          _ids.remove(fresh.id);
          notifyListeners();
        }
      });
    }
    notifyListeners();
    return true;
  }

  /// Tutup baris lama lalu buat baris baru (urutan ini penting karena
  /// server hanya mengizinkan satu anggaran berjalan per kategori).
  Future<String?> _rotate(Budget old, Budget fresh, DateTime prev) async {
    final oldRid = await (_ids[old.id] ?? Future<String?>.value(null));
    if (oldRid == null) return null;
    final closed = await AppData.run(
      () => AppData.db
          .from('budgets')
          .update({'end_month': AppData.dateStr(prev)}).eq('id', oldRid),
      message: 'Perubahan anggaran gagal disimpan.',
    );
    if (!closed) return null;
    final newRid = await _insert(fresh);
    if (newRid == null) {
      // Buka lagi baris lama supaya data di server tetap utuh.
      await AppData.run(
        () => AppData.db
            .from('budgets')
            .update({'end_month': null}).eq('id', oldRid),
      );
    }
    return newRid;
  }

  /// Hentikan anggaran. Kalau baru dibuat bulan ini, barisnya dihapus;
  /// kalau sudah berjalan sejak bulan lalu, riwayatnya tetap disimpan.
  void remove(int id) {
    final i = _items.indexWhere((b) => b.id == id);
    if (i < 0) return;
    final b = _items[i];
    final now = _nowMonth();

    NotificationStore.instance.push(
      title: 'Anggaran dihapus',
      body: 'Anggaran ${b.category.name} sudah dihapus.',
      action: NotificationAction.openBudget,
    );

    if (!b.startMonth.isBefore(now)) {
      _items.removeAt(i);
      _ids.remove(id)?.then((rid) async {
        if (rid == null) return;
        await AppData.run(
          () => AppData.db.from('budgets').delete().eq('id', rid),
          message: 'Anggaran gagal dihapus di server.',
        );
      });
    } else {
      _items[i] = b.copyWith(endMonth: _prevMonth(now));
      _setEnd(id, _prevMonth(now), 'Anggaran gagal dihapus di server.');
    }
    notifyListeners();
  }

  /// Dipanggil CategoryStore saat kategori diubah nama/warnanya.
  void replaceCategory(TxCategory old, TxCategory fresh) {
    var changed = false;
    for (var i = 0; i < _items.length; i++) {
      if (_sameCategory(_items[i].category, old)) {
        _items[i] = _items[i].copyWith(category: fresh);
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  /// Dipanggil CategoryStore saat kategori dihapus. Di server barisnya ikut
  /// terhapus otomatis (ON DELETE CASCADE), jadi cukup bersihkan di sini.
  void dropForCategory(TxCategory c) {
    final ids = _items
        .where((b) => _sameCategory(b.category, c))
        .map((b) => b.id)
        .toList();
    if (ids.isEmpty) return;
    _items.removeWhere((b) => ids.contains(b.id));
    for (final id in ids) {
      _ids.remove(id);
    }
    notifyListeners();
  }
}