import 'package:flutter/material.dart';
import '../../supabase_config.dart';
import '../sidebar.dart';
import 'Orders_create_stock_out_page.dart';
import 'Orders_stock_in_page.dart';
import 'Orders_stock_out_receives.dart';
import 'Orders_stock_out_previous.dart';
import 'Orders_detail_popup.dart';
import 'orders_header.dart';

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
  final List<String>? initialFilterStatuses;
  const OrdersPage({super.key, this.initialFilterStatuses});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class OrderRow {
  final String id;
  final String name;
  final String status;
  final String orderStatus;
  OrderRow({
    required this.id,
    required this.name,
    required this.status,
    required this.orderStatus,
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
  final Map<String, dynamic>? manager;
  final Map<String, dynamic>? storageStaff;
  final Map<String, dynamic>? deliveryDriver;

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
    this.manager,
    this.storageStaff,
    this.deliveryDriver,
  });
}

/* ----------------------- FILTER POPUP ----------------------- */

class _OrdersPageState extends State<OrdersPage> {
  static const Color _filterGold = Color(0xFFF9D949);
  int stockTab = 0;
  int? hoveredRow;
  bool _loading = true;
  String? _error;
  List<OrderRow> _orders = [];
  String _searchQuery = '';
  Set<String> _selectedStatuses = {};
  final GlobalKey _filterButtonKey = GlobalKey();
  OverlayEntry? _filterOverlay;

  List<OrderRow> get _filteredOrders {
    Iterable<OrderRow> filtered = _orders;

    if (_selectedStatuses.isNotEmpty) {
      filtered = filtered.where((o) => _selectedStatuses.contains(o.status));
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((o) => o.name.toLowerCase().startsWith(q));
    }

    return filtered.toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    // Apply initial filters if provided
    if (widget.initialFilterStatuses != null) {
      _selectedStatuses.addAll(widget.initialFilterStatuses!);
    }
    _fetchOrders();
  }

  @override
  void dispose() {
    _filterOverlay?.remove();
    _filterOverlay = null;
    super.dispose();
  }

  Future<void> _fetchOrders() async {
    try {
      // Get today's date in YYYY-MM-DD format
      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // Fetch orders with status and delivered_date
      final data = await supabase
          .from('customer_order')
          .select('''
            customer_order_id,
            order_status,
            customer:customer_id(name),
            customer_order_description(delivered_date)
            ''')
          .order('customer_order_id', ascending: false);

      final list = <OrderRow>[];
      for (final row in data) {
        final id = (row['customer_order_id'] ?? '').toString();
        final status = (row['order_status'] ?? '').toString();

        // Get the latest delivered_date from order descriptions
        final descriptions = row['customer_order_description'] as List?;
        String deliveredDate = '';
        if (descriptions != null && descriptions.isNotEmpty) {
          DateTime? latestDate;
          for (final desc in descriptions) {
            final dateStr = desc['delivered_date'] as String?;
            if (dateStr != null) {
              final date = DateTime.parse(dateStr);
              if (latestDate == null || date.isAfter(latestDate)) {
                latestDate = date;
              }
            }
          }
          if (latestDate != null) {
            deliveredDate = latestDate.toIso8601String().split(
              'T',
            )[0]; // YYYY-MM-DD format
          }
        }

        // Filter: Show only specific statuses
        bool shouldShow = false;

        if (status == 'Received' ||
            status == 'Pinned' ||
            status == 'Prepared' ||
            status == 'Preparing' || // <-- Added this line
            status == 'Delivery' ||
            status == 'Updated to Accountant') {
          shouldShow = true;
        } else if (status == 'Delivered') {
          // Only show Delivered if delivered_date is today
          if (deliveredDate.isNotEmpty && deliveredDate.startsWith(todayStr)) {
            shouldShow = true;
          }
        }

        if (!shouldShow) {
          continue;
        }

        final customer = (row['customer'] is Map)
            ? (row['customer']['name'] ?? '')
            : '';

        // Convert "Pinned" to "Sended to manager" for display
        final displayStatus = status == 'Pinned' ? 'Sended to manager' : status;

        list.add(
          OrderRow(
            id: id,
            name: customer,
            status: displayStatus,
            orderStatus: status,
          ),
        );
      }

      setState(() {
        _orders = list;
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

  /* ----------------------- FILTER POPUP ----------------------- */

  void _toggleFilterPopup() {
    if (_filterOverlay != null) {
      _closeFilterPopup();
    } else {
      _showFilterPopup();
    }
  }

  void _showFilterPopup() {
    final renderBox =
        _filterButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _filterOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeFilterPopup,
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            left: offset.dx - 220 + size.width,
            top: offset.dy + size.height + 8,
            child: Material(
              color: Colors.transparent,
              child: StatefulBuilder(
                builder: (context, setOverlayState) => GestureDetector(
                  onTap: () {},
                  child: Container(
                    width: 220,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D2D2D),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black54,
                          offset: Offset(0, 4),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 8),
                          child: const Text(
                            'Filter by status',
                            style: TextStyle(
                              color: _filterGold,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Divider(color: Color(0xFF3D3D3D), height: 1),
                        const SizedBox(height: 8),
                        ..._buildStatusCheckboxes(setOverlayState),
                        const SizedBox(height: 8),
                        const Divider(color: Color(0xFF3D3D3D), height: 1),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() => _selectedStatuses.clear());
                                setOverlayState(() {});
                              },
                              child: const Text(
                                'Clear All',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_filterOverlay!);
  }

  List<Widget> _buildStatusCheckboxes(StateSetter setOverlayState) {
    const statuses = [
      'Received',
      'Sended to manager',
      'Preparing',
      'Prepared',
      'Delivery',
      'Updated',
      'Delivered',
    ];

    return statuses.map((status) {
      final isSelected = _selectedStatuses.contains(status);
      return InkWell(
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedStatuses.remove(status);
            } else {
              _selectedStatuses.add(status);
            }
          });
          setOverlayState(() {});
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Row(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: isSelected ? _filterGold : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? _filterGold : Colors.white54,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: isSelected
                    ? const Center(
                        child: Icon(Icons.check, size: 14, color: Colors.black),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  status,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontSize: 13,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  void _closeFilterPopup() {
    _filterOverlay?.remove();
    _filterOverlay = null;
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    final topPadding = height * 0.02;

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
                    // 🔹 HEADER
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: width > 800 ? 60 : 24,
                      ),
                      child: OrdersHeader(
                        stockTab: stockTab,
                        currentTab: 0, // Today tab
                        onStockTabChanged: (i) {
                          if (i == 1) {
                            // ⬅️ الانتقال إلى صفحة Stock-in
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
                        onTabChanged: (index) {
                          if (index == 1) {
                            // 👉 الانتقال إلى صفحة Stock-out Receives
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const OrdersReceivesPage(),
                              ),
                            );
                          } else if (index == 2) {
                            // 👉 الانتقال إلى صفحة Stock-out Previous
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const StockOutPrevious(),
                              ),
                            );
                          }
                          // index == 0 = Today -> نفس الصفحة، ما نعمل شيء
                        },
                        onCreateOrder: () {
                          // ➕ الانتقال إلى صفحة Create Stock-Out Order
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CreateStockOutPage(),
                            ),
                          );
                        },
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
                            // 🔹 البحث + فلتر
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                SizedBox(
                                  width: 250,
                                  child: _SearchField(
                                    hint: 'Customer Name',
                                    onChanged: (v) {
                                      setState(() {
                                        _searchQuery = v.trim();
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  key: _filterButtonKey,
                                  child: _RoundIconButton(
                                    icon: Icons.filter_alt_rounded,
                                    onTap: _toggleFilterPopup,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            _TableHeader(isWide: width > 800),
                            const SizedBox(height: 6),

                            // 🔹 الجدول
                            Expanded(
                              child: _loading
                                  ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  : _error != null
                                  ? Center(
                                      child: Text(
                                        _error!,
                                        style: const TextStyle(
                                          color: Colors.redAccent,
                                        ),
                                      ),
                                    )
                                  : ListView.separated(
                                      itemCount: _filteredOrders.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(height: 6),
                                      itemBuilder: (context, i) {
                                        final row = _filteredOrders[i];
                                        final bg = i.isEven
                                            ? AppColors.card
                                            : AppColors.cardAlt;
                                        final isHovered = hoveredRow == i;
                                        return MouseRegion(
                                          onEnter: (_) =>
                                              setState(() => hoveredRow = i),
                                          onExit: (_) =>
                                              setState(() => hoveredRow = null),
                                          child: InkWell(
                                            onTap: () async {
                                              // Open editable popup for Received/Updated, read-only for others
                                              if (row.orderStatus ==
                                                      'Received' ||
                                                  row.orderStatus ==
                                                      'Updated to Accountant') {
                                                _openOrderPopup(row);
                                              } else {
                                                // Fetch order details as in _openOrderPopup
                                                showDialog(
                                                  context: context,
                                                  barrierDismissible: false,
                                                  barrierColor: Colors.black26,
                                                  builder: (_) => const Center(
                                                    child:
                                                        CircularProgressIndicator(),
                                                  ),
                                                );
                                                try {
                                                  final detail =
                                                      await _fetchOrderDetail(
                                                        row.id,
                                                      );
                                                  if (!mounted) return;
                                                  Navigator.of(
                                                    context,
                                                    rootNavigator: true,
                                                  ).pop();
                                                  ReadOnlyOrderDetailPopup.show(
                                                    context,
                                                    orderType: 'out',
                                                    status: row.status,
                                                    products: detail.products,
                                                    partyName:
                                                        detail.customerName,
                                                    location: _composeLocation(
                                                      detail.city,
                                                      detail.address,
                                                    ),
                                                    orderDate: detail.orderDate,
                                                    taxPercent:
                                                        detail.taxPercent,
                                                    totalPrice:
                                                        detail.totalPrice,
                                                    orderId:
                                                        int.tryParse(row.id) ??
                                                        detail.orderId,
                                                    manager: detail.manager,
                                                    storageStaff:
                                                        detail.storageStaff,
                                                    deliveryDriver:
                                                        detail.deliveryDriver,
                                                  );
                                                } catch (e) {
                                                  if (mounted) {
                                                    Navigator.of(
                                                      context,
                                                      rootNavigator: true,
                                                    ).pop();
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          'Failed to load order details: $e',
                                                        ),
                                                        behavior:
                                                            SnackBarBehavior
                                                                .floating,
                                                      ),
                                                    );
                                                  }
                                                }
                                              }
                                            },
                                            child: AnimatedContainer(
                                              duration: const Duration(
                                                milliseconds: 200,
                                              ),
                                              decoration: BoxDecoration(
                                                color: bg,
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                                border: isHovered
                                                    ? Border.all(
                                                        color: AppColors.blue,
                                                        width: 2,
                                                      )
                                                    : null,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
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
                                                        fontWeight:
                                                            FontWeight.w800,
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 5,
                                                    child: Text(
                                                      row.name,
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 3,
                                                    child: Align(
                                                      alignment:
                                                          Alignment.centerRight,
                                                      child: _StatusChip(
                                                        status: row.status,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
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

  Future<void> _openOrderPopup(OrderRow order) async {
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
        onOrderUpdated: _fetchOrders,
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
        .select('''
          order_date,
          tax_percent,
          total_balance,
          discount_value,
          managed_by_id,
          prepared_by_id,
          delivered_by_id,
          update_description,
          customer:customer_id(name, address, customer_city:customer_city(name)),
          manager:managed_by_id(name),
          storage_staff:prepared_by_id(name),
          delivery_driver:delivered_by_id(name)
          ''')
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
      manager:
          order['manager'] != null && order['manager'] is Map<String, dynamic>
          ? order['manager']
          : null,
      storageStaff:
          order['storage_staff'] != null &&
              order['storage_staff'] is Map<String, dynamic>
          ? order['storage_staff']
          : null,
      deliveryDriver:
          order['delivery_driver'] != null &&
              order['delivery_driver'] is Map<String, dynamic>
          ? order['delivery_driver']
          : null,
    );
  }

  String _mapStatus(String orderStatus) {
    switch (orderStatus) {
      case 'Updated to Accountant':
        return 'UPDATE';
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
          borderSide: BorderSide(color: Color(0xFFB7A447), width: 1.2),
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
