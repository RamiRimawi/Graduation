// ...existing code...
import 'package:flutter/material.dart';
import '../account_page.dart';
import 'supplier_home_page.dart';

class SupplierBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const SupplierBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const double indicatorWidth = 70.0; // increased width

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF242424),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            offset: Offset(0, -3),
            blurRadius: 6,
          ),
        ],
      ),

      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
        ),

        child: BottomNavigationBar(
          backgroundColor: const Color(0xFF242424),
          currentIndex: currentIndex,
          type: BottomNavigationBarType.fixed,
          elevation: 0,

          // hide built-in labels so we can draw our own label + indicator
          showSelectedLabels: false,
          showUnselectedLabels: false,

          selectedItemColor: const Color(0xFFF9D949),
          unselectedItemColor: Colors.white60,

          onTap: onTap,

          items: [
            BottomNavigationBarItem(
              icon: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.home_filled),
                  const SizedBox(height: 6),
                  Text(
                    'Home',
                    style: TextStyle(
                      color: currentIndex == 0 ? const Color(0xFFF9D949) : Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: currentIndex == 0 ? indicatorWidth : 0, // changed
                    height: 3,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9D949),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
              label: '',
            ),

            BottomNavigationBarItem(
              icon: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person),
                  const SizedBox(height: 6),
                  Text(
                    'Account',
                    style: TextStyle(
                      color: currentIndex == 1 ? const Color(0xFFF9D949) : Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: currentIndex == 1 ? indicatorWidth : 0, // changed
                    height: 3,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9D949),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
              label: '',
            ),
          ],
        ),
      ),
    );
  }
}