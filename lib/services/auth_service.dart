import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/constants.dart';
import 'notification_store.dart';
import 'supabase_service.dart';

/// Hasil operasi auth yang mudah dipakai di UI.
class AuthResult {
  final bool success;
  final String? message;
  final bool needsEmailConfirmation;

  const AuthResult.ok({this.message, this.needsEmailConfirmation = false})
      : success = true;
  const AuthResult.fail(this.message)
      : success = false,
        needsEmailConfirmation = false;
}

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  /// True selama pengguna membuka tautan "atur ulang kata sandi" dari email
  /// dan belum selesai mengisi kata sandi baru. Dipakai main.dart supaya
  /// login otomatis dari tautan itu tidak langsung melempar ke Home.
  static bool recoveryInProgress = false;

  GoTrueClient get _auth => SupabaseService.client.auth;

  Session? get currentSession => _auth.currentSession;
  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => currentSession != null;

  /// Tanggal (tanpa jam) user mendaftar. Kalender riwayat tidak boleh
  /// memilih tanggal sebelum ini. Kalau data akun tidak ada, pakai hari ini.
  static DateTime get signupDate {
    DateTime? d;
    try {
      final raw = SupabaseService.client.auth.currentUser?.createdAt;
      if (raw != null) d = DateTime.tryParse(raw)?.toLocal();
    } catch (_) {}
    d ??= DateTime.now();
    return DateTime(d.year, d.month, d.day);
  }

  Stream<AuthState> get authChanges => _auth.onAuthStateChange;

  Future<AuthResult> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _auth.signUp(email: email.trim(), password: password);
      // Jika "Confirm email" aktif di Supabase, session akan null.
      final needsConfirm = res.session == null;
      return AuthResult.ok(needsEmailConfirmation: needsConfirm);
    } on AuthException catch (e) {
      return AuthResult.fail(_translate(e.message));
    } catch (_) {
      return const AuthResult.fail('Terjadi kesalahan. Coba lagi.');
    }
  }

  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithPassword(email: email.trim(), password: password);
      return const AuthResult.ok();
    } on AuthException catch (e) {
      return AuthResult.fail(_translate(e.message));
    } catch (_) {
      return const AuthResult.fail('Terjadi kesalahan. Coba lagi.');
    }
  }

  Future<AuthResult> signInWithGoogle() async {
    try {
      await _auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : AppConstants.oauthRedirect,
      );
      return const AuthResult.ok();
    } on AuthException catch (e) {
      return AuthResult.fail(_translate(e.message));
    } catch (_) {
      return const AuthResult.fail('Gagal masuk dengan Google.');
    }
  }

  Future<AuthResult> resetPassword(String email) async {
    try {
      await _auth.resetPasswordForEmail(
        email.trim(),
        // Tautan di email membuka aplikasi lewat deep link yang sama dengan
        // login Google (harus ada di Supabase -> Redirect URLs).
        redirectTo: kIsWeb ? null : AppConstants.oauthRedirect,
      );
      return const AuthResult.ok(
        message: 'Tautan reset kata sandi sudah dikirim ke email kamu.',
      );
    } on AuthException catch (e) {
      return AuthResult.fail(_translate(e.message));
    } catch (_) {
      return const AuthResult.fail('Terjadi kesalahan. Coba lagi.');
    }
  }

  /// Simpan kata sandi baru (sesi dari tautan reset sudah aktif).
  Future<AuthResult> updatePassword(String newPassword) async {
    try {
      await _auth.updateUser(UserAttributes(password: newPassword));
      return const AuthResult.ok();
    } on AuthException catch (e) {
      return AuthResult.fail(_translate(e.message));
    } catch (_) {
      return const AuthResult.fail('Terjadi kesalahan. Coba lagi.');
    }
  }

  Future<void> signOut() => _auth.signOut();

  /// Hapus akun beserta semua datanya lewat fungsi database
  /// `delete_my_account` (lihat database/delete_my_account.sql).
  ///
  /// Client tidak boleh menghapus user Auth langsung (butuh service role
  /// key), jadi penghapusan dilakukan di server lewat RPC.
  /// Sesi lokal TIDAK ditutup di sini; pemanggil yang memanggil [signOut].
  Future<AuthResult> deleteAccount() async {
    try {
      await SupabaseService.client.rpc('delete_my_account');
      await NotificationStore.instance.deleteLocal();
      return const AuthResult.ok();
    } on PostgrestException catch (e) {
      final m = e.message.toLowerCase();
      if (e.code == 'PGRST202' || m.contains('could not find the function')) {
        return const AuthResult.fail(
            'Fitur hapus akun belum dipasang di database.');
      }
      return const AuthResult.fail('Gagal menghapus akun. Coba lagi.');
    } on AuthException catch (e) {
      return AuthResult.fail(_translate(e.message));
    } catch (_) {
      return const AuthResult.fail(
          'Gagal menghapus akun. Periksa koneksi lalu coba lagi.');
    }
  }

  /// Terjemahkan pesan error umum Supabase ke Bahasa Indonesia.
  String _translate(String message) {
    final m = message.toLowerCase();
    if (m.contains('invalid login credentials')) {
      return 'Email atau kata sandi salah.';
    }
    if (m.contains('already registered') || m.contains('already been registered')) {
      return 'Email ini sudah terdaftar. Silakan masuk.';
    }
    if (m.contains('email not confirmed')) {
      return 'Email belum diverifikasi. Cek kotak masuk kamu.';
    }
    if (m.contains('password should be at least')) {
      return 'Kata sandi terlalu pendek.';
    }
    if (m.contains('different from the old password') ||
        m.contains('same_password')) {
      return 'Kata sandi baru harus berbeda dari yang lama.';
    }
    if (m.contains('session missing') || m.contains('session_not_found')) {
      return 'Tautan reset sudah kedaluwarsa. Minta tautan baru.';
    }
    if (m.contains('rate limit') || m.contains('too many')) {
      return 'Terlalu banyak percobaan. Coba lagi sebentar.';
    }
    if (m.contains('network') || m.contains('socket')) {
      return 'Tidak ada koneksi internet.';
    }
    return message;
  }
}