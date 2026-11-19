import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/constants.dart';
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

  GoTrueClient get _auth => SupabaseService.client.auth;

  Session? get currentSession => _auth.currentSession;
  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => currentSession != null;

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
      await _auth.resetPasswordForEmail(email.trim());
      return const AuthResult.ok(
        message: 'Tautan reset kata sandi sudah dikirim ke email kamu.',
      );
    } on AuthException catch (e) {
      return AuthResult.fail(_translate(e.message));
    } catch (_) {
      return const AuthResult.fail('Terjadi kesalahan. Coba lagi.');
    }
  }

  Future<void> signOut() => _auth.signOut();

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
    if (m.contains('rate limit') || m.contains('too many')) {
      return 'Terlalu banyak percobaan. Coba lagi sebentar.';
    }
    if (m.contains('network') || m.contains('socket')) {
      return 'Tidak ada koneksi internet.';
    }
    return message;
  }
}
