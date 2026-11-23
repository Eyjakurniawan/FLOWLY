import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/app_data.dart';
import '../widgets/connectivity_overlay.dart';
import '../widgets/finance/add_transaction_sheet.dart';
import '../widgets/finance/flowly_bottom_nav.dart';
import 'dashboard_screen.dart';
import 'profile_screen.dart';
import 'reports_screen.dart';
import 'wallet_tab.dart';

/// Cangkang utama setelah login: 4 tab + tombol + di tengah.
///
/// Nama kelas tetap `HomeScreen` supaya AppRouter & SetupScreen tidak
/// perlu diubah.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();

  /// Pindah ke [tab] (0 Beranda, 1 Dompet, 2 Laporan, 3 Profil) lalu,
  /// kalau ada, buka halaman-halaman [pages] berurutan di dalam tab itu.
  /// Dipakai tautan notifikasi.
  static void openIn(int tab, [List<Widget> pages = const []]) =>
      _HomeScreenState._current?._openIn(tab, pages);
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  // Setiap tab punya Navigator sendiri supaya halaman detail
  // (Planning, Notifikasi, dll.) terbuka di dalam tab dan nav bawah
  // tetap terlihat.
  final _navKeys = List.generate(4, (_) => GlobalKey<NavigatorState>());

  static _HomeScreenState? _current;

  void _openIn(int tab, List<Widget> pages) {
    _switchTab(tab);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final nav = _navKeys[tab].currentState;
      if (nav == null) return;
      for (final page in pages) {
        nav.push(MaterialPageRoute(builder: (_) => page));
      }
    });
  }

  @override
  void dispose() {
    if (_current == this) _current = null;
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _current = this;
    // Muat kategori, dompet, transaksi, dan rencana dari Supabase.
    AppData.instance.ensureLoaded();
  }

  void _switchTab(int i) {
    if (_tab == i) {
      // Jika tab yang sama diketuk: langsung reset ke halaman utama tab tersebut.
      _navKeys[i].currentState?.popUntil((route) => route.isFirst);
    } else {
      // Pindah tab: reset tab asal & tab tujuan agar selalu tampil di halaman utama.
      _navKeys[_tab].currentState?.popUntil((route) => route.isFirst);
      _navKeys[i].currentState?.popUntil((route) => route.isFirst);
      setState(() => _tab = i);
    }
  }

  void _onBack() {
    final nav = _navKeys[_tab].currentState;
    if (nav != null && nav.canPop()) {
      nav.pop();
    } else if (_tab != 0) {
      _switchTab(0);
    } else {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: Scaffold(
        body: ConnectivityOverlay(
          child: Stack(
            children: [
              IndexedStack(
                index: _tab,
                children: [
                  Navigator(
                    key: _navKeys[0],
                    onGenerateRoute: (_) => MaterialPageRoute(
                      builder: (_) => DashboardScreen(
                        onOpenWallet: () => _switchTab(1),
                        onOpenReports: () => _switchTab(2),
                      ),
                    ),
                  ),
                  Navigator(
                    key: _navKeys[1],
                    onGenerateRoute: (_) => MaterialPageRoute(
                      builder: (_) => const Scaffold(body: WalletTab()),
                    ),
                  ),
                  Navigator(
                    key: _navKeys[2],
                    onGenerateRoute: (_) => MaterialPageRoute(
                      builder: (_) => const ReportsScreen(),
                    ),
                  ),
                  Navigator(
                    key: _navKeys[3],
                    onGenerateRoute: (_) => MaterialPageRoute(
                      builder: (_) => const ProfileScreen(),
                    ),
                  ),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: FlowlyBottomNav(
                  current: _tab,
                  onTab: _switchTab,
                  onAdd: () => showAddTransactionSheet(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}