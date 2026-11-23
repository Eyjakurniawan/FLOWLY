import 'package:flutter/material.dart';

import '../utils/helpers.dart';

import '../models/finance_models.dart';
import '../services/finance_store.dart';
import '../utils/app_colors.dart';
import '../widgets/finance/common.dart';
import '../widgets/finance/home_header.dart';
import '../widgets/finance/transaction_widgets.dart';

enum _Filter {
  all('Semua'),
  income('Masuk'),
  expense('Keluar');

  final String label;
  const _Filter(this.label);
}

/// Halaman "Lihat semua" transaksi di bulan terpilih.
class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _store = FinanceStore.instance;
  _Filter _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: _store,
          builder: (context, _) {
            final items = _store.transactions(
              type: switch (_filter) {
                _Filter.all => null,
                _Filter.income => TxType.income,
                _Filter.expense => TxType.expense,
              },
            );
            final total = items.fold<int>(0, (s, t) => s + t.signedAmount);
            final caption = switch (_filter) {
              _Filter.all => 'Selisih (masuk dikurangi keluar)',
              _Filter.income => 'Total pemasukan',
              _Filter.expense => 'Total pengeluaran',
            };

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
                          const Text('Transaksi',
                              style: TextStyle(
                                  fontSize: 28, fontWeight: FontWeight.w800)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      FlowlyCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SegmentedTabs<_Filter>(
                              expand: true,
                              values: _Filter.values,
                              selected: _filter,
                              labelOf: (f) => f.label,
                              onChanged: (f) => setState(() => _filter = f),
                            ),
                            const SizedBox(height: 14),
                            Text(caption,
                                style: const TextStyle(
                                    fontSize: 13, color: AppColors.textGrey)),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _store.money(total),
                                style: const TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (items.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 48),
                          child: Center(
                            child: Text('Belum ada transaksi di bulan ini.',
                                style: TextStyle(color: AppColors.textGrey)),
                          ),
                        )
                      else
                        ...buildDayGroups(items),
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