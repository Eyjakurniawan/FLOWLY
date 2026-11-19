import 'package:flutter/material.dart';

import '../models/finance_models.dart';
import '../services/category_store.dart';
import '../services/finance_store.dart';
import '../utils/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/delete_confirm_dialog.dart';
import '../widgets/finance/add_wallet_sheet.dart';
import '../widgets/finance/common.dart';
import '../widgets/finance/home_header.dart';
import '../widgets/primary_button.dart';

/// Pengaturan > Kelola kategori dan dompet.
class CategoryWalletScreen extends StatelessWidget {
  const CategoryWalletScreen({super.key});

  static const _divider = Divider(height: 1, color: Color(0xFFE6EBF7));

  static Color _walletColor(WalletType t) => switch (t) {
        WalletType.bank => const Color(0xFF6B5B9A),
        WalletType.ewallet => const Color(0xFF2563EB),
        WalletType.tunai => const Color(0xFF15803D),
      };

  @override
  Widget build(BuildContext context) {
    final cats = CategoryStore.instance;
    final fin = FinanceStore.instance;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: HomeHeader(),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: Listenable.merge([cats, fin]),
                builder: (context, _) {
                  final expense = cats.byType(TxType.expense);
                  final income = cats.byType(TxType.income);
                  final wallets = fin.wallets;

                  return ListView(
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
                          const Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text('Kategori dan dompet',
                                  style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // ---- kategori pengeluaran
                      _SectionCard(
                        title: 'Kategori pengeluaran',
                        addLabel: '+ Tambah kategori',
                        onAdd: () => _openCategory(context, TxType.expense),
                        children: [
                          for (var i = 0; i < expense.length; i++) ...[
                            if (i > 0) _divider,
                            _ItemRow(
                              color: expense[i].color,
                              title: expense[i].name,
                              onTap: () => _openCategory(
                                  context, TxType.expense,
                                  editing: expense[i]),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 14),

                      // ---- kategori pemasukan
                      _SectionCard(
                        title: 'Kategori pemasukan',
                        addLabel: '+ Tambah kategori',
                        onAdd: () => _openCategory(context, TxType.income),
                        children: [
                          for (var i = 0; i < income.length; i++) ...[
                            if (i > 0) _divider,
                            _ItemRow(
                              color: income[i].color,
                              title: income[i].name,
                              onTap: () => _openCategory(context, TxType.income,
                                  editing: income[i]),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 14),

                      // ---- dompet
                      _SectionCard(
                        title: 'Dompet',
                        addLabel: '+ Tambah dompet',
                        onAdd: () => showAddWalletSheet(context),
                        children: [
                          if (wallets.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text('Belum ada dompet.',
                                  style: TextStyle(
                                      fontSize: 12.5,
                                      color: AppColors.textGrey)),
                            ),
                          for (var i = 0; i < wallets.length; i++) ...[
                            if (i > 0) _divider,
                            _ItemRow(
                              color: _walletColor(wallets[i].type),
                              title: wallets[i].name,
                              subtitle:
                                  '${wallets[i].type.label} • ${fin.money(fin.balanceOf(wallets[i]))}',
                              onTap: () => showFlowlySheet<bool>(
                                context,
                                (_) => _WalletSheet(wallet: wallets[i]),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Dipakai juga oleh form Catat transaksi (chip "+ Baru").
  /// Mengembalikan true kalau kategori berhasil ditambah.
  static Future<bool> addCategory(BuildContext context, TxType type) async {
    final ok = await _openCategory(context, type);
    return ok == true;
  }

  static Future<bool?> _openCategory(
    BuildContext context,
    TxType type, {
    TxCategory? editing,
  }) {
    return showFlowlySheet<bool>(
      context,
      (_) => _CategorySheet(type: type, editing: editing),
    );
  }
}

// ============================================================ komponen

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final String addLabel;
  final VoidCallback onAdd;
  const _SectionCard({
    required this.title,
    required this.children,
    required this.addLabel,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return FlowlyCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          ...children,
          const SizedBox(height: 14),
          _OutlineBtn(label: addLabel, color: AppColors.textDark, onTap: onAdd),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final Color color;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  const _ItemRow({
    required this.color,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 13.5,
                          fontWeight:
                              subtitle == null ? FontWeight.w600 : FontWeight.w800)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!,
                        style: const TextStyle(
                            fontSize: 11.5, color: AppColors.textGrey)),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 22, color: AppColors.textDark),
          ],
        ),
      ),
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _OutlineBtn({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(label,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

Future<bool> _confirmDelete(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Hapus',
              style: TextStyle(color: AppColors.primary)),
        ),
      ],
    ),
  );
  return ok == true;
}

// ================================================= Sheet tambah/ubah kategori

class _CategorySheet extends StatefulWidget {
  final TxType type;
  final TxCategory? editing; // null = tambah baru
  const _CategorySheet({required this.type, this.editing});

  @override
  State<_CategorySheet> createState() => _CategorySheetState();
}

class _CategorySheetState extends State<_CategorySheet> {
  static const _palette = <Color>[
    Color(0xFF1E3A8A),
    Color(0xFF2563EB),
    Color(0xFF0284C7),
    Color(0xFF16A34A),
    Color(0xFF15803D),
    Color(0xFFD97706),
    Color(0xFFDC2626),
    Color(0xFFBE185D),
    Color(0xFF7C3AED),
    Color(0xFF78350F),
    Color(0xFF64748B),
  ];

  late final TextEditingController _name;
  late Color _color;
  String? _error;
  String? _deleteError;

  bool get _isEdit => widget.editing != null;
  bool get _locked => _isEdit && CategoryStore.isFallback(widget.editing!);

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.editing?.name ?? '');
    _color = widget.editing?.color ?? _nextFreeColor();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Color _nextFreeColor() {
    final used =
        CategoryStore.instance.byType(widget.type).map((c) => c.color).toSet();
    for (final c in _palette) {
      if (!used.contains(c)) return c;
    }
    return _palette.first;
  }

  void _save() {
    final store = CategoryStore.instance;
    final ok = _isEdit
        ? store.update(widget.editing!, _name.text, _color)
        : store.add(_name.text, _color, widget.type);
    if (!ok) {
      setState(() => _error = 'Nama kategori itu sudah ada.');
      return;
    }
    Navigator.pop(context, true);
  }

  Future<void> _delete() async {
    final c = widget.editing!;
    if (FinanceStore.instance.categoryInUse(c)) {
      setState(() => _deleteError =
          'Kategori ini masih dipakai transaksi, jadi belum bisa dihapus.');
      return;
    }
    final ok = await _confirmDelete(
      context,
      title: 'Hapus kategori ${c.name}?',
      message: 'Tindakan ini tidak bisa dibatalkan.',
    );
    if (!ok || !mounted) return;
    CategoryStore.instance.remove(c);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = widget.type == TxType.income;
    return SheetFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_isEdit ? 'Ubah kategori' : 'Tambah kategori',
              style:
                  const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(isIncome ? 'Kategori pemasukan' : 'Kategori pengeluaran',
              style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
          const FieldLabel('Nama'),
          TextField(
            controller: _name,
            enabled: !_locked,
            textCapitalization: TextCapitalization.words,
            decoration: flowlyField('Contoh: Kopi, Hadiah', error: _error),
            onChanged: (_) => setState(() => _error = null),
          ),
          const FieldLabel('Warna'),
          IgnorePointer(
            ignoring: _locked,
            child: Opacity(
              opacity: _locked ? 0.4 : 1,
              child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final c in _palette)
                GestureDetector(
                  onTap: () => setState(() => _color = c),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: c,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: _color == c
                        ? const Icon(Icons.check_rounded,
                            size: 20, color: Colors.white)
                        : null,
                  ),
                ),
            ],
          ),
            ),
          ),
          const SizedBox(height: 22),
          PrimaryButton(
            label: _isEdit ? 'Simpan perubahan' : 'Simpan kategori',
            onPressed: _name.text.trim().isNotEmpty || _locked ? _save : null,
          ),
          if (_isEdit && !_locked) ...[
            const SizedBox(height: 10),
            _OutlineBtn(
                label: 'Hapus kategori',
                color: AppColors.primary,
                onTap: _delete),
            if (_deleteError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_deleteError!,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.primary)),
              ),
          ],
        ],
      ),
    );
  }
}

// ===================================================== Sheet ubah dompet

class _WalletSheet extends StatefulWidget {
  final Wallet wallet;
  const _WalletSheet({required this.wallet});

  @override
  State<_WalletSheet> createState() => _WalletSheetState();
}

class _WalletSheetState extends State<_WalletSheet> {
  late final TextEditingController _name;
  late final TextEditingController _balance;
  late WalletType _type;
  String? _error;
  String? _balanceError; // saldo awal bikin saldo dompet minus

  @override
  void initState() {
    super.initState();
    final w = widget.wallet;
    _name = TextEditingController(text: w.name);
    _balance = TextEditingController(
      text: w.initialBalance > 0 ? Fmt.rupiah(w.initialBalance).substring(2) : '',
    );
    _type = w.type;
  }

  @override
  void dispose() {
    _name.dispose();
    _balance.dispose();
    super.dispose();
  }

  void _save() {
    final store = FinanceStore.instance;
    final newInitial = Fmt.parseAmount(_balance.text);
    // Saldo dompet = saldo awal + semua transaksinya; tidak boleh minus.
    final fromTx = store.balanceOf(widget.wallet) - widget.wallet.initialBalance;
    if (newInitial + fromTx < 0) {
      setState(() => _balanceError =
          'Saldo awal terlalu kecil: saldo dompet akan minus. '
          'Minimal ${Fmt.rupiah(-fromTx)}.');
      return;
    }
    final ok = store.updateWallet(
      widget.wallet.name,
      _name.text,
      _type,
      newInitial,
    );
    if (!ok) {
      setState(() => _error = 'Nama dompet itu sudah ada.');
      return;
    }
    Navigator.pop(context, true);
  }

  Future<void> _delete() async {
    final ok = await showDeleteConfirmDialog(
      context,
      title: 'Hapus dompet?',
      message: FinanceStore.instance.deleteWalletMessage(widget.wallet),
    );
    if (!ok || !mounted) return;
    FinanceStore.instance.removeWallet(widget.wallet.name);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return SheetFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ubah dompet',
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
            errorText: _balanceError,
            onChanged: (_) => setState(() => _balanceError = null),
          ),
          const SizedBox(height: 22),
          PrimaryButton(
            label: 'Simpan perubahan',
            onPressed: _name.text.trim().isNotEmpty ? _save : null,
          ),
          const SizedBox(height: 10),
          _OutlineBtn(
              label: 'Hapus dompet', color: AppColors.primary, onTap: _delete),
        ],
      ),
    );
  }
}