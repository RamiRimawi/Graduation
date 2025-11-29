import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final ImagePicker _picker = ImagePicker();
  XFile? _photo;

  bool _isPressed = false; // حالة الضغط على الصورة

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _photo = image;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF202020),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 90, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ================== PROFILE AVATAR ==================
                Stack(
                  children: [
                    GestureDetector(
                      onTapDown: (_) {
                        setState(() => _isPressed = true);
                      },
                      onTapUp: (_) {
                        setState(() => _isPressed = false);
                      },
                      onTapCancel: () {
                        setState(() => _isPressed = false);
                      },
                      child: AnimatedScale(
                        scale: _isPressed ? 1.1 : 1.0,
                        duration: const Duration(milliseconds: 180),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: _isPressed
                                  ? const [
                                      Color(0xFF50B2E7), // أزرق فاتح عند الضغط
                                      Color(0xFF3A8FC9), // أزرق أغمق
                                    ]
                                  : const [
                                      Color(0xFFFFE14D), // ذهب فاتح
                                      Color(0xFFB7A447), // ذهب أغمق
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: _isPressed
                                ? [
                                    BoxShadow(
                                      color: Colors.blueAccent.withOpacity(
                                        0.45,
                                      ),
                                      blurRadius: 30,
                                      spreadRadius: 5,
                                      offset: const Offset(0, 0),
                                    ),
                                  ]
                                : [],
                          ),
                          child: CircleAvatar(
                            radius: 95,
                            backgroundImage: _photo != null
                                ? FileImage(File(_photo!.path)) as ImageProvider
                                : const AssetImage('assets/images/ramadan.jpg'),
                            backgroundColor: Colors.transparent,
                          ),
                        ),
                      ),
                    ),

                    // زر تعديل الصورة
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFB7A447),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Color(0xFF202020),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Text(
                  'Kareem Manasra',
                  style: TextStyle(
                    color: Color(0xFFFFE14D),
                    fontWeight: FontWeight.w700,
                    fontSize: 25,
                  ),
                ),
                const SizedBox(height: 20),
                _buildLabelAndBox('ID #', '14135849'),
                _buildLabelAndBox('Role', 'Storage Staff'),
                _buildLabelAndBox('Address', 'Hebron - thahrea'),
                _buildLabelAndBox('Mobile Number', '0597390235'),
                _buildLabelAndBox('Telephone Number', '022860183'),
              ],
            ),
          ),

          // ========= EXIT BUTTON =========
          Positioned(
            top: 40,
            right: 12,
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context); // log out OR return
              },
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFE74C3C),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.logout, color: Colors.white, size: 28),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabelAndBox(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF2D2D2D),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFFB7A447),
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
