import 'package:flutter/material.dart';

import '../models/finance_models.dart';
import '../services/finance_store.dart';
import '../utils/app_colors.dart';
import '../utils/helpers.dart';
import '../widgets/delete_confirm_dialog.dart';
import '../widgets/finance/common.dart';
import '../widgets/finance/home_header.dart';
import '../widgets/finance/transaction_widgets.dart';

/// Detail satu dompet: saldo terbaru, tombol hapus, dan riwayat transaksi.
class WalletDetailScreen extends StatelessWidget {
  final String walletName;
  const WalletDetailScreen({super.key, required this.walletName});

  Future<void> _confirmDelete(
      BuildContext context, Wallet wallet, int count) async {
    final store = FinanceStore.instance;
    final ok = await showDeleteConfirmDialog(
      context,
      title: 'Hapus dompet?',
      message: store.deleteWalletMessage(wallet),
      confirmLabel: 'Ya, hapus',
    );
    if (!ok || !context.mounted) return;
    Helpers.showSnack(context, 'Dompet "${wallet.name}" dihapus.');
    FinanceStore.instance.removeWallet(wallet.name);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final store = FinanceStore.instance;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: store,
          builder: (context, _) {
            final wallet = store.walletByName(walletName);
            if (wallet == null) return const SizedBox.shrink(); // baru dihapus

            final txs = store.walletTransactions(wallet.name);
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
                          Expanded(
                            child: Text(wallet.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 28, fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      FlowlyCard(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${wallet.type.label} • ${txs.length} transaksi',
                                style: const TextStyle(
                                    fontSize: 13, color: AppColors.textGrey)),
                            const SizedBox(height: 14),
                            const Text('Saldo terbaru',
                                style: TextStyle(
                                    fontSize: 13, color: AppColors.textGrey)),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                store.money(store.balanceOf(wallet)),
                                style: const TextStyle(
                                    fontSize: 38, fontWeight: FontWeight.w800),
                              ),
                            ),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: () =>
                                  _confirmDelete(context, wallet, txs.length),
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: AppColors.primary, width: 1.5),
                                ),
                                child: const Icon(Icons.delete_outline_rounded,
                                    color: AppColors.primary, size: 24),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(4, 22, 4, 0),
                        child: Text('Riwayat transaksi',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w800)),
                      ),
                      if (txs.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Text('Belum ada transaksi di dompet ini.',
                                style: TextStyle(color: AppColors.textGrey)),
                          ),
                        )
                      else
                        ...buildDayGroups(txs),
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