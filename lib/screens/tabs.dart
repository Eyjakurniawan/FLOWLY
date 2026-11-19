import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/setup_service.dart';
import '../utils/app_colors.dart';
import '../widgets/finance/home_header.dart';
import '../widgets/mascot_view.dart';
import '../widgets/primary_button.dart';
import 'splash_screen.dart';

/// Placeholder untuk tab yang belum dibuat (Wallet, Reports).
class ComingSoonTab extends StatelessWidget {
  final String title;
  final String message;
  const ComingSoonTab({super.key, required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: HomeHeader(),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 100),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const MascotView(size: 130),
                  const SizedBox(height: 12),
                  Text(title,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textGrey)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final email = AuthService.instance.currentUser?.email ?? '';
    final nickname = SetupService.instance.nickname;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const MascotView(size: 130),
            const SizedBox(height: 12),
            Text(
              (nickname == null || nickname.isEmpty) ? 'Profil' : nickname,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(email,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textGrey)),
            const SizedBox(height: 28),
            PrimaryButton(
              label: 'Keluar',
              onPressed: () async {
                await AuthService.instance.signOut();
                if (!context.mounted) return;
                Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const SplashScreen()),
                  (_) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}