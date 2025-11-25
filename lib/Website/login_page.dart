import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  // ألوان الواجهة
  static const _bg = Color(0xFF0E1115); // خلفية غامقة
  static const _panel = Color(0xFF232427); // لون الحقول
  static const _gold = Color(0xFFF7D348); // زر Login الأصفر
  static const _blue = Color(
    0xFF0E3A6B,
  ); // ✅ أعدناه لمنع خطأ hot reload (حتى لو غير مستخدم)

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // الخلفية من الصورة
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: size.width, // زِد العرض بدل ما تعمل scale
              height: size.height,
              child: Image.asset(
                'assets/images/Vector.png',
                fit: BoxFit.contain, // يحافظ على الشكل كامل بدون قص أو تمديد
                alignment: Alignment.centerRight, // يبقيها يمين الشاشة
              ),
            ),
          ),

          // المحتوى
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(top: 45),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // الشعار
                      Padding(
                        padding: const EdgeInsets.only(bottom: 30),
                        child: Image.asset(
                          'assets/images/Logo.png',
                          width: 550,
                          fit: BoxFit.contain,
                        ),
                      ),

                      const SizedBox(height: 24),

                      const _GlassField(hint: 'Entre UserName', obscure: false),
                      const SizedBox(height: 16),

                      const _GlassField(hint: 'Entre Password', obscure: true),
                      const SizedBox(height: 30),

                      SizedBox(
                        width: 260,
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _gold,
                            foregroundColor: Colors.black,
                            elevation: 6,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              fontSize: 20,
                            ),
                          ),
                          onPressed: () {
                            // TODO: Handle login
                          },
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Login'),
                              SizedBox(width: 12),
                              Icon(Icons.login_rounded, size: 24),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// حقل إدخال بشكل بانيل غامق
class _GlassField extends StatelessWidget {
  final String hint;
  final bool obscure;
  const _GlassField({required this.hint, required this.obscure});

  static const _panel = Color(0xFF232427);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            offset: Offset(0, 6),
            blurRadius: 16,
            spreadRadius: -8,
          ),
        ],
      ),
      child: TextField(
        obscureText: obscure,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          letterSpacing: .4,
        ),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(.55),
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}
