import 'package:flutter/material.dart';
import '../bottom_navbar.dart';
import '../account_page.dart';
import 'supplier_home_page.dart';

class SupplierShell extends StatefulWidget {
  const SupplierShell({super.key});

  @override
  State<SupplierShell> createState() => _SupplierShellState();
}

class _SupplierShellState extends State<SupplierShell> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  // Pages for supplier
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const SupplierHomePage(),
      const AccountPage(showNavBar: false),
    ];
  }

  void _onNavTap(int index) {
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF202020),
      body: PageView(
        controller: _pageController,
        physics:
            const NeverScrollableScrollPhysics(), // Prevent swipe – navigate via navbar only
        children: _pages,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
