import 'package:flutter/material.dart';

import '../../models/finance_models.dart';
import '../../services/finance_store.dart';
import '../../utils/app_colors.dart';
import '../../utils/helpers.dart';
import '../delete_confirm_dialog.dart';
import 'add_transaction_sheet.dart';
import 'common.dart';

enum _TxAction { edit, delete }

/// Ketuk transaksi di riwayat: sheet pilihan Ubah / Hapus.
Future<void> showTransactionActions(
    BuildContext context, FlowTransaction tx) async {
  final choice = await showFlowlySheet<_TxAction>(
    context,
    (_) => _TxActionsSheet(tx: tx),
  );
  if (choice == null || !context.mounted) return;
  if (choice == _TxAction.edit) {
    await showEditTransactionSheet(context, tx);
  } else {
    await _confirmDelete(context, tx);
  }
}

Future<void> _confirmDelete(BuildContext context, FlowTransaction tx) async {
  final store = FinanceStore.instance;

  // Pemasukan yang saldonya sudah terpakai tidak bisa dihapus.
  final blocker = store.deleteBlocker(tx);
  if (blocker != null) {
    Helpers.showSnack(context, blocker);
    return;
  }

  final amount = store.signedMoney(tx.signedAmount).replaceFirst('-', '\u2212');
  final ok = await showDeleteConfirmDialog(
    context,
    title: 'Hapus transaksi?',
    message: '${tx.title} ($amount) akan dihapus dan saldo dompet disesuaikan.',
    confirmLabel: 'Ya, hapus',
  );
  if (!ok || !context.mounted) return;

  final error = store.deleteTransaction(tx.id);
  Helpers.showSnack(context, error ?? 'Transaksi dihapus.');
}

class _TxActionsSheet extends StatelessWidget {
  final FlowTransaction tx;
  const _TxActionsSheet({required this.tx});

  @override
  Widget build(BuildContext context) {
    final store = FinanceStore.instance;
    // Dompetnya sudah dihapus: transaksi hanya bisa dihapus, tidak diubah.
    final canEdit = store.walletByName(tx.wallet) != null;

    return SheetFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tx.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(
            [
              tx.category.name,
              tx.wallet,
              store.signedMoney(tx.signedAmount),
            ].join(' • '),
            style: const TextStyle(fontSize: 12.5, color: AppColors.textGrey),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              if (canEdit) ...[
                Expanded(
                  child: _ActionButton(
                    label: 'Ubah',
                    borderColor: AppColors.textDark,
                    onTap: () => Navigator.pop(context, _TxAction.edit),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: _ActionButton(
                  label: 'Hapus',
                  borderColor: AppColors.primary,
                  onTap: () => Navigator.pop(context, _TxAction.delete),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color borderColor;
  final VoidCallback onTap;
  const _ActionButton({
    required this.label,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.3),
        ),
        child: Text(label,
            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
      ),
    );
  }
}