import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/constants.dart';

bool _isFlowlyAuthCallback(Uri uri) =>
    uri.scheme == 'com.kelompok7.flowly' && uri.host == 'callback';

/// Inisialisasi & akses client Supabase.
class SupabaseService {
  SupabaseService._();

  static Future<void> init() async {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      publishableKey: AppConstants.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        detectSessionInUriPredicate: _isFlowlyAuthCallback,
      ),
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
