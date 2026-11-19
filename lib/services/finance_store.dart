import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/finance_models.dart';
import '../utils/formatters.dart';
import 'app_data.dart';
import 'category_store.dart';

/// Sumber data keuangan (sementara in-memory).
///
/// Nanti tinggal ganti isi method di sini dengan query Supabase;
/// UI cukup mendengarkan [FinanceStore] lewat ListenableBuilder.
///
/// Default-nya kosong: semua Rp0 sampai pengguna menambah dompet.
/// Ubah [useDemoData] ke `true` untuk memuat data contoh.
class FinanceStore extends ChangeNotifier {
  FinanceStore._() {
    if (useDemoData) _seed();
    _watchMonth();
  }
  static final FinanceStore instance = FinanceStore._();

  static const bool useDemoData = false;

  final List<Wallet> _wallets = [];
  final List<FlowTransaction> _tx = [];

  /// Id transaksi yang dompetnya sudah dihapus. Transaksinya tetap ada
  /// (muncul di Reports), tapi tidak lagi dihitung ke saldo dompet mana pun
  /// - termasuk kalau nanti dibuat dompet baru dengan nama yang sama.
  final Set<int> _orphanIds = {};
  DateTime _month = _monthOf(DateTime.now());
  DateTime _shownMonth = _monthOf(DateTime.now());
  bool _hide = false;
  int _nextId = 1;

  /// Id database tiap dompet aktif (kunci = nama dompet). Berupa Future
  /// karena dompet baru bisa belum selesai disimpan saat dipakai.
  final Map<String, Future<String?>> _walletIds = {};

  static DateTime _monthOf(DateTime d) => DateTime(d.year, d.month);

  // ---------------------------------------------------------------- state

  List<Wallet> get wallets => List.unmodifiable(_wallets);
  bool get hasWallets => _wallets.isNotEmpty;
  DateTime get month => _month;
  bool get hideAmounts => _hide;

  void toggleHide() {
    _hide = !_hide;
    notifyListeners();
  }

  void setMonth(DateTime m) {
    _month = _monthOf(m);
    notifyListeners();
  }

  /// Cek tiap menit: kalau bulan sudah berganti, segarkan semua tampilan.
  void _watchMonth() {
    Timer.periodic(const Duration(minutes: 1), (_) {
      final m = _monthOf(DateTime.now());
      if (m != _shownMonth) {
        _shownMonth = m;
        _month = m;
        notifyListeners();
      }
    });
  }

  // ---------------------------------------------------------- Supabase

  void reset() {
    _wallets.clear();
    _tx.clear();
    _orphanIds.clear();
    _walletIds.clear();
    _nextId = 1;
    _month = _monthOf(DateTime.now());
    _shownMonth = _month;
    notifyListeners();
  }

  static WalletType _typeOf(String? s) => WalletType.values.firstWhere(
        (t) => t.name == s,
        orElse: () => WalletType.bank,
      );

  /// Muat dompet & transaksi milik user dari Supabase.
  Future<void> loadRemote() async {
    final wRows = await AppData.fetchAll('wallets');
    final wallets = <Wallet>[];
    final ids = <String, Future<String?>>{};
    final idToName = <String, String>{};
    final deletedIds = <String>{};
    for (final r in wRows) {
      final id = r['id'] as String;
      final name = r['name'] as String;
      idToName[id] = name;
      if (r['deleted_at'] != null) {
        deletedIds.add(id);
        continue;
      }
      wallets.add(Wallet(
        name,
        _typeOf(r['type'] as String?),
        AppData.toInt(r['initial_balance']),
      ));
      ids[name] = Future<String?>.value(id);
    }

    final expRows = await AppData.fetchAll('expenses');
    final incRows = await AppData.fetchAll('incomes');
    final raw = <MapEntry<TxType, Map<String, dynamic>>>[
      for (final r in expRows) MapEntry(TxType.expense, r),
      for (final r in incRows) MapEntry(TxType.income, r),
    ]..sort((a, b) =>
        '${a.value['created_at']}'.compareTo('${b.value['created_at']}'));

    final cats = CategoryStore.instance;
    final tx = <FlowTransaction>[];
    final orphans = <int>{};
    var nextId = 1;
    for (final e in raw) {
      final r = e.value;
      final cat = cats.byRemoteId(r['category_id'] as String?, e.key);
      final walletId = r['wallet_id'] as String?;
      final d = AppData.parseDate(r['transaction_date']) ?? DateTime.now();
      final note = (r['note'] as String?)?.trim();
      final id = nextId++;
      tx.add(FlowTransaction(
        id: id,
        title: (note == null || note.isEmpty) ? cat.name : note,
        category: cat,
        wallet: idToName[walletId] ?? '',
        amount: AppData.toInt(r['amount']),
        type: e.key,
        date: DateTime(d.year, d.month, d.day, 12),
      ));
      if (deletedIds.contains(walletId)) orphans.add(id);
    }

    _wallets
      ..clear()
      ..addAll(wallets);
    _tx
      ..clear()
      ..addAll(tx);
    _orphanIds
      ..clear()
      ..addAll(orphans);
    _walletIds
      ..clear()
      ..addAll(ids);
    _nextId = nextId;
    notifyListeners();
  }

  /// Simpan transaksi baru; kalau gagal, transaksinya dibatalkan.
  Future<void> _pushTransaction(FlowTransaction t, String? note) async {
    final walletId =
        await (_walletIds[t.wallet] ?? Future<String?>.value(null));
    final catId = await CategoryStore.instance.idOf(t.category);
    final n = note?.trim();
    final ok = await AppData.run(() async {
      if (walletId == null || catId == null) {
        throw StateError('dompet/kategori belum tersimpan di server');
      }
      await AppData.db
          .from(t.type == TxType.expense ? 'expenses' : 'incomes')
          .insert({
        'user_id': AppData.uid,
        'wallet_id': walletId,
        'category_id': catId,
        'amount': t.amount,
        'note': (n == null || n.isEmpty) ? null : n,
        'transaction_date': AppData.dateStr(t.date),
      });
    }, message: 'Transaksi gagal disimpan, jadi dibatalkan. Coba lagi.');
    if (!ok) {
      _tx.removeWhere((x) => x.id == t.id);
      notifyListeners();
    }
  }

  /// Saldo satu dompet = saldo awal + semua transaksinya.
  int balanceOf(Wallet w) =>
      w.initialBalance +
      _tx
          .where((t) => t.wallet == w.name && !_orphanIds.contains(t.id))
          .fold<int>(0, (s, t) => s + t.signedAmount);

  Wallet? walletByName(String name) {
    for (final w in _wallets) {
      if (w.name == name) return w;
    }
    return null;
  }

  bool categoryInUse(TxCategory c) =>
      _tx.any((t) => t.category.name == c.name && t.category.type == c.type);

  /// Ganti kategori lama dengan yang baru di semua transaksi.
  void replaceCategory(TxCategory old, TxCategory fresh) {
    for (var i = 0; i < _tx.length; i++) {
      final t = _tx[i];
      if (t.category.name == old.name && t.category.type == old.type) {
        _tx[i] = t.copyWith(
          category: fresh,
          title: t.title == old.name ? fresh.name : t.title,
        );
      }
    }
    notifyListeners();
  }

  /// Return false kalau nama kosong atau sudah dipakai dompet lain.
  bool updateWallet(
      String oldName, String name, WalletType type, int initialBalance) {
    final n = name.trim();
    final i = _wallets.indexWhere((w) => w.name == oldName);
    if (i < 0 || n.isEmpty) return false;
    if (_wallets.any((w) =>
        w.name != oldName && w.name.toLowerCase() == n.toLowerCase())) {
      return false;
    }
    _wallets[i] = Wallet(n, type, initialBalance);
    if (n != oldName) {
      for (var j = 0; j < _tx.length; j++) {
        if (_tx[j].wallet == oldName && !_orphanIds.contains(_tx[j].id)) {
          _tx[j] = _tx[j].copyWith(wallet: n);
        }
      }
    }
    final idFut = _walletIds.remove(oldName);
    if (idFut != null) {
      _walletIds[n] = idFut;
      final balance = balanceOf(_wallets[i]);
      idFut.then((id) async {
        if (id == null) return;
        await AppData.run(
          () => AppData.db.from('wallets').update({
            'name': n,
            'type': type.name,
            'initial_balance': initialBalance,
            'balance': balance,
          }).eq('id', id),
          message: 'Perubahan dompet gagal disimpan.',
        );
      });
    }
    notifyListeners();
    return true;
  }

  /// Hapus dompetnya saja. Riwayat transaksinya tetap disimpan dan masih
  /// bisa dilihat di Reports, tapi tidak lagi dihitung ke total saldo.
  void removeWallet(String name) {
    for (final t in _tx) {
      if (t.wallet == name) _orphanIds.add(t.id);
    }
    _wallets.removeWhere((w) => w.name == name);
    final idFut = _walletIds.remove(name);
    idFut?.then((id) async {
      if (id == null) return;
      await AppData.run(
        () => AppData.db.from('wallets').update({
          'deleted_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', id),
        message: 'Dompet gagal dihapus di server.',
      );
    });
    notifyListeners();
  }

  /// Semua transaksi satu dompet (semua bulan), terbaru dulu.
  List<FlowTransaction> walletTransactions(String name) {
    final list = _tx
        .where((t) => t.wallet == name && !_orphanIds.contains(t.id))
        .toList()
      ..sort((a, b) {
        final c = b.date.compareTo(a.date);
        return c != 0 ? c : b.id.compareTo(a.id);
      });
    return list;
  }

  /// Return false kalau nama kosong atau sudah dipakai.
  bool addWallet(String name, WalletType type, int initialBalance) {
    final n = name.trim();
    if (n.isEmpty ||
        _wallets.any((w) => w.name.toLowerCase() == n.toLowerCase())) {
      return false;
    }
    final w = Wallet(n, type, initialBalance);
    _wallets.add(w);
    final fut = AppData.guard<String>(() async {
      final row = await AppData.db
          .from('wallets')
          .insert({
            'user_id': AppData.uid,
            'name': n,
            'type': type.name,
            'initial_balance': initialBalance,
          })
          .select('id')
          .single();
      return row['id'] as String;
    }, message: 'Dompet gagal disimpan, jadi dibatalkan. Coba lagi.');
    _walletIds[n] = fut;
    fut.then((id) {
      if (id == null) {
        _wallets.remove(w);
        _walletIds.remove(n);
        notifyListeners();
      }
    });
    notifyListeners();
    return true;
  }

  /// Saldo yang tersedia di dompet [name]; null kalau dompetnya tidak ada.
  int? availableIn(String name) {
    final w = walletByName(name);
    return w == null ? null : balanceOf(w);
  }

  /// Catat transaksi. Return false (dan tidak mencatat apa pun) kalau
  /// pengeluaran melebihi saldo dompet, supaya saldo tidak pernah minus.
  bool addTransaction({
    required TxType type,
    required int amount,
    required TxCategory category,
    required String wallet,
    String? note,
    DateTime? date,
  }) {
    if (type == TxType.expense) {
      final available = availableIn(wallet);
      if (available == null || amount > available) return false;
    }
    final now = DateTime.now();
    final d = date ?? now;
    // hari ini pakai jam sekarang, hari lain jam 12 siang
    final when = Fmt.sameDay(d, now) ? now : DateTime(d.year, d.month, d.day, 12);
    final t = FlowTransaction(
      id: _nextId++,
      title: (note == null || note.trim().isEmpty) ? category.name : note.trim(),
      category: category,
      wallet: wallet,
      amount: amount,
      type: type,
      date: when,
    );
    _tx.add(t);
    notifyListeners();
    _pushTransaction(t, note);
    return true;
  }

  /// Format uang; disamarkan kalau mode sembunyikan saldo aktif.
  String money(int v) => _hide ? 'Rp*****' : Fmt.rupiah(v);
  String signedMoney(int v) {
    if (v == 0) return money(0);
    final prefix = v > 0 ? '+' : '-';
    if (_hide) return '${prefix}Rp*****';
    return Fmt.signedRupiah(v);
  }
  String moneyCompact(int v) => _hide ? 'Rp***' : Fmt.compact(v);

  // -------------------------------------------------------------- queries

  /// Total saldo hanya dari dompet yang masih ada.
  int get totalBalance => _wallets.fold<int>(0, (s, w) => s + balanceOf(w));

  /// Teks penjelasan untuk dialog hapus dompet.
  String deleteWalletMessage(Wallet w) {
    final count = walletTransactions(w.name).length;
    final parts = <String>[
      '\u201C${w.name}\u201D dihapus permanen dan tidak bisa dikembalikan atau diedit.',
      'Saldo ${money(balanceOf(w))} tidak lagi dihitung di total balance.',
      if (count > 0) '$count riwayat transaksinya tetap bisa dilihat di Reports.',
    ];
    return parts.join(' ');
  }

  bool _inMonth(DateTime d) => d.year == _month.year && d.month == _month.month;

  List<FlowTransaction> get monthTransactions {
    final list = _tx.where((t) => _inMonth(t.date)).toList()
      ..sort((a, b) {
        final c = b.date.compareTo(a.date);
        return c != 0 ? c : b.id.compareTo(a.id);
      });
    return list;
  }

  int get monthIncome => _sum(monthTransactions, TxType.income);
  int get monthExpense => _sum(monthTransactions, TxType.expense);

  static int _sum(Iterable<FlowTransaction> l, TxType type) =>
      l.where((t) => t.type == type).fold<int>(0, (s, t) => s + t.amount);

  ({DateTime start, DateTime end}) _range(Period p) {
    switch (p) {
      case Period.weekly:
        final now = DateTime.now();
        final anchor = (_month.year == now.year && _month.month == now.month)
            ? DateTime(now.year, now.month, now.day)
            : _month;
        final start =
            DateTime(anchor.year, anchor.month, anchor.day - (anchor.weekday - 1));
        return (start: start, end: DateTime(start.year, start.month, start.day + 7));
      case Period.monthly:
        return (start: _month, end: DateTime(_month.year, _month.month + 1));
      case Period.yearly:
        return (start: DateTime(_month.year), end: DateTime(_month.year + 1));
    }
  }

  List<FlowTransaction> _inPeriod(Period p) {
    final r = _range(p);
    return _tx
        .where((t) => !t.date.isBefore(r.start) && t.date.isBefore(r.end))
        .toList();
  }

  int incomeOf(Period p) => _sum(_inPeriod(p), TxType.income);
  int expenseOf(Period p) => _sum(_inPeriod(p), TxType.expense);

  String periodLabel(Period p) {
    final r = _range(p);
    switch (p) {
      case Period.weekly:
        final last = DateTime(r.end.year, r.end.month, r.end.day - 1);
        return '${Fmt.dayMonth(r.start)} – ${Fmt.dayMonth(last)} ${last.year}';
      case Period.monthly:
        return Fmt.monthYear(_month);
      case Period.yearly:
        return '${_month.year}';
    }
  }

  int _bucket(Period p, DateTime d) {
    switch (p) {
      case Period.weekly:
        return d.weekday - 1;
      case Period.monthly:
        return ((d.day - 1) ~/ 7).clamp(0, 4);
      case Period.yearly:
        return d.month - 1;
    }
  }

  /// Titik yang dipilih awalnya (hari/minggu/bulan ini kalau ada di rentang).
  int defaultIndex(Period p) {
    final now = DateTime.now();
    final current = _month.year == now.year && _month.month == now.month;
    switch (p) {
      case Period.weekly:
        return current ? now.weekday - 1 : 0;
      case Period.monthly:
        return current ? _bucket(p, now) : 0;
      case Period.yearly:
        return current ? now.month - 1 : _month.month - 1;
    }
  }

  List<CashPoint> cashflow(Period p) {
    final n = switch (p) {
      Period.weekly => 7,
      Period.monthly => 5,
      Period.yearly => 12,
    };
    final inc = List<int>.filled(n, 0);
    final exp = List<int>.filled(n, 0);
    for (final t in _inPeriod(p)) {
      final i = _bucket(p, t.date);
      if (t.type == TxType.income) {
        inc[i] += t.amount;
      } else {
        exp[i] += t.amount;
      }
    }
    return List.generate(n, (i) {
      final (short, full) = switch (p) {
        Period.weekly => (Fmt.dayShort(i + 1), Fmt.dayName(i + 1)),
        Period.monthly => ('Minggu ${i + 1}', 'Minggu ${i + 1}'),
        Period.yearly => (Fmt.monthShort(i + 1), Fmt.monthName(i + 1)),
      };
      return CashPoint(short, full, inc[i], exp[i]);
    });
  }

  /// Pengeluaran per kategori, terbesar dulu. Maksimal [maxSlices] kotak:
  /// sisa di luar (maxSlices - 1) teratas digabung jadi "Lain-lain" supaya kotak tidak terlalu kecil.
  List<CategorySlice> expenseSlices(Period p, {int maxSlices = 5}) {
    final totals = <String, int>{};
    for (final t in _inPeriod(p)) {
      if (t.type != TxType.expense) continue;
      totals[t.category.name] = (totals[t.category.name] ?? 0) + t.amount;
    }
    final grand = totals.values.fold<int>(0, (s, v) => s + v);
    if (grand == 0) return const [];

    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (entries.length <= maxSlices) {
      return entries
          .map((e) => CategorySlice(e.key, e.value, e.value / grand))
          .toList();
    }
    final head = entries.take(maxSlices - 1).toList();
    final tail = entries.skip(maxSlices - 1).toList();
    final restTotal = tail.fold<int>(0, (s, e) => s + e.value);
    return [
      for (final e in head) CategorySlice(e.key, e.value, e.value / grand),
      CategorySlice(
        'Lain-lain',
        restTotal,
        restTotal / grand,
        members: [for (final e in tail) e.key],
      ),
    ];
  }

  /// Transaksi bulan terpilih, opsional difilter nama kategori / tipe.
  List<FlowTransaction> transactions({
    String? category,
    Set<String>? categories,
    TxType? type,
  }) {
    return monthTransactions.where((t) {
      if (type != null && t.type != type) return false;
      if (categories != null && !categories.contains(t.category.name)) {
        return false;
      }
      if (category != null && t.category.name != category) return false;
      return true;
    }).toList();
  }

  // ----------------------------------------------------------------- demo

  void _seed() {
    _wallets.addAll(const [
      Wallet('Tunai', WalletType.tunai, 500000),
      Wallet('BCA', WalletType.bank, 2000000),
      Wallet('DANA', WalletType.ewallet, 300000),
    ]);
    final n = DateTime.now();
    final base = DateTime(n.year, n.month, n.day, 12);
    void add(TxCategory c, int amt, String w, int minutes) {
      _tx.add(FlowTransaction(
        id: _nextId++,
        title: c.name,
        category: c,
        wallet: w,
        amount: amt,
        type: TxType.expense,
        date: base.add(Duration(minutes: minutes)),
      ));
    }

    add(TxCategory.belanja, 250000, 'BCA', 0);
    add(TxCategory.makanan, 25000, 'DANA', 1);
    add(TxCategory.transportasi, 50000, 'BCA', 2);
    add(TxCategory.hiburan, 100000, 'Tunai', 3);
    add(TxCategory.transportasi, 58000, 'Tunai', 4);
  }
}