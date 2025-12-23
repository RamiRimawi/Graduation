import 'package:flutter/material.dart';
import '../bottom_navbar.dart';
import '../account_page.dart';
import 'manager_theme.dart';
import 'HomeManager.dart';
import 'StockOutPage.dart';
import 'Stock-inPage.dart';
import 'NotificationPage.dart';

class ManagerShell extends StatefulWidget {
  const ManagerShell({super.key});

  @override
  State<ManagerShell> createState() => _ManagerShellState();
}

class _ManagerShellState extends State<ManagerShell> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  late UniqueKey _stockOutKey;

  // الصفحات (ممكن لاحقاً تستبدل الـ Placeholder بصفحات حقيقية)
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _stockOutKey = UniqueKey();
    _pages = [
      HomeManagerPage(onSwitchTab: _onNavTap),
      StockOutPage(key: _stockOutKey),
      StockInPage(), // مش const
      NotificationPage(),
      const AccountPage(showNavBar: false),
    ];
  }

  void _onNavTap(int index) {
    if (index == 1) {
      _stockOutKey = UniqueKey();
    }
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic, // نفس إحساس السلايد في stock-out bar
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: PageView(
        controller: _pageController,
        physics:
            const NeverScrollableScrollPhysics(), // يمنع السحب باليد – التنقل من البار فقط
        children: _pages,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
