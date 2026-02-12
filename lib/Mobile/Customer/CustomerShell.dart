import 'package:flutter/material.dart';
import '../bottom_navbar.dart';
import '../account_page.dart';
import 'customer_home_page.dart';
import 'customer_cart_page.dart';
import 'customer_archive_page.dart';

class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key});

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  // Pages for customer
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const CustomerHomePage(),
      const CustomerCartPage(),
      const CustomerArchivePage(),
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
