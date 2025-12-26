import 'package:flutter/material.dart';
import '../sidebar.dart';
import 'Orders_stock_out_page.dart';
import 'Orders_stock_in_page.dart';
import 'Orders_stock_in_previous.dart';
import 'Orders_create_stock_in_page.dart';
import 'Orders_detail_popup.dart';
import '../../supabase_config.dart';

class OrdersStockInReceivesPage extends StatefulWidget {
  const OrdersStockInReceivesPage({super.key});

  @override
  State<OrdersStockInReceivesPage> createState() =>
      _OrdersStockInReceivesPageState();
}

class _OrdersStockInReceivesPageState extends State<OrdersStockInReceivesPage> {
  int stockTab = 1; // ✅ Stock-in هو المحدد
  int currentTab = 1; // ✅ Receives هو التاب الحالي
  int? hoveredIndex;

  List<Map<String, dynamic>> allOrders = [];
  List<Map<String, dynamic>> filteredOrders = [];
  List<Map<String, dynamic>> onHoldOrders = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadReceivesOrders();
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12
        ? date.hour - 12
        : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}';
  }

  Future<void> _loadReceivesOrders() async {
    setState(() => isLoading = true);

    try {
      // Fetch Sent, Updated, and Hold orders
      final response = await supabase
          .from('supplier_order')
          .select('''
            order_id,
            supplier_id,
            order_date,
            order_status,
            created_by_id,
            accountant_id,
            last_tracing_by,
            supplier:supplier_id (
              name
            )
          ''')
          .or(
            'order_status.eq.Sent,order_status.eq.Updated,order_status.eq.Hold',
          )
          .order('order_date', ascending: false);

      final orders = (response as List).cast<Map<String, dynamic>>();

      // Fetch creator names for all unique created_by_id values
      final Set<int?> creatorIds = orders
          .map((order) => order['created_by_id'] as int?)
          .where((id) => id != null)
          .toSet();

      final Map<int, String> creatorNames = {};
      if (creatorIds.isNotEmpty) {
        // Build OR conditions for each creator ID
        final conditions = creatorIds
            .map((id) => 'storage_manager_id.eq.$id')
            .join(',');
        final managerResponse = await supabase
            .from('storage_manager')
            .select('storage_manager_id, name')
            .or(conditions);

        for (var creator in managerResponse) {
          creatorNames[creator['storage_manager_id']] = creator['name'];
        }

        // Also check accountant table
        final accountantConditions = creatorIds
            .map((id) => 'accountant_id.eq.$id')
            .join(',');
        final accountantResponse = await supabase
            .from('accountant')
            .select('accountant_id, name')
            .or(accountantConditions);

        for (var creator in accountantResponse) {
          creatorNames[creator['accountant_id']] = creator['name'];
        }
      }

      // Add creator names to orders
      for (var order in orders) {
        final creatorId = order['created_by_id'];
        if (creatorId != null && creatorNames.containsKey(creatorId)) {
          order['creator_name'] = creatorNames[creatorId];
        }
      }

      final List<Map<String, dynamic>> regularOrders = [];
      final List<Map<String, dynamic>> holdOrders = [];

      for (var order in orders) {
        final status = order['order_status'];
        // For Hold status, always include in onHoldOrders
        if (status == 'Hold') {
          holdOrders.add(order);
          continue;
        }

        // For Sent orders with accountant_id is null, show as 'in (NEW)'
        // TODO: Add manager ID check when user session is implemented
        if (status == 'Sent' && order['accountant_id'] == null) {
          order['display_status'] = 'in (NEW)';
          regularOrders.add(order);
          continue;
        }

        // For Updated orders, show as 'in (updated)'
        if (status == 'Updated') {
          order['display_status'] = 'in (updated)';
          regularOrders.add(order);
        }
      }

      setState(() {
        allOrders = regularOrders;
        filteredOrders = regularOrders;
        onHoldOrders = holdOrders;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading receives orders: $e');
      setState(() => isLoading = false);
    }
  }

  void _filterOrders(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredOrders = allOrders;
      } else {
        filteredOrders = allOrders.where((order) {
          final supplierName =
              order['supplier']['name']?.toString().toLowerCase() ?? '';
          return supplierName.startsWith(query.toLowerCase());
        }).toList();
      }
    });
  }

  Future<List<Map<String, dynamic>>> _fetchOrderProducts(int orderId) async {
    try {
      final response = await supabase
          .from('supplier_order_description')
          .select('''
            product_id,
            quantity,
            price_per_product,
            product:product_id (
              name,
              brand:brand_id(name),
              unit:unit_id(unit_name)
            )
          ''')
          .eq('order_id', orderId);

      final products = (response as List).cast<Map<String, dynamic>>();

      // Format products for the popup
      return products.map((product) {
        final productData = product['product'] as Map<String, dynamic>? ?? {};
        final brandData = productData['brand'] as Map<String, dynamic>? ?? {};

        return {
          'id': product['product_id'],
          'name': productData['name'] ?? 'Unknown Product',
          'brand': brandData['name'] ?? 'Unknown Brand',
          'price': '${product['price_per_product'] ?? 0}\$',
          'quantity': product['quantity'] ?? 0,
          'total':
              '${((product['price_per_product'] ?? 0) * (product['quantity'] ?? 0)).toStringAsFixed(2)}\$',
        };
      }).toList();
    } catch (e) {
      print('Error fetching order products: $e');
      return [];
    }
  }

  void _showOrderDetails(
    BuildContext context,
    Map<String, dynamic> order,
  ) async {
    final orderId = order['order_id'] as int;
    final status = order['order_status'] as String;

    // Determine order type and status for popup
    String orderType = 'in';
    String popupStatus = 'NEW';

    if (status == 'Updated') {
      popupStatus = 'UPDATE';
    } else if (status == 'Hold') {
      popupStatus = 'HOLD'; // Use HOLD status to avoid Later button
    }

    // Fetch products for this order
    final products = await _fetchOrderProducts(orderId);

    // Check if context is still mounted before showing dialog
    if (!context.mounted) return;

    // Show the popup
    OrderDetailPopup.show(
      context,
      orderType: orderType,
      status: popupStatus,
      products: products,
      partyName: order['supplier']['name'] ?? 'Unknown Supplier',
      orderDate: DateTime.parse(order['order_date']),
      orderId: orderId,
    );
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
                    const SizedBox(height: 40),

                    // 🔹 HEADER
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
                            // 🔁 Stock-out / Stock-in toggle
                            _StockToggle(
                              selected: stockTab,
                              onChanged: (i) {
                                if (i == 0) {
                                  // Stock-out
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

                    // 🔹 Tabs Today / Receives / Previous
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _SimpleTabs(
                        current: currentTab,
                        onTap: (i) {
                          setState(() => currentTab = i);

                          if (i == 0) {
                            // 👉 Today (Stock-in الرئيسية)
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const StockInPage(),
                              ),
                            );
                          } else if (i == 2) {
                            // 👉 Previous
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const StockInPreviousPage(),
                              ),
                            );
                          }
                          // i == 1 = Receives (نفس الصفحة)
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 🔹 Search + Filter
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          width: 230,
                          child: _SearchField(
                            hint: 'Supplier Name',
                            onChanged: _filterOrders,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // 🔹 Table header
                    const _TableHeader(),
                    const SizedBox(height: 8),

                    // 🔹 Lists
                    Expanded(
                      child: isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF50B2E7),
                              ),
                            )
                          : ListView(
                              children: [
                                // main list
                                ...List.generate(filteredOrders.length, (i) {
                                  final order = filteredOrders[i];
                                  final orderId = order['order_id'].toString();
                                  final supplierName =
                                      order['supplier']['name'] ?? 'Unknown';
                                  final status = order['order_status'] ?? '';
                                  final createdBy =
                                      order['creator_name'] ??
                                      order['last_tracing_by'] ??
                                      'System';

                                  final orderDate = DateTime.parse(
                                    order['order_date'],
                                  );
                                  final time = _formatTime(orderDate);
                                  final date = _formatDate(orderDate);

                                  // Determine type based on status
                                  String type = 'in (NEW)';
                                  if (status == 'Updated') {
                                    type = 'in (UPDATE)';
                                  } else if (status == 'Rejected') {
                                    type = 'in (REJECTED)';
                                  } else if (status == 'Accepted') {
                                    type = 'in (ACCEPTED)';
                                  }

                                  final even = int.tryParse(orderId) ?? 0;
                                  final bg = even.isEven
                                      ? const Color(0xFF2D2D2D)
                                      : const Color(0xFF262626);

                                  return MouseRegion(
                                    onEnter: (_) =>
                                        setState(() => hoveredIndex = i),
                                    onExit: (_) =>
                                        setState(() => hoveredIndex = null),
                                    child: InkWell(
                                      onTap: () =>
                                          _showOrderDetails(context, order),
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
                                                orderId,
                                                style: _cellStyle(),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 3,
                                              child: Text(
                                                supplierName,
                                                style: _cellStyle(),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                type,
                                                style: _cellStyle(),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                createdBy,
                                                style: _cellStyle(),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                time,
                                                style: _cellStyle(),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Align(
                                                alignment:
                                                    Alignment.centerRight,
                                                child: Text(
                                                  date,
                                                  style: _cellStyle(),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }),

                                if (onHoldOrders.isNotEmpty) ...[
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

                                  // on hold list
                                  ...List.generate(onHoldOrders.length, (i) {
                                    final order = onHoldOrders[i];
                                    final orderId = order['order_id']
                                        .toString();
                                    final supplierName =
                                        order['supplier']['name'] ?? 'Unknown';
                                    final createdBy =
                                        order['creator_name'] ??
                                        order['last_tracing_by'] ??
                                        'System';

                                    final orderDate = DateTime.parse(
                                      order['order_date'],
                                    );
                                    final time = _formatTime(orderDate);
                                    final date = _formatDate(orderDate);

                                    final even = int.tryParse(orderId) ?? 0;
                                    final bg = even.isEven
                                        ? const Color(0xFF2D2D2D)
                                        : const Color(0xFF262626);

                                    return MouseRegion(
                                      onEnter: (_) => setState(
                                        () => hoveredIndex = i + 1000,
                                      ),
                                      onExit: (_) =>
                                          setState(() => hoveredIndex = null),
                                      child: InkWell(
                                        onTap: () =>
                                            _showOrderDetails(context, order),
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
                                              color: hoveredIndex == i + 1000
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
                                                  orderId,
                                                  style: _cellStyle(),
                                                ),
                                              ),
                                              Expanded(
                                                flex: 3,
                                                child: Text(
                                                  supplierName,
                                                  style: _cellStyle(),
                                                ),
                                              ),
                                              Expanded(
                                                flex: 2,
                                                child: Text(
                                                  'in (HOLD)',
                                                  style: _cellStyle(),
                                                ),
                                              ),
                                              Expanded(
                                                flex: 2,
                                                child: Text(
                                                  createdBy,
                                                  style: _cellStyle(),
                                                ),
                                              ),
                                              Expanded(
                                                flex: 2,
                                                child: Text(
                                                  time,
                                                  style: _cellStyle(),
                                                ),
                                              ),
                                              Expanded(
                                                flex: 2,
                                                child: Align(
                                                  alignment:
                                                      Alignment.centerRight,
                                                  child: Text(
                                                    date,
                                                    style: _cellStyle(),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
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

/// ---------------- Tabs ----------------
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

/// ---------------- Table header ----------------
class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: const [
            _HeaderCell(text: 'Order ID #', flex: 2),
            _HeaderCell(text: 'Supplier Name', flex: 3),
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

/// ---------------- Search / Filter / Toggle / Button ----------------
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
