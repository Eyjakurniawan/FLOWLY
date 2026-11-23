import 'package:flutter/material.dart';

import '../models/finance_models.dart';
import '../services/finance_store.dart';
import '../utils/app_colors.dart';
import '../utils/helpers.dart';
import '../widgets/delete_confirm_dialog.dart';
import '../widgets/finance/common.dart';
import '../widgets/finance/home_header.dart';
import '../widgets/finance/transaction_widgets.dart';
import 'category_wallet_screen.dart';

/// Detail satu dompet: saldo terbaru, tombol ubah dan hapus, serta riwayat
/// transaksi.
class WalletDetailScreen extends StatefulWidget {
  final String walletName;
  const WalletDetailScreen({super.key, required this.walletName});

  @override
  State<WalletDetailScreen> createState() => _WalletDetailScreenState();
}

class _WalletDetailScreenState extends State<WalletDetailScreen> {
  // Nama bisa berubah setelah dompet diubah, jadi disimpan di state.
  late String _name = widget.walletName;

  Future<void> _edit(BuildContext context, Wallet wallet) async {
    final r = await showEditWalletSheet(context, wallet);
    if (r == null || !mounted) return;
    if (r.deleted) {
      Helpers.showSnack(context, 'Dompet "${r.name}" dihapus.');
      Navigator.of(context).pop();
    } else {
      setState(() => _name = r.name);
    }
  }

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
            final wallet = store.walletByName(_name);
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
                            Row(
                              children: [
                                _RoundAction(
                                  icon: Icons.edit_outlined,
                                  onTap: () => _edit(context, wallet),
                                ),
                                const SizedBox(width: 10),
                                _RoundAction(
                                  icon: Icons.delete_outline_rounded,
                                  onTap: () => _confirmDelete(
                                      context, wallet, txs.length),
                                ),
                              ],
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

/// Tombol bulat bergaris oranye (ubah / hapus dompet).
class _RoundAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary, width: 1.5),
        ),
        child: Icon(icon, color: AppColors.primary, size: 24),
      ),
    );
  }
}