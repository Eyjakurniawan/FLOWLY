import 'package:flutter/material.dart';

import '../../models/budget_models.dart';
import '../../services/budget_store.dart';
import '../../services/finance_store.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../mascot_view.dart';
import 'common.dart';

/// Warna batang progres: biru aman, kuning mendekati batas, merah lewat.
Color budgetColor(BudgetLevel level) => switch (level) {
      BudgetLevel.safe => AppColors.link,
      BudgetLevel.warning => AppColors.medium,
      BudgetLevel.over => AppColors.primary,
    };

class _Bar extends StatelessWidget {
  final double value;
  final Color color;
  const _Bar(this.value, {this.color = AppColors.link});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(
        value: value,
        minHeight: 10,
        backgroundColor: const Color(0xFFE3EAFB),
        color: color,
      ),
    );
  }
}

/// Kartu Anggaran di Beranda. Kosong = ajakan membuat, terisi = ringkasan
/// bulan ini.
class BudgetCard extends StatelessWidget {
  final VoidCallback? onTap;
  const BudgetCard({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final budgets = BudgetStore.instance;
    final fin = FinanceStore.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([budgets, fin]),
      builder: (context, _) {
        final s = budgets.summaryFor(DateTime.now());
        final empty = s.isEmpty;
        final title =
            empty ? 'Belum ada anggaran' : '${s.items.length} anggaran aktif';
        final subtitle = empty
            ? 'Batasi belanja kopi, nongkrong, dan lainnya'
            : '${fin.money(s.totalSpent)} terpakai dari ${fin.money(s.totalLimit)}';

        return FlowlyCard(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Anggaran bulan ini',
                  style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
              const SizedBox(height: 2),
              Row(
                children: [
                  Expanded(
                    child: Text(title,
                        style: const TextStyle(
                            fontSize: 21, fontWeight: FontWeight.w800)),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 12.5, color: AppColors.textGrey)),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: empty ? 0 : s.progress,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFE3EAFB),
                  color: budgetColor(s.level),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Pil bulan "Riwayat per bulan". Diketuk membuka sheet "Pilih bulan" yang
/// sama dengan di Laporan.
class BudgetMonthPill extends StatelessWidget {
  final DateTime selected;
  final VoidCallback onTap;
  const BudgetMonthPill({
    super.key,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(Fmt.monthYear(selected),
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
          ],
        ),
      ),
    );
  }
}

/// Kartu besar di atas daftar: "Aman dipakai per hari" (bulan ini) atau
/// sisa anggaran (bulan lalu).
class BudgetSummaryCard extends StatelessWidget {
  final BudgetMonthSummary summary;
  final bool isCurrent;
  const BudgetSummaryCard({
    super.key,
    required this.summary,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    final fin = FinanceStore.instance;
    final s = summary;
    final now = DateTime.now();

    final label = isCurrent ? 'Aman dipakai per hari' : 'Sisa anggaran bulan itu';
    final big = isCurrent ? s.safePerDay(now) : s.totalRoom;

    String sub;
    if (s.isEmpty) {
      sub = 'Belum ada anggaran';
    } else if (isCurrent) {
      sub = '${fin.money(s.totalSpent)} terpakai dari ${fin.money(s.totalLimit)}'
          ' • ${s.daysLeft(now)} hari tersisa bulan ini';
    } else {
      sub = 'Terpakai ${fin.money(s.totalSpent)} dari ${fin.money(s.totalLimit)}';
    }

    return FlowlyCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 12.5, color: AppColors.textGrey)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              fin.money(big),
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 2),
          Text(sub,
              style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
          const SizedBox(height: 12),
          _Bar(s.isEmpty ? 0 : s.progress, color: budgetColor(s.level)),
        ],
      ),
    );
  }
}

/// Tampilan saat belum ada anggaran.
class BudgetEmptyState extends StatelessWidget {
  final bool isCurrent;
  const BudgetEmptyState({super.key, this.isCurrent = true});

  static const _style = TextStyle(fontSize: 12.5, color: AppColors.textGrey);

  /// Satu baris yang mengecil sendiri kalau layar terlalu sempit, supaya
  /// teksnya selalu rapi dua baris memanjang ke samping.
  Widget _line(String text) => SizedBox(
        width: double.infinity,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(text, textAlign: TextAlign.center, style: _style),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 0),
      child: Column(
        children: [
          const MascotView(size: 160, expression: MascotExpression.flag),
          const SizedBox(height: 8),
          Text(isCurrent ? 'Belum ada anggaran' : 'Tidak ada anggaran',
              style:
                  const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          if (isCurrent) ...[
            _line('Pasang batas bulanan untuk pos yang gampang bocor, '
                'misalnya kopi'),
            const SizedBox(height: 2),
            _line('atau nongkrong. Aku bantu jaga supaya tidak overbudget.'),
          ] else
            _line('Tidak ada anggaran yang berlaku di bulan ini.'),
        ],
      ),
    );
  }
}

/// Kalimat maskot di atas kartu ringkasan, menyesuaikan kondisi anggaran.
String budgetTipText(BudgetMonthSummary s, bool isCurrent) {
  final fin = FinanceStore.instance;
  BudgetUsage? over;
  BudgetUsage? warn;
  for (final u in s.items) {
    if (u.isOver) over ??= u;
    if (u.level == BudgetLevel.warning) warn ??= u;
  }
  if (isCurrent) {
    if (over != null) {
      return '${over.budget.category.name} sudah lewat batas '
          '${fin.money(-over.remaining)}. Tidak apa-apa, rem dulu ya sampai '
          'bulan depan.';
    }
    if (warn != null) {
      return '${warn.budget.category.name} sudah ${warn.percent}% dari batas. '
          'Pelan-pelan ya, sisa ${fin.money(warn.room)}.';
    }
    return 'Semua anggaran masih aman. Pertahankan ya!';
  }
  if (over != null) {
    return 'Di bulan ini ${over.budget.category.name} melewati batas '
        '${fin.money(-over.remaining)}.';
  }
  return 'Semua anggaran di bulan ini terkendali. Mantap!';
}

/// Maskot + balon ucapan di atas kartu ringkasan.
class BudgetMascotBubble extends StatelessWidget {
  final BudgetMonthSummary summary;
  final bool isCurrent;
  const BudgetMascotBubble({
    super.key,
    required this.summary,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    final calm = summary.level == BudgetLevel.safe;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        MascotView(
          size: 76,
          expression: calm ? MascotExpression.happy : MascotExpression.normal,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Text(
              budgetTipText(summary, isCurrent),
              style: const TextStyle(fontSize: 13.5, height: 1.35),
            ),
          ),
        ),
      ],
    );
  }
}

/// Kartu satu anggaran.
class BudgetItemCard extends StatelessWidget {
  final BudgetUsage usage;
  final DateTime month;
  final bool isCurrent;
  final VoidCallback? onTap;
  const BudgetItemCard({
    super.key,
    required this.usage,
    required this.month,
    required this.isCurrent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fin = FinanceStore.instance;
    final u = usage;
    final color = budgetColor(u.level);

    String status;
    if (u.isOver) {
      status = 'Lewat ${fin.money(-u.remaining)} dari batas';
    } else if (isCurrent) {
      final perDay = u.room ~/ daysLeftInMonth();
      status = 'Sisa ${fin.money(u.remaining)} • aman ${fin.money(perDay)}/hari';
    } else {
      status = 'Sisa ${fin.money(u.remaining)}';
    }

    return FlowlyCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 14, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const MascotView(size: 48),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: u.budget.category.color,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(u.budget.category.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('Bulanan • ${Fmt.monthYear(month)}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textGrey)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text('${u.percent}%',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: u.isOver ? AppColors.primary : AppColors.textDark)),
            ],
          ),
          const SizedBox(height: 10),
          _Bar(u.progress, color: color),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(fin.money(u.spent),
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(width: 8),
              Text('dari ${fin.money(u.limit)}',
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.textGrey)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            status,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: u.isOver ? FontWeight.w700 : FontWeight.w500,
              color: u.isOver ? AppColors.primary : AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}