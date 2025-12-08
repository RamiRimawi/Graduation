import 'package:flutter/material.dart';
import 'deleviry_detail.dart';
import '../account_page.dart';
import '../../supabase_config.dart';

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

  void _onItemTapped(int index) {
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AccountPage()),
      );
      return;
    }
    setState(() => _selectedIndex = index);
  }

  Future<void> _fetchCustomers() async {
    setState(() => _isLoading = true);
    
    try {
      // Fetch customer orders with related customer data
      // Only show orders with status 'Delivery' assigned to this delivery driver
      final data = await supabase
          .from('customer_order')
          .select(
            'customer_order_id, order_date, order_status, delivered_by_id, customer:customer_id(customer_id, name), customer_order_description(*)',
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
        
        // Count inventory items from order descriptions
        final orderDescriptions = row['customer_order_description'] as List<dynamic>? ?? [];
        final inventoryNo = orderDescriptions.length;

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
          'inventory': inventoryNo,
        });
      }

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
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DeleviryDetail(
                        customerName: customer['name'],
                        customerId: customer['customerId'],
                        orderId: customer['orderId'],
                        deliveryDriverId: widget.deliveryDriverId,
                      ),
                    ),
                  );
                },
                child: Container(
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

                            // PRODUCT BOX — bigger
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
                                    '${customer['inventory']}',
                                    style: const TextStyle(
                                      color: Color(0xFFFFEFFF),
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'inventory #',
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
              ),
            );
          },
        ),
      ),

      // NAV BAR
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF242424),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(22),
            topRight: Radius.circular(22),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black54,
              offset: Offset(0, -3),
              blurRadius: 6,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(22),
            topRight: Radius.circular(22),
          ),
          child: BottomNavigationBar(
            backgroundColor: const Color(0xFF242424),
            currentIndex: _selectedIndex,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            selectedItemColor: const Color(0xFFF9D949),
            unselectedItemColor: Colors.white60,
            onTap: _onItemTapped,
            items: [
              BottomNavigationBarItem(
                icon: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.home_filled),
                    const SizedBox(height: 6),
                    Text(
                      'Home',
                      style: TextStyle(
                        color: _selectedIndex == 0 ? const Color(0xFFF9D949) : Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: _selectedIndex == 0 ? 70.0 : 0,
                      height: 3,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9D949),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person),
                    const SizedBox(height: 6),
                    Text(
                      'Account',
                      style: TextStyle(
                        color: _selectedIndex == 1 ? const Color(0xFFF9D949) : Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: _selectedIndex == 1 ? 70.0 : 0,
                      height: 3,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9D949),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
                label: '',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
