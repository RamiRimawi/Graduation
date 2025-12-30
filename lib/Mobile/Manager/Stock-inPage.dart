import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../manager_theme.dart';
import 'CreateStockInOrderPage.dart';
import 'StockInOrderDetailsPage.dart';

class StockInPage extends StatefulWidget {
  const StockInPage({super.key});

  @override
  State<StockInPage> createState() => _StockInPageState();
}

class _StockInPageState extends State<StockInPage> {
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> allOrders = [];
  List<Map<String, dynamic>> filteredOrders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrders();

    _searchController.addListener(() {
      final query = _searchController.text.toLowerCase();

      setState(() {
        filteredOrders = allOrders.where((order) {
          final supplier = order["supplier"].toString().toLowerCase();
          // Search by supplier name starting with query
          return supplier.startsWith(query);
        }).toList();
      });
    });
  }

  Future<void> _fetchOrders() async {
    try {
      setState(() => _loading = true);

      // Fetch supplier orders with status 'Accepted' and join with supplier
      final response = await Supabase.instance.client
          .from('supplier_order')
          .select('''
            order_id,
            supplier:supplier_id(name),
            order_date
          ''')
          .eq('order_status', 'Accepted')
          .order('order_id', ascending: false);

      final List<Map<String, dynamic>> orders = [];

      for (final order in response) {
        final orderId = order['order_id'] as int?;
        final supplierData = order['supplier'] as Map?;
        final supplierName = supplierData?['name'] as String? ?? 'Unknown';

        // Format order date
        final orderDateStr = order['order_date'] as String?;
        String dateDisplay = '-';
        if (orderDateStr != null && orderDateStr.isNotEmpty) {
          try {
            final dateTime = DateTime.parse(orderDateStr);
            dateDisplay = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
          } catch (e) {
            dateDisplay = '-';
          }
        }

        if (orderId != null) {
          orders.add({
            'id': orderId,
            'supplier': supplierName,
            'orderDate': dateDisplay,
          });
        }
      }

      if (mounted) {
        setState(() {
          allOrders = orders;
          filteredOrders = orders;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching supplier orders: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===================== TITLE =====================
              const Text(
                "Recommended orders",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),

              // ===================== SEARCH FIELD =====================
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 0,
                ),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: AppColors.gold, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        decoration: const InputDecoration(
                          hintText: "Supplier Name",
                          hintStyle: TextStyle(
                            color: Colors.white54,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ===================== TABLE HEADER =====================
              const Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      "Order ID #",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: Text(
                      "Supplier Name",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      "Order Date",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(height: 1, color: Colors.white24),
              const SizedBox(height: 14),

              // ===================== ORDERS LIST =====================
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.gold),
                      )
                    : filteredOrders.isEmpty
                    ? const Center(
                        child: Text(
                          'No accepted orders found',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredOrders.length,
                        itemBuilder: (_, i) {
                          final o = filteredOrders[i];

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => StockInOrderDetailsPage(
                                    orderId: o["id"] as int,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Row(
                                children: [
                                  // Order ID
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      "${o["id"]}",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),

                                  // Supplier Name
                                  Expanded(
                                    flex: 5,
                                    child: Text(
                                      o["supplier"],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),

                                  // Order Date
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      "${o["orderDate"]}",
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
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

              const SizedBox(height: 10),

              // ===================== Create Order BUTTON =====================
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CreateStockInOrderPage(),
                      ),
                    );
                  },

                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_box_rounded,
                          color: Colors.black,
                          size: 22,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Create Order",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
