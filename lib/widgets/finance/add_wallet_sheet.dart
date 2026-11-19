import 'package:flutter/material.dart';

import '../../models/finance_models.dart';
import '../../services/finance_store.dart';
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

  bool get _canSave => _name.text.trim().isNotEmpty;

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
          AmountField(controller: _balance),
          const SizedBox(height: 22),
          PrimaryButton(
            label: 'Simpan Dompet',
            onPressed: _canSave ? _save : null,
          ),
        ],
      ),
    );
  }
}