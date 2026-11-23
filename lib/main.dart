import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'utils/app_router.dart';
import 'screens/splash_screen.dart';
import 'screens/reset_password_screen.dart';
import 'services/app_data.dart';
import 'services/auth_service.dart';
import 'services/connectivity_service.dart';
import 'services/supabase_service.dart';
import 'services/text_scale_store.dart';
import 'utils/helpers.dart';
import 'utils/app_theme.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Layar penuh sampai belakang bar sistem; nav bawah yang mengatur jaraknya
  // lewat MediaQuery sehingga otomatis naik di atas tombol back/home/recent.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarContrastEnforced: false,
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  await SupabaseService.init();

  // Ukuran huruf pilihan pengguna (Pengaturan -> Ukuran huruf).
  await TextScaleStore.instance.load();

  // Pantau koneksi; saat internet kembali, muat ulang data dari server.
  ConnectivityService.instance.onBackOnline = () => AppData.instance.reload();
  ConnectivityService.instance.start();

  // Pesan kalau data gagal dimuat/disimpan ke Supabase.
  AppData.onError = (message) {
    final ctx = navigatorKey.currentContext;
    if (ctx != null) Helpers.showSnack(ctx, message, isError: true);
  };

  // Setelah login Google (OAuth) selesai, arahkan otomatis ke Home.
  SupabaseService.client.auth.onAuthStateChange.listen((data) {
    if (data.event == AuthChangeEvent.signedOut) {
      // Jangan sisakan data akun sebelumnya di HP yang sama.
      AppData.instance.clear();
    }
    // Pengguna membuka tautan "atur ulang kata sandi" dari email.
    if (data.event == AuthChangeEvent.passwordRecovery) {
      AuthService.recoveryInProgress = true;
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
        (_) => false,
      );
    }
    if (data.event == AuthChangeEvent.signedIn &&
        !AuthService.recoveryInProgress) {
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => AppRouter.afterAuth()),
        (_) => false,
      );
    }
  });

  runApp(const FlowlyApp());
}

class FlowlyApp extends StatelessWidget {
  const FlowlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flowly',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: AppTheme.light,
      // Ukuran huruf dari Pengaturan dikalikan dengan ukuran teks bawaan HP.
      builder: (context, child) => ListenableBuilder(
        listenable: TextScaleStore.instance,
        child: child,
        builder: (context, child) {
          final mq = MediaQuery.of(context);
          final device = mq.textScaler.scale(14) / 14;
          return MediaQuery(
            data: mq.copyWith(
              textScaler:
                  TextScaler.linear(device * TextScaleStore.instance.scale),
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
      home: const SplashScreen(),
    );
  }
}