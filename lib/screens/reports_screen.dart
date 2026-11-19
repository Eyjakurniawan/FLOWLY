import 'package:flutter/material.dart';

import '../models/finance_models.dart';
import '../services/finance_store.dart';
import '../utils/app_colors.dart';
import '../utils/formatters.dart';
import '../utils/fit_text.dart';
import '../widgets/finance/common.dart';
import '../widgets/finance/home_header.dart';
import '../widgets/finance/transaction_widgets.dart';
import '../widgets/mascot_view.dart';

enum _TxFilter {
  all('Semua'),
  income('Masuk'),
  expense('Keluar');

  final String label;
  const _TxFilter(this.label);
}

/// Permintaan dari luar (mis. kartu saldo di Home) agar Reports langsung
/// menampilkan riwayat transaksi dengan filter tertentu.
enum ReportsFocus { income, expense }

class ReportsFocusRequest {
  final ReportsFocus focus;
  // Tanpa operator ==, jadi tiap permintaan baru selalu memicu listener.
  ReportsFocusRequest(this.focus);
}

/// Tab Reports: ringkasan bulan, kategori terbesar, dan riwayat transaksi.
/// Bulan yang tampil mengikuti bulan terpilih di [FinanceStore].
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  /// Isi dengan [ReportsFocusRequest] untuk lompat ke riwayat Masuk/Keluar.
  static final ValueNotifier<ReportsFocusRequest?> focusRequest =
      ValueNotifier(null);

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _store = FinanceStore.instance;
  _TxFilter _filter = _TxFilter.all;
  String? _wallet; // null = semua dompet
  final _scroll = ScrollController();
  final _historyKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    ReportsScreen.focusRequest.addListener(_onFocusRequest);
  }

  @override
  void dispose() {
    ReportsScreen.focusRequest.removeListener(_onFocusRequest);
    _scroll.dispose();
    super.dispose();
  }

  void _onFocusRequest() {
    final req = ReportsScreen.focusRequest.value;
    if (req == null) return;
    setState(() {
      _filter = req.focus == ReportsFocus.income
          ? _TxFilter.income
          : _TxFilter.expense;
      _wallet = null;
    });
    _scrollToHistory();
  }

  void _scrollToHistory() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      void go() {
        final ctx = _historyKey.currentContext;
        if (ctx == null) return;
        Scrollable.ensureVisible(
          ctx,
          alignment: 0,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }

      if (_historyKey.currentContext == null && _scroll.hasClients) {
        // Kartu riwayat belum dibangun (di luar layar): turun dulu ke bawah.
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
        WidgetsBinding.instance.addPostFrameCallback((_) => go());
      } else {
        go();
      }
    });
  }

  static const _gap = SizedBox(height: 14);

  // ------------------------------------------------------------- helpers

  String _message() {
    final s = _store;
    final month = Fmt.monthYear(s.month);
    if (s.monthTransactions.isEmpty) {
      return 'Belum ada data untuk bulan ini. Catat dulu ya, nanti kuringkas.';
    }
    final slices = s.expenseSlices(Period.monthly);
    if (slices.isEmpty) {
      return 'Belum ada pengeluaran di $month. Pemasukanmu ${s.money(s.monthIncome)}, mantap!';
    }
    final top = slices.first;
    final pct = (top.share * 100).round();
    final income = s.monthIncome;
    final expense = s.monthExpense;
    final tail = expense > income
        ? ' Hati-hati, pengeluaran melebihi pemasukan.'
        : (expense < income
            ? ' Bagus, pengeluaranmu masih di bawah pemasukan.'
            : '');
    return 'Pengeluaran terbesarmu di $month ada di ${top.name}, $pct% dari total.$tail';
  }

  Future<void> _pickMonth() async {
    final picked = await showMonthPickerSheet(context, _store.month);
    if (picked != null) _store.setMonth(picked);
  }

  // --------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: _store,
          builder: (context, _) {
            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: HomeHeader(),
                ),
                Expanded(
                  child: ListView(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 124),
                    children: [
                      _buildBubble(),
                      _gap,
                      _buildSummary(),
                      _gap,
                      _buildTopCategories(),
                      _gap,
                      KeyedSubtree(key: _historyKey, child: _buildHistory()),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // -------------------------------------------------- maskot + balon ucapan

  Widget _buildBubble() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const MascotView(size: 76),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Text(_message(),
                style: const TextStyle(fontSize: 13.5, height: 1.35)),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------ ringkasan

  Widget _buildSummary() {
    final s = _store;
    final income = s.monthIncome;
    final expense = s.monthExpense;
    final diff = income - expense;
    // Selisih selalu hitam, baik positif maupun negatif.
    const diffColor = AppColors.textDark;

    return FlowlyCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Ringkasan',
                    style:
                        TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
              ),
              GestureDetector(
                onTap: _pickMonth,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(Fmt.monthYear(s.month),
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 2),
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, c) {
              const gap = 16.0;
              final colWidth = (c.maxWidth - gap) / 2;
              // Satu ukuran font untuk ketiga nominal; mengecil bersama
              // kalau ada yang terlalu panjang, jarak kolom tetap.
              final fontSize = fitFontSize(
                context,
                texts: [
                  s.money(income),
                  s.money(expense),
                  s.signedMoney(diff),
                ],
                maxWidth: colWidth,
                maxFont: 22,
                minFont: 11,
              );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _Stat(
                          label: 'Pemasukan',
                          value: s.money(income),
                          color: AppColors.link,
                          fontSize: fontSize,
                        ),
                      ),
                      const SizedBox(width: gap),
                      Expanded(
                        child: _Stat(
                          label: 'Pengeluaran',
                          value: s.money(expense),
                          color: AppColors.primary,
                          fontSize: fontSize,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _Stat(
                    label: 'Selisih',
                    value: s.signedMoney(diff),
                    color: diffColor,
                    fontSize: fontSize,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------ kategori terbesar

  Widget _buildTopCategories() {
    final s = _store;
    final slices = s.expenseSlices(Period.monthly, maxSlices: 999);
    final month = Fmt.monthYear(s.month);

    return FlowlyCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Kategori terbesar',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          if (slices.isEmpty)
            Text(
              s.monthTransactions.isEmpty
                  ? 'Belum ada transaksi pada $month.'
                  : 'Belum ada pengeluaran pada $month.',
              style: const TextStyle(fontSize: 12.5, color: AppColors.textGrey),
            )
          else
            for (var i = 0; i < slices.length; i++)
              Padding(
                padding: EdgeInsets.only(bottom: i == slices.length - 1 ? 0 : 16),
                child: _CategoryRow(
                  name: slices[i].name,
                  trailing:
                      '${s.moneyCompact(slices[i].total)} • ${(slices[i].share * 100).round()}%',
                  // Batang dibandingkan dengan kategori terbesar.
                  value: slices[i].total / slices.first.total,
                  color: TxCategory.colorFor(slices[i].name),
                ),
              ),
        ],
      ),
    );
  }

  // ------------------------------------------------------ riwayat transaksi

  Widget _buildHistory() {
    final s = _store;
    final month = Fmt.monthYear(s.month);
    final wallet =
        (_wallet != null && s.walletByName(_wallet!) != null) ? _wallet : null;

    final items = s
        .transactions(
          type: switch (_filter) {
            _TxFilter.all => null,
            _TxFilter.income => TxType.income,
            _TxFilter.expense => TxType.expense,
          },
        )
        .where((t) => wallet == null || t.wallet == wallet)
        .toList();

    // Kelompokkan per hari (items sudah terbaru dulu).
    final groups = <DateTime, List<FlowTransaction>>{};
    for (final t in items) {
      final day = DateTime(t.date.year, t.date.month, t.date.day);
      groups.putIfAbsent(day, () => []).add(t);
    }

    return FlowlyCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Riwayat transaksi',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          SegmentedTabs<_TxFilter>(
            expand: true,
            values: _TxFilter.values,
            selected: _filter,
            labelOf: (f) => f.label,
            onChanged: (f) => setState(() => _filter = f),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _WalletChip(
                  label: 'Semua dompet',
                  selected: wallet == null,
                  onTap: () => setState(() => _wallet = null),
                ),
                for (final w in s.wallets) ...[
                  const SizedBox(width: 8),
                  _WalletChip(
                    label: w.name,
                    selected: wallet == w.name,
                    onTap: () => setState(() => _wallet = w.name),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(
                s.monthTransactions.isEmpty
                    ? 'Belum ada transaksi pada $month.'
                    : 'Tidak ada transaksi untuk filter ini.',
                style:
                    const TextStyle(fontSize: 12.5, color: AppColors.textGrey),
              ),
            )
          else
            for (final e in groups.entries) ...[
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(Fmt.dayLabel(e.key),
                    style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textGrey)),
              ),
              TransactionList(items: e.value, showDay: false),
            ],
        ],
      ),
    );
  }
}

// ======================================================== widget kecil

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final double fontSize;
  const _Stat({
    required this.label,
    required this.value,
    required this.color,
    this.fontSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value,
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w800,
                  color: color)),
        ),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final String name;
  final String trailing;
  final double value; // 0..1
  final Color color;
  const _CategoryRow({
    required this.name,
    required this.trailing,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 8),
            Text(trailing,
                style:
                    const TextStyle(fontSize: 12, color: AppColors.textGrey)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: value > 1 ? 1.0 : value,
            minHeight: 8,
            backgroundColor: const Color(0xFFE3EAFB),
            color: color,
          ),
        ),
      ],
    );
  }
}

class _WalletChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _WalletChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.textDark : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.textDark : const Color(0xFFD5DCEF),
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.textDark,
          ),
        ),
      ),
    );
  }
}