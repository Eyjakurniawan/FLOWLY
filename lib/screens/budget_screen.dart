import 'package:flutter/material.dart';

import '../utils/helpers.dart';

import '../models/budget_models.dart';
import '../services/budget_store.dart';
import '../services/finance_store.dart';
import '../widgets/finance/budget_sheets.dart';
import '../widgets/finance/budget_widgets.dart';
import '../widgets/finance/common.dart';
import '../widgets/finance/home_header.dart';
import '../widgets/finance/planning_widgets.dart';

/// Halaman Anggaran (dibuka dari kartu Anggaran di Beranda).
class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  DateTime _month = monthStart(DateTime.now());

  /// Sheet "Pilih bulan" yang sama dengan di Laporan. Bulan yang dipilih
  /// hanya berlaku di halaman ini (tidak mengubah bulan di Beranda).
  Future<void> _pickMonth() async {
    final picked = await showMonthPickerSheet(context, _month);
    if (picked != null && mounted) {
      setState(() => _month = monthStart(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = BudgetStore.instance;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          // FinanceStore ikut didengar: pengeluaran baru mengubah pemakaian,
          // dan mode "sembunyikan saldo" ikut bekerja.
          listenable: Listenable.merge([store, FinanceStore.instance]),
          builder: (context, _) {
            final nowMonth = monthStart(DateTime.now());
            final selected = _month;
            final isCurrent = selected == nowMonth;
            final summary = store.summaryFor(selected);

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
                          const Text('Anggaran',
                              style: TextStyle(
                                  fontSize: 28, fontWeight: FontWeight.w800)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const Expanded(
                            child: Text('Riwayat per bulan',
                                style: TextStyle(
                                    fontSize: 13, color: Color(0xFF5B6B8F))),
                          ),
                          BudgetMonthPill(
                            selected: selected,
                            onTap: _pickMonth,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (!summary.isEmpty) ...[
                        BudgetMascotBubble(
                            summary: summary, isCurrent: isCurrent),
                        const SizedBox(height: 12),
                      ],
                      BudgetSummaryCard(
                          summary: summary, isCurrent: isCurrent),
                      const SizedBox(height: 14),
                      if (isCurrent) ...[
                        PlanningActionButton(
                          label: '+ Buat anggaran',
                          filled: true,
                          onTap: () => showCreateBudgetSheet(context),
                        ),
                        const SizedBox(height: 14),
                      ],
                      if (summary.isEmpty)
                        BudgetEmptyState(isCurrent: isCurrent)
                      else
                        for (final u in summary.items) ...[
                          BudgetItemCard(
                            usage: u,
                            month: selected,
                            isCurrent: isCurrent,
                            onTap: isCurrent
                                ? () => showEditBudgetSheet(
                                    context, u.budget.id)
                                : null,
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