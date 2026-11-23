import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/finance_models.dart';
import '../../services/finance_store.dart';
import '../../utils/app_colors.dart';
import 'common.dart';

const _incomeColor = AppColors.link;
const _expenseColor = AppColors.primary;
const _expenseText = Color(0xFFC2371F);

class CashflowCard extends StatefulWidget {
  const CashflowCard({super.key});

  @override
  State<CashflowCard> createState() => _CashflowCardState();
}

class _CashflowCardState extends State<CashflowCard> {
  final _store = FinanceStore.instance;
  Period _period = Period.monthly;
  int? _picked; // null = ikut default (periode berjalan)

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        final points = _store.cashflow(_period);
        final index =
            (_picked ?? _store.defaultIndex(_period)).clamp(0, points.length - 1);
        final sel = points[index];
        final income = _store.incomeOf(_period);
        final expense = _store.expenseOf(_period);
        final diff = income - expense;
        final labelStyle = TextStyle(
          fontSize: 11.5,
          color: AppColors.textGrey,
          fontFamily: DefaultTextStyle.of(context).style.fontFamily,
        );

        return FlowlyCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Arus kas',
                      style:
                          TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: SegmentedTabs<Period>(
                        values: Period.values,
                        selected: _period,
                        labelOf: (p) => p.label,
                        onChanged: (p) => setState(() {
                          _period = p;
                          _picked = null;
                        }),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text.rich(
                TextSpan(
                  style:
                      const TextStyle(fontSize: 12.5, color: AppColors.textGrey),
                  children: [
                    TextSpan(
                      text: sel.fullLabel,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark),
                    ),
                    TextSpan(
                      text:
                      ' • Pemasukan ${_store.moneyCompact(sel.income)} • Pengeluaran ${_store.moneyCompact(sel.expense)}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 190,
                child: LayoutBuilder(
                  builder: (context, c) {
                    void pick(double dx) {
                      final n = points.length;
                      final step = (c.maxWidth - 2 * _CashPainter.padX) / (n - 1);
                      final i = ((dx - _CashPainter.padX) / step).round();
                      setState(() => _picked = i.clamp(0, n - 1));
                    }

                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (d) => pick(d.localPosition.dx),
                      onHorizontalDragUpdate: (d) => pick(d.localPosition.dx),
                      child: CustomPaint(
                        size: Size(c.maxWidth, 190),
                        painter: _CashPainter(
                          points: points,
                          selected: index,
                          labelStyle: labelStyle,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              const Row(
                children: [
                  _Legend(color: _incomeColor, text: 'Pemasukan'),
                  SizedBox(width: 18),
                  _Legend(color: _expenseColor, text: 'Pengeluaran'),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Divider(height: 1, color: Color(0xFFE3EAFB)),
              ),
              Text(_store.periodLabel(_period),
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textGrey)),
              const SizedBox(height: 10),
              _StatsRow(
                stats: [
                  _StatData('Pemasukan', _store.money(income), _incomeColor),
                  _StatData(
                      'Pengeluaran', _store.money(expense), _expenseText),
                  _StatData(
                      'Selisih', _store.signedMoney(diff), AppColors.textDark),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String text;
  const _Legend({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}

class _StatData {
  final String label;
  final String value;
  final Color color;
  const _StatData(this.label, this.value, this.color);
}

/// Tiga angka (Pemasukan, Pengeluaran, Selisih) dengan jarak antar kolom
/// yang tetap. Kalau ada nominal yang kepanjangan, ukuran font ketiga
/// angka diperkecil bersama-sama (satu ukuran yang sama) sampai semuanya
/// muat di kolomnya, jadi jaraknya tidak pernah menyempit.
class _StatsRow extends StatelessWidget {
  final List<_StatData> stats;
  const _StatsRow({required this.stats});

  static const double _gap = 14;
  static const double _maxFont = 15;
  static const double _minFont = 9;

  /// Ukuran font terbesar (<= _maxFont) yang membuat semua nominal muat.
  double _fitFontSize(BuildContext context, double colWidth) {
    final base = DefaultTextStyle.of(context).style;
    final scaler = MediaQuery.textScalerOf(context);
    for (var size = _maxFont; size >= _minFont; size -= 0.5) {
      var fits = true;
      for (final st in stats) {
        final tp = TextPainter(
          text: TextSpan(
            text: st.value,
            style: base.merge(
                TextStyle(fontSize: size, fontWeight: FontWeight.w800)),
          ),
          textDirection: TextDirection.ltr,
          textScaler: scaler,
          maxLines: 1,
        )..layout();
        if (tp.width > colWidth) {
          fits = false;
          break;
        }
      }
      if (fits) return size;
    }
    return _minFont;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final colWidth =
            (c.maxWidth - _gap * (stats.length - 1)) / stats.length;
        final fontSize = _fitFontSize(context, colWidth);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < stats.length; i++) ...[
              if (i > 0) const SizedBox(width: _gap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(stats[i].label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12.5, color: AppColors.textGrey)),
                    const SizedBox(height: 4),
                    // Pengaman terakhir kalau font sudah di ukuran minimum.
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(stats[i].value,
                          maxLines: 1,
                          softWrap: false,
                          style: TextStyle(
                              fontSize: fontSize,
                              fontWeight: FontWeight.w800,
                              color: stats[i].color)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _CashPainter extends CustomPainter {
  static const double padX = 22;
  static const double _top = 12;
  static const double _labelH = 28;

  final List<CashPoint> points;
  final int selected;
  final TextStyle labelStyle;

  _CashPainter({
    required this.points,
    required this.selected,
    required this.labelStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final n = points.length;
    final bottom = size.height - _labelH;
    final plotH = bottom - _top;
    final maxV = math.max(
      1,
      points.fold<int>(0, (m, p) => math.max(m, math.max(p.income, p.expense))),
    ).toDouble();
    final step = n > 1 ? (size.width - 2 * padX) / (n - 1) : 0.0;

    double x(int i) => padX + i * step;
    double y(int v) => bottom - (v / maxV) * plotH;

    final inc = [for (var i = 0; i < n; i++) Offset(x(i), y(points[i].income))];
    final exp = [for (var i = 0; i < n; i++) Offset(x(i), y(points[i].expense))];

    // garis putus-putus di titik terpilih
    final guide = Paint()
      ..color = const Color(0xFF9AA3B8)
      ..strokeWidth = 1;
    for (double dy = _top; dy < bottom; dy += 8) {
      canvas.drawLine(Offset(x(selected), dy),
          Offset(x(selected), math.min(dy + 4, bottom)), guide);
    }

    Paint stroke(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(_smooth(inc), stroke(_incomeColor));
    canvas.drawPath(_smooth(exp), stroke(_expenseColor));

    void dot(Offset o, Color c) {
      canvas.drawCircle(o, 6.5, Paint()..color = Colors.white);
      canvas.drawCircle(o, 4.6, Paint()..color = c);
    }

    dot(inc[selected], _incomeColor);
    dot(exp[selected], _expenseColor);

    // label sumbu x
    for (var i = 0; i < n; i++) {
      final active = i == selected;
      final tp = TextPainter(
        text: TextSpan(
          text: points[i].label,
          style: labelStyle.copyWith(
            fontWeight: active ? FontWeight.w800 : FontWeight.w500,
            color: active ? AppColors.textDark : AppColors.textGrey,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final left = (x(i) - tp.width / 2).clamp(0.0, size.width - tp.width);
      tp.paint(canvas, Offset(left, bottom + 10));
    }
  }

  /// Kurva S: kontrol horizontal di tengah tiap segmen.
  Path _smooth(List<Offset> pts) {
    final p = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      final a = pts[i - 1];
      final b = pts[i];
      final mx = (a.dx + b.dx) / 2;
      p.cubicTo(mx, a.dy, mx, b.dy, b.dx, b.dy);
    }
    return p;
  }

  @override
  bool shouldRepaint(covariant _CashPainter old) =>
      old.points != points || old.selected != selected;
}