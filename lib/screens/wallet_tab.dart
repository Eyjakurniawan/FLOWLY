import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/finance_models.dart';
import '../services/finance_store.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/dashed_box.dart';
import '../widgets/finance/add_wallet_sheet.dart';
import '../widgets/finance/common.dart';
import '../widgets/finance/home_header.dart';
import '../widgets/mascot_view.dart';
import 'wallet_detail_screen.dart';

/// Warna tiap dompet (urut sesuai dompet dibuat, jadi warnanya tetap).
const _walletColors = [
  Color(0xFF8B4F2A),
  Color(0xFF3F7D5F),
  Color(0xFF1D4FD8),
  Color(0xFF6B5B9A),
  Color(0xFFB45309),
  Color(0xFFBE185D),
];

class _WalletView {
  final Wallet wallet;
  final int balance;
  final Color color;
  const _WalletView(this.wallet, this.balance, this.color);
}

/// Tab Wallet: ringkasan saldo, proporsi per dompet, dan daftar dompet.
class WalletTab extends StatelessWidget {
  const WalletTab({super.key});

  List<_WalletView> _views(FinanceStore s) {
    final list = [
      for (var i = 0; i < s.wallets.length; i++)
        _WalletView(
          s.wallets[i],
          s.balanceOf(s.wallets[i]),
          _walletColors[i % _walletColors.length],
        ),
    ];
    list.sort((a, b) => b.balance.compareTo(a.balance)); // terbesar dulu
    return list;
  }

  String _bubbleText(FinanceStore s, List<_WalletView> v) {
    if (v.isEmpty) {
      return 'Belum ada dompet. Tambahkan dompet pertamamu, lalu catat transaksi dari sana.';
    }
    if (v.length == 1) {
      return 'Semua saldo kamu ada di ${v.first.wallet.name}: ${s.moneyCompact(s.totalBalance)}.';
    }
    return 'Saldo terbesar ada di ${v.first.wallet.name}. Total ${s.moneyCompact(s.totalBalance)} tersebar di ${v.length} dompet.';
  }

  Future<void> _add(BuildContext context) async {
    final name = await showAddWalletSheet(context);
    if (name != null && context.mounted) {
      Helpers.showSnack(context, 'Dompet "$name" ditambahkan.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = FinanceStore.instance;
    return SafeArea(
      bottom: false,
      child: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final views = _views(store);
          final positiveTotal =
              views.fold<int>(0, (s, v) => s + math.max(0, v.balance));

          return Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: HomeHeader(),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(16, 10, 16, Helpers.navClearance(context)),
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const MascotView(
                          size: 88,
                          expression: MascotExpression.wink,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _SpeechBubble(text: _bubbleText(store, views)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FlowlyCard(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total saldo',
                              style: TextStyle(
                                  fontSize: 13, color: AppColors.textGrey)),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              store.money(store.totalBalance),
                              style: const TextStyle(
                                  fontSize: 38, fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _ShareBar(items: views),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: () => _add(context),
                      child: Container(
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3EAFB),
                          borderRadius: BorderRadius.circular(16),
                          border:
                              Border.all(color: AppColors.textDark, width: 1.2),
                        ),
                        child: const Text('+ Tambah dompet',
                            style: TextStyle(
                                fontSize: 14.5, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (views.isEmpty)
                      const _EmptyWallets()
                    else ...[
                      FlowlyCard(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 6),
                        child: Column(
                          children: [
                            for (var i = 0; i < views.length; i++) ...[
                              if (i > 0)
                                const Divider(
                                    height: 1, color: Color(0xFFE6EBF7)),
                              _WalletRow(
                                view: views[i],
                                share: positiveTotal > 0 && views[i].balance > 0
                                    ? (views[i].balance / positiveTotal * 100)
                                        .round()
                                    : null,
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => WalletDetailScreen(
                                        walletName: views[i].wallet.name),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(6, 12, 6, 0),
                        child: Text(
                          'Ketuk dompet untuk melihat riwayat transaksinya.',
                          style: TextStyle(
                              fontSize: 12.5, color: AppColors.textGrey),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Tampilan saat belum ada dompet: kotak putus-putus dengan maskot.
class _EmptyWallets extends StatelessWidget {
  const _EmptyWallets();

  @override
  Widget build(BuildContext context) {
    return FlowlyCard(
      padding: const EdgeInsets.all(14),
      child: DashedBox(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const MascotView(size: 120),
                    Positioned(
                      bottom: 4,
                      child: Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: const Color(0xFFD97706), width: 1.5),
                        ),
                        child: const Text(
                          'Rp',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Belum ada dompet',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tambahkan dompet pertama (bank, dompet digital, atau tunai) dan isi saldo awalnya, lalu catat transaksi dari sana.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12.5, height: 1.4, color: AppColors.textGrey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Balon bicara Floy dengan ekor di kiri.
class _SpeechBubble extends StatelessWidget {
  final String text;
  const _SpeechBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE6EBF7)),
          ),
          child: Text(text,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w500, height: 1.35)),
        ),
        Positioned(
          left: -5,
          top: 28,
          child: Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  left: BorderSide(color: Color(0xFFE6EBF7)),
                  bottom: BorderSide(color: Color(0xFFE6EBF7)),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Bar proporsi saldo tiap dompet.
class _ShareBar extends StatelessWidget {
  final List<_WalletView> items;
  const _ShareBar({required this.items});

  @override
  Widget build(BuildContext context) {
    final positive = items.where((v) => v.balance > 0).toList();
    if (positive.isEmpty) {
      return Container(
        height: 14,
        decoration: BoxDecoration(
          color: AppColors.strengthEmpty,
          borderRadius: BorderRadius.circular(7),
        ),
      );
    }
    return SizedBox(
      height: 14,
      child: Row(
        children: [
          for (var i = 0; i < positive.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              flex: positive[i].balance,
              child: Container(
                decoration: BoxDecoration(
                  color: positive[i].color,
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WalletRow extends StatelessWidget {
  final _WalletView view;
  final int? share; // persen dari total, null kalau saldo 0 / minus
  final VoidCallback onTap;
  const _WalletRow({
    required this.view,
    required this.share,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final store = FinanceStore.instance;
    final subtitle = share == null
        ? view.wallet.type.label
        : '${view.wallet.type.label} • $share% dari total';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: view.color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(view.wallet.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12.5, color: AppColors.textGrey)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(store.money(view.balance),
                style:
                    const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}