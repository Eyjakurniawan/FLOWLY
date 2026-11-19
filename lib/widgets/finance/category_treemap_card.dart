import 'package:flutter/material.dart';

import '../../models/finance_models.dart';
import '../../services/finance_store.dart';
import '../../utils/app_colors.dart';
import 'common.dart';

/// Bobot minimum supaya kategori kecil tetap terbaca.
const _minWeight = 0.12;
const _treemapHeight = 235.0;

class CategoryTreemapCard extends StatefulWidget {
  final String? selected;
  final ValueChanged<CategorySlice?> onSelect;

  const CategoryTreemapCard({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  @override
  State<CategoryTreemapCard> createState() => _CategoryTreemapCardState();
}

class _CategoryTreemapCardState extends State<CategoryTreemapCard> {
  final _store = FinanceStore.instance;
  Period _period = Period.monthly;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        final slices = _store.expenseSlices(_period);
        return FlowlyCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pengeluaran per kategori',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              SegmentedTabs<Period>(
                expand: true,
                values: Period.values,
                selected: _period,
                labelOf: (p) => p.label,
                onChanged: (p) {
                  widget.onSelect(null);
                  setState(() => _period = p);
                },
              ),
              const SizedBox(height: 12),
              Text(
                '${_store.periodLabel(_period)} • Ketuk untuk filter',
                style:
                    const TextStyle(fontSize: 12.5, color: AppColors.textGrey),
              ),
              const SizedBox(height: 10),
              if (slices.isEmpty)
                const SizedBox(
                  height: 120,
                  child: Center(
                    child: Text('Belum ada pengeluaran di periode ini.',
                        style: TextStyle(color: AppColors.textGrey)),
                  ),
                )
              else
                SizedBox(
                  height: _treemapHeight,
                  child: LayoutBuilder(
                    builder: (context, c) => _buildTreemap(slices, c.maxWidth),
                  ),
                ),
              const SizedBox(height: 12),
              const Text(
                'Luas kotak mengikuti besar pengeluaran. Maksimal 5 kotak; kategori kecil digabung jadi Lain-lain.',
                style: TextStyle(fontSize: 12, color: AppColors.textGrey),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTreemap(List<CategorySlice> slices, double width) {
    final weights = [
      for (final s in slices) s.share < _minWeight ? _minWeight : s.share,
    ];
    final rects = List<Rect>.filled(slices.length, Rect.zero);
    _split(
      List.generate(slices.length, (i) => i),
      weights,
      Rect.fromLTWH(0, 0, width, _treemapHeight),
      rects,
    );

    return Stack(
      children: [
        for (var i = 0; i < slices.length; i++)
          Positioned.fromRect(
            rect: rects[i].deflate(3),
            child: _Tile(
              slice: slices[i],
              color: TxCategory.colorFor(slices[i].name),
              dimmed:
                  widget.selected != null && widget.selected != slices[i].name,
              onTap: () => widget.onSelect(
                widget.selected == slices[i].name ? null : slices[i],
              ),
            ),
          ),
      ],
    );
  }

  /// Bagi daftar (sudah terurut menurun) jadi dua kelompok yang jumlahnya
  /// paling seimbang, lalu potong sisi terpanjang. Diulang rekursif.
  void _split(List<int> idx, List<double> w, Rect r, List<Rect> out) {
    if (idx.length == 1) {
      out[idx.first] = r;
      return;
    }
    final total = idx.fold<double>(0, (s, i) => s + w[i]);
    var best = 1;
    var bestDiff = double.infinity;
    var acc = 0.0;
    for (var k = 1; k < idx.length; k++) {
      acc += w[idx[k - 1]];
      final diff = (total - 2 * acc).abs();
      if (diff < bestDiff) {
        bestDiff = diff;
        best = k;
      }
    }
    final left = idx.sublist(0, best);
    final right = idx.sublist(best);
    final ratio = left.fold<double>(0, (s, i) => s + w[i]) / total;

    if (r.width >= r.height) {
      final lw = r.width * ratio;
      _split(left, w, Rect.fromLTWH(r.left, r.top, lw, r.height), out);
      _split(right, w,
          Rect.fromLTWH(r.left + lw, r.top, r.width - lw, r.height), out);
    } else {
      final lh = r.height * ratio;
      _split(left, w, Rect.fromLTWH(r.left, r.top, r.width, lh), out);
      _split(right, w,
          Rect.fromLTWH(r.left, r.top + lh, r.width, r.height - lh), out);
    }
  }
}

class _Tile extends StatelessWidget {
  final CategorySlice slice;
  final Color color;
  final bool dimmed;
  final VoidCallback onTap;

  const _Tile({
    required this.slice,
    required this.color,
    required this.dimmed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final store = FinanceStore.instance;
    final pct = '${(slice.share * 100).round()}%';

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: dimmed ? 0.35 : 1,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: LayoutBuilder(
            builder: (context, c) {
              final wide = c.maxWidth >= 110;
              final tall = c.maxHeight >= 56;
              return Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      slice.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: c.maxWidth < 70 ? 11.5 : 14,
                      ),
                    ),
                    const Spacer(),
                    if (tall)
                      Text(
                        wide
                            ? '$pct • ${store.moneyCompact(slice.total)}'
                            : pct,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}