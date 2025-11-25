import 'package:flutter/material.dart';
import 'Bar.dart';
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

  // الصفحات (ممكن لاحقاً تستبدل الـ Placeholder بصفحات حقيقية)
 final List<Widget> _pages = [
  const HomeManagerPage(),
  const StockOutPage(),
  StockInPage(), // مش const
  NotificationPage(),
  const _PlaceholderPage(title: 'Account'),
];


  void _onNavTap(int index) {
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
      bottomNavigationBar: BottomNav(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  final String title;
  const _PlaceholderPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Center(
        child: Text(
          '$title Page\n(Coming Soon)',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
