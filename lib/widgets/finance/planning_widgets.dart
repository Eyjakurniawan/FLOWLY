import 'package:flutter/material.dart';

import '../../models/planning_models.dart';
import '../../services/finance_store.dart';
import '../../services/planning_store.dart';
import '../../utils/app_colors.dart';
import '../../utils/formatters.dart';
import '../mascot_view.dart';
import 'common.dart';

class _Bar extends StatelessWidget {
  final double value;
  const _Bar(this.value);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(
        value: value,
        minHeight: 10,
        backgroundColor: const Color(0xFFE3EAFB),
        color: AppColors.link,
      ),
    );
  }
}

/// Maskot + balon ucapan di atas kartu total.
class PlanningMascotBubble extends StatelessWidget {
  const PlanningMascotBubble({super.key});

  @override
  Widget build(BuildContext context) {
    final plans = PlanningStore.instance;
    final text = plans.activeCount == 0
        ? 'Semua rencana sudah tercapai. Hebat!'
        : '${plans.activeCount} rencana berjalan, ${plans.percent}% menuju target. Setor rutin ya!';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const MascotView(size: 76),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Text(text,
                style: const TextStyle(fontSize: 13.5, height: 1.35)),
          ),
        ),
      ],
    );
  }
}

/// Kartu "Total terkumpul" di atas daftar planning.
class PlanningTotalCard extends StatelessWidget {
  const PlanningTotalCard({super.key});

  @override
  Widget build(BuildContext context) {
    final plans = PlanningStore.instance;
    final fin = FinanceStore.instance;
    // Dengar store sendiri: kartu ini dipanggil dengan `const`, jadi tanpa
    // ini angkanya tidak ikut berubah saat mode sembunyikan saldo diubah.
    return ListenableBuilder(
      listenable: Listenable.merge([plans, fin]),
      builder: (context, _) => _buildCard(plans, fin),
    );
  }

  Widget _buildCard(PlanningStore plans, FinanceStore fin) {
    return FlowlyCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total terkumpul',
              style: TextStyle(fontSize: 12.5, color: AppColors.textGrey)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              fin.money(plans.totalSaved),
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            plans.isEmpty
                ? 'Belum ada rencana'
                : '${plans.activeCount} aktif • ${plans.doneCount} tercapai • ${plans.percent}% dari target ${fin.moneyCompact(plans.totalBudget)}',
            style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
          ),
          const SizedBox(height: 12),
          _Bar(plans.progress),
        ],
      ),
    );
  }
}

/// Tombol "+ Buat planning" (oranye) dan "Kalkulator tabungan" (garis).
class PlanningActionButton extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback onTap;
  const PlanningActionButton({
    super.key,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final shape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(18));
    final text = FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(label,
          maxLines: 1,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
    );
    return SizedBox(
      height: 54,
      child: filled
          ? ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textDark,
                elevation: 0,
                shape: shape,
              ),
              child: text,
            )
          : OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textDark,
                side: const BorderSide(color: AppColors.border, width: 1.2),
                shape: shape,
              ),
              child: text,
            ),
    );
  }
}

/// Tampilan saat belum ada planning.
class PlanningEmptyState extends StatelessWidget {
  const PlanningEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(28, 24, 28, 0),
      child: Column(
        children: [
          MascotView(size: 150),
          SizedBox(height: 10),
          Text('Belum ada rencana',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          SizedBox(height: 6),
          Text(
            'Mulai dari satu target kecil, misalnya dana darurat. Aku bantu pantau progresnya.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: AppColors.textGrey),
          ),
        ],
      ),
    );
  }
}

/// Kartu satu planning.
class PlanningItemCard extends StatelessWidget {
  final Planning plan;
  final VoidCallback onTap;
  const PlanningItemCard({super.key, required this.plan, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fin = FinanceStore.instance;
    final t = plan.target;
    final targetText = '${t.day} ${Fmt.monthName(t.month)} ${t.year}';
    final unit = plan.frequency.unit;

    return FlowlyCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const MascotView(size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plan.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 16.5, fontWeight: FontWeight.w800)),
                    Text(plan.category,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textGrey)),
                  ],
                ),
              ),
              Text('${plan.percent}%',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 12),
          _Bar(plan.progress),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(fin.money(plan.saved),
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(width: 8),
              Text('dari ${fin.money(plan.budget)}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textGrey)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Target $targetText • Alokasi ${fin.money(plan.suggestion)}/$unit',
            style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
          ),
          const SizedBox(height: 4),
          Text(
            plan.isDone
                ? 'Target tercapai!'
                : 'Sisa ${plan.periodsLeft} $unit sampai target',
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}