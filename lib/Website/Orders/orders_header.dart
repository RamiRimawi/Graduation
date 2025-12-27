import 'package:flutter/material.dart';

/// Reusable header widget for all order pages
/// Contains: Title, Stock toggle, Create order button, Notification icon, and Tabs
class OrdersHeader extends StatelessWidget {
  /// Current stock tab: 0 = Stock-out, 1 = Stock-in
  final int stockTab;

  /// Current page tab: 0 = Today, 1 = Receives, 2 = Previous
  final int currentTab;

  /// Callback when stock toggle is changed
  final ValueChanged<int> onStockTabChanged;

  /// Callback when page tab is tapped
  final ValueChanged<int> onTabChanged;

  /// Callback when create order button is pressed
  final VoidCallback onCreateOrder;

  /// Callback when notification icon is tapped (optional)
  final VoidCallback? onNotificationTap;

  const OrdersHeader({
    super.key,
    required this.stockTab,
    required this.currentTab,
    required this.onStockTabChanged,
    required this.onTabChanged,
    required this.onCreateOrder,
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 40),
        // Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Orders',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            Row(
              children: [
                // Stock toggle
                _StockToggle(selected: stockTab, onChanged: onStockTabChanged),
                const SizedBox(width: 16),
                // Create order button
                _CreateOrderButton(onPressed: onCreateOrder),
                const SizedBox(width: 10),
                // Notification icon
                InkWell(
                  onTap: onNotificationTap,
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 30),
        // Tabs
        Align(
          alignment: Alignment.centerLeft,
          child: _SimpleTabs(current: currentTab, onTap: onTabChanged),
        ),
      ],
    );
  }
}

/// Stock-out / Stock-in toggle widget
class _StockToggle extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;
  const _StockToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: ShapeDecoration(
        color: const Color(0xFF1B1B1B),
        shape: StadiumBorder(
          side: BorderSide(color: const Color(0xFFB7A447).withOpacity(.5)),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _pill(
            'Stock-out',
            Icons.logout_rounded,
            selected == 0,
            () => onChanged(0),
          ),
          _pill(
            'Stock-in',
            Icons.login_rounded,
            selected == 1,
            () => onChanged(1),
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, IconData icon, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: ShapeDecoration(
          color: active ? const Color(0xFF2D2D2D) : Colors.transparent,
          shape: const StadiumBorder(),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

/// Create order button widget
class _CreateOrderButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _CreateOrderButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const ShapeDecoration(
        shape: StadiumBorder(),
        color: Color(0xFFFFE14D),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onPressed,
          customBorder: const StadiumBorder(),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.add_box_rounded, color: Colors.black87),
                SizedBox(width: 8),
                Text(
                  'Create order',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Today / Receives / Previous tabs widget
class _SimpleTabs extends StatelessWidget {
  final int current;
  final ValueChanged<int> onTap;
  const _SimpleTabs({required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const tabs = ['Today', 'Receives', 'Previous'];

    return Row(
      children: List.generate(tabs.length, (i) {
        final active = current == i;
        return Padding(
          padding: const EdgeInsets.only(right: 22),
          child: InkWell(
            onTap: () => onTap(i),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tabs[i],
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withOpacity(active ? 1 : .7),
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  height: 3,
                  width: active ? _textWidth(tabs[i], context) : 0,
                  decoration: BoxDecoration(
                    color: active
                        ? const Color(0xFF50B2E7)
                        : Colors.transparent,
                    borderRadius: const BorderRadius.all(Radius.circular(4)),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  double _textWidth(String text, BuildContext context) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    return tp.width;
  }
}
