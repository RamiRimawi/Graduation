import 'package:flutter/material.dart';
import '../../supabase_config.dart';
import '../sidebar.dart';
import 'Orders_create_stock_out_page.dart';
import 'Orders_stock_out_page.dart';
import 'Orders_stock_in_page.dart';
import 'Orders_stock_out_previous.dart';
import 'Orders_detail_popup.dart';
import 'orders_header.dart';

class OrderReceiveRow {
  final String id;
  final String customerName;
  final String type;
  final String orderStatus;
  final String createdBy;
  final String time;
  final String date;
  OrderReceiveRow({
    required this.id,
    required this.customerName,
    required this.type,
    required this.orderStatus,
    required this.createdBy,
    required this.time,
    required this.date,
  });
}

class _OrderDetailData {
  final String customerName;
  final String? city;
  final String? address;
  final DateTime orderDate;
  final num? taxPercent;
  final num? totalPrice;
  final num discountValue;
  final String? updateDescription;
  final int orderId;
  final List<Map<String, dynamic>> products;

  _OrderDetailData({
    required this.customerName,
    required this.orderDate,
    required this.products,
    required this.orderId,
    this.discountValue = 0,
    this.updateDescription,
    this.city,
    this.address,
    this.taxPercent,
    this.totalPrice,
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
          .inFilter('order_status', [
            'Received',
            'Updated to Accountant',
            'Hold',
          ])
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
        final type = status == 'Updated to Accountant'
            ? 'out (UPDATE)'
            : status == 'Hold'
            ? 'out'
            : 'out (NEW)';

        final orderRow = OrderReceiveRow(
          id: id,
          customerName: customerName,
          type: type,
          orderStatus: status,
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
    final height = MediaQuery.of(context).size.height;
    final topPadding = height * 0.02;

    return Scaffold(
      body: Row(
        children: [
          const Sidebar(activeIndex: 1),
          Expanded(
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  top: topPadding,
                  left: width > 800 ? 60 : 24,
                  right: width > 800 ? 60 : 24,
                ),
                child: Column(
                  children: [
                    // 🔹 HEADER
                    OrdersHeader(
                      stockTab: stockTab,
                      currentTab: currentTab,
                      onStockTabChanged: (i) {
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
                      onTabChanged: (i) {
                        setState(() => currentTab = i);
                        if (i == 0) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const OrdersPage(),
                            ),
                          );
                        } else if (i == 2) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const StockOutPrevious(),
                            ),
                          );
                        }
                      },
                      onCreateOrder: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CreateStockOutPage(),
                          ),
                        );
                      },
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
                                      child: InkWell(
                                        onTap: () => _openOrderPopup(o),
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
                                      child: InkWell(
                                        onTap: () => _openOrderPopup(o),
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

  Future<void> _openOrderPopup(OrderReceiveRow order) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black26,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final detail = await _fetchOrderDetail(order.id);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      OrderDetailPopup.show(
        context,
        orderType: 'out',
        status: _mapStatus(order.orderStatus),
        products: detail.products,
        partyName: detail.customerName,
        location: _composeLocation(detail.city, detail.address),
        orderDate: detail.orderDate,
        taxPercent: detail.taxPercent,
        totalPrice: detail.totalPrice,
        discountValue: detail.discountValue,
        updateDescription: detail.updateDescription,
        orderId: int.tryParse(order.id) ?? detail.orderId,
      );
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load order details: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<_OrderDetailData> _fetchOrderDetail(String orderId) async {
    final parsedId = int.tryParse(orderId);
    final order = await supabase
        .from('customer_order')
        .select(
          'order_date, tax_percent, total_balance, discount_value, update_description, customer:customer_id(name, address, customer_city:customer_city(name))',
        )
        .eq('customer_order_id', parsedId ?? orderId)
        .maybeSingle();

    if (order == null) {
      throw Exception('Order not found');
    }

    final items = await supabase
        .from('customer_order_description')
        .select(
          'product_id, quantity, updated_quantity, total_price, product:product_id(name, selling_price, brand:brand_id(name), unit:unit_id(unit_name))',
        )
        .eq('customer_order_id', parsedId ?? orderId);

    final products = <Map<String, dynamic>>[];
    for (final item in items) {
      final product = item['product'] as Map<String, dynamic>?;
      final brand = product?['brand'] as Map<String, dynamic>?;
      final unit = product?['unit'] as Map<String, dynamic>?;
      final quantity = (item['quantity'] ?? 0) as num;
      final updatedQuantity = item['updated_quantity'] as num?;
      final total = (item['total_price'] ?? 0) as num;
      final price = (product?['selling_price'] ?? 0) as num;

      // For UPDATE status, use updated_quantity if available, otherwise use original quantity
      final effectiveQuantity = updatedQuantity ?? quantity;

      products.add({
        'id': item['product_id']?.toString() ?? '-',
        'name': product?['name'] ?? 'Unknown',
        'brand': brand?['name'] ?? '-',
        'price': _formatMoney(price),
        'quantity': effectiveQuantity,
        'updated_quantity': updatedQuantity,
        'original_quantity': quantity,
        'total': _formatMoney(price * effectiveQuantity),
        'unit_name': unit?['unit_name'] ?? 'pcs',
      });
    }

    final orderDateRaw = order['order_date']?.toString();
    final orderDate = orderDateRaw != null && orderDateRaw.isNotEmpty
        ? DateTime.parse(orderDateRaw)
        : DateTime.now();

    return _OrderDetailData(
      customerName: (order['customer']?['name'] ?? 'Unknown') as String,
      city: order['customer']?['customer_city']?['name'] as String?,
      address: order['customer']?['address'] as String?,
      orderDate: orderDate,
      taxPercent: order['tax_percent'] as num?,
      totalPrice: order['total_balance'] as num?,
      discountValue: (order['discount_value'] ?? 0) as num,
      updateDescription: order['update_description'] as String?,
      orderId: parsedId ?? int.tryParse(orderId) ?? 0,
      products: products,
    );
  }

  String _mapStatus(String orderStatus) {
    switch (orderStatus) {
      case 'Updated to Accountant':
        return 'UPDATE';
      case 'Hold':
        return 'HOLD';
      default:
        return 'NEW';
    }
  }

  String _composeLocation(String? city, String? address) {
    if ((city == null || city.isEmpty) &&
        (address == null || address.isEmpty)) {
      return '-';
    }
    if (city != null &&
        city.isNotEmpty &&
        address != null &&
        address.isNotEmpty) {
      return '$city - $address';
    }
    return city?.isNotEmpty == true ? city! : address ?? '-';
  }

  String _formatMoney(num value) {
    final asDouble = value.toDouble();
    if (asDouble == 0) return '-';
    return '${asDouble.toStringAsFixed(2)}\$';
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
