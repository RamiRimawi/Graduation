import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../supabase_config.dart';
import 'Supplier/supplier_home_page.dart';
import 'DeliveryDriver/deleviry_home.dart';
import 'StroageStaff/staff_home.dart';
import 'Manager/ManagerShell.dart';
import 'Customer/customer_home_page.dart';
import 'Sales Rep/salesRep_home_page.dart';

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

  String _normalizeArabicDigits(String input) {
    const arabicIndic = '٠١٢٣٤٥٦٧٨٩';
    const easternArabicIndic = '۰۱۲۳۴۵۶۷۸۹';
    final buffer = StringBuffer();

    for (final ch in input.runes) {
      final char = String.fromCharCode(ch);
      final idxArabic = arabicIndic.indexOf(char);
      if (idxArabic >= 0) {
        buffer.write(idxArabic.toString());
        continue;
      }
      final idxEastern = easternArabicIndic.indexOf(char);
      if (idxEastern >= 0) {
        buffer.write(idxEastern.toString());
        continue;
      }
      buffer.write(char);
    }

    return buffer.toString();
  }

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

  Future<void> _cacheUserAccountData(String userType, String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? id = int.tryParse(userId);

      if (id == null) return;

      // Fetch data based on user type
      Map<String, dynamic>? profile;
      Map<String, dynamic>? userAccount;
      String? role;

      // Get profile image from accounts table
      final accountData = await supabase
          .from('accounts')
          .select('profile_image')
          .eq('user_id', id)
          .maybeSingle();

      switch (userType) {
        case 'supplier':
          profile = await supabase
              .from('supplier')
              .select('supplier_id,name,mobile_number,telephone_number,address')
              .eq('supplier_id', id)
              .maybeSingle();
          role = 'Supplier';
          break;

        case 'delivery':
          profile = await supabase
              .from('delivery_driver')
              .select(
                'delivery_driver_id,name,mobile_number,telephone_number,address',
              )
              .eq('delivery_driver_id', id)
              .maybeSingle();
          role = 'Delivery Driver';
          break;

        case 'storage_staff':
          profile = await supabase
              .from('storage_staff')
              .select(
                'storage_staff_id,name,mobile_number,telephone_number,address',
              )
              .eq('storage_staff_id', id)
              .maybeSingle();
          role = 'Storage Staff';
          break;

        case 'manager':
          profile = await supabase
              .from('storage_manager')
              .select(
                'storage_manager_id,name,mobile_number,telephone_number,address',
              )
              .eq('storage_manager_id', id)
              .maybeSingle();
          role = 'Storage Manager';
          break;

        case 'customer':
          profile = await supabase
              .from('customer')
              .select('customer_id,name,mobile_number,telephone_number,address')
              .eq('customer_id', id)
              .maybeSingle();
          role = 'Customer';
          break;
      }

      userAccount = accountData;

      // Cache the data in SharedPreferences
      if (profile != null) {
        await prefs.setString(
          'cached_user_name',
          profile['name']?.toString() ?? 'Unknown',
        );
        await prefs.setString('cached_user_role', role ?? userType);
        await prefs.setString(
          'cached_user_address',
          profile['address']?.toString() ?? '',
        );
        await prefs.setString(
          'cached_user_mobile',
          profile['mobile_number']?.toString() ?? '',
        );
        await prefs.setString(
          'cached_user_telephone',
          profile['telephone_number']?.toString() ?? '',
        );
        await prefs.setString(
          'current_user_name',
          profile['name']?.toString() ?? 'Unknown',
        );

        if (userAccount != null && userAccount['profile_image'] != null) {
          await prefs.setString(
            'cached_user_image',
            userAccount['profile_image'].toString(),
          );
        }
      }
    } catch (e) {
      debugPrint('Error caching user data: $e');
      // Continue with login even if caching fails
    }
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
    final userId = _normalizeArabicDigits(_userIdController.text.trim());
    final password = _normalizeArabicDigits(_passwordController.text.trim());

    if (userId.isEmpty || password.isEmpty) {
      _showError('Please enter User ID and Password');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Query unified accounts table
      final accountResult = await supabase
          .from('accounts')
          .select('user_id, password, type, is_active')
          .eq('user_id', int.tryParse(userId) ?? 0)
          .maybeSingle();

      if (accountResult == null) {
        _showError('Invalid User ID or Password');
        setState(() => _isLoading = false);
        return;
      }

      // Check password
      if (accountResult['password'] != password) {
        _showError('Invalid User ID or Password');
        setState(() => _isLoading = false);
        return;
      }

      // Check if account is active
      if (accountResult['is_active'] != true) {
        _showError('Account is inactive. Contact administrator.');
        setState(() => _isLoading = false);
        return;
      }

      // Map type to internal userType
      final accountType = accountResult['type'] as String?;
      String? userType;

      if (accountType == 'Supplier') {
        userType = 'supplier';
      } else if (accountType == 'Delivery Driver') {
        userType = 'delivery';
      } else if (accountType == 'Storage Staff') {
        userType = 'storage_staff';
      } else if (accountType == 'Storage Manager') {
        userType = 'manager';
      } else if (accountType == 'Sales Rep') {
        userType = 'sales_rep';
      } else if (accountType == 'Customer') {
        userType = 'customer';
      } else if (accountType == 'Accountant') {
        _showError('Accountant login not supported in mobile app');
        setState(() => _isLoading = false);
        return;
      }

      if (userType == null) {
        _showError('Unknown account type');
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

      // Cache all user account data for immediate display in account page
      await _cacheUserAccountData(userType, userId);

      final String roleTag = switch (userType) {
        'delivery' => 'driver',
        'storage_staff' => 'storage_staff',
        'manager' => 'manager',
        'sales_rep' => 'sales_rep',
        'customer' => 'customer',
        'supplier' => 'supplier',
        _ => userType,
      };
      await OneSignal.User.addTagWithKey('role', roleTag);
      await OneSignal.User.addTagWithKey('user_id', userId);

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
            homePage = const ManagerShell();
            break;
          case 'sales_rep':
            homePage = const SalesRepHomePage();
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
                      normalizeArabicDigits: true,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(9),
                      ],
                      maxLength: 9,
                    ),
                    const SizedBox(height: 16),

                    // ---- Password ----
                    _buildLoginField(
                      hint: 'Enter Password',
                      obscure: true,
                      focusNode: _passwordFocus,
                      controller: _passwordController,
                      normalizeArabicDigits: true,
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
                          disabledBackgroundColor: AppColors.yellow.withOpacity(
                            0.5,
                          ),
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
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
    bool normalizeArabicDigits = false,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscure,
      enabled: !_isLoading,
      keyboardType: keyboardType,
      inputFormatters: [
        if (normalizeArabicDigits) _ArabicDigitsToLatinFormatter(),
        ...?inputFormatters,
      ],
      maxLength: maxLength,
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
        counterText: maxLength != null ? '' : null,
      ),
    );
  }
}

class _ArabicDigitsToLatinFormatter extends TextInputFormatter {
  static const _arabicIndic = '٠١٢٣٤٥٦٧٨٩';
  static const _easternArabicIndic = '۰۱۲۳۴۵۶۷۸۹';

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    final buffer = StringBuffer();

    for (final ch in text.runes) {
      final char = String.fromCharCode(ch);
      final idxArabic = _arabicIndic.indexOf(char);
      if (idxArabic >= 0) {
        buffer.write(idxArabic.toString());
        continue;
      }
      final idxEastern = _easternArabicIndic.indexOf(char);
      if (idxEastern >= 0) {
        buffer.write(idxEastern.toString());
        continue;
      }
      buffer.write(char);
    }

    final normalized = buffer.toString();
    if (normalized == text) return newValue;

    final selectionIndex = normalized.length;
    return TextEditingValue(
      text: normalized,
      selection: TextSelection.collapsed(offset: selectionIndex),
      composing: TextRange.empty,
    );
  }
}
