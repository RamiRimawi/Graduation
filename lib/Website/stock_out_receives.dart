import 'package:flutter/material.dart';
import 'sidebar.dart';
import 'create_stock_out_page.dart';
import 'stock_out_page.dart';
import 'stock_in_page.dart';
import 'stock_out_previous.dart';

void main() {
  runApp(const StockOutReceivesPage());
}

class StockOutReceivesPage extends StatelessWidget {
  const StockOutReceivesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dolphin Orders Receives',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF202020),
        fontFamily: 'Roboto',
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFB7A447),
          surface: Color(0xFF2D2D2D),
          secondary: Color(0xFF50B2E7),
        ),
      ),
      home: const OrdersReceivesPage(),
    );
  }
}

class OrdersReceivesPage extends StatefulWidget {
  const OrdersReceivesPage({super.key});

  @override
  State<OrdersReceivesPage> createState() => _OrdersReceivesPageState();
}

class _OrdersReceivesPageState extends State<OrdersReceivesPage> {
  int stockTab = 0;
  int currentTab = 1; // Receives selected
  int? hoveredIndex; // ✅ لتتبع الصف الذي عليه الماوس

  final orders = const [
    ('26', 'Ahmad Nizar', 'out (NEW)', 'Sender', '12:30 AM', '14/8'),
    ('27', 'Saed Rimawi', 'out (NEW)', 'Sender', '10:43 AM', '14/8'),
    ('30', 'Akef Al Asmar', 'in (NEW)', 'Sender', '9:30 AM', '14/8'),
    ('29', 'Nizar Fares', 'out (UPDATE)', 'Ayman Rimawi', '8:43 AM', '14/8'),
    ('31', 'Sameer Haj', 'in (NEW)', 'Sender', '2:30 PM', '13/8'),
    (
      '28',
      'Eyas Barghouthi',
      'out (UPDATE)',
      'Ayman Rimawi',
      '8:43 AM',
      '14/8',
    ),
    ('20', 'Sami jaber', 'out (NEW)', 'Sender', '2:30 PM', '13/8'),
  ];

  final onHold = const [
    ('20', 'Sami jaber', 'in (NEW)', 'Sender', '10:43 AM', '14/8'),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Row(
        children: [
          const Sidebar(activeIndex: 1),
          Expanded(
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: width > 800 ? 60 : 24,
                ),
                child: Column(
                  children: [
                    // 🔹 HEADER
                    const SizedBox(height: 40),
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
                            _StockToggle(
                              selected: stockTab,
                              onChanged: (i) {
                                if (i == 1) {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const OrdersStockInPage(),
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
                                    builder: (_) => const CreateStockOutPage(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 10),
                            const Icon(
                              Icons.notifications_none_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // 🔹 Tabs
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _SimpleTabs(
                        current: currentTab,
                        onTap: (i) {
                          setState(() => currentTab = i);
                          if (i == 0) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const StockOutPage(),
                              ),
                            );
                          } else {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const StockOutPrevious(),
                              ),
                            );
                          }
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 🔹 Search & Filter
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          width: 230,
                          child: _SearchField(
                            hint: 'Customer Name',
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

                    // 🔹 Table header
                    _TableHeader(),
                    const SizedBox(height: 8),

                    // 🔹 Orders list
                    Expanded(
                      child: ListView(
                        children: [
                          ...List.generate(orders.length, (i) {
                            final o = orders[i];
                            final even = int.tryParse(o.$1) ?? 0;
                            final bg = even.isEven
                                ? const Color(0xFF2D2D2D)
                                : const Color(0xFF262626);

                            // ✅ Hover effect فقط
                            return MouseRegion(
                              onEnter: (_) => setState(() => hoveredIndex = i),
                              onExit: (_) =>
                                  setState(() => hoveredIndex = null),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: bg,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: hoveredIndex == i
                                        ? const Color(0xFF50B2E7)
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Text(o.$1, style: _cellStyle()),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(o.$2, style: _cellStyle()),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(o.$3, style: _cellStyle()),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(o.$4, style: _cellStyle()),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(o.$5, style: _cellStyle()),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: Text(o.$6, style: _cellStyle()),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 20),
                          const Text(
                            'On Hold',
                            style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...List.generate(onHold.length, (i) {
                            final o = onHold[i];
                            final even = int.tryParse(o.$1) ?? 0;
                            final bg = even.isEven
                                ? const Color(0xFF2D2D2D)
                                : const Color(0xFF262626);

                            return MouseRegion(
                              onEnter: (_) =>
                                  setState(() => hoveredIndex = i + 100),
                              onExit: (_) =>
                                  setState(() => hoveredIndex = null),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: bg,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: hoveredIndex == i + 100
                                        ? const Color(0xFF50B2E7)
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Text(o.$1, style: _cellStyle()),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(o.$2, style: _cellStyle()),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(o.$3, style: _cellStyle()),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(o.$4, style: _cellStyle()),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(o.$5, style: _cellStyle()),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: Text(o.$6, style: _cellStyle()),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
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

  TextStyle _cellStyle() =>
      const TextStyle(color: Colors.white, fontWeight: FontWeight.w600);
}

// 🔹 Tabs
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
                  width: active
                      ? _textWidth(tabs[i], context)
                      : 0, // ✅ بطول الكلمة
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

// 🔹 Table Header
class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: const [
            _HeaderCell(text: 'Order ID #', flex: 2),
            _HeaderCell(text: 'Customer Name', flex: 3),
            _HeaderCell(text: 'Type', flex: 2),
            _HeaderCell(text: 'Created by', flex: 2),
            _HeaderCell(text: 'Time', flex: 2),
            _HeaderCell(text: 'Date', flex: 2, alignEnd: true),
          ],
        ),
        const SizedBox(height: 6),
        Container(height: 1, color: Colors.white24),
      ],
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final int flex;
  final bool alignEnd;
  const _HeaderCell({required this.text, this.flex = 1, this.alignEnd = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Align(
        alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

// 🔹 Search Field
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
          borderSide: const BorderSide(color: Color(0xFFB7A447), width: 1.2),
        ),
      ),
    );
  }
}

// 🔹 Filter Button
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
        border: Border.all(color: const Color(0xFF2D2D2D), width: 3),
      ),
      child: Material(
        color: const Color(0xFF2D2D2D),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 20, color: const Color(0xFFB7A447)),
          ),
        ),
      ),
    );
  }
}

// 🔹 Stock Toggle
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

// 🔹 Create Order Button
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
