import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/planning_models.dart';
import '../../services/finance_store.dart';
import '../../services/planning_store.dart';
import '../../utils/app_colors.dart';
import '../../utils/formatters.dart';
import '../../utils/helpers.dart';
import '../primary_button.dart';
import 'common.dart';
import 'flowly_date_picker.dart';

Future<T?> _show<T>(BuildContext context, Widget sheet) =>
    showFlowlySheet<T>(context, (_) => sheet);

/// 1250000 -> "1.250.000" (tanpa "Rp", untuk mengisi kolom angka).
String _plain(int v) => Fmt.rupiah(v).substring(2);

/// Tanggal target (harus setelah hari ini).
Future<DateTime?> _pickTargetDate(BuildContext context, DateTime? current) {
  final now = DateTime.now();
  final tomorrow = DateTime(now.year, now.month, now.day + 1);
  final initial = (current != null && !current.isBefore(tomorrow))
      ? current
      : DateTime(now.year, now.month + 1, now.day);
  return showFlowlyDatePicker(
    context,
    initialDate: initial,
    firstDate: tomorrow,
    lastDate: _targetLast(),
  );
}

/// Tanggal setoran (tidak boleh lewat dari hari ini).
Future<DateTime?> _pickDepositDate(BuildContext context, DateTime current) {
  final now = DateTime.now();
  return showFlowlyDatePicker(
    context,
    initialDate: current,
    firstDate: DateTime(2020),
    lastDate: DateTime(now.year, now.month, now.day),
  );
}

/// Rentang tanggal target (harus setelah hari ini, maksimal 30 tahun).
DateTime _targetFirst() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day + 1);
}

DateTime _targetLast() => DateTime(DateTime.now().year + 30, 12, 31);

/// Rentang tanggal setoran (2020 sampai hari ini).
DateTime _depositFirst() => DateTime(2020);

DateTime _depositLast() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
}

/// "dd/mm/yyyy" -> DateTime, atau null kalau belum lengkap / tidak ada
/// di kalender (mis. 31/02/2026).
DateTime? _parseSlashDate(String text) {
  final m = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(text);
  if (m == null) return null;
  final d = int.parse(m.group(1)!);
  final mo = int.parse(m.group(2)!);
  final y = int.parse(m.group(3)!);
  final date = DateTime(y, mo, d);
  if (date.year != y || date.month != mo || date.day != d) return null;
  return date;
}

/// Ketik angka saja; garis miring dipasang otomatis -> dd/mm/yyyy.
class _DateSlashFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String digitsOf(String t) => t.replaceAll(RegExp(r'[^0-9]'), '');
    var digits = digitsOf(newValue.text);
    // Hapus "/" dengan backspace: hapus juga angka di depannya.
    if (newValue.text.length < oldValue.text.length &&
        digits == digitsOf(oldValue.text) &&
        digits.isNotEmpty) {
      digits = digits.substring(0, digits.length - 1);
    }
    if (digits.length > 8) digits = digits.substring(0, 8);
    final b = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 2 || i == 4) b.write('/');
      b.write(digits[i]);
    }
    final text = b.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Kolom tanggal: bisa diketik langsung (keyboard angka bawaan HP), dan
/// ikon kalender di ujung membuka pemilih tanggal.
///
/// [onChanged] dipanggil tiap isi berubah dengan tanggal yang valid dan
/// masuk rentang [first]..[last], atau null kalau belum lengkap / tidak valid.
class _DateField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onPickCalendar;
  final ValueChanged<DateTime?> onChanged;
  final DateTime first;
  final DateTime last;
  final String rangeError;
  const _DateField({
    required this.controller,
    required this.onPickCalendar,
    required this.onChanged,
    required this.first,
    required this.last,
    required this.rangeError,
  });

  String? get _error {
    final text = controller.text;
    if (text.length < 10) return null; // masih mengetik
    final d = _parseSlashDate(text);
    if (d == null) return 'Tanggal tidak valid.';
    if (d.isBefore(first) || d.isAfter(last)) return rangeError;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [_DateSlashFormatter()],
      onChanged: (text) {
        final d = _parseSlashDate(text);
        final ok = d != null && !d.isBefore(first) && !d.isAfter(last);
        onChanged(ok ? d : null);
      },
      decoration: flowlyField('dd/mm/yyyy', error: _error).copyWith(
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_today_outlined, size: 20),
          tooltip: 'Pilih dari kalender',
          onPressed: () {
            FocusScope.of(context).unfocus();
            onPickCalendar();
          },
        ),
      ),
    );
  }
}

/// Label kecil di atas kolom (lebih rapat dari FieldLabel).
class _SmallLabel extends StatelessWidget {
  final String text;
  const _SmallLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 6),
        child: Text(text,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textGrey)),
      );
}

/// Pilihan kategori: daftar muncul DI BAWAH kolom (tidak menutupi kolom),
/// baris yang terpilih berlatar biru.
class _CategoryField extends StatefulWidget {
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  const _CategoryField({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  State<_CategoryField> createState() => _CategoryFieldState();
}

class _CategoryFieldState extends State<_CategoryField> {
  static const _fill = Color(0xFFE3EAFB);
  bool _open = false;
  final _anchor = GlobalKey();

  void _toggle() {
    setState(() => _open = !_open);
    if (_open) {
      // setelah daftar terbuka, gulir supaya kolom + daftar terlihat
      Future.delayed(const Duration(milliseconds: 260), () {
        final ctx = _anchor.currentContext;
        if (!mounted || ctx == null) return;
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.05,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Widget _item(String c) {
    final selected = c == widget.value;
    return Material(
      color: selected ? AppColors.link : Colors.transparent,
      child: InkWell(
        onTap: () {
          widget.onChanged(c);
          setState(() => _open = false);
        },
        child: Container(
          height: 44,
          width: double.infinity,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            c,
            style: TextStyle(
              fontSize: 15,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? Colors.white : AppColors.textDark,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      key: _anchor,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ---- kolom
        Material(
          color: _fill,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _toggle,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14.5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _open ? AppColors.border : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.value,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down_rounded),
                  ),
                ],
              ),
            ),
          ),
        ),
        // ---- daftar (di bawah kolom)
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: _open
              ? Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: _fill,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: Column(
                      children: [for (final c in widget.options) _item(c)],
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

// ======================================================== Buat / ubah planning

Future<void> showCreatePlanningSheet(BuildContext context) async {
  final saved = await _show<bool>(context, const _PlanFormSheet());
  if (saved == true && context.mounted) {
    Helpers.showSnack(context, 'Rencana dibuat.');
  }
}

class _PlanFormSheet extends StatefulWidget {
  /// null = buat baru, isi = ubah planning ini.
  final Planning? editing;
  const _PlanFormSheet({this.editing});

  @override
  State<_PlanFormSheet> createState() => _PlanFormSheetState();
}

class _PlanFormSheetState extends State<_PlanFormSheet> {
  final _name = TextEditingController();
  final _budget = TextEditingController();
  final _saved = TextEditingController();
  final _dateText = TextEditingController();
  final _alloc = TextEditingController();

  String _category = Planning.categories.first;
  PlanFrequency _freq = PlanFrequency.daily;
  DateTime? _target;

  bool get _isEdit => widget.editing != null;

  int get _budgetValue => Fmt.parseAmount(_budget.text);
  int get _savedValue => Fmt.parseAmount(_saved.text);
  int get _allocValue => Fmt.parseAmount(_alloc.text);

  /// Dana yang sudah terkumpul (saat ubah: dari planning, bukan dari kolom).
  int get _alreadySaved => _isEdit ? widget.editing!.saved : _savedValue;

  bool get _savedTooBig =>
      !_isEdit &&
      _budgetValue > 0 &&
      _savedValue > 0 &&
      _savedValue >= _budgetValue;

  bool get _budgetTooSmall =>
      _isEdit && _budgetValue > 0 && _budgetValue < widget.editing!.saved;

  bool get _canSave =>
      _name.text.trim().isNotEmpty &&
      _budgetValue > 0 &&
      _target != null &&
      _allocValue > 0 &&
      (_isEdit ? !_budgetTooSmall : _savedValue < _budgetValue);

  /// Saran setoran per periode (hanya saran, nominal tetap diisi sendiri).
  int? get _suggestion {
    if (_target == null || _budgetValue <= _alreadySaved) return null;
    return _freq.allocationFor(_budgetValue - _alreadySaved, _target!);
  }

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    if (e != null) {
      _name.text = e.name;
      _budget.text = _plain(e.budget);
      _category = e.category;
      _freq = e.frequency;
      _target = e.target;
      _dateText.text = Fmt.slashDate(e.target);
      _alloc.text = _plain(e.allocation);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _budget.dispose();
    _saved.dispose();
    _dateText.dispose();
    _alloc.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await _pickTargetDate(context, _target);
    if (picked == null) return;
    setState(() {
      _target = picked;
      _dateText.text = Fmt.slashDate(picked);
    });
  }

  void _save() {
    final store = PlanningStore.instance;
    if (_isEdit) {
      store.update(
        widget.editing!.id,
        name: _name.text,
        category: _category,
        budget: _budgetValue,
        target: _target!,
        frequency: _freq,
        allocation: _allocValue,
      );
    } else {
      store.add(
        name: _name.text,
        category: _category,
        budget: _budgetValue,
        saved: _savedValue,
        target: _target!,
        frequency: _freq,
        allocation: _allocValue,
      );
    }
    Navigator.pop(context, true);
  }

  Widget _hint() {
    const grey = TextStyle(fontSize: 12, color: AppColors.textGrey, height: 1.4);
    final s = _suggestion;
    if (s == null) {
      return const Text(
        'Isi budget dan target selesai untuk melihat saran setoran.',
        style: grey,
      );
    }
    final n = _freq.periodsUntil(_target!);
    return Text.rich(
      TextSpan(
        style: grey,
        children: [
          const TextSpan(text: 'Saran: '),
          TextSpan(
            text: '${Fmt.rupiah(s)}/${_freq.unit}',
            style: const TextStyle(
                fontWeight: FontWeight.w800, color: AppColors.textDark),
          ),
          TextSpan(
              text:
                  ' ($n ${_freq.unit} sampai target). Nominal tetap kamu isi sendiri.'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SheetFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_isEdit ? 'Ubah rencana' : 'Buat rencana',
              style:
                  const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
          const FieldLabel('Nama rencana'),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: flowlyField('Contoh: Bali, Laptop, Motor'),
            onChanged: (_) => setState(() {}),
          ),
          const FieldLabel('Rencana Anggaran (Rp)'),
          AmountField(
            controller: _budget,
            errorText: _budgetTooSmall
                  ? 'Tidak boleh kurang dari dana terkumpul.'
                  : null,
            onChanged: (_) => setState(() {}),
          ),
          if (!_isEdit) ...[
            const FieldLabel('Sudah terkumpul (Rp, opsional)'),
            AmountField(
              controller: _saved,
              errorText: _savedTooBig ? 'Harus lebih kecil dari budget.' : null,
              onChanged: (_) => setState(() {}),
            ),
          ],
          const FieldLabel('Kategori'),
          _CategoryField(
            value: _category,
            options: Planning.categories,
            onChanged: (v) => setState(() => _category = v),
          ),
          const FieldLabel('Target selesai'),
          _DateField(
            controller: _dateText,
            onPickCalendar: _pickDate,
            onChanged: (d) => setState(() => _target = d),
            first: _targetFirst(),
            last: _targetLast(),
            rangeError: 'Pilih tanggal setelah hari ini.',
          ),
          const FieldLabel('Saran alokasi'),
          SegmentedTabs<PlanFrequency>(
            values: PlanFrequency.values,
            selected: _freq,
            labelOf: (f) => f.label,
            expand: true,
            onChanged: (f) => setState(() => _freq = f),
          ),
          const SizedBox(height: 10),
          _hint(),
          FieldLabel('Nominal setoran (Rp)'),
          AmountField(
            controller: _alloc,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 22),
          PrimaryButton(
            label: _isEdit ? 'Simpan perubahan' : 'Simpan rencana',
            onPressed: _canSave ? _save : null,
          ),
        ],
      ),
    );
  }
}

// ==================================================== Detail & setor dana

Future<void> showPlanningDetailSheet(BuildContext context, int id) async {
  final result = await _show<String>(context, _PlanningDetailSheet(id: id));
  if (!context.mounted) return;
  if (result == 'delete') Helpers.showSnack(context, 'Rencana dihapus.');
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
            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _PlanningDetailSheet extends StatefulWidget {
  final int id;
  const _PlanningDetailSheet({required this.id});

  @override
  State<_PlanningDetailSheet> createState() => _PlanningDetailSheetState();
}

class _PlanningDetailSheetState extends State<_PlanningDetailSheet> {
  final _store = PlanningStore.instance;
  final _amount = TextEditingController();
  final _dateText = TextEditingController();

  late DateTime _date = _today();
  bool _dateValid = true; // false kalau tanggal yang diketik belum valid

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  @override
  void initState() {
    super.initState();
    _dateText.text = Fmt.slashDate(_date);
    final p = _store.byId(widget.id);
    if (p != null) _applySuggestion(p);
  }

  @override
  void dispose() {
    _amount.dispose();
    _dateText.dispose();
    super.dispose();
  }

  /// Isi kolom nominal dengan alokasi planning (maksimal sisa target).
  void _applySuggestion(Planning p) {
    final s = p.allocation > p.remaining ? p.remaining : p.allocation;
    _amount.text = s > 0 ? _plain(s) : '';
  }

  Future<void> _pickDate() async {
    final picked = await _pickDepositDate(context, _date);
    if (picked == null) return;
    setState(() {
      _date = picked;
      _dateValid = true;
      _dateText.text = Fmt.slashDate(picked);
    });
  }

  void _deposit(Planning p, int amount) {
    _store.deposit(p.id, amount, date: _date);
    final fresh = _store.byId(p.id);
    setState(() {
      _date = _today(); // kembali ke hari ini
      _dateText.text = Fmt.slashDate(_date);
      if (fresh != null) _applySuggestion(fresh);
    });
  }

  Future<void> _edit(Planning p) async {
    await _show<bool>(context, _PlanFormSheet(editing: p));
    if (!mounted) return;
    final fresh = _store.byId(p.id);
    if (fresh != null) setState(() => _applySuggestion(fresh));
  }

  Future<void> _confirmDeletePlan(Planning p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hapus rencana ${p.name}?'),
        content: const Text('Tindakan ini tidak bisa dibatalkan.'),
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
    if (ok != true || !mounted) return;
    _store.remove(p.id);
    Navigator.pop(context, 'delete');
  }

  Future<void> _confirmDeleteDeposit(Planning p, PlanDeposit d) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hapus setoran ${Fmt.rupiah(d.amount)}?'),
        content: const Text('Dana terkumpul akan berkurang sebesar nominal ini.'),
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
    if (ok != true || !mounted) return;
    _store.removeDeposit(p.id, d.id);
    final fresh = _store.byId(p.id);
    if (fresh != null) setState(() => _applySuggestion(fresh));
  }

  /// Terbaru dulu (tanggal, lalu urutan dicatat). "Terkumpul awal" selalu di bawah.
  List<PlanDeposit> _sorted(Planning p) {
    final entries = <MapEntry<int, PlanDeposit>>[];
    for (var i = 0; i < p.deposits.length; i++) {
      entries.add(MapEntry(i, p.deposits[i]));
    }
    entries.sort((a, b) {
      if (a.value.isInitial != b.value.isInitial) {
        return a.value.isInitial ? 1 : -1;
      }
      final c = b.value.date.compareTo(a.value.date);
      return c != 0 ? c : b.key.compareTo(a.key);
    });
    return entries.map((e) => e.value).toList();
  }

  Widget _historyRow(Planning p, PlanDeposit d, {required bool last}) {
    final fin = FinanceStore.instance;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFE3EAFB))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fin.money(d.amount),
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  d.isInitial ? 'Terkumpul awal' : Fmt.fullDate(d.date),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textGrey),
                ),
              ],
            ),
          ),
          if (!d.isInitial)
            TextButton(
              onPressed: () => _confirmDeleteDeposit(p, d),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 36),
              ),
              child: const Text('Hapus',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fin = FinanceStore.instance;
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        final p = _store.byId(widget.id);
        if (p == null) return const SizedBox.shrink();

        final amount = Fmt.parseAmount(_amount.text);
        final payable = amount > p.remaining ? p.remaining : amount;
        final history = _sorted(p);

        return SheetFrame(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.name,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(
                '${p.category} • ${fin.money(p.saved)} dari ${fin.money(p.budget)}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textDark),
              ),
              if (!p.isDone) ...[
                const _SmallLabel('Tanggal setoran'),
                _DateField(
                  controller: _dateText,
                  onPickCalendar: _pickDate,
                  onChanged: (d) => setState(() {
                    _dateValid = d != null;
                    if (d != null) _date = d;
                  }),
                  first: _depositFirst(),
                  last: _depositLast(),
                  rangeError: 'Tidak boleh lewat dari hari ini.',
                ),
                const _SmallLabel('Nominal setoran (Rp)'),
                AmountField(
                  controller: _amount,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sisa target ${fin.money(p.remaining)} • Saran setoran ${fin.money(p.allocation)}/${p.frequency.unit}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textGrey),
                ),
                const SizedBox(height: 14),
                PrimaryButton(
                  label: payable > 0 ? 'Setor ${Fmt.rupiah(payable)}' : 'Setor',
                  onPressed: (payable > 0 && _dateValid)
                      ? () => _deposit(p, payable)
                      : null,
                ),
              ] else
                const Padding(
                  padding: EdgeInsets.only(top: 14),
                  child: Text('Target tercapai!',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _OutlineBtn(
                      label: 'Ubah',
                      color: AppColors.textDark,
                      onTap: () => _edit(p),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _OutlineBtn(
                      label: 'Hapus',
                      color: AppColors.primary,
                      onTap: () => _confirmDeletePlan(p),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Riwayat setoran',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              if (history.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text('Belum ada setoran.',
                      style: TextStyle(
                          fontSize: 12.5, color: AppColors.textGrey)),
                )
              else
                for (var i = 0; i < history.length; i++)
                  _historyRow(p, history[i], last: i == history.length - 1),
            ],
          ),
        );
      },
    );
  }
}

// ======================================================= Kalkulator tabungan

Future<void> showSavingsCalculatorSheet(BuildContext context) =>
    _show<void>(context, const _CalculatorSheet());

class _CalculatorSheet extends StatefulWidget {
  const _CalculatorSheet();

  @override
  State<_CalculatorSheet> createState() => _CalculatorSheetState();
}

class _CalculatorSheetState extends State<_CalculatorSheet> {
  final _goal = TextEditingController();
  final _saved = TextEditingController();
  final _dateText = TextEditingController();
  DateTime? _target;

  @override
  void dispose() {
    _goal.dispose();
    _saved.dispose();
    _dateText.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await _pickTargetDate(context, _target);
    if (picked == null) return;
    setState(() {
      _target = picked;
      _dateText.text = Fmt.slashDate(picked);
    });
  }

  @override
  Widget build(BuildContext context) {
    final goal = Fmt.parseAmount(_goal.text);
    final saved = Fmt.parseAmount(_saved.text);
    final remaining = goal - saved;

    return SheetFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Kalkulator tabungan',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
          const FieldLabel('Target dana (Rp)'),
          AmountField(
            controller: _goal,
            onChanged: (_) => setState(() {}),
          ),
          const FieldLabel('Sudah terkumpul (Rp, opsional)'),
          AmountField(
            controller: _saved,
            onChanged: (_) => setState(() {}),
          ),
          const FieldLabel('Target selesai'),
          _DateField(
            controller: _dateText,
            onPickCalendar: _pickDate,
            onChanged: (d) => setState(() => _target = d),
            first: _targetFirst(),
            last: _targetLast(),
            rangeError: 'Pilih tanggal setelah hari ini.',
          ),
          const SizedBox(height: 18),
          if (goal > 0 && _target != null && remaining <= 0)
            const Text('Target sudah tercapai.',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700))
          else if (goal > 0 && _target != null) ...[
            Text('Sisa yang perlu dikumpulkan: ${Fmt.rupiah(remaining)}',
                style: const TextStyle(
                    fontSize: 12.5, color: AppColors.textGrey)),
            const SizedBox(height: 10),
            for (final f in PlanFrequency.values)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3EAFB),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Text(f.label,
                        style: const TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text(
                      '${Fmt.rupiah(f.allocationFor(remaining, _target!))}/${f.unit}',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
          ] else
            const Text(
              'Isi target dana dan tanggal selesai untuk melihat setoran yang dibutuhkan.',
              style: TextStyle(fontSize: 12.5, color: AppColors.textGrey),
            ),
        ],
      ),
    );
  }
}