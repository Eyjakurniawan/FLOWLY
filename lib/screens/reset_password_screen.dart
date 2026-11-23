import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../utils/app_router.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../utils/validators.dart';
import '../widgets/app_text_field.dart'; // AppTextField + FieldError
import '../widgets/auth_header.dart';
import '../widgets/mascot_bubble.dart';
import '../widgets/password_strength_bar.dart';
import '../widgets/primary_button.dart';

/// Layar "atur ulang kata sandi". Terbuka otomatis saat pengguna mengetuk
/// tautan reset di email (lihat listener passwordRecovery di main.dart).
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  String? _passError; // ditampilkan di bawah petunjuk kekuatan sandi
  bool _loading = false;

  @override
  void dispose() {
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String? _validateConfirm(String? v) {
    if (v == null || v.isEmpty) return 'Ulangi kata sandi dulu.';
    if (v != _passCtrl.text) return 'Kata sandi tidak sama.';
    return null;
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    final result = await AuthService.instance.updatePassword(_passCtrl.text);
    if (!mounted) return;
    setState(() => _loading = false);

    if (!result.success) {
      Helpers.showSnack(context, result.message ?? 'Gagal menyimpan kata sandi.',
          isError: true);
      return;
    }

    // Selesai: lepas penanda reset, lalu masuk ke aplikasi (sesi sudah aktif
    // dari tautan reset).
    AuthService.recoveryInProgress = false;
    Helpers.showTopAlert(context, 'Kata sandi berhasil diubah.');
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => AppRouter.afterAuth()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AuthHeader(),
                const SizedBox(height: 24),
                const MascotBubble(
                  title: 'Atur ulang kata sandi',
                  subtitle: 'Buat kata sandi baru untuk akunmu.',
                  expression: MascotExpression.happy,
                  authStyle: true,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  label: 'Kata sandi baru',
                  hint: 'Minimal 8 karakter',
                  controller: _passCtrl,
                  isPassword: true,
                  textInputAction: TextInputAction.next,
                  validator: Validators.newPassword,
                  onChanged: (_) => setState(() {}),
                  showError: false,
                  onErrorChanged: (e) => setState(() => _passError = e),
                ),
                const SizedBox(height: 8),
                PasswordStrengthBar(password: _passCtrl.text),
                if (_passError != null) ...[
                  const SizedBox(height: 4),
                  FieldError(_passError!),
                ],
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Ulangi kata sandi',
                  hint: 'Ketik ulang kata sandi baru',
                  controller: _confirmCtrl,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  validator: _validateConfirm,
                ),
                const SizedBox(height: 22),
                PrimaryButton(
                  label: 'Simpan kata sandi',
                  loading: _loading,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}