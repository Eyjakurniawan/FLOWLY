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
import '../widgets/primary_button.dart';
import '../utils/app_router.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _loading = false;
  bool _googleLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    final result = await AuthService.instance.signIn(
      email: _emailCtrl.text,
      password: _passCtrl.text,
    );
    if (!mounted) return;
    setState(() => _loading = false);

    if (!result.success) {
      Helpers.showSnack(context, result.message ?? 'Gagal masuk.',
          isError: true);
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => AppRouter.afterAuth()),
      (_) => false,
    );
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

  Future<void> _forgotPassword() async {
    final emailError = Validators.email(_emailCtrl.text);
    if (emailError != null) {
      Helpers.showSnack(
        context,
        'Isi email kamu dulu, lalu ketuk "Lupa kata sandi?".',
        isError: true,
      );
      return;
    }
    final result = await AuthService.instance.resetPassword(_emailCtrl.text);
    if (!mounted) return;
    Helpers.showSnack(
      context,
      result.message ?? 'Gagal mengirim tautan reset.',
      isError: !result.success,
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
                const SizedBox(height: 20),
                const MascotBubble(
                  title: 'Hai, balik lagi!',
                  subtitle: 'Aku jagain arus uangmu tadi.',
                  expression: MascotExpression.happy,
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
                  hint: 'Kata sandi Anda',
                  controller: _passCtrl,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  validator: Validators.requiredPassword,
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: _forgotPassword,
                    child: const Text(
                      'Lupa kata sandi?',
                      style: TextStyle(
                        color: AppColors.link,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                PrimaryButton(
                  label: 'Masuk',
                  loading: _loading,
                  onPressed: _login,
                ),
                const SizedBox(height: 18),
                const OrDivider(),
                const SizedBox(height: 18),
                GoogleButton(loading: _googleLoading, onPressed: _google),
                const SizedBox(height: 28),
                AuthSwitchText(
                  question: 'Belum punya akun?',
                  action: 'Daftar',
                  onTap: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}