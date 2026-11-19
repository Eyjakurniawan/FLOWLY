import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../services/supabase_service.dart';
import '../../utils/app_colors.dart';
import 'number_pad.dart';

/// Kartu putih berujung bulat yang dipakai di semua section.
class FlowlyCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const FlowlyCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(28);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: const [
          BoxShadow(
            color: Color(0x14122B5E),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Tab pil (Weekly | Monthly | Yearly, Semua | Masuk | Keluar).
class SegmentedTabs<T> extends StatelessWidget {
  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;
  final bool expand;

  const SegmentedTabs({
    super.key,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final items = values.map((v) {
      final active = v == selected;
      final pill = AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(13),
          boxShadow: active
              ? const [
                  BoxShadow(
                    color: Color(0x1A122B5E),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          labelOf(v),
          maxLines: 1,
          style: TextStyle(
            fontSize: 13,
            fontWeight: active ? FontWeight.w800 : FontWeight.w600,
            color: active ? AppColors.textDark : const Color(0xFF5B6B8F),
          ),
        ),
      );
      final tappable = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(v),
        child: pill,
      );
      return expand ? Expanded(child: tappable) : tappable;
    }).toList();

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE3EAFB),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: items,
      ),
    );
  }
}

/// Pil pilihan (kategori, dompet, jenis). Terpilih = hitam.
class ChoiceBubble extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final bool outlined; // gaya "+ Tambah dompet"

  const ChoiceBubble({
    super.key,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.icon,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : AppColors.textDark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.textDark
              : (outlined ? Colors.white : const Color(0xFFE3EAFB)),
          borderRadius: BorderRadius.circular(18),
          border: outlined
              ? Border.all(color: const Color(0xFFB8C4E6), width: 1.2)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 6),
            ],
            Text(label,
                style: TextStyle(
                    fontSize: 13.5, fontWeight: FontWeight.w600, color: fg)),
          ],
        ),
      ),
    );
  }
}

/// Gaya kolom isian biru muda seperti di desain.
InputDecoration flowlyField(String hint, {String? error}) {
  return InputDecoration(
    hintText: hint,
    errorText: error,
    filled: true,
    fillColor: const Color(0xFFE3EAFB),
    hintStyle: const TextStyle(color: AppColors.hint, fontSize: 14),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
  );
}

class FieldLabel extends StatelessWidget {
  final String text;
  const FieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 8),
        child: Text(text,
            style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textGrey)),
      );
}

/// Tinggi maksimal semua pop-up yang naik dari bawah (80% layar).
/// Isi yang lebih panjang bisa digulir; yang pendek menyesuaikan isinya.
const double kSheetMaxHeightFactor = 0.8;

/// Satu-satunya cara membuka pop-up bawah (selain Catat transaksi),
/// supaya tampilannya seragam: tidak menutup seluruh layar, bisa digulir,
/// dan naik mengikuti keyboard saat mengetik.
Future<T?> showFlowlySheet<T>(BuildContext context, WidgetBuilder builder) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    useRootNavigator: true, // tampil di atas navbar bawah
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => _SheetCap(child: builder(ctx)),
  );
}

class _SheetCap extends StatelessWidget {
  final Widget child;
  const _SheetCap({required this.child});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final kb = mq.viewInsets.bottom;
    return LayoutBuilder(builder: (context, c) {
      final cap = math.min(mq.size.height * kSheetMaxHeightFactor,
          math.max(0.0, c.maxHeight - kb));
      return Padding(
        // Keyboard mendorong sheet naik, tinggi isi tetap terjaga.
        padding: EdgeInsets.only(bottom: kb),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: cap),
          child: child,
        ),
      );
    });
  }
}

/// Pop-up "Pilih bulan" (dipakai Beranda & Laporan).
Future<DateTime?> showMonthPickerSheet(
    BuildContext context, DateTime selected) {
  return showFlowlySheet<DateTime>(
    context,
    (ctx) => _MonthPickerSheet(selected: selected),
  );
}

class _MonthPickerSheet extends StatefulWidget {
  final DateTime selected;
  const _MonthPickerSheet({required this.selected});

  @override
  State<_MonthPickerSheet> createState() => _MonthPickerSheetState();
}

class _MonthPickerSheetState extends State<_MonthPickerSheet> {
  late int _year;

  /// Bulan pendaftaran user. Bulan sebelumnya tetap tampil tapi abu-abu
  /// dan tidak bisa dipilih. Kalau data akun tidak ada, pakai bulan ini.
  static DateTime _signupMonth() {
    DateTime? d;
    try {
      final raw = SupabaseService.client.auth.currentUser?.createdAt;
      if (raw != null) d = DateTime.tryParse(raw)?.toLocal();
    } catch (_) {}
    d ??= DateTime.now();
    return DateTime(d.year, d.month);
  }

  late final DateTime _signup = _signupMonth();

  /// Rentang riwayat: dari bulan daftar sampai bulan ini (tidak bisa ke
  /// masa depan). Tahun paling awal = tahun daftar, paling akhir = tahun ini.
  late final int _minYear = _signup.year;
  late final int _maxYear = DateTime.now().year;

  bool _monthEnabled(int year, int month) {
    final m = DateTime(year, month);
    final now = DateTime.now();
    return !m.isBefore(_signup) && !m.isAfter(DateTime(now.year, now.month));
  }

  static const _monthLabels = [
    'Jan', 'Feb', 'Mar',
    'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep',
    'Okt', 'Nov', 'Des',
  ];

  @override
  void initState() {
    super.initState();
    _year = widget.selected.year.clamp(_minYear, _maxYear);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final bottomSafe = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomSafe),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header: < 2026 >
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, size: 24),
                color: const Color(0xFF0F172A),
                disabledColor: const Color(0xFFCBD5E1),
                splashRadius: 20,
                // Abu-abu & tidak bisa ditekan di tahun paling awal.
                onPressed:
                    _year > _minYear ? () => setState(() => _year--) : null,
              ),
              Text(
                '$_year',
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, size: 24),
                color: const Color(0xFF0F172A),
                disabledColor: const Color(0xFFCBD5E1),
                splashRadius: 20,
                // Abu-abu & tidak bisa ditekan di tahun paling akhir.
                onPressed:
                    _year < _maxYear ? () => setState(() => _year++) : null,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Grid 4 baris x 3 kolom
          for (int row = 0; row < 4; row++) ...[
            if (row > 0) const SizedBox(height: 10),
            Row(
              children: [
                for (int col = 0; col < 3; col++) ...[
                  if (col > 0) const SizedBox(width: 10),
                  Expanded(
                    child: _buildMonthButton(
                      month: row * 3 + col + 1,
                      label: _monthLabels[row * 3 + col],
                      now: now,
                    ),
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: 18),

          // Tombol "Bulan ini"
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF0F172A), width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
              onPressed: () {
                Navigator.pop(context, DateTime(now.year, now.month));
              },
              child: const Text(
                'Bulan ini',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthButton({
    required int month,
    required String label,
    required DateTime now,
  }) {
    final isSelected =
        widget.selected.year == _year && widget.selected.month == month;
    final Color bg;
    final Color textColor;
    final FontWeight fontWeight;
    final enabled = _monthEnabled(_year, month);

    if (!enabled) {
      // Sebelum bulan daftar atau setelah bulan ini: abu-abu, tidak bisa dipilih.
      bg = const Color(0xFFF1F5F9);
      textColor = const Color(0xFFC3C9DA);
      fontWeight = FontWeight.w600;
    } else if (isSelected) {
      bg = const Color(0xFF0F172A);
      textColor = Colors.white;
      fontWeight = FontWeight.w700;
    } else {
      bg = const Color(0xFFF1F5F9);
      textColor = const Color(0xFF0F172A);
      fontWeight = FontWeight.w600;
    }

    return SizedBox(
      height: 48,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: enabled
              ? () => Navigator.pop(context, DateTime(_year, month))
              : null,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: fontWeight,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Kerangka bottom sheet: pegangan, bisa di-scroll, dan menjadi "rumah"
/// keypad angka untuk semua [AmountField] di dalamnya.
///
/// Saat sebuah [AmountField] diketuk, keyboard bawaan tidak muncul;
/// yang muncul hanya [NumberPad] di dasar sheet. Isian nominal tetap di
/// tempatnya (tidak naik ke atas seperti di Catat transaksi).
class SheetFrame extends StatefulWidget {
  final Widget child;
  const SheetFrame({super.key, required this.child});

  @override
  State<SheetFrame> createState() => _SheetFrameState();
}

class _ActiveAmount {
  final TextEditingController controller;
  final FocusNode focus;
  final ValueChanged<String>? onChanged;
  final BuildContext fieldContext;
  const _ActiveAmount(
      this.controller, this.focus, this.onChanged, this.fieldContext);
}

class _SheetFrameState extends State<SheetFrame> {
  _ActiveAmount? _active;

  void _show(_ActiveAmount a) {
    setState(() => _active = a);
    // Pastikan kolom yang sedang diisi tidak tertutup keypad.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !a.fieldContext.mounted) return;
      Scrollable.ensureVisible(
        a.fieldContext,
        alignment: 0.3,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
  }

  void _hide(FocusNode focus) {
    if (_active?.focus == focus && mounted) setState(() => _active = null);
  }

  void _press(String key) {
    final a = _active;
    if (a == null) return;
    if (applyPadKey(a.controller, key)) a.onChanged?.call(a.controller.text);
  }

  void _clear() {
    final a = _active;
    if (a == null || a.controller.text.isEmpty) return;
    a.controller.clear();
    a.onChanged?.call('');
  }

  void _done() => _active?.focus.unfocus();

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.of(context).padding.bottom;
    return _KeypadScope(
      show: _show,
      hide: _hide,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              // Ketuk area kosong = tutup keypad / keyboard.
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                    20, 10, 20, _active == null ? 24 : 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD3DAEC),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    widget.child,
                  ],
                ),
              ),
            ),
          ),
          if (_active != null)
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomSafe),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE3EAFB))),
              ),
              child: NumberPad(
                onKey: _press,
                onClear: _clear,
                onDone: _done,
              ),
            ),
        ],
      ),
    );
  }
}

class _KeypadScope extends InheritedWidget {
  final void Function(_ActiveAmount) show;
  final void Function(FocusNode) hide;
  const _KeypadScope(
      {required this.show, required this.hide, required super.child});

  static _KeypadScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_KeypadScope>();

  @override
  bool updateShouldNotify(_KeypadScope old) => false;
}

/// Kolom nominal (Rp) yang memakai keypad angka milik [SheetFrame].
/// Gunakan sebagai pengganti `TextField` + `ThousandsFormatter`.
class AmountField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  /// true = tampilan besar "Nominal / Rp0" (dipakai di Catat transaksi).
  final bool large;

  const AmountField({
    super.key,
    required this.controller,
    this.hint = '0',
    this.errorText,
    this.onChanged,
    this.large = false,
  });

  @override
  State<AmountField> createState() => _AmountFieldState();
}

class _AmountFieldState extends State<AmountField> {
  final _focus = FocusNode();
  _KeypadScope? _scope;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scope = _KeypadScope.maybeOf(context);
  }

  void _onFocus() {
    // Untuk garis tepi saat fokus (mode large).
    if (mounted) setState(() {});
    final scope = _scope;
    if (scope == null) return;
    if (_focus.hasFocus) {
      scope.show(_ActiveAmount(
          widget.controller, _focus, widget.onChanged, context));
    } else {
      scope.hide(_focus);
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    _focus.dispose();
    super.dispose();
  }

  /// Tampilan besar: label "Nominal" ada DI DALAM kotak, di atas angka.
  Widget _buildLarge() {
    final hasError = widget.errorText != null;
    // Nominal ikut merah saat ada error (mis. melebihi saldo).
    final big = TextStyle(
      fontSize: 28,
      height: 1.15,
      fontWeight: FontWeight.w800,
      color: hasError ? AppColors.primary : AppColors.textDark,
    );
    // Border tetap hitam saat error; hanya tulisan yang jadi merah.
    final borderColor = (hasError || _focus.hasFocus)
        ? AppColors.border
        : Colors.transparent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _focus.requestFocus(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: const Color(0xFFE3EAFB),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor, width: 1.4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Label tetap warna biasa walau nominal error (hanya angka yang merah).
                const Text('Nominal',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textGrey)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text('Rp', style: big),
                    Expanded(
                      child: TextField(
                        controller: widget.controller,
                        focusNode: _focus,
                        readOnly: true, // keyboard bawaan tidak muncul
                        showCursor: false,
                        enableInteractiveSelection: false,
                        keyboardType: TextInputType.none,
                        // Ketukan di keypad (di luar kolom ini) jangan
                        // menghilangkan fokus (di web default-nya begitu).
                        onTapOutside: (_) {},
                        style: big,
                        decoration: InputDecoration(
                          isCollapsed: true,
                          filled: false,
                          border: InputBorder.none,
                          hintText: widget.hint,
                          hintStyle: big,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Pesan error tidak ditampilkan di sini; form yang memakainya
        // menaruh pesannya sendiri (mis. di bawah kolom catatan).
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.large) return _buildLarge();
    final base = flowlyField(widget.hint, error: widget.errorText);
    return TextField(
      controller: widget.controller,
      focusNode: _focus,
      readOnly: true, // keyboard bawaan tidak muncul
      showCursor: false,
      enableInteractiveSelection: false,
      keyboardType: TextInputType.none,
      // Ketukan di keypad (di luar kolom ini) jangan menghilangkan fokus.
      // Di web/desktop default Flutter-nya melepas fokus, sehingga keypad
      // langsung tertutup begitu tombolnya diklik.
      onTapOutside: (_) {},
      decoration: base.copyWith(
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border, width: 1.4),
        ),
      ),
    );
  }
}