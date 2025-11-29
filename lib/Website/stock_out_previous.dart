import 'package:flutter/material.dart';
import 'sidebar.dart';
import 'stock_in_page.dart';
import 'stock_out_page.dart'; // عشان نرجع لصفحة Today
import 'stock_out_receives.dart'; // عشان نروح لصفحة Receives
import 'create_stock_out_page.dart';

// 🎨 الألوان نفس الباليت
class AppColors {
  static const white = Color(0xFFFFFFFF);
  static const gold = Color(0xFFB7A447);
  static const bgDark = Color(0xFF202020);
  static const card = Color(0xFF2D2D2D);
  static const cardAlt = Color(0xFF262626);
  static const divider = Color(0xFF6F6F6F);
  static const blue = Color(0xFF50B2E7);
}

class StockOutPrevious extends StatefulWidget {
  const StockOutPrevious({super.key});

  @override
  State<StockOutPrevious> createState() => _StockOutPreviousState();
}

class _StockOutPreviousState extends State<StockOutPrevious> {
  int stockTab = 0; // Stock-out selected
  int currentTab = 2; // Previous tab selected
  int? hoveredRow;

  final previousOrders = const [
    (id: '26', name: 'Ahmad Nizar', inventory: '1', date: '12/5/2020'),
    (id: '27', name: 'Saed Rimawi', inventory: '2', date: '12/5/2023'),
    (id: '30', name: 'Akef Al Asmar', inventory: '1', date: '12/5/2022'),
    (id: '29', name: 'Nizar Fares', inventory: '1', date: '12/5/2025'),
    (id: '31', name: 'Sameer Haj', inventory: '1', date: '12/5/2021'),
    (id: '28', name: 'Eyas Barghouthi', inventory: '2', date: '12/5/2025'),
    (id: '20', name: 'Sami jaber', inventory: '2', date: '12/5/2020'),
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
                    // 🔹 العنوان + التوغّل + Create order + Notifications
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
                                    // الانتقال إلى Stock-in
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
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const CreateStockOutPage(),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 12),
                              // 🔔 زر الإشعارات
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Material(
                                    color: Colors.transparent,
                                    shape: const CircleBorder(),
                                    child: InkWell(
                                      onTap: () {
                                        // هنا ممكن تفتح صفحة الإشعارات لو حاب
                                      },
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
                            // Tabs: Today / Receives / Previous
                            Align(
                              alignment: Alignment.centerLeft,
                              child: _TopTabs(
                                current: currentTab,
                                onTap: (index) {
                                  setState(() => currentTab = index);
                                  if (index == 0) {
                                    // Today
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const OrdersPage(),
                                      ),
                                    );
                                  } else if (index == 1) {
                                    // Receives
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                            const OrdersReceivesPage(),
                                      ),
                                    );
                                  }
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
                                itemCount: previousOrders.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 6),
                                itemBuilder: (context, i) {
                                  final row = previousOrders[i];
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
                                          // Order ID
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

                                          // Customer Name
                                          Expanded(
                                            flex: 4,
                                            child: Text(
                                              row.name,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),

                                          // Inventory #
                                          Expanded(
                                            flex: 8,
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                row.inventory,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ),

                                          // Date (ذهبي)
                                          Expanded(
                                            flex: 4,
                                            child: Align(
                                              alignment: Alignment.centerRight,
                                              child: Text(
                                                row.date,
                                                style: const TextStyle(
                                                  color: AppColors.gold,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                ),
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

/// تبويبات Today / Receives / Previous بنفس ستايل الصورة
class _TopTabs extends StatelessWidget {
  final int current;
  final ValueChanged<int> onTap;
  const _TopTabs({required this.current, required this.onTap});

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
                    color: AppColors.white.withOpacity(active ? 1 : .7),
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  height: 3,
                  width: active ? _textWidth(tabs[i], context) : 0,
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
      textDirection: TextDirection.ltr,
    )..layout();
    return textPainter.width;
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
        fillColor: AppColors.card,
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
          borderSide: const BorderSide(color: Colors.black, width: 1.2),
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

// 🔹 زر Create order (نفس الستايل)
class _CreateOrderButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _CreateOrderButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
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
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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

// 🔹 Stock-in / Stock-out toggle (نفس التصميم)
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

// 🔹 هيدر الجدول (Order ID / Customer / Inventory / Date)
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
            _hCell('Customer Name', flex: 4),
            _hCell('Inventory #', flex: 8),
            _hCell('Date', flex: 4, alignEnd: true),
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
