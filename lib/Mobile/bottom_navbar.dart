import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BottomNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  String? _role;
  static const double _indicatorWidth = 70.0;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('current_user_role');
    if (mounted) {
      setState(() => _role = role);
    }
  }

  // Return a list of item descriptors for the given role.
  List<_NavItem> _itemsForRole(String? role) {
    // Normalize role strings we expect
    final r = (role ?? '').toLowerCase();

    // Storage Manager layout (first picture)
    if (r == 'manager' || r == 'storage_manager') {
      return [
        _NavItem(Icons.home_filled, 'Home'),
        _NavItem(Icons.upload_outlined, 'Stock-out'),
        _NavItem(Icons.download_outlined, 'Stock-in'),
        _NavItem(Icons.notifications_outlined, 'Notification', showDot: true),
        _NavItem(Icons.person, 'Account'),
      ];
    }

    // Customer layout (second picture)
    if (r == 'customer') {
      return [
        _NavItem(Icons.home_filled, 'Home'),
        _NavItem(Icons.shopping_cart_outlined, 'Cart'),
        _NavItem(Icons.archive_outlined, 'Archive'),
        _NavItem(Icons.person, 'Account'),
      ];
    }

    // Sales Rep layout (third picture)
    if (r == 'sales_rep' || r == 'sales') {
      return [
        _NavItem(Icons.home_filled, 'Home'),
        _NavItem(Icons.shopping_cart_outlined, 'Cart'),
        _NavItem(Icons.list_alt, 'Orders'),
        _NavItem(Icons.people_alt_outlined, 'Customers'),
        _NavItem(Icons.person, 'Account'),
      ];
    }

    // Default (old) layout — keep the original compact two-item layout
    return [
      _NavItem(Icons.home_filled, 'Home'),
      _NavItem(Icons.person, 'Account'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final items = _itemsForRole(_role);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF242424),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
        ),
        child: BottomNavigationBar(
          backgroundColor: const Color(0xFF242424),
          currentIndex: widget.currentIndex.clamp(0, items.length - 1),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          selectedItemColor: const Color(0xFFF9D949),
          unselectedItemColor: Colors.white60,
          onTap: (i) {
            // Protect against out-of-range indexes if caller passed an index that
            // doesn't exist for this role's layout.
            final idx = i.clamp(0, items.length - 1);
            widget.onTap(idx);
          },
          items: items.map((desc) {
            final idx = items.indexOf(desc);
            final selected = idx == widget.currentIndex;
            final labelColor = selected ? const Color(0xFFF9D949) : Colors.white60;

            // build icon with optional notification dot
            Widget iconWidget = Icon(desc.icon, size: 24, color: labelColor);

            if (desc.showDot) {
              // add a small yellow dot on top-right
              iconWidget = Stack(
                clipBehavior: Clip.none,
                children: [
                  iconWidget,
                  Positioned(
                    right: -2,
                    top: -6,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9D949),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF242424), width: 2),
                      ),
                    ),
                  ),
                ],
              );
            }

            return BottomNavigationBarItem(
              icon: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  iconWidget,
                  const SizedBox(height: 6),
                  Text(
                    desc.label,
                    style: TextStyle(
                      color: labelColor,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: selected ? _indicatorWidth : 0,
                    height: 3,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9D949),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
              label: '',
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final bool showDot;
  const _NavItem(this.icon, this.label, {this.showDot = false});
}