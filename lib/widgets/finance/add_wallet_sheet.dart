import 'package:flutter/material.dart';

import '../../models/finance_models.dart';
import '../../services/finance_store.dart';
import '../../utils/app_colors.dart';
import '../../utils/formatters.dart';
import '../primary_button.dart';
import 'common.dart';

/// Return nama dompet yang baru dibuat, atau null kalau dibatalkan.
Future<String?> showAddWalletSheet(BuildContext context) {
  return showFlowlySheet<String>(context, (_) => const _AddWalletSheet());
}

class _AddWalletSheet extends StatefulWidget {
  const _AddWalletSheet();

  @override
  State<_AddWalletSheet> createState() => _AddWalletSheetState();
}

class _AddWalletSheetState extends State<_AddWalletSheet> {
  final _name = TextEditingController();
  final _balance = TextEditingController();
  WalletType _type = WalletType.bank;
  String? _error;

  bool get _hasName => _name.text.trim().isNotEmpty;
  bool get _hasBalance => _balance.text.trim().isNotEmpty;
  bool get _canSave => _hasName && _hasBalance;

  /// Pesan di atas tombol selama form belum lengkap.
  String get _hint {
    if (!_hasName && !_hasBalance) {
      return 'Isi nama dompet dan saldo awal dulu untuk menyimpan.';
    }
    if (!_hasName) return 'Isi nama dompet dulu untuk menyimpan.';
    return 'Isi saldo awal dulu untuk menyimpan. Isi 0 jika masih kosong.';
  }

  @override
  void dispose() {
    _name.dispose();
    _balance.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    final ok = FinanceStore.instance
        .addWallet(name, _type, Fmt.parseAmount(_balance.text));
    if (!ok) {
      setState(() => _error = 'Nama dompet itu sudah ada.');
      return;
    }
    Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    return SheetFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tambah dompet',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
          const FieldLabel('Nama'),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: flowlyField('Contoh: Mandiri, ShopeePay', error: _error),
            onChanged: (_) => setState(() => _error = null),
          ),
          const FieldLabel('Jenis'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in WalletType.values)
                ChoiceBubble(
                  label: t.label,
                  selected: t == _type,
                  onTap: () => setState(() => _type = t),
                ),
            ],
          ),
          const FieldLabel('Saldo awal (Rp)'),
          AmountField(
            controller: _balance,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          const Text(
            'Isi sesuai saldo di rekening atau dompet aslimu sekarang. Isi 0 jika masih kosong. Setelah disimpan, saldo hanya berubah lewat transaksi.',
            style: TextStyle(
                fontSize: 12.5, height: 1.4, color: AppColors.textGrey),
          ),
          const SizedBox(height: 16),
          if (!_canSave) ...[
            Center(
              child: Text(
                _hint,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error),
              ),
            ),
            const SizedBox(height: 8),
          ],
          PrimaryButton(
            label: 'Simpan Dompet',
            onPressed: _canSave ? _save : null,
          ),
        ],
      ),
    );
  }
}