import 'package:flutter/material.dart';

import '../../models/finance_models.dart';
import '../../services/finance_store.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../mascot_view.dart';
import 'common.dart';

/// Ringkasan transaksi yang baru disimpan (untuk pop-up "Tersimpan!").
class TxSavedInfo {
  final TxType type;
  final String category;
  final int amount;
  final String wallet;
  final int walletBalance; // saldo dompet setelah transaksi

  const TxSavedInfo({
    required this.type,
    required this.category,
    required this.amount,
    required this.wallet,
    required this.walletBalance,
  });
}

/// Hasil pop-up: true = "Catat lagi", false/null = "Selesai".
Future<bool> showTxSavedSheet(BuildContext context, TxSavedInfo info) async {
  final again = await showFlowlySheet<bool>(
    context,
    (_) => _TxSavedSheet(info: info),
    offlineOk: true,
  );
  return again == true;
}

class _TxSavedSheet extends StatelessWidget {
  final TxSavedInfo info;
  const _TxSavedSheet({required this.info});

  @override
  Widget build(BuildContext context) {
    final store = FinanceStore.instance;
    final isIncome = info.type == TxType.income;
    final direction = isIncome ? 'masuk ke' : 'keluar dari';
    final message =
        '${info.category} • ${store.money(info.amount)} $direction ${info.wallet}. '
        'Saldo sekarang ${store.money(info.walletBalance)}.';

    return SheetFrame(
      child: Column(
        children: [
          const MascotView(size: 130, expression: MascotExpression.happy),
          const SizedBox(height: 8),
          const Text('Tersimpan!',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, height: 1.45, color: AppColors.textGrey),
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textDark,
                      side: const BorderSide(
                          color: AppColors.border, width: 1.2),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      textStyle: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    child: const Text('Catat lagi'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textDark,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      textStyle: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    child: const Text('Selesai'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}