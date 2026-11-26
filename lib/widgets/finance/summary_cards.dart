import 'package:flutter/material.dart';

import '../../services/finance_store.dart';
import '../../services/planning_store.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../mascot_view.dart';
import 'common.dart';
import 'water_tank.dart';

/// Kartu navy "Total Balance" + dua tile pemasukan/pengeluaran.
class BalanceCard extends StatelessWidget {
  final VoidCallback? onTap;

  /// Ketuk tile Pemasukan / Pengeluaran (mis. buka tab Reports).
  final VoidCallback? onTapIncome;
  final VoidCallback? onTapExpense;
  const BalanceCard({
    super.key,
    this.onTap,
    this.onTapIncome,
    this.onTapExpense,
  });

  @override
  Widget build(BuildContext context) {
    final store = FinanceStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        return GestureDetector(
          onTap: onTap,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF16358F), AppColors.navyBottom],
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33122B5E),
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Air di belakang isi kartu; tinggi mengikuti saldo.
                Positioned.fill(
                  child: IgnorePointer(
                    child: WaterTank(level: tankLevel(store)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 96),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Total Saldo',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 14)),
                                const SizedBox(height: 4),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    store.money(store.totalBalance),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 38,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Container(
                                      width: 7,
                                      height: 7,
                                      decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Flexible(
                                      child: Text('Total dari semua dompet',
                                          style: TextStyle(
                                              color: Colors.white, fontSize: 13)),
                                    ),
                                  ],
                                ),
                                if (!store.hasWallets) ...[
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Belum ada dompet. Tambahkan di tab Dompet.',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 12),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const Positioned(
                            right: 0,
                            top: 0,
                            child: Icon(Icons.chevron_right_rounded,
                                color: Colors.white70),
                          ),
                          const Positioned(
                            right: 4,
                            top: 8,
                            child: MascotView(
                              size: 84,
                              expression: MascotExpression.wink,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _FlowTile(
                              icon: Icons.south_west_rounded,
                              label: 'Pemasukan',
                              amount: store.money(store.monthIncome),
                              tint: const Color(0x332563EB),
                              onTap: onTapIncome,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _FlowTile(
                              icon: Icons.north_east_rounded,
                              label: 'Pengeluaran',
                              amount: store.money(store.monthExpense),
                              tint: const Color(0x33E8472B),
                              onTap: onTapExpense,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FlowTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String amount;
  final Color tint;
  final VoidCallback? onTap;
  const _FlowTile({
    required this.icon,
    required this.label,
    required this.amount,
    required this.tint,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: _content(),
    );
  }

  Widget _content() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: Colors.white),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(color: Colors.white, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tampil saat belum ada transaksi di bulan terpilih.
class EmptyLedgerCard extends StatelessWidget {
  const EmptyLedgerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const FlowlyCard(
      padding: EdgeInsets.fromLTRB(24, 22, 24, 26),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            MascotView(size: 130, expression: MascotExpression.coin),
            SizedBox(height: 10),
            Text('Yuk catat yang pertama!',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            SizedBox(height: 6),
            Text(
              'Tekan tombol + di bawah untuk mencatat pemasukan atau pengeluaran pertamamu.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: AppColors.textGrey),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kartu Planning di Home. Kosong = ajakan membuat, terisi = ringkasan.
class PlanningCard extends StatelessWidget {
  final VoidCallback? onTap;
  const PlanningCard({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final plans = PlanningStore.instance;
    final fin = FinanceStore.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([plans, fin]),
      builder: (context, _) {
        final empty = plans.isEmpty;
        final title = empty
            ? 'Belum ada rencana'
            : (plans.activeCount > 0
                ? '${plans.activeCount} rencana aktif'
                : 'Semua rencana tercapai');
        final subtitle = empty
            ? 'Buat target tabungan pertama kamu'
            : (plans.activeCount > 0
                ? '${fin.money(plans.activeSaved)} terkumpul dari ${fin.money(plans.activeBudget)}'
                : '${fin.money(plans.totalSaved)} terkumpul dari ${fin.money(plans.totalBudget)}');

        return FlowlyCard(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Rencana',
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
                  value: empty
                      ? 0
                      : (plans.activeCount > 0
                          ? plans.activeProgress
                          : plans.progress),
                  minHeight: 8,
                  backgroundColor: const Color(0xFFE3EAFB),
                  color: AppColors.link,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}