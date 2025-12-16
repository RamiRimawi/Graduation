import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../supabase_config.dart';
import '../account_page.dart';
import '../bottom_navbar.dart';
import 'order_details_page.dart';

class SupplierHomePage extends StatefulWidget {
  const SupplierHomePage({super.key});

  @override
  State<SupplierHomePage> createState() => _SupplierHomePageState();
}

class _SupplierHomePageState extends State<SupplierHomePage> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _orders = [];
      });
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? userIdStr = prefs.getString('current_user_id');
      final int? supplierId = userIdStr != null ? int.tryParse(userIdStr) : null;

      if (supplierId == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Fetch all supplier_order records for this supplier
      final orders = await supabase
          .from('supplier_order')
          .select('order_id, created_by_id, order_date, order_status')
          .eq('supplier_id', supplierId)
          .eq('order_status', 'Sent')
          .order('order_date', ascending: false);

      final List<Map<String, dynamic>> ordersWithProducts = [];

      // For each order, fetch the product count and creator name
      for (final order in orders) {
        final orderId = order['order_id'];

        // Get product count (number of distinct products in this order)
        final products = await supabase
            .from('supplier_order_description')
            .select('product_id')
            .eq('order_id', orderId);

        final productCount = (products as List).length.toString();

        // Get creator/contact name (try to get from any related table or use ID)
        final createdById = order['created_by_id'];
        String creatorName = 'Order #$orderId';

        if (createdById != null) {
          // Try to fetch name from storage_manager table
          final creator = await supabase
              .from('storage_manager')
              .select('name')
              .eq('storage_manager_id', createdById)
              .maybeSingle();

          if (creator != null && creator['name'] != null) {
            creatorName = creator['name'] as String;
          }
        }

        ordersWithProducts.add({
          'id': orderId.toString(),
          'name': creatorName,
          'productCount': productCount,
          'order': order,
        });
      }

      setState(() {
        _orders = ordersWithProducts;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading orders: $e');
      setState(() => _isLoading = false);
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
            : _orders.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32.0),
                      child: Text(
                        'No orders yet',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
                    itemCount: _orders.length,
                    itemBuilder: (context, index) {
                      final orderData = _orders[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildCard(
                          id: orderData['id'],
                          name: orderData['name'],
                          products: orderData['productCount'],
                          orderId: orderData['order']['order_id'],
                        ),
                      );
                    },
                  ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0,
        onTap: (i) {
          if (i == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AccountPage()),
            );
          }
        },
      ),
    );
  }

  /// -----------------------------------------------------------------
  /// Card for one order (same UI/UX as before)
  /// -----------------------------------------------------------------
  Widget _buildCard({
    required String id,
    required String name,
    required String products,
    required int orderId,
  }) {
    return GestureDetector(
      onTap: () async {
        final shouldRefresh = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderDetailsPage(
              orderId: orderId,
              customerName: name,
            ),
          ),
        );

        if (shouldRefresh == true) {
          await _loadOrders();
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    id,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 28),

                  Expanded(
                    child: Text(
                      'Dolphin Company',
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
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          products,
                          style: const TextStyle(
                            color: Color(0xFFFFEFFF),
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'products',
                          style: TextStyle(
                            color: Color(0xFFB7A447),
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
    );
  }
}