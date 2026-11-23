import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../utils/validators.dart';
import '../widgets/app_text_field.dart'; // AppTextField + FieldError
import '../widgets/auth_header.dart';
import '../widgets/auth_switch_text.dart';
import '../widgets/google_button.dart';
import '../widgets/mascot_bubble.dart';
import '../widgets/or_divider.dart';
import '../widgets/password_strength_bar.dart';
import '../widgets/primary_button.dart';
import '../utils/app_router.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _agree = false;
  bool _agreeError = false; // "Centang persetujuan..." di bawah kotak centang
  String? _passError; // pesan error kata sandi (ditampilkan di bawah petunjuk)
  bool _loading = false;
  bool _googleLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();
    // Validasi semua kolom + kotak centang sekaligus, supaya semua pesan
    // error muncul bersamaan.
    final formOk = _formKey.currentState!.validate();
    setState(() => _agreeError = !_agree);
    if (!formOk || !_agree) return;

    setState(() => _loading = true);
    final result = await AuthService.instance.signUp(
      email: _emailCtrl.text,
      password: _passCtrl.text,
    );
    if (!mounted) return;
    setState(() => _loading = false);

    if (!result.success) {
      Helpers.showSnack(context, result.message ?? 'Gagal mendaftar.',
          isError: true);
      return;
    }

    if (result.needsEmailConfirmation) {
      Helpers.showSnack(
        context,
        'Akun dibuat! Cek email kamu untuk verifikasi, lalu masuk.',
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else {
      Navigator.of(context).pushAndRemoveUntil(
       MaterialPageRoute(builder: (_) => AppRouter.afterAuth()),
        (_) => false,
      );
    }
  }

  Future<void> _google() async {
    setState(() => _googleLoading = true);
    final result = await AuthService.instance.signInWithGoogle();
    if (!mounted) return;
    setState(() => _googleLoading = false);
    if (!result.success) {
      Helpers.showSnack(context, result.message ?? 'Gagal masuk dengan Google.',
          isError: true);
    }
    // Setelah OAuth selesai, listener di main.dart yang mengarahkan ke Home.
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
                  title: 'Halo, aku Floy!',
                  subtitle: 'Daftar dulu, nanti aku bantu atur semuanya.',
                  expression: MascotExpression.wink,
                  authStyle: true,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  label: 'Email',
                  hint: 'nama@email.com',
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: Validators.email,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Kata sandi',
                  hint: 'Minimal 8 karakter',
                  controller: _passCtrl,
                  isPassword: true,
                  validator: Validators.newPassword,
                  onChanged: (_) => setState(() {}),
                  // Pesan error kata sandi ditaruh di bawah petunjuk (di
                  // bawah ini), bukan langsung di bawah kolom.
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
                _buildAgreement(),
                if (_agreeError) ...[
                  const SizedBox(height: 14),
                  const FieldError('Centang persetujuan untuk melanjutkan.'),
                  const SizedBox(height: 13),
                ] else
                  const SizedBox(height: 22),
                PrimaryButton(
                  label: 'Buat akun',
                  loading: _loading,
                  onPressed: _register,
                ),
                const SizedBox(height: 18),
                const OrDivider(),
                const SizedBox(height: 18),
                GoogleButton(loading: _googleLoading, onPressed: _google),
                const SizedBox(height: 28),
                AuthSwitchText(
                  question: 'Sudah punya akun?',
                  action: 'Masuk',
                  onTap: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAgreement() {
    const bold = TextStyle(fontWeight: FontWeight.w800);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Transform.scale(
            scale: 1.25,
            child: Checkbox(
              value: _agree,
              activeColor: AppColors.primary,
              onChanged: (v) => setState(() {
                _agree = v ?? false;
                if (_agree) _agreeError = false;
              }),
            ),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text.rich(
            TextSpan(
              style: const TextStyle(fontSize: 12, color: AppColors.textDark),
              children: [
                const TextSpan(text: 'Aku setuju dengan '),
                TextSpan(
                  text: 'Syarat Layanan',
                  style: bold,
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      // TODO: buka halaman Syarat Layanan
                    },
                ),
                const TextSpan(text: ' dan '),
                TextSpan(
                  text: 'Kebijakan Privasi',
                  style: bold,
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      // TODO: buka halaman Kebijakan Privasi
                    },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }  
}