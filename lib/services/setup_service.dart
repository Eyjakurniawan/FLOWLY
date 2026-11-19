import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/setup_data.dart';
import 'auth_service.dart';
import 'supabase_service.dart';

/// Menyimpan & membaca hasil setup awal.
///
/// Sementara disimpan di user metadata Supabase Auth (tanpa tabel).
/// Kalau nanti sudah ada tabel `profiles`, cukup ubah isi [save].
class SetupService {
  SetupService._();
  static final SetupService instance = SetupService._();

  GoTrueClient get _auth => SupabaseService.client.auth;

  Map<String, dynamic> get _meta => _auth.currentUser?.userMetadata ?? {};

  /// Sudah selesai setup?
  bool get isDone => _meta['setup_done'] == true;

  String? get nickname => _meta['nickname'] as String?;

  Future<AuthResult> save(SetupData data) async {
    try {
      await _auth.updateUser(UserAttributes(data: data.toMetadata()));
      return const AuthResult.ok();
    } on AuthException catch (e) {
      return AuthResult.fail(e.message);
    } catch (_) {
      return const AuthResult.fail('Gagal menyimpan pengaturan. Coba lagi.');
    }
  }

    /// Ganti nama panggilan (dipakai di Profil/Pengaturan).
  Future<AuthResult> updateNickname(String nickname) async {
    final name = nickname.trim();
    if (name.isEmpty) {
      return const AuthResult.fail('Nama panggilan wajib diisi.');
    }
    if (name.length > 20) {
      return const AuthResult.fail('Nama panggilan maksimal 20 karakter.');
    }
    try {
      await _auth.updateUser(UserAttributes(data: {'nickname': name}));
      return const AuthResult.ok(message: 'Nama panggilan diperbarui.');
    } on AuthException catch (e) {
      return AuthResult.fail(e.message);
    } catch (_) {
      return const AuthResult.fail('Gagal memperbarui nama. Coba lagi.');
    }
  }
}