import 'package:flutter/material.dart';
import '../bottom_navbar.dart';
import '../account_page.dart';
import 'salesRep_home_page.dart';
import 'salesRep_cart_page.dart';
import 'salesRep_archive_page.dart';
import 'salesRep_customers_page.dart';

class SalesRepShell extends StatefulWidget {
  const SalesRepShell({super.key});

  @override
  State<SalesRepShell> createState() => _SalesRepShellState();
}

class _SalesRepShellState extends State<SalesRepShell> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  // Pages for sales rep
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const SalesRepHomePage(),
      const SalesRepCartPage(),
      const SalesRepArchivePage(),
      const SalesRepCustomersPage(),
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
