import 'package:flutter/material.dart';
import 'sidebar.dart';
import 'create_stock_in_page.dart';
import 'stock_out_page.dart';
import 'stock_in_previous.dart';
import 'stock_in_receives.dart';

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

class StockInPage extends StatefulWidget {
  const StockInPage({super.key});

  @override
  State<StockInPage> createState() => _StockInPageState();
}

class _StockInPageState extends State<StockInPage> {
  int stockTab = 1;
  int? hoveredRow;

  final orders = const [
    (id: '101', name: 'Ahmad Nizar', status: 'Pending'),
    (id: '102', name: 'Saed Rimawi', status: 'Accepted'),
    (id: '103', name: 'Akef Al Asmar', status: 'Accepted'),
    (id: '104', name: 'Nizar Fares', status: 'Delivered'),
    (id: '105', name: 'Sameer Haj', status: 'Rejected'),
    (id: '106', name: 'Eyas Barghouthi', status: 'Pending'),
    (id: '107', name: 'Sami Jaber', status: 'Accepted'),
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
                    // 🔹 العنوان والأزرار
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
                                  if (i == 0) {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const OrdersPage(),
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
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const CreateStockInPage(),
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

                    // 🔹 Tabs + Table
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
                                  if (index == 0) {
                                    // Today
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                            const StockInPage(),
                                      ),
                                    );
                                  } else if (index == 1) {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                            const OrdersStockInReceivesPage(),
                                      ),
                                    );
                                  } else if (index == 2) {
                                    // Previous
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const StockInPreviousPage(),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                            const SizedBox(height: 16),

                            // 🔹 البحث والفلتر
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 250,
                                  child: _SearchField(
                                    hint: 'Supplier Name',
                                    onChanged: (v) {},
                                  ),
                                ),
                                const SizedBox(width: 10),
                                _RoundIconButton(
                                  icon: Icons.filter_alt_rounded,
                                  onTap: () {},
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            _TableHeader(isWide: width > 800),
                            const SizedBox(height: 6),

                            // 🔹 القائمة
                            Expanded(
                              child: ListView.separated(
                                itemCount: orders.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 10),
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
                                      height: 64,
                                      decoration: BoxDecoration(
                                        color: bg,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: isHovered
                                              ? AppColors.blue
                                              : Colors.transparent,
                                          width: 1.5,
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            flex: 2,
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                row.id,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 5,
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                row.name,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
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

// 🔹 الأزرار والتفاصيل الثانوية نفسها كما هي من كودك السابق 🔹
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
        color: AppColors.card,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 20, color: AppColors.gold),
          ),
        ),
      ),
    );
  }
}

// 🔹 Create order button
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

// 🔹 تبويبات
// 🔹 التبويبات
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
          child: InkWell(
            onTap: () {
              setState(() => current = i);
              widget.onTap(i);
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  widget.tabs[i],
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white.withOpacity(active ? 1 : .7),
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 3,
                  width: active
                      ? _textWidth(widget.tabs[i], context)
                      : 0, // ✅ نفس عرض الكلمة
                  decoration: BoxDecoration(
                    color: active ? AppColors.blue : Colors.transparent,
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
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    return textPainter.width + 2; // خليه نفس عرض الكلمة تمامًا
  }
}

// 🔹 البحث
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
          borderSide: BorderSide(color: AppColors.blue, width: 2.3),
        ),
      ),
    );
  }
}

// 🔹 Stock-in / Stock-out toggle
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
            _hCell('Supplier Name', flex: 5),
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

// 🔹 صف الطلب
// ignore: unused_element
class _OrderRow extends StatelessWidget {
  final String id;
  final String name;
  final String status;
  final Color background;

  const _OrderRow({
    required this.id,
    required this.name,
    required this.status,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ShapeDecoration(
        color: background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              id,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerRight,
              child: _StatusChip(status: status),
            ),
          ),
        ],
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
    } else if (status == 'Accepted') {
      text = Colors.greenAccent.shade400;
      bg = Colors.greenAccent.shade400.withOpacity(.15);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: ShapeDecoration(
        color: bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: text,
          fontWeight: FontWeight.w800,
          letterSpacing: .2,
        ),
      ),
    );
  }
}
