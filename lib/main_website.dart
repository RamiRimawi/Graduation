import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'supabase_config.dart';
import 'Website/login_page.dart';
import 'Website/dashboard_page.dart';
import 'Website/account_page.dart';
import 'Website/Delivery/delivery_page.dart';
import 'Website/MobileAccounts/mobile_accounts_page.dart';
import 'Website/Management/Management_page.dart';
import 'Website/Payment/Payment_page.dart';
import 'Website/Report/report_page.dart';
import 'Website/Report/report_customer.dart';
import 'Website/Report/report_supplier.dart';
import 'Website/Report/report_destroyed_product.dart';
import 'Website/Inventory/inventory_page.dart';
import 'Website/Orders/Orders_stock_out_page.dart';
import 'Website/Damaged_Product/damaged_products_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
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

      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        textTheme: GoogleFonts.robotoTextTheme(
          ThemeData.dark().textTheme,
        ).apply(bodyColor: white, displayColor: white),
        fontFamily: GoogleFonts.roboto().fontFamily,
        colorScheme: ColorScheme.dark(
          surface: panel,
          primary: gold,
          secondary: blue,
        ),
      ),

      // 🔹 البداية من صفحة Login
      initialRoute: '/login',

      routes: {
        '/login': (_) => const LoginPage(),
        '/dashboard': (_) => const DashboardPage(),
        '/delivery': (_) => const DeliveryPage(),
        '/mobileAccounts': (_) => const MobileAccountsPage(),
        '/usersManagement': (_) => const UsersManagementPage(),
        '/payment': (_) => const PaymentPage(),
        '/report': (_) => const ReportPage(),
        '/reportCustomer': (_) => const ReportCustomerPage(),
        '/reportSupplier': (_) => const ReportSupplierPage(),
        '/reportDestroyedProduct': (_) => const ReportDestroyedProductPage(),
        '/inventory': (_) => const InventoryPage(),
        '/stockOut': (_) => const OrdersPage(),
        '/account': (_) => const ProfilePageContent(),
        '/damagedProducts': (_) => const DamagedProductsPage(),
      },
    );
  }
}
