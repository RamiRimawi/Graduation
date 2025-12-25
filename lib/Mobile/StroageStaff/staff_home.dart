import 'package:flutter/material.dart';
import 'staff_detail.dart';
import '../account_page.dart';
import '../bottom_navbar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeStaff extends StatefulWidget {
  const HomeStaff({super.key});

  @override
  State<HomeStaff> createState() => _HomeStaffState();
}

class _HomeStaffState extends State<HomeStaff> {
  int _selectedIndex = 0;
  bool _loading = true;
  List<Map<String, dynamic>> customers = const [];

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  Future<void> _fetchCustomers() async {
    try {
      setState(() => _loading = true);
      final prefs = await SharedPreferences.getInstance();
      final String? userIdStr = prefs.getString('current_user_id');
      final int? staffId = userIdStr != null ? int.tryParse(userIdStr) : null;
      if (staffId == null) {
        setState(() => _loading = false);
        return;
      }

      // Fetch customer_order_inventory items assigned to this staff
      final List<dynamic> inventoryItems = await Supabase.instance.client
          .from('customer_order_inventory')
          .select('customer_order_id, product_id')
          .eq('prepared_by', staffId)
          .order('customer_order_id');

      if (inventoryItems.isEmpty) {
        setState(() => _loading = false);
        return;
      }

      // Get unique order IDs
      final Set<int> orderIds = {};
      for (final item in inventoryItems) {
        final orderId = item['customer_order_id'] as int?;
        if (orderId != null) {
          orderIds.add(orderId);
        }
      }

      if (orderIds.isEmpty) {
        setState(() => _loading = false);
        return;
      }

      // Fetch customer names for these orders (only Preparing status)
      final List<dynamic> orders = await Supabase.instance.client
          .from('customer_order')
          .select('customer_order_id, order_status, customer:customer_id(name)')
          .filter('customer_order_id', 'in', orderIds.toList())
          .eq('order_status', 'Preparing')
          .order('customer_order_id');

      // Count products assigned to this staff per order
      Map<int, int> productCounts = {};
      for (final item in inventoryItems) {
        final id = item['customer_order_id'] as int?;
        if (id == null) continue;
        productCounts[id] = (productCounts[id] ?? 0) + 1;
      }

      final List<Map<String, dynamic>> mapped = orders
          .map<Map<String, dynamic>>((o) {
            final id = o['customer_order_id'] as int? ?? 0;
            final customer =
                (o['customer'] as Map?)?['name']?.toString() ?? 'Unknown';
            final products = productCounts[id] ?? 0;
            return {'id': id, 'name': customer, 'products': products};
          })
          .toList();

      if (mounted) {
        setState(() {
          customers = mapped;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching customers: $e');
      if (mounted) setState(() => _loading = false);
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF202020),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFFFE14D)),
              )
            : customers.isEmpty
            ? const Center(
                child: Text(
                  'No orders Preparing',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
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
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CustomerDetail(
                              customerName: customer['name'],
                              customerId: customer['id'],
                            ),
                          ),
                        );
                        // Refresh the list when returning from detail page
                        if (result == true && mounted) {
                          _fetchCustomers();
                        }
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
                            horizontal: 20,
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
                                    '${customer['id']}',
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
                                    width: 85,
                                    height: 89,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF262626),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '${customer['products']}',
                                          style: const TextStyle(
                                            color: Color(0xFFFFEFFF),
                                            fontSize: 25,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          'Product',
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

      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
