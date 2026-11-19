/// Tujuan pengguna (Setup 1). Boleh pilih lebih dari satu.
enum SetupGoal {
  dailyExpense('Catat pengeluaran harian'),
  monthlySaving('Hemat tiap bulan'),
  emergencyFund('Kumpulkan dana darurat'),
  dreamItem('Beli barang impian'),
  payDebt('Lunasi cicilan');

  final String label;
  const SetupGoal(this.label);
}

/// Gaya budget (Setup 3). Pilih satu.
enum BudgetStyle {
  santai('Santai', 'Longgar, aku ingatkan seperlunya'),
  seimbang('Seimbang', 'Sisihkan sebagian untuk tabungan'),
  ketat('Ketat', 'Fokus hemat, aku lebih cerewet');

  final String title;
  final String description;
  const BudgetStyle(this.title, this.description);
}

/// Jam pengingat harian (Setup 4).
enum ReminderTime {
  morning('07.00', 'Pagi'),
  noon('12.00', 'Siang'),
  night('20.00', 'Malam');

  final String time;
  final String period;
  const ReminderTime(this.time, this.period);

  String get label => '$time $period';
}

/// Seluruh jawaban dari alur setup.
class SetupData {
  final Set<SetupGoal> goals;
  final String nickname;
  final BudgetStyle budgetStyle;
  final bool reminderEnabled;
  final ReminderTime reminderTime;

  const SetupData({
    required this.goals,
    required this.nickname,
    required this.budgetStyle,
    required this.reminderEnabled,
    required this.reminderTime,
  });

  /// Bentuk yang disimpan ke user metadata Supabase.
  Map<String, dynamic> toMetadata() => {
        'nickname': nickname.trim(),
        'goals': goals.map((g) => g.name).toList(),
        'budget_style': budgetStyle.name,
        'reminder_enabled': reminderEnabled,
        'reminder_time': reminderEnabled ? reminderTime.time : null,
        'setup_done': true,
      };
}