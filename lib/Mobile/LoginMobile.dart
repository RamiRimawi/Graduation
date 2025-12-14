import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../supabase_config.dart';
import 'Supplier/supplier_home_page.dart';
import 'DeliveryDriver/deleviry_home.dart';
import 'StroageStaff/staff_home.dart';
import 'Manager/HomeManager.dart';
import 'Customer/customer_home_page.dart';

class DolphinApp extends StatelessWidget {
  const DolphinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dolphin Stock System',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bgDark,
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const LoginPage(),
    );
  }
}

/// 🎨 ألوان
class AppColors {
  static const white = Color(0xFFFFFFFF);
  static const bgDark = Color(0xFF202020);
  static const card = Color(0xFF2D2D2D);
  static const yellow = Color(0xFFFFE14D);
  static const black = Color(0xFF000000);
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool rememberMe = false;
  bool _isLoading = false;
  late FocusNode _usernameFocus;
  late FocusNode _passwordFocus;
  
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _usernameFocus = FocusNode();
    _passwordFocus = FocusNode();
    _checkRememberedUser();
  }

  @override
  void dispose() {
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    _userIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkRememberedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUserId = prefs.getString('userId');
    final savedPassword = prefs.getString('password');
    final savedRememberMe = prefs.getBool('rememberMe') ?? false;

    if (savedRememberMe && savedUserId != null && savedPassword != null) {
      setState(() {
        _userIdController.text = savedUserId;
        _passwordController.text = savedPassword;
        rememberMe = true;
      });
      // Auto login
      _handleLogin();
    }
  }

  Future<void> _handleLogin() async {
    final userId = _userIdController.text.trim();
    final password = _passwordController.text.trim();

    if (userId.isEmpty || password.isEmpty) {
      _showError('Please enter User ID and Password');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Try to find user in all user tables
      String? userType;
      Map<String, dynamic>? userData;

      // Check Supplier
      final supplierResult = await supabase
          .from('user_account_supplier')
          .select('supplier_id, password')
          .eq('supplier_id', int.tryParse(userId) ?? 0)
          .maybeSingle();

      if (supplierResult != null && supplierResult['password'] == password) {
        userType = 'supplier';
        userData = supplierResult;
      }

      // Check Delivery Driver
      if (userType == null) {
        final driverResult = await supabase
            .from('user_account_delivery_driver')
            .select('delivery_driver_id, password')
            .eq('delivery_driver_id', int.tryParse(userId) ?? 0)
            .maybeSingle();

        if (driverResult != null && driverResult['password'] == password) {
          userType = 'delivery';
          userData = driverResult;
        }
      }

      // Check Storage Staff
      if (userType == null) {
        final staffResult = await supabase
            .from('user_account_storage_staff')
            .select('storage_staff_id, password')
            .eq('storage_staff_id', int.tryParse(userId) ?? 0)
            .maybeSingle();

        if (staffResult != null && staffResult['password'] == password) {
          userType = 'storage_staff';
          userData = staffResult;
        }
      }

      // Check Storage Manager
      if (userType == null) {
        final managerResult = await supabase
            .from('user_account_storage_manager')
            .select('storage_manager_id, password')
            .eq('storage_manager_id', int.tryParse(userId) ?? 0)
            .maybeSingle();

        if (managerResult != null && managerResult['password'] == password) {
          userType = 'manager';
          userData = managerResult;
        }
      }

      // Check Customer (NEW)
      if (userType == null) {
        final customerResult = await supabase
            .from('user_account_customer')
            .select('customer_id, password')
            .eq('customer_id', int.tryParse(userId) ?? 0)
            .maybeSingle();

        if (customerResult != null && customerResult['password'] == password) {
          userType = 'customer';
          userData = customerResult;
        }
      }

      if (userType == null || userData == null) {
        _showError('Invalid User ID or Password');
        setState(() => _isLoading = false);
        return;
      }

      // Save to SharedPreferences if Remember Me is checked
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', userId);
      await prefs.setString('userType', userType);
      // Save for account_page.dart compatibility
      await prefs.setString('current_user_id', userId);
      await prefs.setString('current_user_role', userType);
      
      if (rememberMe) {
        await prefs.setString('password', password);
        await prefs.setBool('rememberMe', true);
      }

      // Navigate to appropriate home page
      if (mounted) {
        Widget homePage;
        switch (userType) {
          case 'supplier':
            homePage = const SupplierHomePage();
            break;
          case 'delivery':
            homePage = HomeDeleviry(deliveryDriverId: int.parse(userId));
            break;
          case 'storage_staff':
            homePage = const HomeStaff();
            break;
          case 'manager':
            homePage = const HomeManagerPage();
            break;
          case 'customer':
            homePage = const CustomerHomePage();
            break;
          default:
            _showError('Unknown user type');
            setState(() => _isLoading = false);
            return;
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => homePage),
        );
      }
    } catch (e) {
      debugPrint('Login error: $e');
      _showError('Login failed: ${e.toString()}');
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Stack(
        children: [
          // ===== الخلفية =====
          Positioned.fill(
            child: Image.asset(
              'assets/images/VectorMobile.png',
              fit: BoxFit.cover,
              alignment: Alignment.centerRight,
            ),
          ),

          // ===== المحتوى =====
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ---- اللوغو ----
                    Transform.translate(
                      offset: const Offset(0, -35),
                      child: SizedBox(
                        height: 260,
                        child: Image.asset(
                          'assets/images/Logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ---- User ID ----
                    _buildLoginField(
                      hint: 'Enter User ID',
                      obscure: false,
                      focusNode: _usernameFocus,
                      controller: _userIdController,
                    ),
                    const SizedBox(height: 16),

                    // ---- Password ----
                    _buildLoginField(
                      hint: 'Enter Password',
                      obscure: true,
                      focusNode: _passwordFocus,
                      controller: _passwordController,
                    ),
                    const SizedBox(height: 16),

                    // ---- Remember me ----
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 20,
                          width: 20,
                          child: Checkbox(
                            value: rememberMe,
                            onChanged: (val) {
                              setState(() => rememberMe = val ?? false);
                            },
                            side: const BorderSide(
                              color: AppColors.yellow,
                              width: 1.8,
                            ),
                            activeColor: AppColors.yellow,
                            checkColor: AppColors.black,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Remember me',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // ---- Login Button ----
                    SizedBox(
                      width: 220,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.yellow,
                          shape: const StadiumBorder(),
                          padding: EdgeInsets.zero,
                          elevation: 4,
                          disabledBackgroundColor: AppColors.yellow.withOpacity(0.5),
                        ),
                        child: SizedBox(
                          height: 50,
                          child: Center(
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: AppColors.black,
                                    strokeWidth: 2,
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Text(
                                        'Login',
                                        style: TextStyle(
                                          color: AppColors.black,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(
                                        Icons.arrow_right_alt,
                                        color: AppColors.black,
                                        size: 24,
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================
  // 🔥 TextField مع Border ذهبي عند التركيز
  // ============================
  Widget _buildLoginField({
    required String hint,
    required bool obscure,
    required FocusNode focusNode,
    required TextEditingController controller,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscure,
      enabled: !_isLoading,
      style: const TextStyle(
        color: AppColors.white,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      cursorColor: AppColors.yellow,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color(0xFF777777),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: AppColors.card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),

        // === الـ Border العادي ===
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.transparent, width: 1.7),
        ),

        // === Border لما يصير Focus ===
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.yellow, width: 1.7),
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}