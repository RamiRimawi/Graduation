import 'package:flutter/material.dart';
import '../supabase_config.dart';
import 'sidebar.dart';
import 'create_stock_out_page.dart';
import 'stock_out_page.dart';
import 'stock_in_page.dart';
import 'stock_out_previous.dart';

class OrderReceiveRow {
  final String id;
  final String customerName;
  final String type;
  final String createdBy;
  final String time;
  final String date;
  OrderReceiveRow({
    required this.id,
    required this.customerName,
    required this.type,
    required this.createdBy,
    required this.time,
    required this.date,
  });
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
  bool _loading = true;
  String? _error;
  List<OrderReceiveRow> _orders = [];
  List<OrderReceiveRow> _onHold = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    try {
      // Fetch only orders with Received, Updated, or Hold status
      final data = await supabase
          .from('customer_order')
          .select(
            'customer_order_id, order_status, order_date, last_action_by, customer:customer_id(name)',
          )
          .inFilter('order_status', ['Received', 'Updated', 'Hold'])
          .order('customer_order_id', ascending: false);

      final ordersList = <OrderReceiveRow>[];
      final onHoldList = <OrderReceiveRow>[];

      for (final row in data) {
        final id = (row['customer_order_id'] ?? '').toString();
        final status = (row['order_status'] ?? '').toString();

        final customerName = (row['customer'] is Map)
            ? (row['customer']['name'] ?? 'Unknown')
            : 'Unknown';
        final createdBy = (row['last_action_by'] ?? 'System') as String;

        final orderDate = row['order_date'] != null
            ? DateTime.parse(row['order_date'])
            : DateTime.now();
        final time =
            '${orderDate.hour}:${orderDate.minute.toString().padLeft(2, '0')}';
        final date = '${orderDate.day}/${orderDate.month}';

        // Type: "out (UPDATE)" for Updated, "out (NEW)" for Received, "out" for Hold
        final type = status == 'Updated'
            ? 'out (UPDATE)'
            : status == 'Hold'
            ? 'out'
            : 'out (NEW)';

        final orderRow = OrderReceiveRow(
          id: id,
          customerName: customerName,
          type: type,
          createdBy: createdBy,
          time: time,
          date: date,
        );

        // Separate orders: Hold goes to "On Hold" section, others to main list
        if (status == 'Hold') {
          onHoldList.add(orderRow);
        } else {
          ordersList.add(orderRow);
        }
      }

      setState(() {
        _orders = ordersList;
        _onHold = onHoldList;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<OrderReceiveRow> get _filteredOrders {
    if (_searchQuery.isEmpty) return _orders;
    final q = _searchQuery.toLowerCase();
    return _orders
        .where((o) => o.customerName.toLowerCase().startsWith(q))
        .toList(growable: false);
  }

  List<OrderReceiveRow> get _filteredOnHold {
    if (_searchQuery.isEmpty) return _onHold;
    final q = _searchQuery.toLowerCase();
    return _onHold
        .where((o) => o.customerName.toLowerCase().startsWith(q))
        .toList(growable: false);
  }

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
                                      builder: (_) => const StockInPage(),
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
                                builder: (_) => const OrdersPage(),
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
                            onChanged: (v) {
                              setState(() {
                                _searchQuery = v.trim();
                              });
                            },
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
                      child: _loading
                          ? const Center(child: CircularProgressIndicator())
                          : _error != null
                          ? Center(
                              child: Text(
                                _error!,
                                style: const TextStyle(color: Colors.redAccent),
                              ),
                            )
                          : ListView(
                              children: [
                                if (_filteredOrders.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.all(40.0),
                                    child: Center(
                                      child: Text(
                                        'No Received orders found',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  ...List.generate(_filteredOrders.length, (i) {
                                    final o = _filteredOrders[i];
                                    final even = int.tryParse(o.id) ?? 0;
                                    final bg = even.isEven
                                        ? const Color(0xFF2D2D2D)
                                        : const Color(0xFF262626);

                                    return MouseRegion(
                                      onEnter: (_) =>
                                          setState(() => hoveredIndex = i),
                                      onExit: (_) =>
                                          setState(() => hoveredIndex = null),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        margin: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 14,
                                        ),
                                        decoration: BoxDecoration(
                                          color: bg,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
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
                                              child: Text(
                                                o.id,
                                                style: _cellStyle(),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 3,
                                              child: Text(
                                                o.customerName,
                                                style: _cellStyle(),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                o.type,
                                                style: _cellStyle(),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                o.createdBy,
                                                style: _cellStyle(),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                o.time,
                                                style: _cellStyle(),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Align(
                                                alignment:
                                                    Alignment.centerRight,
                                                child: Text(
                                                  o.date,
                                                  style: _cellStyle(),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                if (_filteredOnHold.isNotEmpty) ...[
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
                                  ...List.generate(_filteredOnHold.length, (i) {
                                    final o = _filteredOnHold[i];
                                    final even = int.tryParse(o.id) ?? 0;
                                    final bg = even.isEven
                                        ? const Color(0xFF2D2D2D)
                                        : const Color(0xFF262626);

                                    return MouseRegion(
                                      onEnter: (_) => setState(
                                        () => hoveredIndex = i + 100,
                                      ),
                                      onExit: (_) =>
                                          setState(() => hoveredIndex = null),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        margin: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 14,
                                        ),
                                        decoration: BoxDecoration(
                                          color: bg,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
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
                                              child: Text(
                                                o.id,
                                                style: _cellStyle(),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 3,
                                              child: Text(
                                                o.customerName,
                                                style: _cellStyle(),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                o.type,
                                                style: _cellStyle(),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                o.createdBy,
                                                style: _cellStyle(),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                o.time,
                                                style: _cellStyle(),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Align(
                                                alignment:
                                                    Alignment.centerRight,
                                                child: Text(
                                                  o.date,
                                                  style: _cellStyle(),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                ],
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
