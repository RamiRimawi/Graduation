import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/sidebar.dart';

class MobileAccountsPage extends StatelessWidget {
  const MobileAccountsPage({super.key});

  // ألوان عامة
  static const Color bg = Color(0xFF202020);
  static const Color panel = Color(0xFF2D2D2D);
  static const Color gold = Color(0xFFF9D949);
  static const Color borderGold = Color(0xFFB7A447);

  @override
  Widget build(BuildContext context) {
    final Map<String, List<String>> accountGroups = {
      "Storage Manager": ["Mohammad Assi"],
      "Storage Staff": [
        "Moath Mouadi",
        "Ameer Yasin",
        "Abdullah Odwan",
        "Kareem Manasra",
        "Ramadan Abu Syam",
        "Ammar Shobaki",
        "Ibraheem Inaya",
      ],
      "Delivery Driver": [
        "Ata Musleh",
        "Ibraheem Inaya",
        "Abdullah Odwan",
        "Kareem Manasra",
        "Moath Mouadi",
      ],
      "Customer": [
        "Ramadan Abu Syam",
        "Ammar Shobaki",
        "Moath Mouadi",
        "Ameer Yasin",
        "Ata Musleh",
        "Ibraheem Inaya",
        "Rami Rimawi",
      ],
      "Sales Rep": [
        "Abdullah Odwan",
        "Kareem Manasra",
        "Ayman Rimawi",
        "Rami Rimawi",
        "Ramadan Abu Syam",
        "Moath Mouadi",
        "Ameer Yasin",
      ],
      "Supplier": [
        "Ayman Rimawi",
        "Rami Rimawi",
        "Abdullah Odwan",
        "Kareem Manasra",
      ],
    };

    return Scaffold(
      backgroundColor: bg,
      body: Row(
        children: [
          const Sidebar(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // العنوان + الزر
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Mobile Account",
                        style: GoogleFonts.roboto(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: gold,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        onPressed: () => _openRoleChooser(context),
                        icon: const Icon(Icons.person_add_alt_1,
                            color: Colors.black),
                        label: const Text(
                          "Add Account",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // حقل البحث
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 250,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: panel,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.person_search_rounded,
                                color: Colors.white60, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                style: TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: "Account Name",
                                  hintStyle: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 14,
                                  ),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            SizedBox(width: 5),
                            Icon(Icons.filter_alt_rounded,
                                color: Colors.amberAccent),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  // القوائم + الكروت
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final entry in accountGroups.entries) ...[
                            Text(
                              entry.key,
                              style: GoogleFonts.roboto(
                                color: const Color(0xFFB7A447),
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                for (final name in entry.value)
                                  _AccountCard(name: name),
                              ],
                            ),
                            const SizedBox(height: 35),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /* ----------------------- POPUP: CHOOSE ROLE ----------------------- */

  void _openRoleChooser(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      builder: (ctx) {
        return Stack(
          children: [
            // Blur الخلفية
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(color: Colors.black.withOpacity(0.55)),
                ),
              ),
            ),

            // صندوق اختيار الدور
            Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 880),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black54,
                        offset: Offset(0, 10),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Padding(
                        padding:
                            const EdgeInsets.only(top: 6, right: 8, left: 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Choose Account Role",
                              style: GoogleFonts.roboto(
                                color: gold,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 26),
                            Wrap(
                              spacing: 22,
                              runSpacing: 22,
                              alignment: WrapAlignment.center,
                              children: [
                                _RoleCard(
                                  title: 'Customer',
                                  icon: Icons.groups_rounded,
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    _openRoleForm(
                                        context, _RoleFormType.customer);
                                  },
                                ),
                                _RoleCard(
                                  title: 'Supplier',
                                  icon: Icons.inventory_2_rounded,
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    _openRoleForm(
                                        context, _RoleFormType.supplier);
                                  },
                                ),
                                _RoleCard(
                                  title: 'Sales Rep',
                                  icon: Icons.badge_rounded,
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    _openRoleForm(
                                        context, _RoleFormType.salesRep);
                                  },
                                ),
                                _RoleCard(
                                  title: 'Storage Staff',
                                  icon: Icons.warehouse_rounded,
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    _openRoleForm(
                                        context, _RoleFormType.storageStaff);
                                  },
                                ),
                                _RoleCard(
                                  title: 'Delivery',
                                  icon: Icons.local_shipping_rounded,
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    _openRoleForm(
                                        context, _RoleFormType.deliveryDriver);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: IconButton(
                          splashRadius: 20,
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded,
                              color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /* ------------------- POPUPS: FORMS لكل نوع حساب ------------------- */

  void _openRoleForm(BuildContext context, _RoleFormType type) {
    late final String title;
    late final Widget form;

    switch (type) {
      case _RoleFormType.customer:
        title = 'Customer';
        form = const _SimpleThreeFieldForm(
          firstLabel: 'Customer Name',
          firstHint: 'Select Customer Name',
        );
        break;
      case _RoleFormType.supplier:
        title = 'Supplier';
        form = const _SimpleThreeFieldForm(
          firstLabel: 'Supplier Name',
          firstHint: 'Select Supplier Name',
        );
        break;
      case _RoleFormType.salesRep:
        title = 'Sales Rep';
        form = const _SimpleThreeFieldForm(
          firstLabel: 'Sales Rep Name',
          firstHint: 'Select Sales Rep Name',
        );
        break;
      case _RoleFormType.deliveryDriver:
        title = 'Delivery Driver';
        form = const _ExtendedStaffForm(
          title: 'Delivery Driver',
          nameLabel: 'Delivery Driver Name',
        );
        break;
      case _RoleFormType.storageStaff:
        title = 'Storage Staff';
        form = const _ExtendedStaffForm(
          title: 'Storage Staff',
          nameLabel: 'Storage Staff Name',
        );
        break;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      builder: (ctx) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(color: Colors.black.withOpacity(0.55)),
                ),
              ),
            ),
            Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  constraints: const BoxConstraints(
                    maxWidth: 880,
                    minWidth: 620,
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black54,
                        offset: Offset(0, 10),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Padding(
                        padding:
                            const EdgeInsets.only(top: 6, right: 8, left: 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.roboto(
                                color: gold,
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 26),
                            form,
                          ],
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: IconButton(
                          splashRadius: 20,
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded,
                              color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// أنواع النماذج
enum _RoleFormType { customer, supplier, salesRep, storageStaff, deliveryDriver }

// الكرت في القائمة الرئيسية
class _AccountCard extends StatelessWidget {
  final String name;

  const _AccountCard({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            offset: Offset(0, 3),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 15,
            backgroundColor: Colors.grey,
            child: Icon(Icons.person, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------------- Role Card داخل Popup -------------------- */

class _RoleCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 210,
        height: 170,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Colors.black45,
              offset: Offset(0, 8),
              blurRadius: 18,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: Colors.black.withOpacity(0.85)),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.roboto(
                color: const Color(0xFFF9D949),
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ----------------- النماذج البسيطة (Customer/Supplier/SalesRep) ----------------- */

class _SimpleThreeFieldForm extends StatelessWidget {
  final String firstLabel;
  final String firstHint;

  const _SimpleThreeFieldForm({
    required this.firstLabel,
    required this.firstHint,
  });

  @override
  Widget build(BuildContext context) {
    final nameCtrl = TextEditingController();
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FormLabel(firstLabel),
        const SizedBox(height: 6),
        _FormFieldBox(
          controller: nameCtrl,
          hint: firstHint,
          isDropdown: true,
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _FormLabel('User Name'),
                  const SizedBox(height: 6),
                  _FormFieldBox(
                    controller: userCtrl,
                    hint: 'Entre User Name',
                  ),
                ],
              ),
            ),
            const SizedBox(width: 28),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _FormLabel('Password'),
                  const SizedBox(height: 6),
                  _FormFieldBox(
                    controller: passCtrl,
                    hint: 'Entre Password',
                    obscure: true,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 26),
        const _SubmitButton(),
      ],
    );
  }
}

/* ----------------- النماذج الممتدة (Storage Staff / Delivery Driver) ----------------- */

class _ExtendedStaffForm extends StatelessWidget {
  final String title;
  final String nameLabel;

  const _ExtendedStaffForm({
    required this.title,
    required this.nameLabel,
  });

  @override
  Widget build(BuildContext context) {
    final nameCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();
    final telCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Name
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FormLabel(nameLabel),
                    const SizedBox(height: 6),
                    _FormFieldBox(
                      controller: nameCtrl,
                      hint: 'Entre Full Name',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Mobile / Telephone
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FormLabel('Mobile Number'),
                    const SizedBox(height: 6),
                    _FormFieldBox(
                      controller: mobileCtrl,
                      hint: 'Entre Mobile Number',
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 28),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FormLabel('Telephone Number'),
                    const SizedBox(height: 6),
                    _FormFieldBox(
                      controller: telCtrl,
                      hint: 'Entre Telephone Number',
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Address
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FormLabel('Address'),
                    const SizedBox(height: 6),
                    _FormFieldBox(
                      controller: addressCtrl,
                      hint: 'Entre Address',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // User / Pass
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FormLabel('User Name'),
                    const SizedBox(height: 6),
                    _FormFieldBox(
                      controller: userCtrl,
                      hint: 'Entre Account User Name',
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 28),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FormLabel('Password'),
                    const SizedBox(height: 6),
                    _FormFieldBox(
                      controller: passCtrl,
                      hint: 'Entre Account Password',
                      obscure: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          const _SubmitButton(),
        ],
      ),
    );
  }
}

/* --------------------------- Helpers للحقول --------------------------- */

class _FormLabel extends StatelessWidget {
  final String text;
  const _FormLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.roboto(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _FormFieldBox extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final bool isDropdown;
  final TextInputType? keyboardType;

  const _FormFieldBox({
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.isDropdown = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF232427),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: MobileAccountsPage.borderGold, width: 1),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: Colors.white54,
            fontSize: 13,
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          suffixIcon: isDropdown
              ? const Icon(Icons.expand_more_rounded,
                  color: MobileAccountsPage.borderGold)
              : null,
        ),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: SizedBox(
        height: 58,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: MobileAccountsPage.gold,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 40),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              fontSize: 18,
            ),
          ),
          onPressed: () {
            Navigator.of(context).pop(); // مؤقتاً بس يسكر الـ popup
          },
          icon: const Icon(Icons.person_add_alt_1, size: 26),
          label: const Text("Submit"),
        ),
      ),
    );
  }
}
