import 'package:flutter/material.dart';

import '../../models/finance_models.dart';
import '../../services/finance_store.dart';
import '../../utils/app_colors.dart';
import '../../utils/fit_text.dart';
import '../../utils/formatters.dart';
import 'common.dart';

class TransactionTile extends StatelessWidget {
  final FlowTransaction tx;

  /// false kalau sudah ada judul hari di atasnya (daftar per hari).
  final bool showDay;
  const TransactionTile({super.key, required this.tx, this.showDay = true});

  /// Lebar minimum area keterangan supaya tetap terbaca.
  static const double _minTextWidth = 96;

  @override
  Widget build(BuildContext context) {
    final store = FinanceStore.instance;
    final income = tx.type == TxType.income;
    final amount = store.money(tx.amount);

    final amountText = income ? '+$amount' : '-$amount';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: LayoutBuilder(builder: (context, c) {
        // Lebar yang tersisa setelah ikon (46) dan jarak (14 + 10).
        final available = c.maxWidth - 46 - 14 - 10;
        // Keterangan (judul + kategori • dompet) selalu dapat minimal
        // [_minTextWidth]; nominal mengecil kalau melebihi sisanya.
        final maxAmountWidth = (available - _minTextWidth).clamp(70.0, 1e6);
        final amountSize = fitFontSize(
          context,
          texts: [amountText],
          maxWidth: maxAmountWidth,
          maxFont: 17,
          minFont: 10,
        );
        return Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tx.category.color,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              tx.category.name.substring(0, 1),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 15.5, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(
                  [
                    tx.category.name,
                    tx.wallet,
                    if (showDay) Fmt.dayLabel(tx.date),
                  ].join(' • '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12.5, color: AppColors.textGrey),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxAmountWidth),
            // FittedBox = pengaman terakhir kalau font sudah minimum.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                amountText,
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  fontSize: amountSize,
                  fontWeight: FontWeight.w800,
                  color: income ? AppColors.link : AppColors.textDark,
                ),
              ),
            ),
          ),
        ],
      );
      }),
    );
  }
}

/// Daftar transaksi dengan garis pemisah, dipakai di Home & layar Transaksi.
class TransactionList extends StatelessWidget {
  final List<FlowTransaction> items;
  final bool showDay;
  const TransactionList({super.key, required this.items, this.showDay = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const Divider(height: 1, color: Color(0xFFE6EBF7)),
          TransactionTile(tx: items[i], showDay: showDay),
        ],
      ],
    );
  }
}

class RecentTransactionsCard extends StatelessWidget {
  final String? filter;

  /// Nama kategori asli untuk kotak gabungan "Lain-lain" (null = [filter] saja).
  final Set<String>? filterCategories;
  final VoidCallback onClearFilter;
  final VoidCallback onSeeAll;

  const RecentTransactionsCard({
    super.key,
    required this.filter,
    this.filterCategories,
    required this.onClearFilter,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final store = FinanceStore.instance;
    final items = (filterCategories != null
            ? store.transactions(categories: filterCategories)
            : store.transactions(category: filter))
        .take(5)
        .toList();

    return FlowlyCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(filter == null ? 'Transaksi terbaru' : 'Transaksi $filter',
                    style: const TextStyle(
                        fontSize: 19, fontWeight: FontWeight.w800)),
              ),
              GestureDetector(
                onTap: onSeeAll,
                child: const Text('Lihat semua',
                    style: TextStyle(
                        color: AppColors.link, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('Belum ada transaksi.',
                    style: TextStyle(color: AppColors.textGrey)),
              ),
            )
          else
            TransactionList(items: items),
        ],
      ),
    );
  }
}

/// Kelompokkan per hari: judul hari + kartu berisi transaksinya.
/// [items] harus sudah terurut terbaru dulu.
List<Widget> buildDayGroups(List<FlowTransaction> items) {
  final groups = <DateTime, List<FlowTransaction>>{};
  for (final t in items) {
    final day = DateTime(t.date.year, t.date.month, t.date.day);
    groups.putIfAbsent(day, () => []).add(t);
  }
  return [
    for (final e in groups.entries) ...[
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
        child: Text(Fmt.dayLabel(e.key),
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textGrey)),
      ),
      FlowlyCard(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
        child: TransactionList(items: e.value, showDay: false),
      ),
    ],
  ];
}