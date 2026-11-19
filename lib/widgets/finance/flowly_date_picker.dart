import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';
import '../../utils/formatters.dart';

/// Kalender kecil gaya Flowly (pengganti showDatePicker bawaan Flutter).
///
/// - Header "Bulan Tahun ▾": ketuk untuk memilih bulan/tahun.
/// - Panah naik/turun: pindah bulan.
/// - Ketuk tanggal: langsung terpilih dan kalender menutup.
/// - Tanggal di luar [firstDate]..[lastDate] tampil abu-abu dan tidak bisa dipilih.
///
/// Mengembalikan null kalau dibatalkan.
Future<DateTime?> showFlowlyDatePicker(
  BuildContext context, {
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  return showDialog<DateTime>(
    context: context,
    barrierColor: Colors.black38,
    builder: (_) => _FlowlyCalendar(
      initial: initialDate,
      first: firstDate,
      last: lastDate,
    ),
  );
}

class _FlowlyCalendar extends StatefulWidget {
  final DateTime initial;
  final DateTime first;
  final DateTime last;
  const _FlowlyCalendar({
    required this.initial,
    required this.first,
    required this.last,
  });

  @override
  State<_FlowlyCalendar> createState() => _FlowlyCalendarState();
}

class _FlowlyCalendarState extends State<_FlowlyCalendar> {
  static const _dow = ['Mg', 'Sn', 'Sl', 'Rb', 'Km', 'Jm', 'Sb']; // Minggu dulu
  static const _disabled = Color(0xFFC3C9DA);

  late final DateTime _first;
  late final DateTime _last;
  late final DateTime _selected;
  late DateTime _view; // tanggal 1 pada bulan yang sedang tampil
  bool _pickMonth = false;
  late int _pickYear;

  @override
  void initState() {
    super.initState();
    _first = DateUtils.dateOnly(widget.first);
    _last = DateUtils.dateOnly(widget.last);
    var i = DateUtils.dateOnly(widget.initial);
    if (i.isBefore(_first)) i = _first;
    if (i.isAfter(_last)) i = _last;
    _selected = i;
    _view = DateTime(i.year, i.month);
    _pickYear = i.year;
  }

  // ------------------------------------------------------------ aturan

  bool _dayOk(DateTime d) => !d.isBefore(_first) && !d.isAfter(_last);

  bool _monthOk(int y, int m) {
    final start = DateTime(y, m, 1);
    final end = DateTime(y, m + 1, 0);
    return !end.isBefore(_first) && !start.isAfter(_last);
  }

  bool _yearOk(int y) => y >= _first.year && y <= _last.year;

  void _shift(int delta) {
    if (_pickMonth) {
      final y = _pickYear + delta;
      if (_yearOk(y)) setState(() => _pickYear = y);
      return;
    }
    final t = DateTime(_view.year, _view.month + delta);
    if (_monthOk(t.year, t.month)) setState(() => _view = t);
  }

  bool _canShift(int delta) {
    if (_pickMonth) return _yearOk(_pickYear + delta);
    final t = DateTime(_view.year, _view.month + delta);
    return _monthOk(t.year, t.month);
  }

  // ------------------------------------------------------------- bagian

  Widget _arrow(IconData icon, int delta) {
    final ok = _canShift(delta);
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: ok ? () => _shift(delta) : null,
      child: SizedBox(
        width: 32,
        height: 32,
        child: Icon(icon, size: 22, color: ok ? AppColors.textDark : _disabled),
      ),
    );
  }

  Widget _header() {
    final title = _pickMonth ? '$_pickYear' : Fmt.monthYear(_view);
    return Row(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() {
            _pickMonth = !_pickMonth;
            _pickYear = _view.year;
          }),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 13.5, fontWeight: FontWeight.w800)),
                Icon(
                  _pickMonth
                      ? Icons.arrow_drop_up_rounded
                      : Icons.arrow_drop_down_rounded,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        _arrow(Icons.keyboard_arrow_up_rounded, -1),
        _arrow(Icons.keyboard_arrow_down_rounded, 1),
      ],
    );
  }

  Widget _weekdays() {
    return Row(
      children: [
        for (final d in _dow)
          Expanded(
            child: Center(
              child: Text(d,
                  style: const TextStyle(
                      fontSize: 11.5, fontWeight: FontWeight.w700)),
            ),
          ),
      ],
    );
  }

  Widget _cell(DateTime d, DateTime today) {
    final inMonth = d.month == _view.month;
    final ok = _dayOk(d);
    final sel = DateUtils.isSameDay(d, _selected);
    final isToday = DateUtils.isSameDay(d, today);

    Color fg = !ok
        ? _disabled
        : (inMonth ? AppColors.textDark : AppColors.textGrey);
    if (sel) fg = Colors.white;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: ok ? () => Navigator.of(context).pop(d) : null,
        child: Container(
          height: 34,
          margin: const EdgeInsets.all(1.5),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: sel ? AppColors.link : null,
            borderRadius: BorderRadius.circular(8),
            border: (isToday && !sel)
                ? Border.all(color: AppColors.link, width: 1.2)
                : null,
          ),
          child: Text(
            '${d.day}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: (sel || isToday) ? FontWeight.w700 : FontWeight.w500,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }

  Widget _days(DateTime today) {
    final leading = _view.weekday % 7; // Minggu = 0
    return Column(
      children: [
        for (var r = 0; r < 6; r++)
          Row(
            children: [
              for (var c = 0; c < 7; c++)
                _cell(
                  DateTime(_view.year, _view.month, 1 - leading + r * 7 + c),
                  today,
                ),
            ],
          ),
      ],
    );
  }

  Widget _monthCell(int m) {
    final ok = _monthOk(_pickYear, m);
    final sel = _view.year == _pickYear && _view.month == m;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: ok
            ? () => setState(() {
                  _view = DateTime(_pickYear, m);
                  _pickMonth = false;
                })
            : null,
        child: Container(
          height: 40,
          margin: const EdgeInsets.all(3),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: sel ? AppColors.link : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            Fmt.monthShort(m),
            style: TextStyle(
              fontSize: 13,
              fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
              color: sel
                  ? Colors.white
                  : (ok ? AppColors.textDark : _disabled),
            ),
          ),
        ),
      ),
    );
  }

  Widget _monthGrid() {
    return Column(
      children: [
        for (var r = 0; r < 4; r++)
          Row(children: [
            for (var c = 0; c < 3; c++) _monthCell(r * 3 + c + 1),
          ]),
      ],
    );
  }

  Widget _footer(DateTime today) {
    final todayOk = _dayOk(today);
    return Row(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).pop(),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Text('Batal',
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textGrey)),
          ),
        ),
        const Spacer(),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: todayOk ? () => Navigator.of(context).pop(today) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text('Hari ini',
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: todayOk ? AppColors.link : _disabled)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: SizedBox(
        width: 292,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _header(),
              const SizedBox(height: 6),
              if (_pickMonth)
                _monthGrid()
              else ...[
                _weekdays(),
                const SizedBox(height: 4),
                _days(today),
              ],
              const SizedBox(height: 6),
              _footer(today),
            ],
          ),
        ),
      ),
    );
  }
}