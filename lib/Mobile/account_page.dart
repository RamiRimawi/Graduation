import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'Supplier/supplier_bottom_nav.dart';
import 'Supplier/supplier_home_page.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final ImagePicker _picker = ImagePicker();
  XFile? _photo;

  bool _isPressed = false;

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
                Stack(
                  children: [
                    GestureDetector(
                      onTapDown: (_) => setState(() => _isPressed = true),
                      onTapUp: (_) => setState(() => _isPressed = false),
                      onTapCancel: () => setState(() => _isPressed = false),
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
                                      Color(0xFF50B2E7),
                                      Color(0xFF3A8FC9),
                                    ]
                                  : const [
                                      Color(0xFFFFE14D),
                                      Color(0xFFB7A447),
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 95,
                            backgroundImage: _photo != null
                                ? FileImage(File(_photo!.path))
                                : const AssetImage('assets/images/ramadan.jpg')
                                    as ImageProvider,
                          ),
                        ),
                      ),
                    ),

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
                          ),
                          child: const Icon(Icons.edit,
                              color: Color(0xFF202020)),
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

          Positioned(
            top: 40,
            right: 12,
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFE74C3C),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.logout,
                    color: Colors.white, size: 28),
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: SupplierBottomNav(
        currentIndex: 1,
        onTap: (i) {
          if (i == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const SupplierHomePage()),
            );
          }
        },
      ),
    );
  }

  Widget _buildLabelAndBox(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 22,
              )),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
