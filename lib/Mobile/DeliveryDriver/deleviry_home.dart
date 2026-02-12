import 'package:flutter/material.dart';
import 'delivery_order_details.dart';
import '../../supabase_config.dart';

class HomeDeleviry extends StatefulWidget {
  final int deliveryDriverId;

  const HomeDeleviry({super.key, required this.deliveryDriverId});

  @override
  State<HomeDeleviry> createState() => _HomeDeleviryState();
}

class _HomeDeleviryState extends State<HomeDeleviry> {

  List<Map<String, dynamic>> customers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCustomersGrouped();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh when returning to this screen
    _fetchCustomersGrouped();
  }

  Future<void> _fetchCustomersGrouped() async {
    setState(() => _isLoading = true);

    try {
      final data =
          await supabase
                  .from('customer_order')
                  .select(
                    'customer_order_id, order_date, customer:customer_id(customer_id, name), customer_order_inventory(inventory_id)',
                  )
                  .eq('order_status', 'Delivery')
                  .eq('delivered_by_id', widget.deliveryDriverId)
                  .order('order_date', ascending: false)
                  .limit(200)
              as List<dynamic>;

      // Group orders by customerId
      final Map<int, Map<String, dynamic>> grouped = {};

      for (final row in data) {
        final customerData = row['customer'] as Map<String, dynamic>? ?? {};
        final customerId = customerData['customer_id'] as int?;
        if (customerId == null) continue;

        final customerName =
            customerData['name'] as String? ?? 'Unknown Customer';
        final orderId = row['customer_order_id'] as int? ?? 0;

        final orderDateStr = row['order_date'] as String?;
        final orderDate = orderDateStr != null
            ? DateTime.tryParse(orderDateStr)
            : null;

        final orderInventory =
            row['customer_order_inventory'] as List<dynamic>? ?? [];
        final productCount = orderInventory.length;

        grouped.putIfAbsent(customerId, () {
          return {
            'customerId': customerId,
            'name': customerName,
            'orders': <Map<String, dynamic>>[],
            'latestOrderDate': orderDate,
          };
        });

        final orders =
            grouped[customerId]!['orders'] as List<Map<String, dynamic>>;
        orders.add({
          'orderId': orderId,
          'productCount': productCount,
          'orderDate': orderDate,
        });

        final latest = grouped[customerId]!['latestOrderDate'] as DateTime?;
        if (latest == null ||
            (orderDate != null && orderDate.isAfter(latest))) {
          grouped[customerId]!['latestOrderDate'] = orderDate;
        }
      }

      final result = grouped.values.toList();

      // Sort customers by latest order date (newest first)
      result.sort((a, b) {
        final da = a['latestOrderDate'] as DateTime?;
        final db = b['latestOrderDate'] as DateTime?;
        if (da != null && db != null) return db.compareTo(da);
        if (da != null) return -1;
        if (db != null) return 1;
        return 0;
      });

      // Sort each customer's orders by orderDate newest first (optional but nice)
      for (final c in result) {
        final orders = (c['orders'] as List<Map<String, dynamic>>);
        orders.sort((x, y) {
          final dx = x['orderDate'] as DateTime?;
          final dy = y['orderDate'] as DateTime?;
          if (dx != null && dy != null) return dy.compareTo(dx);
          if (dx != null) return -1;
          if (dy != null) return 1;
          return (y['orderId'] as int).compareTo(x['orderId'] as int);
        });
      }

      if (!mounted) return;
      setState(() {
        customers = result;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Failed to load deliveries: $e');
      if (!mounted) return;
      setState(() {
        customers = [];
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load deliveries: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openOrderDetails({
    required int orderId,
    required String customerName,
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DeliveryOrderDetails(
          orderId: orderId,
          customerName: customerName,
          readOnly: false,
          deliveryDriverId: widget.deliveryDriverId,
        ),
      ),
    );

    // Refresh after returning
    if (mounted) {
      await _fetchCustomersGrouped();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF202020),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFB7A447)),
              )
            : customers.isEmpty
            ? const Center(
                child: Text(
                  'No active deliveries assigned to you',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
                itemCount: customers.length,
                itemBuilder: (context, index) {
                  final customer = customers[index];
                  final name =
                      customer['name'] as String? ?? 'Unknown Customer';
                  final orders =
                      (customer['orders'] as List<Map<String, dynamic>>);

                  // لو مافي orders لأي سبب
                  if (orders.isEmpty) return const SizedBox.shrink();

                  // آخر/أحدث أوردر (للشكل القديم)
                  final latest = orders.first;
                  final latestOrderId = latest['orderId'] as int? ?? 0;
                  final latestProductCount =
                      latest['productCount'] as int? ?? 0;

                  // إذا عنده أكثر من أوردر
                  final isMulti = orders.length > 1;

                  // لو متعدد: نجمع عدد المنتجات لكل الأوردرات (اختياري)
                  final totalProducts = orders.fold<int>(
                    0,
                    (sum, o) => sum + ((o['productCount'] as int?) ?? 0),
                  );

                  // ====== التصميم القديم (Order واحد) ======
                  Widget singleOrderCard() {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DeliveryOrderDetails(
                                orderId: latestOrderId,
                                customerName: name,
                                readOnly: false,
                                deliveryDriverId: widget.deliveryDriverId,
                              ),
                            ),
                          );
                          if (mounted) await _fetchCustomersGrouped();
                        },
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF2D2D2D),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.25),
                                    blurRadius: 1,
                                    spreadRadius: 1,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: const [
                                        Text(
                                          'ID #',
                                          style: TextStyle(
                                            color: Color(0xFFB7A447),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(width: 34),
                                        Text(
                                          'Customer Name',
                                          style: TextStyle(
                                            color: Color(0xFFB7A447),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          '$latestOrderId',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 23,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 28),
                                        Expanded(
                                          child: Text(
                                            name,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Container(
                                          width: 84,
                                          height: 84,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF262626),
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                '$latestProductCount',
                                                style: const TextStyle(
                                                  color: Color(0xFFFFEFFF),
                                                  fontSize: 25,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                'Products',
                                                style: TextStyle(
                                                  color: const Color(
                                                    0xFFB7A447,
                                                  ),
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              top: -6,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFB7A447),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Assigned',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // ====== التصميم الجديد (أكثر من Order) ======
                  Widget multiOrderCard() {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF2D2D2D),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.25),
                                  blurRadius: 1,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: const [
                                      Text(
                                        'ID #',
                                        style: TextStyle(
                                          color: Color(0xFFB7A447),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(width: 34),
                                      Text(
                                        'Customer Name',
                                        style: TextStyle(
                                          color: Color(0xFFB7A447),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),

                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      // نخليها تعرض أحدث orderId مثل قبل
                                      Text(
                                        '$latestOrderId',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 23,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 28),
                                      Expanded(
                                        child: Text(
                                          name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),

                                      const SizedBox(width: 16),

                                      // إجمالي المنتجات لكل أوردرات الزبون (اختياري)
                                      Container(
                                        width: 84,
                                        height: 84,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF262626),
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              '$totalProducts',
                                              style: const TextStyle(
                                                color: Color(0xFFFFEFFF),
                                                fontSize: 25,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              'Products',
                                              style: TextStyle(
                                                color: const Color(0xFFB7A447),
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${orders.length} orders',
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 12),

                                  // Chips للأوردرات
                                  SizedBox(
                                    height: 44,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: orders.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(width: 10),
                                      itemBuilder: (context, i) {
                                        final o = orders[i];
                                        final oid = o['orderId'] as int? ?? 0;
                                        final pc =
                                            o['productCount'] as int? ?? 0;

                                        return InkWell(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          onTap: () async {
                                            await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    DeliveryOrderDetails(
                                                      orderId: oid,
                                                      customerName: name,
                                                      readOnly: false,
                                                      deliveryDriverId: widget
                                                          .deliveryDriverId,
                                                    ),
                                              ),
                                            );
                                            if (mounted)
                                              await _fetchCustomersGrouped();
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF262626),
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              border: Border.all(
                                                color: const Color(
                                                  0xFFB7A447,
                                                ).withOpacity(0.6),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  'Order #$oid',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 7,
                                                        vertical: 3,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                      0xFFB7A447,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          9,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    '$pc',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w900,
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

                          Positioned(
                            top: -6,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFB7A447),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Assigned (${orders.length})',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // ✅ الشرط الأساسي
                  return isMulti ? multiOrderCard() : singleOrderCard();
                },
              ),
      ),
    );
  }
}
