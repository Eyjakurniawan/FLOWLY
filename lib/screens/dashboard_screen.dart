import 'package:flutter/material.dart';

import '../models/finance_models.dart';
import '../services/finance_store.dart';
import '../widgets/finance/cashflow_card.dart';
import '../widgets/finance/category_treemap_card.dart';
import '../widgets/finance/home_header.dart';
import '../widgets/finance/summary_cards.dart';
import '../widgets/finance/transaction_widgets.dart';
import 'planning_screen.dart';
import 'reports_screen.dart';
import 'transactions_screen.dart';

/// Tab Home.
class DashboardScreen extends StatefulWidget {
  final VoidCallback onOpenWallet;
  final VoidCallback onOpenReports;
  const DashboardScreen({
    super.key,
    required this.onOpenWallet,
    required this.onOpenReports,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _store = FinanceStore.instance;
  CategorySlice? _slice; // kotak yang dipilih di treemap
  String? get _filter => _slice?.name;

  static const _gap = SizedBox(height: 14);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: _store,
          builder: (context, _) {
            final hasTx = _store.monthTransactions.isNotEmpty;
            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: HomeHeader(),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 124),
                    children: [
                      BalanceCard(
                        onTap: widget.onOpenWallet,
                        onTapIncome: () {
                          widget.onOpenReports();
                          ReportsScreen.focusRequest.value =
                              ReportsFocusRequest(ReportsFocus.income);
                        },
                        onTapExpense: () {
                          widget.onOpenReports();
                          ReportsScreen.focusRequest.value =
                              ReportsFocusRequest(ReportsFocus.expense);
                        },
                      ),
                      _gap,
                      if (!hasTx) ...[const EmptyLedgerCard(), _gap],
                      PlanningCard(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PlanningScreen(),
                          ),
                        ),
                      ),
                      if (hasTx) ...[
                        _gap,
                        const CashflowCard(),
                        _gap,
                        CategoryTreemapCard(
                          selected: _filter,
                          onSelect: (c) => setState(() => _slice = c),
                        ),
                        _gap,
                        RecentTransactionsCard(
                          filter: _filter,
                          filterCategories: _slice?.categoryNames,
                          onClearFilter: () => setState(() => _slice = null),
                          onSeeAll: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const TransactionsScreen(),
                            ),
                          ),
                        ),
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