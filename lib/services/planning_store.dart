import 'package:flutter/foundation.dart';

import '../models/planning_models.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import 'app_data.dart';
import 'notification_store.dart';

/// Sumber data rencana, tersimpan di Supabase (tabel `planning` dan
/// `planning_deposits`). Tampilan diperbarui langsung, lalu disimpan ke
/// server di latar belakang.
class PlanningStore extends ChangeNotifier {
  PlanningStore._();
  static final PlanningStore instance = PlanningStore._();

  final List<Planning> _plans = [];
  int _nextId = 1;
  int _nextDepositId = 1;

  /// Id database tiap rencana / setoran (bisa belum selesai disimpan).
  final Map<int, Future<String?>> _planIds = {};
  final Map<int, Future<String?>> _depIds = {};

  List<Planning> get plans => List.unmodifiable(_plans);
  bool get isEmpty => _plans.isEmpty;

  int get activeCount => _plans.where((p) => !p.isDone).length;
  int get doneCount => _plans.where((p) => p.isDone).length;
  /// Rencana yang belum selesai lebih dulu, yang sudah 100% di paling bawah
  /// (urutan di dalam tiap kelompok tetap).
  List<Planning> get sortedPlans => [
        ..._plans.where((p) => !p.isDone),
        ..._plans.where((p) => p.isDone),
      ];

  /// Ringkasan hanya dari rencana yang belum selesai (dipakai di Beranda).
  int get activeSaved =>
      _plans.where((p) => !p.isDone).fold<int>(0, (s, p) => s + p.saved);
  int get activeBudget =>
      _plans.where((p) => !p.isDone).fold<int>(0, (s, p) => s + p.budget);
  double get activeProgress {
    if (activeBudget <= 0) return 0;
    final v = activeSaved / activeBudget;
    return v > 1 ? 1.0 : v;
  }

  int get totalSaved => _plans.fold<int>(0, (s, p) => s + p.saved);
  int get totalBudget => _plans.fold<int>(0, (s, p) => s + p.budget);

  double get progress {
    if (totalBudget <= 0) return 0;
    final p = totalSaved / totalBudget;
    return p > 1 ? 1.0 : p;
  }

  int get percent {
    if (totalBudget <= 0) return 0;
    return totalSaved * 100 ~/ totalBudget;
  }

  Planning? byId(int id) {
    for (final p in _plans) {
      if (p.id == id) return p;
    }
    return null;
  }

  static DateTime _dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

  // ---------------------------------------------------------- Supabase

  void reset() {
    _plans.clear();
    _planIds.clear();
    _depIds.clear();
    _nextId = 1;
    _nextDepositId = 1;
    notifyListeners();
  }

  static PlanFrequency _freqOf(String? s) => PlanFrequency.values.firstWhere(
        (f) => f.name == s,
        orElse: () => PlanFrequency.monthly,
      );

  Future<void> loadRemote() async {
    final pRows = await AppData.fetchAll('planning');
    final dRows = await AppData.fetchAll('planning_deposits');
    final byPlan = <String, List<Map<String, dynamic>>>{};
    for (final d in dRows) {
      byPlan.putIfAbsent(d['planning_id'] as String, () => []).add(d);
    }

    _plans.clear();
    _planIds.clear();
    _depIds.clear();
    _nextId = 1;
    _nextDepositId = 1;
    final today = _dayOf(DateTime.now());

    for (final r in pRows) {
      final remoteId = r['id'] as String;
      final pid = _nextId++;
      final deps = <PlanDeposit>[];
      final rows = byPlan[remoteId] ?? <Map<String, dynamic>>[];
      for (final d in rows) {
        final did = _nextDepositId++;
        _depIds[did] = Future<String?>.value(d['id'] as String);
        deps.add(PlanDeposit(
          id: did,
          amount: AppData.toInt(d['amount']),
          date: AppData.parseDate(d['deposit_date']) ?? today,
          isInitial: d['is_initial'] == true,
        ));
      }
      _plans.add(Planning(
        id: pid,
        name: r['name'] as String,
        category: (r['category'] as String?) ?? 'Lainnya',
        budget: AppData.toInt(r['target_amount']),
        saved: deps.fold<int>(0, (s, d) => s + d.amount),
        target: AppData.parseDate(r['target_date']) ?? today,
        frequency: _freqOf(r['frequency'] as String?),
        allocation: AppData.toInt(r['monthly_allocation']),
        deposits: deps,
      ));
      _planIds[pid] = Future<String?>.value(remoteId);
    }
    notifyListeners();
  }

  Future<String?> _insertDeposit(
    String planId,
    int amount,
    DateTime date, {
    bool initial = false,
  }) =>
      AppData.guard<String>(() async {
        final row = await AppData.db
            .from('planning_deposits')
            .insert({
              'user_id': AppData.uid,
              'planning_id': planId,
              'amount': amount,
              'deposit_date': AppData.dateStr(date),
              'is_initial': initial,
            })
            .select('id')
            .single();
        return row['id'] as String;
      }, message: 'Setoran gagal disimpan. Coba lagi.');

  /// Samakan kolom dana terkumpul di database dengan nilai sekarang.
  void _pushCollected(int planId) {
    final p = byId(planId);
    final fut = _planIds[planId];
    if (p == null || fut == null) return;
    final saved = p.saved;
    fut.then((rid) async {
      if (rid == null) return;
      await AppData.run(
        () => AppData.db
            .from('planning')
            .update({'collected_amount': saved}).eq('id', rid),
        message: 'Dana terkumpul gagal disimpan.',
      );
    });
  }

  // ------------------------------------------------------------- aksi

  void add({
    required String name,
    required String category,
    required int budget,
    required int saved,
    required DateTime target,
    required PlanFrequency frequency,
    required int allocation,
  }) {
    final start = saved > budget ? budget : saved;
    final pid = _nextId++;
    final today = _dayOf(DateTime.now());
    final n = name.trim();
    final did = start > 0 ? _nextDepositId++ : 0;
    _plans.add(Planning(
      id: pid,
      name: n,
      category: category,
      budget: budget,
      saved: start,
      target: target,
      frequency: frequency,
      allocation: allocation,
      deposits: start > 0
          ? [
              PlanDeposit(
                id: did,
                amount: start,
                date: today,
                isInitial: true,
              ),
            ]
          : const [],
    ));

    NotificationStore.instance.push(
      title: 'Rencana dibuat',
      body: 'Rencana "$n" dengan target ${Fmt.rupiah(budget)} berhasil dibuat.',
      action: NotificationAction.openPlanning,
      mood: MascotExpression.happy,
    );

    final planFut = AppData.guard<String>(() async {
      final row = await AppData.db
          .from('planning')
          .insert({
            'user_id': AppData.uid,
            'name': n,
            'category': category,
            'target_amount': budget,
            'collected_amount': start,
            'target_date': AppData.dateStr(target),
            'frequency': frequency.name,
            'monthly_allocation': allocation,
          })
          .select('id')
          .single();
      return row['id'] as String;
    }, message: 'Rencana gagal disimpan, jadi dibatalkan. Coba lagi.');
    _planIds[pid] = planFut;
    if (start > 0) {
      _depIds[did] = planFut.then((rid) async {
        if (rid == null) return null;
        return _insertDeposit(rid, start, today, initial: true);
      });
    }
    planFut.then((rid) {
      if (rid == null) {
        _plans.removeWhere((p) => p.id == pid);
        _planIds.remove(pid);
        notifyListeners();
      }
    });

    notifyListeners();
  }

  /// Ubah data rencana. Dana terkumpul & riwayat setoran tidak berubah.
  void update(
    int id, {
    required String name,
    required String category,
    required int budget,
    required DateTime target,
    required PlanFrequency frequency,
    required int allocation,
  }) {
    final i = _plans.indexWhere((p) => p.id == id);
    if (i < 0) return;
    final p = _plans[i];
    final n = name.trim();
    NotificationStore.instance.push(
      title: 'Rencana diperbarui',
      body: 'Rencana "$n" berhasil diubah.',
      action: NotificationAction.openPlanning,
      mood: MascotExpression.wink,
    );
    _plans[i] = p.copyWith(
      name: n,
      category: category,
      budget: budget,
      target: target,
      frequency: frequency,
      allocation: allocation,
    );
    if (!p.isDone && _plans[i].isDone) {
      NotificationStore.instance.push(
        title: 'Target tercapai',
        body: 'Selamat! Rencana "$n" sudah mencapai target '
            '${Fmt.rupiah(budget)}.',
        action: NotificationAction.openPlanning,
        mood: MascotExpression.happy,
      );
    }
    _planIds[id]?.then((rid) async {
      if (rid == null) return;
      await AppData.run(
        () => AppData.db.from('planning').update({
          'name': n,
          'category': category,
          'target_amount': budget,
          'target_date': AppData.dateStr(target),
          'frequency': frequency.name,
          'monthly_allocation': allocation,
        }).eq('id', rid),
        message: 'Perubahan rencana gagal disimpan.',
      );
    });
    notifyListeners();
  }

  /// Catat setoran (tidak melebihi sisa target). [date] default hari ini.
  void deposit(int id, int amount, {DateTime? date}) {
    final i = _plans.indexWhere((p) => p.id == id);
    if (i < 0 || amount <= 0) return;
    final p = _plans[i];
    final room = p.budget - p.saved;
    if (room <= 0) return;
    final real = amount > room ? room : amount;
    final day = _dayOf(date ?? DateTime.now());
    final did = _nextDepositId++;
    _plans[i] = p.copyWith(
      saved: p.saved + real,
      deposits: [
        ...p.deposits,
        PlanDeposit(id: did, amount: real, date: day),
      ],
    );
    final planFut = _planIds[id];
    if (planFut != null) {
      _depIds[did] = planFut.then((rid) async {
        if (rid == null) return null;
        return _insertDeposit(rid, real, day);
      });
    }
    _pushCollected(id);
    if (_plans[i].isDone) {
      NotificationStore.instance.push(
        title: 'Target tercapai',
        body: 'Selamat! Rencana "${p.name}" sudah mencapai target '
            '${Fmt.rupiah(p.budget)}.',
        action: NotificationAction.openPlanning,
        mood: MascotExpression.happy,
      );
    }
    notifyListeners();
  }

  /// Hapus satu setoran; dana terkumpul ikut berkurang.
  void removeDeposit(int planId, int depositId) {
    final i = _plans.indexWhere((p) => p.id == planId);
    if (i < 0) return;
    final p = _plans[i];
    final left = p.deposits.where((d) => d.id != depositId).toList();
    final saved = left.fold<int>(0, (s, d) => s + d.amount);
    _plans[i] = p.copyWith(saved: saved, deposits: left);
    _depIds.remove(depositId)?.then((did) async {
      if (did == null) return;
      await AppData.run(
        () => AppData.db.from('planning_deposits').delete().eq('id', did),
        message: 'Setoran gagal dihapus di server.',
      );
    });
    _pushCollected(planId);
    notifyListeners();
  }

  void remove(int id) {
    final gone = byId(id);
    if (gone != null) {
      NotificationStore.instance.push(
        title: 'Rencana dihapus',
        body: 'Rencana "${gone.name}" beserta riwayat setorannya sudah dihapus.',
        action: NotificationAction.openPlanning,
      );
    }
    _plans.removeWhere((p) => p.id == id);
    _planIds.remove(id)?.then((rid) async {
      if (rid == null) return;
      await AppData.run(
        () => AppData.db.from('planning').delete().eq('id', rid),
        message: 'Rencana gagal dihapus di server.',
      );
    });
    notifyListeners();
  }
}