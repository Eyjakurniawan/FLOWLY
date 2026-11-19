import 'package:flutter/material.dart';

import '../../models/finance_models.dart';
import '../../services/finance_store.dart';
import '../../utils/app_colors.dart';
import '../../utils/formatters.dart';
import '../mascot_view.dart';
import '../primary_button.dart';
import '../../screens/category_wallet_screen.dart';
import '../../services/category_store.dart';
import 'add_wallet_sheet.dart';
import 'common.dart';
import 'flowly_date_picker.dart';
import 'saved_sheet.dart';

/// Dipanggil dari tombol + di nav bawah.
///
/// Satu bottom sheet (sama seperti pop-up lain): form tampil dulu, ketuk
/// kolom Nominal -> keypad angka muncul di dasar sheet (sama seperti semua
/// kolom nominal lain lewat [AmountField]), "Selesai" menutup keypad.
Future<void> showAddTransactionSheet(BuildContext context) async {
  final info = await showFlowlySheet<TxSavedInfo>(
    context,
    (_) => const _AddTxSheet(),
  );
  if (info == null || !context.mounted) return;

  // Pop-up "Tersimpan!" -> "Catat lagi" membuka form transaksi baru.
  final again = await showTxSavedSheet(context, info);
  if (again && context.mounted) await showAddTransactionSheet(context);
}

/// Chip dengan garis putus-putus.
class _DashedChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _DashedChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: _DashedRRectPainter(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Offset.zero & size,
        const Radius.circular(18),
      ));
    final paint = Paint()
      ..color = const Color(0xFF5B6B8F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 4), paint);
        d += 7;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AddTxSheet extends StatefulWidget {
  const _AddTxSheet();

  @override
  State<_AddTxSheet> createState() => _AddTxSheetState();
}

class _AddTxSheetState extends State<_AddTxSheet> {
  final _store = FinanceStore.instance;
  final _amount = TextEditingController();
  final _note = TextEditingController();

  TxType _type = TxType.expense;
  TxCategory? _category = TxCategory.byType(TxType.expense).firstOrNull;
  String? _wallet;
  late DateTime _date = _today();

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  @override
  void initState() {
    super.initState();
    if (_store.wallets.isNotEmpty) _wallet = _store.wallets.first.name;
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  int get _value => Fmt.parseAmount(_amount.text);
  bool get _canSave =>
      _value > 0 && _wallet != null && _category != null && !_insufficient;

  /// Saldo dompet yang dipilih (null kalau belum ada dompet).
  int? get _available => _wallet == null ? null : _store.availableIn(_wallet!);

  /// Pengeluaran tidak boleh melebihi saldo dompet.
  bool get _insufficient {
    final a = _available;
    return _type == TxType.expense && a != null && _value > a;
  }

  Future<void> _pickDate() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final picked = await showFlowlyDatePicker(
      context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: _today(),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  Future<void> _addCategory() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final before = CategoryStore.instance.byType(_type).length;
    final added = await CategoryWalletScreen.addCategory(context, _type);
    if (!added || !mounted) return;
    final list = CategoryStore.instance.byType(_type);
    if (list.length > before) setState(() => _category = list.last);
  }

  Future<void> _addWallet() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final name = await showAddWalletSheet(context);
    if (name != null && mounted) setState(() => _wallet = name);
  }

  void _save() {
    final saved = _store.addTransaction(
      type: _type,
      amount: _value,
      category: _category!,
      wallet: _wallet!,
      note: _note.text,
      date: _date,
    );
    // Pengaman: store menolak kalau saldo tidak cukup.
    if (!saved) {
      setState(() {});
      return;
    }
    final wallet = _store.walletByName(_wallet!);
    Navigator.pop(
      context,
      TxSavedInfo(
        type: _type,
        category: _category!.name,
        amount: _value,
        wallet: _wallet!,
        walletBalance: wallet == null ? 0 : _store.balanceOf(wallet),
      ),
    );
  }

  /// "Saldo BCA tersedia Rp150.000.000" / ajakan menambah dompet.
  Widget _walletHint() {
    Wallet? selected;
    for (final w in _store.wallets) {
      if (w.name == _wallet) {
        selected = w;
        break;
      }
    }
    final text = selected == null
        ? 'Tambahkan dompet dulu'
        : 'Saldo ${selected.name} tersedia ${_store.money(_store.balanceOf(selected))}';
    if (_insufficient && selected != null) {
      final have = _available ?? 0;
      return Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 8),
        child: Text(
          'Saldo ${selected.name} tidak cukup. Tersedia ${_store.money(have)}, '
          'kurang ${_store.money(_value - have)}. Kecilkan nominal, pilih '
          'dompet lain, atau tambah saldo dulu.',
          style: const TextStyle(
              fontSize: 12,
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: AppColors.primary),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      child: Text(text,
          style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cats = TxCategory.byType(_type);

    // SheetFrame (common.dart) menyediakan handle, area gulir, dan keypad
    // angka untuk semua AmountField di dalamnya.
    return SheetFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text('Catat transaksi',
                    style:
                        TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
              ),
              MascotView(size: 40),
            ],
          ),
          const SizedBox(height: 14),
          SegmentedTabs<TxType>(
            expand: true,
            // Pengeluaran di kiri, Pemasukan di kanan.
            values: const [TxType.expense, TxType.income],
            selected: _type,
            labelOf: (t) => t == TxType.expense ? 'Pengeluaran' : 'Pemasukan',
            onChanged: (t) => setState(() {
              _type = t;
              _category = TxCategory.byType(t).firstOrNull;
            }),
          ),
          const SizedBox(height: 14),
          // Nominal: keypad angka standar (sama seperti input nominal lain).
          AmountField(
            controller: _amount,
            large: true,
            errorText: _insufficient
                ? 'Melebihi saldo $_wallet (tersedia '
                    '${_store.money(_available ?? 0)}).'
                : null,
            onChanged: (_) => setState(() {}),
          ),
          const FieldLabel('Kategori'),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final c in cats) ...[
                  ChoiceBubble(
                    label: c.name,
                    selected: c == _category,
                    onTap: () => setState(() => _category = c),
                  ),
                  const SizedBox(width: 8),
                ],
                _DashedChip(label: '+ Baru', onTap: _addCategory),
              ],
            ),
          ),
          const FieldLabel('Dompet'),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final w in _store.wallets) ...[
                  ChoiceBubble(
                    label: w.name,
                    selected: w.name == _wallet,
                    onTap: () => setState(() => _wallet = w.name),
                  ),
                  const SizedBox(width: 8),
                ],
                _DashedChip(
                  label: _store.wallets.isEmpty ? '+ Tambah dompet' : '+ Baru',
                  onTap: _addWallet,
                ),
              ],
            ),
          ),
          const FieldLabel('Tanggal'),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFE3EAFB),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(Fmt.slashDate(_date),
                        style: const TextStyle(fontSize: 14.5)),
                  ),
                  const Icon(Icons.calendar_today_outlined,
                      size: 18, color: AppColors.textGrey),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _note,
            textCapitalization: TextCapitalization.sentences,
            decoration: flowlyField('Catatan (opsional), mis. kopi susu'),
          ),
          _walletHint(),
          PrimaryButton(
            label: 'Simpan transaksi',
            onPressed: _canSave ? _save : null,
          ),
        ],
      ),
    );
  }
}