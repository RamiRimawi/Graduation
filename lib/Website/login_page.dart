import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const _bg = Color(0xFF0E1115);
  static const _gold = Color(0xFFF7D348);

  final TextEditingController idController = TextEditingController();
  final TextEditingController passController = TextEditingController();

  bool usernameError = false;
  bool passwordError = false;
  bool loading = false;

  Future<void> login() async {
    setState(() {
      loading = true;
      usernameError = false;
      passwordError = false;
    });

    final supabase = Supabase.instance.client;
    final id = idController.text.trim();
    final pass = passController.text.trim();

    try {
      final response = await supabase
          .from('user_account_accountant')
          .select('password')
          .eq('accountant_id', id)
          .maybeSingle();

      print("LOGIN RESPONSE: $response");

      if (response == null) {
        setState(() {
          usernameError = true;
          loading = false;
        });
        return;
      }

      final savedPass = response['password'];

      if (savedPass != pass) {
        setState(() {
          passwordError = true;
          loading = false;
        });
        return;
      }

      // Store accountant ID in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('accountant_id', int.parse(id));
      print('Stored accountant_id: $id');

      Navigator.pushReplacementNamed(context, "/dashboard");
    } catch (e) {
      print("LOGIN ERROR: $e");
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: Image.asset(
                'assets/images/Vector.png',
                fit: BoxFit.contain,
                alignment: Alignment.centerRight,
              ),
            ),
          ),

          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(top: 45),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 30),
                        child: Image.asset(
                          'assets/images/Logo.png',
                          width: 550,
                          fit: BoxFit.contain,
                        ),
                      ),

                      const SizedBox(height: 24),

                      _GlassField(
                        hint: "Enter Username",
                        obscure: false,
                        controller: idController,
                        error: usernameError,
                        errorMessage: "Invalid username",
                        onChanged: () {
                          setState(() => usernameError = false);
                        },
                      ),

                      const SizedBox(height: 16),

                      _GlassField(
                        hint: "Enter Password",
                        obscure: true,
                        controller: passController,
                        error: passwordError,
                        errorMessage: "Wrong password",
                        onChanged: () {
                          setState(() => passwordError = false);
                        },
                      ),

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
                          onPressed: loading ? null : login,
                          child: loading
                              ? const CircularProgressIndicator(color: Colors.black)
                              : const Row(
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

class _GlassField extends StatefulWidget {
  final String hint;
  final bool obscure;
  final TextEditingController controller;
  final bool error;
  final String errorMessage;
  final VoidCallback onChanged;

  const _GlassField({
    required this.hint,
    required this.obscure,
    required this.controller,
    required this.error,
    required this.errorMessage,
    required this.onChanged,
  });

  @override
  State<_GlassField> createState() => _GlassFieldState();
}

class _GlassFieldState extends State<_GlassField> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  static const _panel = Color(0xFF232427);
  static const _gold = Color(0xFFF7D348);

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.error
        ? Colors.redAccent
        : (_isFocused ? _gold : Colors.transparent);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: _panel,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 2),
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
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.obscure,
            onChanged: (_) => widget.onChanged(),
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
              hintText: widget.hint,
              hintStyle: TextStyle(
                color: Colors.white54,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),

        if (widget.error)
          Padding(
            padding: const EdgeInsets.only(left: 6, top: 6),
            child: Text(
              widget.errorMessage,
              style: const TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
      ],
    );
  }
}
