import 'package:flutter/material.dart';

import '../screens/budget_screen.dart';
import '../screens/category_wallet_screen.dart';
import '../screens/home_screen.dart';
import '../screens/planning_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/transactions_screen.dart';
import '../screens/wallet_detail_screen.dart';
import '../services/finance_store.dart';
import '../services/notification_store.dart';
import '../widgets/finance/add_transaction_sheet.dart';

/// Membuka halaman yang terkait dengan sebuah notifikasi.
class NotificationRouter {
  NotificationRouter._();

  /// Mengembalikan false kalau aksinya harus ditangani pemanggil
  /// (mis. pengaturan jam pengingat yang ada di halaman Notifikasi).
  static bool open(BuildContext context, AppNotification n) {
    switch (n.action) {
      case NotificationAction.none:
      case NotificationAction.dailyReminderSetting:
        return false;
      case NotificationAction.addTransaction:
        showAddTransactionSheet(context);
        return true;
      case NotificationAction.openWallets:
        HomeScreen.openIn(1);
        return true;
      case NotificationAction.openWallet:
        final name = n.refName;
        final exists =
            name != null && FinanceStore.instance.walletByName(name) != null;
        HomeScreen.openIn(
            1, exists ? [WalletDetailScreen(walletName: name!)] : const []);
        return true;
      case NotificationAction.openTransactions:
        HomeScreen.openIn(0, const [TransactionsScreen()]);
        return true;
      case NotificationAction.openCategories:
        HomeScreen.openIn(
            3, const [SettingsScreen(), CategoryWalletScreen()]);
        return true;
      case NotificationAction.openPlanning:
        HomeScreen.openIn(0, const [PlanningScreen()]);
        return true;
      case NotificationAction.openBudget:
        HomeScreen.openIn(0, const [BudgetScreen()]);
        return true;
      case NotificationAction.openSettings:
        HomeScreen.openIn(3, const [SettingsScreen()]);
        return true;
      case NotificationAction.openProfile:
        HomeScreen.openIn(3);
        return true;
    }
  }
}