import 'package:flutter/material.dart';

void main() {
  runApp(const DolphinApp());
}

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Stack(
        children: [
          // ===== الخلفية =====
          Positioned.fill(
            child: Image.asset(
              'assets/images/VectorMobile.png', // اسم الصورة الجديدة
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
                      offset: const Offset(0, -35), // ✅ رفعنا اللوغو شوي لفوق
                      child: SizedBox(
                        height: 260,
                        child: Image.asset(
                          'assets/images/Logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // ---- اسم المستخدم ----
                    _buildTextField(hint: 'Enter User Name', obscure: false),
                    const SizedBox(height: 16),

                    // ---- كلمة المرور ----
                    _buildTextField(hint: 'Enter Password', obscure: true),
                    const SizedBox(height: 16),

                    // ---- تذكّرني ----
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

                    // ---- زر تسجيل الدخول ----
                    SizedBox(
                      width: 220,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.yellow,
                          shape: const StadiumBorder(),
                          padding: EdgeInsets.zero,
                          elevation: 4,
                        ),
                        child: SizedBox(
                          height: 50,
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
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

  Widget _buildTextField({required String hint, required bool obscure}) {
    return TextField(
      obscureText: obscure,
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
          letterSpacing: 0.4,
        ),
        filled: true,
        fillColor: AppColors.card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.yellow, width: 1.5),
        ),
      ),
    );
  }
}
