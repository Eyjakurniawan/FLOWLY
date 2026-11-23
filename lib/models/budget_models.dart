import 'finance_models.dart';

/// Tanggal 1 pada bulan dari [d] (jam 00.00).
DateTime monthStart(DateTime d) => DateTime(d.year, d.month);

/// Sisa hari di bulan [now], termasuk hari ini (minimal 1).
int daysLeftInMonth([DateTime? now]) {
  final n = now ?? DateTime.now();
  final last = DateTime(n.year, n.month + 1, 0).day;
  final left = last - n.day + 1;
  return left < 1 ? 1 : left;
}

/// Satu anggaran: batas pengeluaran per bulan untuk satu kategori.
///
/// Anggaran berlaku berulang tiap bulan sejak [startMonth]. Kalau dihentikan
/// atau batasnya diubah di bulan berikutnya, [endMonth] diisi bulan terakhir
/// anggaran itu berlaku (null = masih berjalan). Dengan begini riwayat bulan
/// lalu tetap menampilkan batas yang dulu berlaku.
class Budget {
  final int id;
  final TxCategory category;
  final int limit;
  final DateTime startMonth;
  final DateTime? endMonth;

  const Budget({
    required this.id,
    required this.category,
    required this.limit,
    required this.startMonth,
    this.endMonth,
  });

  Budget copyWith({TxCategory? category, int? limit, DateTime? endMonth}) =>
      Budget(
        id: id,
        category: category ?? this.category,
        limit: limit ?? this.limit,
        startMonth: startMonth,
        endMonth: endMonth ?? this.endMonth,
      );

  /// Masih berjalan (belum dihentikan).
  bool get isActive => endMonth == null;

  /// true kalau anggaran ini berlaku di bulan [month].
  bool appliesTo(DateTime month) {
    final m = monthStart(month);
    if (m.isBefore(startMonth)) return false;
    final end = endMonth;
    return end == null || !m.isAfter(end);
  }
}

enum BudgetLevel { safe, warning, over }

/// Pemakaian satu anggaran di satu bulan.
class BudgetUsage {
  final Budget budget;
  final int spent;
  const BudgetUsage(this.budget, this.spent);

  int get limit => budget.limit;
  int get remaining => limit - spent;
  bool get isOver => spent > limit;

  /// Sisa yang masih boleh dipakai (tidak pernah negatif).
  int get room => remaining > 0 ? remaining : 0;

  double get ratio => limit <= 0 ? 0 : spent / limit;
  double get progress => ratio > 1 ? 1.0 : ratio;
  int get percent => limit <= 0 ? 0 : spent * 100 ~/ limit;

  BudgetLevel get level {
    if (isOver) return BudgetLevel.over;
    if (limit > 0 && spent * 100 >= limit * 80) return BudgetLevel.warning;
    return BudgetLevel.safe;
  }
}

/// Ringkasan semua anggaran yang berlaku di satu bulan.
class BudgetMonthSummary {
  final DateTime month;
  final List<BudgetUsage> items;
  const BudgetMonthSummary(this.month, this.items);

  bool get isEmpty => items.isEmpty;

  int get totalLimit => items.fold<int>(0, (s, u) => s + u.limit);
  int get totalSpent => items.fold<int>(0, (s, u) => s + u.spent);

  /// Jumlah sisa tiap anggaran. Kelebihan di satu kategori tidak
  /// mengurangi sisa kategori lain.
  int get totalRoom => items.fold<int>(0, (s, u) => s + u.room);

  int get overCount => items.where((u) => u.isOver).length;

  double get progress {
    if (totalLimit <= 0) return 0;
    final p = totalSpent / totalLimit;
    return p > 1 ? 1.0 : p;
  }

  BudgetLevel get level {
    if (items.isEmpty) return BudgetLevel.safe;
    if (overCount > 0 || totalSpent > totalLimit) return BudgetLevel.over;
    if (totalLimit > 0 && totalSpent * 100 >= totalLimit * 80) {
      return BudgetLevel.warning;
    }
    return BudgetLevel.safe;
  }

  /// Sisa hari di bulan ini, termasuk hari [now] (minimal 1).
  int daysLeft(DateTime now) {
    final last = DateTime(month.year, month.month + 1, 0).day;
    final left = last - now.day + 1;
    return left < 1 ? 1 : left;
  }

  /// Batas aman pengeluaran per hari sampai akhir bulan.
  int safePerDay(DateTime now) => totalRoom ~/ daysLeft(now);
}