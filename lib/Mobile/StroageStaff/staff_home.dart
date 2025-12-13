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

      // Fetch orders prepared by this storage staff
        final List<dynamic> orders = await Supabase.instance.client
          .from('customer_order')
          .select('customer_order_id, customer:customer_id(name)')
          .eq('prepared_by_id', staffId)
          .order('customer_order_id');

      // Collect order ids for counting products
      final orderIds = orders
          .map<int?>((o) => o['customer_order_id'] as int?)
          .whereType<int>()
          .toList();

      Map<int, int> productCounts = {};
      if (orderIds.isNotEmpty) {
        final List<dynamic> desc = await Supabase.instance.client
            .from('customer_order_description')
            .select('customer_order_id, quantity')
            // Use generic filter to avoid in_ version issues
            .filter('customer_order_id', 'in', orderIds);

        for (final row in desc) {
          final id = row['customer_order_id'] as int?;
          if (id == null) continue;
          final qty = (row['quantity'] as num?)?.toInt() ?? 0;
          if (qty == 0) continue;
          productCounts[id] = (productCounts[id] ?? 0) + qty;
        }
      }

      final List<Map<String, dynamic>> mapped = orders.map<Map<String, dynamic>>((o) {
        final id = o['customer_order_id'] as int? ?? 0;
        final customer = (o['customer'] as Map?)?['name']?.toString() ?? 'Unknown';
        final products = productCounts[id] ?? 0;
        return {'id': id, 'name': customer, 'products': products};
      }).toList();

      setState(() {
        customers = mapped;
        _loading = false;
      });
    } catch (_) {
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
                      builder: (context) => CustomerDetail(
                        customerName: customer['name'],
                        customerId: customer['id'],
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
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 34),
                            Text(
                              'Customer Name',
                              style: TextStyle(
                                color: const Color(0xFFB7A447),
                                fontSize: 18,
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
                                fontSize: 32,
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
                                  fontSize: 26,
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
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${customer['products']}',
                                    style: const TextStyle(
                                      color: Color(0xFFFFEFFF),
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Product',
                                    style: TextStyle(
                                      color: const Color(0xFFB7A447),
                                      fontSize: 16,
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
