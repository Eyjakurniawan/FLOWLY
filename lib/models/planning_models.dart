/// Seberapa sering pengguna menyetor ke sebuah planning.
enum PlanFrequency {
  daily('Harian', 'hari', 1),
  weekly('Mingguan', 'minggu', 7),
  monthly('Bulanan', 'bulan', 30);

  final String label;
  final String unit;
  final int days;
  const PlanFrequency(this.label, this.unit, this.days);

  /// Jumlah periode dari hari ini sampai [target] (minimal 1).
  int periodsUntil(DateTime target, [DateTime? now]) {
    final n = now ?? DateTime.now();
    final from = DateTime(n.year, n.month, n.day);
    final to = DateTime(target.year, target.month, target.day);
    final diffDays = (to.difference(from).inHours / 24).round();
    final p = (diffDays / days).ceil();
    return p < 1 ? 1 : p;
  }

  /// Setoran per periode, dibulatkan ke atas ke kelipatan Rp1.000.
  int allocationFor(int remaining, DateTime target) {
    if (remaining <= 0) return 0;
    final raw = (remaining / periodsUntil(target)).ceil();
    return ((raw + 999) ~/ 1000) * 1000;
  }
}

/// Satu catatan setoran di riwayat sebuah planning.
class PlanDeposit {
  final int id;
  final int amount;
  final DateTime date; // hanya tanggal (jam 00.00)
  final bool isInitial; // true = "Terkumpul awal" saat planning dibuat

  const PlanDeposit({
    required this.id,
    required this.amount,
    required this.date,
    this.isInitial = false,
  });
}

class Planning {
  static const categories = [
    'Kendaraan',
    'Liburan',
    'Gadget',
    'Rumah',
    'Pendidikan',
    'Dana darurat',
    'Lainnya',
  ];

  final int id;
  final String name;
  final String category;
  final int budget; // target dana
  final int saved; // sudah terkumpul (jumlah semua setoran)
  final DateTime target; // target selesai
  final PlanFrequency frequency;
  final int allocation; // nominal setoran per periode (diisi pengguna)
  final List<PlanDeposit> deposits; // urut sesuai waktu dicatat

  const Planning({
    required this.id,
    required this.name,
    required this.category,
    required this.budget,
    required this.saved,
    required this.target,
    required this.frequency,
    required this.allocation,
    this.deposits = const [],
  });

  Planning copyWith({
    String? name,
    String? category,
    int? budget,
    int? saved,
    DateTime? target,
    PlanFrequency? frequency,
    int? allocation,
    List<PlanDeposit>? deposits,
  }) =>
      Planning(
        id: id,
        name: name ?? this.name,
        category: category ?? this.category,
        budget: budget ?? this.budget,
        saved: saved ?? this.saved,
        target: target ?? this.target,
        frequency: frequency ?? this.frequency,
        allocation: allocation ?? this.allocation,
        deposits: deposits ?? this.deposits,
      );

  int get remaining => budget > saved ? budget - saved : 0;
  bool get isDone => saved >= budget;

  double get progress {
    if (budget <= 0) return 0;
    final p = saved / budget;
    return p > 1 ? 1.0 : p;
  }

  int get percent {
    if (budget <= 0) return 0;
    final p = saved * 100 ~/ budget;
    return p > 100 ? 100 : p;
  }

  /// Sisa periode setoran sampai target tercapai.
  int get periodsLeft =>
      allocation <= 0 ? 0 : (remaining / allocation).ceil();
}