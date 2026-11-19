import 'supabase_service.dart';

/// Mengirim laporan masalah dari halaman Bantuan & Dukungan ke Supabase
/// (tabel `support_reports`, lihat SQL di catatan).
class SupportService {
  SupportService._();

  /// Melempar exception kalau gagal (koneksi putus, tabel belum ada, dll).
  static Future<void> sendReport({
    required String type,
    required String message,
  }) async {
    final user = SupabaseService.client.auth.currentUser;
    await SupabaseService.client.from('support_reports').insert({
      // user_id diisi otomatis oleh database (default auth.uid())
      'email': user?.email,
      'type': type,
      'message': message,
    });
  }
}