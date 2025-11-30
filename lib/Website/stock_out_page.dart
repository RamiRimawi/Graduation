import 'package:flutter/material.dart';
import 'sidebar.dart';
import 'create_stock_out_page.dart';
import 'stock_in_page.dart';
import 'stock_out_receives.dart';
import 'stock_out_previous.dart';

// 🎨 الألوان
class AppColors {
  static const white = Color(0xFFFFFFFF);
  static const gold = Color(0xFFB7A447);
  static const bgDark = Color(0xFF202020);
  static const card = Color(0xFF2D2D2D);
  static const cardAlt = Color(0xFF262626);
  static const divider = Color(0xFF6F6F6F);
  static const blue = Color(0xFF50B2E7);
  static const danger = Color(0xFFE15A5A);
  static const delivered = Color(0xFF9FA1A2);
}

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  int stockTab = 0;
  int? hoveredRow;

  final orders = const [
    (id: '26', name: 'Ahmad Nizar', status: 'Pending'),
    (id: '27', name: 'Saed Rimawi', status: 'Pending'),
    (id: '30', name: 'Akef Al Asmar', status: 'Preparing'),
    (id: '29', name: 'Nizar Fares', status: 'Delivering'),
    (id: '31', name: 'Sameer Haj', status: 'Delivering'),
    (id: '28', name: 'Eyas Barghouthi', status: 'Delivered'),
    (id: '20', name: 'Sami Jaber', status: 'Rejected'),
  ];

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    final topPadding = height * 0.06;

    return Scaffold(
      body: Row(
        children: [
          const Sidebar(activeIndex: 1),
          Expanded(
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.only(top: topPadding),
                child: Column(
                  children: [
                    // 🔹 العنوان + الأزرار
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: width > 800 ? 60 : 24,
                      ),
                      child: Row(
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
                              _StockToggle(
                                selected: stockTab,
                                onChanged: (i) {
                                  if (i == 1) {
                                    // ⬅️ الانتقال إلى صفحة Stock-in
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                            const StockInPage(),
                                      ),
                                    );
                                  } else {
                                    setState(() => stockTab = i);
                                  }
                                },
                              ),
                              const SizedBox(width: 16),
                              _CreateOrderButton(
                                onPressed: () {
                                  // ➕ الانتقال إلى صفحة Create Stock-Out Order
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const CreateStockOutPage(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 🔹 Tabs
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: width > 800 ? 60 : 24,
                        ),
                        child: Column(
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: _SimpleTabs(
                                tabs: const ['Today', 'Receives', 'Previous'],
                                onTap: (index) {
                                  if (index == 1) {
                                    // 👉 الانتقال إلى صفحة Stock-out Receives
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                            const OrdersReceivesPage(),
                                      ),
                                    );
                                  } else if (index == 2) {
                                    // 👉 الانتقال إلى صفحة Stock-out Previous
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const StockOutPrevious(),
                                      ),
                                    );
                                  }
                                  // index == 0 = Today -> نفس الصفحة، ما نعمل شيء
                                },
                              ),
                            ),
                            const SizedBox(height: 16),

                            // 🔹 البحث + فلتر
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                SizedBox(
                                  width: 250,
                                  child: _SearchField(
                                    hint: 'Customer Name',
                                    onChanged: (v) {},
                                  ),
                                ),
                                const SizedBox(width: 12),
                                _RoundIconButton(
                                  icon: Icons.filter_alt_rounded,
                                  onTap: () {},
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            _TableHeader(isWide: width > 800),
                            const SizedBox(height: 6),

                            // 🔹 الجدول
                            Expanded(
                              child: ListView.separated(
                                itemCount: orders.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 6),
                                itemBuilder: (context, i) {
                                  final row = orders[i];
                                  final bg = i.isEven
                                      ? AppColors.card
                                      : AppColors.cardAlt;
                                  final isHovered = hoveredRow == i;

                                  return MouseRegion(
                                    onEnter: (_) =>
                                        setState(() => hoveredRow = i),
                                    onExit: (_) =>
                                        setState(() => hoveredRow = null),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      decoration: BoxDecoration(
                                        color: bg,
                                        borderRadius: BorderRadius.circular(14),
                                        border: isHovered
                                            ? Border.all(
                                                color: AppColors.blue,
                                                width: 2,
                                              )
                                            : null,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              row.id,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 5,
                                            child: Text(
                                              row.name,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 3,
                                            child: Align(
                                              alignment: Alignment.centerRight,
                                              child: _StatusChip(
                                                status: row.status,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleTabs extends StatefulWidget {
  final List<String> tabs;
  final ValueChanged<int> onTap;
  const _SimpleTabs({required this.tabs, required this.onTap});

  @override
  State<_SimpleTabs> createState() => _SimpleTabsState();
}

class _SimpleTabsState extends State<_SimpleTabs> {
  int current = 0;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(widget.tabs.length, (i) {
        final active = current == i;
        return Padding(
          padding: EdgeInsets.only(right: i == widget.tabs.length - 1 ? 0 : 22),
          child: GestureDetector(
            onTap: () {
              setState(() => current = i);
              widget.onTap(i);
            },
            child: Container(
              padding: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: active ? AppColors.blue : Colors.transparent,
                    width: active ? 3 : 0,
                  ),
                ),
              ),
              child: Text(
                widget.tabs[i],
                style: TextStyle(
                  color: active
                      ? AppColors.white
                      : AppColors.white.withOpacity(0.7),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// 🔹 حقل البحث
class _SearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String>? onChanged;
  const _SearchField({required this.hint, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.group_outlined, size: 18),
        filled: true,
        fillColor: const Color(0xFF2D2D2D),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(
            color: const Color.fromARGB(255, 0, 0, 0),
            width: 1.2,
          ),
        ),
      ),
    );
  }
}

// 🔹 زر الفلتر
class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.card, width: 3),
      ),
      child: Material(
        color: const Color(0xFF2D2D2D),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              size: 20,
              color: AppColors.gold,
            ), // فلتر ذهبي صغير
          ),
        ),
      ),
    );
  }
}

// 🔹 زر Create order + الإشعارات
class _CreateOrderButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _CreateOrderButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 🔹 زر Create order أكبر شوي
        DecoratedBox(
          decoration: const ShapeDecoration(
            shape: StadiumBorder(),
            gradient: LinearGradient(
              colors: [Color(0xFFFFE14D), Color(0xFFFFE14D)],
            ),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onPressed,
              customBorder: const StadiumBorder(),
              child: const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ), // أكبر
                child: Row(
                  children: [
                    Icon(Icons.add_box_rounded, color: Colors.black87),
                    SizedBox(width: 8),
                    Text(
                      'Create order',
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w800,
                        fontSize: 15, // أكبر قليلاً
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),

        // 🔔 زر الإشعارات
        Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: () {},
                customBorder: const CircleBorder(),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(
                    Icons.notifications_none_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppColors.blue,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// 🔹 Stock-in / Stock-out
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
          side: BorderSide(color: AppColors.gold.withOpacity(.5)),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _pill(
            context,
            'Stock-out',
            Icons.logout_rounded,
            selected == 0,
            () => onChanged(0),
          ),
          _pill(
            context,
            'Stock-in',
            Icons.login_rounded,
            selected == 1,
            () => onChanged(1),
          ),
        ],
      ),
    );
  }

  Widget _pill(
    BuildContext ctx,
    String label,
    IconData icon,
    bool selected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: ShapeDecoration(
          color: selected ? AppColors.card : Colors.transparent,
          shape: const StadiumBorder(),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.white),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// 🔹 عنوان الجدول
class _TableHeader extends StatelessWidget {
  final bool isWide;
  const _TableHeader({required this.isWide});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _hCell('Order ID #', flex: 2),
            _hCell('Customer Name', flex: 5),
            _hCell('Status', alignEnd: true, flex: 3),
          ],
        ),
        const SizedBox(height: 8),
        Container(height: 1, color: AppColors.divider.withOpacity(.5)),
      ],
    );
  }

  Expanded _hCell(String text, {int flex = 1, bool alignEnd = false}) {
    return Expanded(
      flex: flex,
      child: Align(
        alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// 🔹 حالة الطلب
class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color text = AppColors.gold;
    Color bg = AppColors.gold.withOpacity(.12);

    if (status == 'Delivered') {
      text = AppColors.delivered;
      bg = AppColors.delivered.withOpacity(.15);
    } else if (status == 'Rejected') {
      text = AppColors.danger;
      bg = AppColors.danger.withOpacity(.15);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: ShapeDecoration(
        color: bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: text,
          fontWeight: FontWeight.w800,
          fontSize: 13,
          letterSpacing: .2,
        ),
      ),
    );
  }
}
