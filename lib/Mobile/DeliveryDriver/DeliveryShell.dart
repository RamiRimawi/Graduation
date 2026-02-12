import 'package:flutter/material.dart';
import '../bottom_navbar.dart';
import '../account_page.dart';
import '../Manager/manager_theme.dart';
import 'deleviry_home.dart';
import 'delivery_archive.dart';

class DeliveryShell extends StatefulWidget {
  final int deliveryDriverId;

  const DeliveryShell({super.key, required this.deliveryDriverId});

  @override
  State<DeliveryShell> createState() => _DeliveryShellState();
}

class _DeliveryShellState extends State<DeliveryShell> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  // Pages for delivery driver
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeDeleviry(deliveryDriverId: widget.deliveryDriverId),
      DeliveryArchive(deliveryDriverId: widget.deliveryDriverId),
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
      backgroundColor: AppColors.bgDark,
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
