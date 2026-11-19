import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../utils/validators.dart';
import '../widgets/app_text_field.dart';
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
    if (!_formKey.currentState!.validate()) return;
    if (!_agree) {
      Helpers.showSnack(
        context,
        'Setujui Syarat Layanan dan Kebijakan Privasi dulu ya.',
        isError: true,
      );
      return;
    }

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
                const SizedBox(height: 20),
                const MascotBubble(
                  title: 'Halo, aku Floy!',
                  subtitle: 'Daftar dulu, nanti aku bantu atur semuanya.',
                  expression: MascotExpression.wink,
                ),
                const SizedBox(height: 24),
                AppTextField(
                  label: 'Email',
                  hint: 'nama@gmail.com',
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: Validators.email,
                ),
                const SizedBox(height: 20),
                AppTextField(
                  label: 'Kata sandi',
                  hint: 'Minimal 8 karakter',
                  controller: _passCtrl,
                  isPassword: true,
                  validator: Validators.newPassword,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                PasswordStrengthBar(password: _passCtrl.text),
                const SizedBox(height: 20),
                _buildAgreement(),
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
          child: Checkbox(
            value: _agree,
            activeColor: AppColors.primary,
            onChanged: (v) => setState(() => _agree = v ?? false),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text.rich(
            TextSpan(
              style: const TextStyle(fontSize: 11, color: AppColors.textDark),
              children: [
                const TextSpan(text: 'Saya setuju dengan '),
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