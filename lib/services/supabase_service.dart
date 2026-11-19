import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/constants.dart';

/// Inisialisasi & akses client Supabase.
class SupabaseService {
  SupabaseService._();

  static Future<void> init() async {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
