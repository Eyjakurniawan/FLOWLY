import 'package:flutter/material.dart';

import '../../models/budget_models.dart';
import '../../models/finance_models.dart';
import '../../screens/category_wallet_screen.dart';
import '../../services/budget_store.dart';
import '../../services/category_store.dart';
import '../../services/finance_store.dart';
import '../../utils/app_colors.dart';
import '../../utils/formatters.dart';
import '../delete_confirm_dialog.dart';
import '../primary_button.dart';
import 'common.dart';

/// Pop-up "Buat anggaran". True kalau anggaran tersimpan.
Future<bool?> showCreateBudgetSheet(BuildContext context) =>
    showFlowlySheet<bool>(context, (_) => const _BudgetSheet());

/// Pop-up "Ubah anggaran" (batas bisa diubah, anggaran bisa dihapus).
Future<bool?> showEditBudgetSheet(BuildContext context, int budgetId) =>
    showFlowlySheet<bool>(context, (_) => _BudgetSheet(budgetId: budgetId));

class _BudgetSheet extends StatefulWidget {
  final int? budgetId;
  const _BudgetSheet({this.budgetId});

  @override
  State<_BudgetSheet> createState() => _BudgetSheetState();
}

class _BudgetSheetState extends State<_BudgetSheet> {
  static const _newKey = '__kategori_baru__';

  final _amount = TextEditingController();
  TxCategory? _category;
  String? _error;

  Budget? get _editing =>
      widget.budgetId == null ? null : BudgetStore.instance.byId(widget.budgetId!);
  bool get _isEdit => widget.budgetId != null;

  @override
  void initState() {
    super.initState();
    final e = _editing;
    if (e != null) {
      _category = e.category;
      _amount.text = Fmt.groupDigits(e.limit.toString());
    } else {
      final free = BudgetStore.instance.availableCategories;
      _category = free.isEmpty ? null : free.first;
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  int get _limit => Fmt.parseAmount(_amount.text);
  bool get _valid => _category != null && _limit > 0;

  Future<void> _onPick(String? key) async {
    if (key == null) return;
    if (key == _newKey) {
      final added =
          await CategoryWalletScreen.addCategory(context, TxType.expense);
      if (!added || !mounted) return;
      // Kategori baru ditaruh paling akhir di daftar pengeluaran.
      final list = CategoryStore.instance.byType(TxType.expense);
      setState(() {
        _category = list.isEmpty ? _category : list.last;
        _error = null;
      });
      return;
    }
    final match = CategoryStore.instance
        .byType(TxType.expense)
        .where((c) => c.name == key);
    if (match.isEmpty) return;
    setState(() {
      _category = match.first;
      _error = null;
    });
  }

  void _save() {
    final store = BudgetStore.instance;
    final ok = _isEdit
        ? store.updateLimit(widget.budgetId!, _limit)
        : store.add(_category!, _limit);
    if (!ok) {
      setState(() => _error = 'Kategori ini sudah punya anggaran.');
      return;
    }
    Navigator.pop(context, true);
  }

  Future<void> _delete() async {
    final e = _editing;
    if (e == null) return;
    final ok = await showDeleteConfirmDialog(
      context,
      title: 'Hapus anggaran?',
      message:
          'Anggaran "${e.category.name}" akan dihapus. Kategori dan transaksinya tetap ada.',
    );
    if (!ok || !mounted) return;
    BudgetStore.instance.remove(e.id);
    Navigator.pop(context, true);
  }

  /// Teks bantuan di bawah kolom batas. Setelah batas diisi, menampilkan
  /// perkiraan aman per hari dan pengeluaran bulan ini di kategori itu.
  String _helper() {
    final c = _category;
    final limit = _limit;
    if (c == null || limit <= 0) return 'Isi batas pengeluaran per bulan.';
    final fin = FinanceStore.instance;
    final spent = fin.categoryExpenseInMonth(c, DateTime.now());
    final room = limit > spent ? limit - spent : 0;
    final perDay = room ~/ daysLeftInMonth();
    return 'Sekitar ${fin.money(perDay)} per hari • terpakai '
        '${fin.money(spent)}. Berlaku mulai bulan ini.';
  }

  Widget _dropdown() {
    final store = BudgetStore.instance;
    // Saat membuat: hanya kategori yang belum punya anggaran.
    final names = _isEdit
        ? <String>[_category?.name ?? '']
        : [for (final c in store.availableCategories) c.name];
    final value = (_category != null && names.contains(_category!.name))
        ? _category!.name
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE3EAFB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          borderRadius: BorderRadius.circular(16),
          dropdownColor: Colors.white,
          menuMaxHeight: 320,
          itemHeight: 56,
          style: const TextStyle(
              fontSize: 15, color: AppColors.textDark),
          hint: const Text('Pilih kategori',
              style: TextStyle(color: AppColors.hint, fontSize: 14)),
          onChanged: _isEdit ? null : _onPick,
          items: [
            for (final n in names)
              DropdownMenuItem<String>(value: n, child: Text(n)),
            if (!_isEdit)
              const DropdownMenuItem<String>(
                value: _newKey,
                child: Text('+ Kategori baru…',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SheetFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_isEdit ? 'Ubah anggaran' : 'Buat anggaran',
              style:
                  const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          const Text(
            'Batas pengeluaran per bulan untuk satu kategori. Reset otomatis tiap awal bulan.',
            style: TextStyle(fontSize: 12, color: AppColors.textGrey),
          ),
          const FieldLabel('Kategori'),
          _dropdown(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(_error!,
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.error)),
            ),
          const FieldLabel('Batas per bulan (Rp)'),
          AmountField(
            controller: _amount,
            hint: '0',
            onChanged: (_) => setState(() => _error = null),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(_helper(),
                style: const TextStyle(
                    fontSize: 11.5, color: AppColors.textGrey)),
          ),
          const SizedBox(height: 22),
          PrimaryButton(
            label: _isEdit ? 'Simpan perubahan' : 'Simpan anggaran',
            onPressed: _valid ? _save : null,
          ),
          if (_isEdit) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: _delete,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textDark,
                  side: const BorderSide(color: AppColors.primary, width: 1.2),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Hapus anggaran',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}