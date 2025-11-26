import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// 🔹 صفحات الويب
import 'Website/login_page.dart';
import 'Website/dashboard_page.dart';
import 'Website/delivery_page.dart';
import 'Website/mobile_accounts_page.dart';
import 'Website/users_management_page.dart';
import 'Website/payment_page.dart';
import 'Website/report_page.dart';
import 'Website/inventory_page.dart';
import 'Website/stock_out_page.dart';

void main() {
  runApp(const DolphinApp());
}

class DolphinApp extends StatelessWidget {
  const DolphinApp({super.key});

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF202020);
    const panel = Color(0xFF2D2D2D);
    const gold = Color(0xFFB7A447);
    const blue = Color(0xFF50B2E7);
    const white = Colors.white;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dolphin Dashboard',

      // 🔹 الثيم
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        textTheme: GoogleFonts.robotoTextTheme().apply(
          bodyColor: white,
          displayColor: white,
        ),
        colorScheme: ColorScheme.dark(
          surface: panel,
          primary: gold,
          secondary: blue,
        ),
      ),

      // 🔹 البداية من صفحة Login
      initialRoute: '/login',

      // 🔹 جميع الراوتس
      routes: {
        '/login': (_) => const LoginPage(),
        '/dashboard': (_) => const DashboardPage(),
        '/delivery': (_) => const DeliveryPage(),
        '/mobileAccounts': (_) => const MobileAccountsPage(),
        '/usersManagement': (_) => const UsersManagementPage(),
        '/payment': (_) => const PaymentPage(),
        '/report': (_) => const ReportPage(),
        '/inventory': (_) => const InventoryPage(),
        '/stockOut': (_) => const OrdersPage(),
      },
    );
  }
}
