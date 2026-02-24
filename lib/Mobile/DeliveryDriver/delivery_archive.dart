import 'package:flutter/material.dart';
import 'delivery_order_details.dart';
import '../../supabase_config.dart';

class DeliveryArchive extends StatefulWidget {
  final int deliveryDriverId;

  const DeliveryArchive({super.key, required this.deliveryDriverId});

  @override
  State<DeliveryArchive> createState() => _DeliveryArchiveState();
}

class _DeliveryArchiveState extends State<DeliveryArchive> {
  List<Map<String, dynamic>> customers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDeliveredOrders();
  }

  String _formatDeliveryDate(String? dateString) {
    if (dateString == null) return '';

    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) {
        return 'now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes} minutes ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} hours ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateString;
    }
  }

  Future<void> _fetchDeliveredOrders() async {
    setState(() => _isLoading = true);

    try {
      // Fetch only delivered orders assigned to this delivery driver
      final data =
          await supabase
                  .from('customer_order')
                  .select(
                    'customer_order_id, order_date, order_status, delivered_by_id, customer:customer_id(customer_id, name), customer_order_inventory(inventory_id, inventory:inventory_id(inventory_name)), customer_order_description(delivered_date)',
                  )
                  .eq('order_status', 'Delivered')
                  .eq('delivered_by_id', widget.deliveryDriverId)
                  .order('order_date', ascending: false)
                  .limit(100)
              as List<dynamic>;

      final List<Map<String, dynamic>> fetched = [];

      for (final row in data) {
        final customerData = row['customer'] as Map<String, dynamic>? ?? {};
        final customerId = customerData['customer_id'] as int?;
        final customerName =
            customerData['name'] as String? ?? 'Unknown Customer';
        final orderId = row['customer_order_id'] as int?;
        final orderDateStr = row['order_date'] as String?;
        DateTime? orderDate;

        if (orderDateStr != null) {
          orderDate = DateTime.tryParse(orderDateStr);
        }

        // Get order items and derive product count
        final orderInventory =
            row['customer_order_inventory'] as List<dynamic>? ?? [];
        int? inventoryId;
        final int productCount = orderInventory.length;

        if (orderInventory.isNotEmpty) {
          inventoryId = orderInventory[0]['inventory_id'] as int?;
        }

        // Get delivered_date from customer_order_description
        final orderDescription =
            row['customer_order_description'] as List<dynamic>? ?? [];
        String? deliveredDate;
        DateTime? deliveredAt;

        if (orderDescription.isNotEmpty) {
          deliveredDate = orderDescription[0]['delivered_date'] as String?;
          if (deliveredDate != null) {
            deliveredAt = DateTime.tryParse(deliveredDate);
          }
        }

        fetched.add({
          'orderId': orderId ?? customerId ?? 0,
          'customerId': customerId ?? 0,
          'name': customerName,
          'inventory': inventoryId ?? 0,
          'productCount': productCount,
          'orderStatus': row['order_status'] as String? ?? 'Delivered',
          'deliveredDate': deliveredDate,
          'deliveredAt': deliveredAt,
          'orderDate': orderDate,
        });
      }

      // Sort by delivered date, newest first
      fetched.sort((a, b) {
        final da =
            (a['deliveredAt'] as DateTime?) ?? (a['orderDate'] as DateTime?);
        final db =
            (b['deliveredAt'] as DateTime?) ?? (b['orderDate'] as DateTime?);
        if (da != null && db != null) return db.compareTo(da);
        if (da != null) return -1;
        if (db != null) return 1;

        final oa = a['orderId'] as int?;
        final ob = b['orderId'] as int?;
        if (oa != null && ob != null) return ob.compareTo(oa);
        return 0;
      });

      if (!mounted) return;
      setState(() {
        customers = fetched;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Failed to load delivered orders: $e');
      if (!mounted) return;
      setState(() {
        customers = [];
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load delivered orders: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF202020),
      appBar: AppBar(
        backgroundColor: const Color(0xFF202020),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Delivery Archive',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFB7A447)),
              )
            : customers.isEmpty
            ? RefreshIndicator(
                color: const Color(0xFFB7A447),
                backgroundColor: const Color(0xFF2D2D2D),
                onRefresh: _fetchDeliveredOrders,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 200),
                    Center(
                      child: Text(
                        'No delivered orders yet',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                color: const Color(0xFFB7A447),
                backgroundColor: const Color(0xFF2D2D2D),
                onRefresh: _fetchDeliveredOrders,
                child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
                itemCount: customers.length,
                itemBuilder: (context, index) {
                  final customer = customers[index];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DeliveryOrderDetails(
                              orderId: customer['orderId'],
                              customerName: customer['name'],
                              readOnly: true,
                              deliveryDriverId: widget.deliveryDriverId,
                            ),
                          ),
                        );
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
                                  // TITLE ROW
                                  Row(
                                    children: [
                                      Text(
                                        'ID #',
                                        style: TextStyle(
                                          color: const Color(0xFFB7A447),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 34),
                                      Text(
                                        'Customer Name',
                                        style: TextStyle(
                                          color: const Color(0xFFB7A447),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 2),

                                  // Delivered Date
                                  if (customer['deliveredDate'] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Delivered: ${_formatDeliveryDate(customer['deliveredDate'])}',
                                            style: const TextStyle(
                                              color: Colors.green,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                  // MAIN CONTENT
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        '${customer['orderId']}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 23,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 28),

                                      // NAME
                                      Expanded(
                                        child: Text(
                                          customer['name'],
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),

                                      const SizedBox(width: 16),

                                      // PRODUCT BOX — show product count
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
                                              '${customer['productCount'] ?? 0}',
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
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Status Badge
                          Positioned(
                            top: -6,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Delivered',
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
                },
              ),
              ),
      ),
    );
  }
}
