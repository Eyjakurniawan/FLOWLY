import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'utils/app_router.dart';
import 'screens/splash_screen.dart';
import 'services/app_data.dart';
import 'services/supabase_service.dart';
import 'utils/helpers.dart';
import 'utils/app_theme.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await SupabaseService.init();

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
    if (data.event == AuthChangeEvent.signedIn) {
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
      home: const SplashScreen(),
    );
  }
}