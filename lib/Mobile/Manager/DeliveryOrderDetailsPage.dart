import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'order_item.dart';
import '../manager_theme.dart';

class DeliveryOrderDetailsPage extends StatefulWidget {
  final int orderId;

  const DeliveryOrderDetailsPage({super.key, required this.orderId});

  @override
  State<DeliveryOrderDetailsPage> createState() =>
      _DeliveryOrderDetailsPageState();
}

class _DeliveryOrderDetailsPageState extends State<DeliveryOrderDetailsPage> {
  String _customerName = '';
  List<OrderItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrderDetails();
  }

  Future<void> _fetchOrderDetails() async {
    try {
      final supabase = Supabase.instance.client;

      // Fetch order with customer name
      final orderResponse = await supabase
          .from('customer_order')
          .select('customer:customer_id(name)')
          .eq('customer_order_id', widget.orderId)
          .single();

      final customer = orderResponse['customer'] as Map<String, dynamic>?;
      final customerName = customer?['name'] as String? ?? 'Unknown';

      // Fetch all inventory items for this order
      final inventoryResponse = await supabase
          .from('customer_order_inventory')
          .select('*')
          .eq('customer_order_id', widget.orderId);

      if (inventoryResponse.isEmpty) {
        setState(() {
          _customerName = customerName;
          _loading = false;
        });
        return;
      }

      // Get unique product IDs
      final productIds = inventoryResponse
          .map((i) => i['product_id'] as int)
          .toSet()
          .toList();

      // Fetch products
      final productsResponse = await supabase
          .from('product')
          .select('product_id, name, brand_id, unit_id')
          .inFilter('product_id', productIds);

      // Get brand and unit IDs
      final brandIds = productsResponse
          .map((p) => p['brand_id'] as int?)
          .where((id) => id != null)
          .toSet()
          .toList();

      final unitIds = productsResponse
          .map((p) => p['unit_id'] as int?)
          .where((id) => id != null)
          .toSet()
          .toList();

      // Fetch brands and units
      final brandsResponse = brandIds.isNotEmpty
          ? await supabase
                .from('brand')
                .select('brand_id, name')
                .inFilter('brand_id', brandIds)
          : [];

      final unitsResponse = unitIds.isNotEmpty
          ? await supabase
                .from('unit')
                .select('unit_id, unit_name')
                .inFilter('unit_id', unitIds)
          : [];

      // Build maps
      final productMap = {for (var p in productsResponse) p['product_id']: p};
      final brandMap = {for (var b in brandsResponse) b['brand_id']: b};
      final unitMap = {for (var u in unitsResponse) u['unit_id']: u};

      // Consolidate items by product (sum quantities if split)
      final Map<int, double> productQtyMap = {};
      for (final item in inventoryResponse) {
        final productId = item['product_id'] as int;
        // Prefer prepared_quantity when available, fall back to quantity
        final qty =
            (item['prepared_quantity'] as num?)?.toDouble() ??
            (item['quantity'] as num?)?.toDouble() ??
            0.0;
        productQtyMap[productId] = (productQtyMap[productId] ?? 0.0) + qty;
      }

      // Build items list
      final List<OrderItem> items = [];
      for (final entry in productQtyMap.entries) {
        final product = productMap[entry.key];
        if (product == null) continue;

        final brandId = product['brand_id'] as int?;
        final unitId = product['unit_id'] as int?;

        final brandName = brandId != null
            ? (brandMap[brandId]?['name'] as String? ?? '')
            : '';
        final unitName = unitId != null
            ? (unitMap[unitId]?['unit_name'] as String? ?? '')
            : '';

        items.add(
          OrderItem(
            entry.key,
            product['name'] as String? ?? 'Unknown',
            brandName,
            unitName,
            entry.value.toInt(),
          ),
        );
      }

      setState(() {
        _customerName = customerName;
        _items = items;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error fetching delivery order details: $e');
      setState(() => _loading = false);
    }
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
              // Back
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _customerName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              if (_loading)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.yellow),
                  ),
                )
              else ...[
                // HEADER
                const Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Text(
                        "Product Name",
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        "Brand",
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        "Qty",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),
                Container(height: 1, color: Colors.white24),
                const SizedBox(height: 10),

                Expanded(
                  child: _items.isEmpty
                      ? const Center(
                          child: Text(
                            'No items found',
                            style: TextStyle(color: Colors.white),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _items.length,
                          itemBuilder: (_, i) {
                            final item = _items[i];

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: Text(
                                      item.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      item.brand,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Center(
                                      child: Text(
                                        "${item.qty} ${item.unit}",
                                        style: const TextStyle(
                                          color: AppColors.gold,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
