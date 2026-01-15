import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

      initialRoute: '/login',
      onGenerateRoute: (settings) => _onGenerateRoute(settings),
    );
  }

  static Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    return MaterialPageRoute(
      settings: settings,
      builder: (context) => _AuthGuard(
        routeName: settings.name ?? '/login',
      ),
    );
  }
}

class _AuthGuard extends StatelessWidget {
  final String routeName;

  const _AuthGuard({required this.routeName});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF202020),
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFFB7A447),
              ),
            ),
          );
        }

        final isLoggedIn = snapshot.data ?? false;

        // If trying to access login page while logged in, redirect to dashboard
        if (routeName == '/login') {
          if (isLoggedIn) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacementNamed(context, '/dashboard');
            });
          }
          return const LoginPage();
        }

        // If not logged in and trying to access protected page, redirect to login
        if (!isLoggedIn) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/login');
          });
          return const Scaffold(
            backgroundColor: Color(0xFF202020),
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFFB7A447),
              ),
            ),
          );
        }

        // User is logged in, show the requested page
        return _getPageForRoute(routeName);
      },
    );
  }

  Future<bool> _isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final accountantId = prefs.getInt('accountant_id');
    return accountantId != null;
  }

  Widget _getPageForRoute(String route) {
    switch (route) {
      case '/dashboard':
        return const DashboardPage();
      case '/delivery':
        return const DeliveryPage();
      case '/mobileAccounts':
        return const MobileAccountsPage();
      case '/usersManagement':
        return const UsersManagementPage();
      case '/payment':
        return const PaymentPage();
      case '/report':
        return const ReportPage();
      case '/reportCustomer':
        return const ReportCustomerPage();
      case '/reportSupplier':
        return const ReportSupplierPage();
      case '/reportDestroyedProduct':
        return const ReportDestroyedProductPage();
      case '/inventory':
        return const InventoryPage();
      case '/stockOut':
        return const OrdersPage();
      case '/account':
        return const ProfilePageContent();
      case '/damagedProducts':
        return const DamagedProductsPage();
      default:
        return const LoginPage();
    }
  }
}