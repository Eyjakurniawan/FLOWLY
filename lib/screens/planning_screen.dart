import 'package:flutter/material.dart';

import '../utils/helpers.dart';

import '../services/finance_store.dart';
import '../services/planning_store.dart';
import '../widgets/finance/home_header.dart';
import '../widgets/finance/planning_sheets.dart';
import '../widgets/finance/planning_widgets.dart';

/// Halaman Planning (dibuka dari kartu Planning di Home).
class PlanningScreen extends StatelessWidget {
  const PlanningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final plans = PlanningStore.instance;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          // FinanceStore ikut didengar supaya mode "sembunyikan saldo" bekerja.
          listenable: Listenable.merge([plans, FinanceStore.instance]),
          builder: (context, _) {
            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: HomeHeader(),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(16, 10, 16, Helpers.navClearance(context)),
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.of(context).maybePop(),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.chevron_left_rounded,
                                  size: 28),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text('Rencana',
                              style: TextStyle(
                                  fontSize: 28, fontWeight: FontWeight.w800)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (!plans.isEmpty) ...[
                        const PlanningMascotBubble(),
                        const SizedBox(height: 14),
                      ],
                      const PlanningTotalCard(),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: PlanningActionButton(
                              label: '+ Buat rencana',
                              filled: true,
                              onTap: () => showCreatePlanningSheet(context),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: PlanningActionButton(
                              label: 'Kalkulator tabungan',
                              onTap: () => showSavingsCalculatorSheet(context),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (plans.isEmpty)
                        const PlanningEmptyState()
                      else
                        for (final p in plans.sortedPlans) ...[
                          PlanningItemCard(
                            plan: p,
                            onTap: () => showPlanningDetailSheet(context, p.id),
                          ),
                          const SizedBox(height: 14),
                        ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}