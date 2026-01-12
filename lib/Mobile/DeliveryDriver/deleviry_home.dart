import 'package:flutter/material.dart';
import 'delivery_archive.dart';
import 'delivery_order_details.dart';
import '../account_page.dart';
import '../../supabase_config.dart';
import '../bottom_navbar.dart';

class HomeDeleviry extends StatefulWidget {
  final int deliveryDriverId;
  
  const HomeDeleviry({super.key, required this.deliveryDriverId});

  @override
  State<HomeDeleviry> createState() => _HomeDeleviryState();
}

class _HomeDeleviryState extends State<HomeDeleviry> {
  int _selectedIndex = 0;
  List<Map<String, dynamic>> customers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh when returning to this screen
    _fetchCustomers();
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      // Already on Home - do nothing
      return;
    }
    if (index == 1) {
      // Navigate to Archive page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DeliveryArchive(deliveryDriverId: widget.deliveryDriverId),
        ),
      );
      return;
    }
    if (index == 2) {
      // Navigate to Account page
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AccountPage()),
      );
      return;
    }
  }

  Future<void> _fetchCustomers() async {
    setState(() => _isLoading = true);
    
    try {
      // Fetch customer orders with related customer data and inventory info
      // Show only orders with status 'Delivery' (pending deliveries) assigned to this delivery driver
      final data = await supabase
          .from('customer_order')
          .select(
            'customer_order_id, order_date, customer:customer_id(customer_id, name), customer_order_inventory(inventory_id)',
          )
          .eq('order_status', 'Delivery')
          .eq('delivered_by_id', widget.deliveryDriverId)
          .order('order_date', ascending: false)
          .limit(100) as List<dynamic>;

      final seenCustomerIds = <int>{};
      final List<Map<String, dynamic>> fetched = [];

      for (final row in data) {
        final customerData = row['customer'] as Map<String, dynamic>? ?? {};
        final customerId = customerData['customer_id'] as int?;
        final customerName = customerData['name'] as String? ?? 'Unknown Customer';
        final orderId = row['customer_order_id'] as int?;
        final orderDateStr = row['order_date'] as String?;
        DateTime? orderDate;

        if (orderDateStr != null) {
          orderDate = DateTime.tryParse(orderDateStr);
        }
        
        // Get order items (customer_order_inventory) and derive product count
        final orderInventory = row['customer_order_inventory'] as List<dynamic>? ?? [];
        final int productCount = orderInventory.length;

        if (customerId != null && seenCustomerIds.contains(customerId)) {
          continue;
        }

        if (customerId != null) {
          seenCustomerIds.add(customerId);
        }

        fetched.add({
          'orderId': orderId ?? customerId ?? 0,
          'customerId': customerId ?? 0,
          'name': customerName,
          'productCount': productCount,
          'orderDate': orderDate,
        });
      }

      // Sort by order date - newest first (already ordered by query but keeping for consistency)
      fetched.sort((a, b) {
        final da = a['orderDate'] as DateTime?;
        final db = b['orderDate'] as DateTime?;
        if (da != null && db != null) return db.compareTo(da);
        if (da != null) return -1;
        if (db != null) return 1;
        return 0;
      });

      if (!mounted) return;
      setState(() {
        customers = fetched;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF202020),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFB7A447),
                ),
              )
            : customers.isEmpty
                ? const Center(
                    child: Text(
                      'No active deliveries assigned to you',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
                    itemCount: customers.length,
                    itemBuilder: (context, index) {
            final customer = customers[index];

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DeliveryOrderDetails(
                        orderId: customer['orderId'],
                        customerName: customer['name'],
                        readOnly: false,
                        deliveryDriverId: widget.deliveryDriverId,
                      ),
                    ),
                  );
                  // Refresh the list after returning from order details
                  if (mounted) {
                    await _fetchCustomers();
                  }
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

                        // MAIN CONTENT
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
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
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
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
                    // Status Badge - Assigned
                    Positioned(
                      top: -6,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          },
        ),
      ),

      // NAV BAR
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
