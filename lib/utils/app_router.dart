import 'package:flutter/material.dart';

import '../screens/home_screen.dart';
import '../screens/setup_screen.dart';
import '../services/setup_service.dart';

class AppRouter {
  AppRouter._();

  /// Halaman tujuan setelah berhasil login/daftar:
  /// belum setup -> SetupScreen, sudah -> HomeScreen.
  static Widget afterAuth() =>
      SetupService.instance.isDone ? const HomeScreen() : const SetupScreen();
}