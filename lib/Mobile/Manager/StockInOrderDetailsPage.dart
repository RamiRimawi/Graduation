import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'manager_theme.dart';

class StockInOrderDetailsPage extends StatefulWidget {
  final int orderId;

  const StockInOrderDetailsPage({super.key, required this.orderId});

  @override
  State<StockInOrderDetailsPage> createState() =>
      _StockInOrderDetailsPageState();
}

class _StockInOrderDetailsPageState extends State<StockInOrderDetailsPage> {
  bool _loading = true;
  String _supplierName = '';
  String _orderStatus = '';
  DateTime? _orderDate;
  List<_OrderItem> _items = [];

  @override
  void initState() {
    super.initState();
    _fetchOrderDetails();
  }

  Future<void> _fetchOrderDetails() async {
    try {
      final supabase = Supabase.instance.client;

      // Fetch order with supplier
      final orderResponse = await supabase
          .from('supplier_order')
          .select('supplier:supplier_id(name), order_status, order_date')
          .eq('order_id', widget.orderId)
          .single();

      _supplierName = orderResponse['supplier']['name'] as String? ?? 'Unknown';
      _orderStatus = orderResponse['order_status'] as String? ?? 'Unknown';
      _orderDate = orderResponse['order_date'] != null
          ? DateTime.parse(orderResponse['order_date'] as String)
          : null;

      // Fetch order inventory (products with quantities)
      final inventoryResponse = await supabase
          .from('supplier_order_inventory')
          .select('product_id, quantity, batch_id')
          .eq('order_id', widget.orderId);

      // Fetch product details separately
      final productIds = inventoryResponse
          .map((row) => row['product_id'] as int)
          .toSet()
          .toList();

      final productsResponse = await supabase
          .from('product')
          .select('product_id, name, brand_id, unit_id')
          .inFilter('product_id', productIds);

      final productMap = {
        for (var p in productsResponse) p['product_id'] as int: p,
      };

      // Fetch brand details
      final brandIds = productsResponse
          .map((p) => p['brand_id'] as int?)
          .where((id) => id != null)
          .toSet()
          .toList();

      final brandsResponse = await supabase
          .from('brand')
          .select('brand_id, name')
          .inFilter('brand_id', brandIds);

      final brandMap = {for (var b in brandsResponse) b['brand_id'] as int: b};

      // Fetch unit details
      final unitIds = productsResponse
          .map((p) => p['unit_id'] as int?)
          .where((id) => id != null)
          .toSet()
          .toList();

      final unitsResponse = await supabase
          .from('unit')
          .select('unit_id, unit_name')
          .inFilter('unit_id', unitIds);

      final unitMap = {for (var u in unitsResponse) u['unit_id'] as int: u};

      // Fetch batch details (includes storage location)
      final batchIds = inventoryResponse
          .map((row) => row['batch_id'] as int?)
          .where((id) => id != null)
          .toSet()
          .toList();

      Map<int, dynamic> batchMap = {};
      if (batchIds.isNotEmpty) {
        final batchResponse = await supabase
            .from('batch')
            .select('batch_id, storage_location_descrption')
            .inFilter('batch_id', batchIds);

        batchMap = {for (var b in batchResponse) b['batch_id'] as int: b};
      }

      // Build items list
      final List<_OrderItem> items = [];

      for (final row in inventoryResponse) {
        final productId = row['product_id'] as int?;
        final quantityRaw = row['quantity'];
        final quantity = quantityRaw is int
            ? quantityRaw
            : (quantityRaw is String ? int.tryParse(quantityRaw) ?? 0 : 0);
        final batchId = row['batch_id'] as int?;

        if (productId == null) continue;

        final product = productMap[productId];
        if (product == null) continue;

        final brandId = product['brand_id'] as int?;
        final unitId = product['unit_id'] as int?;
        final brand = brandId != null ? brandMap[brandId] : null;
        final unit = unitId != null ? unitMap[unitId] : null;
        final batch = batchId != null ? batchMap[batchId] : null;

        final storageLocation =
            batch?['storage_location_descrption'] as String?;

        items.add(
          _OrderItem(
            productName: product['name'] as String? ?? 'Unknown',
            brandName: brand?['name'] as String? ?? 'Unknown',
            unitName: unit?['unit_name'] as String? ?? 'Unit',
            quantity: quantity,
            batchLocation: storageLocation,
          ),
        );
      }

      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error fetching stock-in order: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.bgDark,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back + Title
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _supplierName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Order info
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _orderStatus == 'Accepted'
                          ? Colors.green.withOpacity(0.2)
                          : AppColors.gold.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _orderStatus == 'Accepted'
                            ? Colors.green
                            : AppColors.gold,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _orderStatus,
                      style: TextStyle(
                        color: _orderStatus == 'Accepted'
                            ? Colors.green
                            : AppColors.gold,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (_orderDate != null) ...[
                    const SizedBox(width: 12),
                    Text(
                      '${_orderDate!.day}/${_orderDate!.month}/${_orderDate!.year}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 20),

              // Items
              Expanded(
                child: _items.isEmpty
                    ? const Center(
                        child: Text(
                          'No items found',
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: AppColors.gold.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Items header
                            const Row(
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: Text(
                                    'Product',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 4,
                                  child: Padding(
                                    padding: EdgeInsets.only(left: 24),
                                    child: Text(
                                      'Batch',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Padding(
                                    padding: EdgeInsets.only(left: 8),
                                    child: Text(
                                      'Qty',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Items list
                            Expanded(
                              child: ListView.builder(
                                itemCount: _items.length,
                                itemBuilder: (_, i) {
                                  final item = _items[i];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.bgDark.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 5,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.productName,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                item.brandName,
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          flex: 4,
                                          child: Text(
                                            item.batchLocation ?? 'No Batch',
                                            style: TextStyle(
                                              color: item.batchLocation != null
                                                  ? AppColors.gold
                                                  : Colors.white54,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              left: 8,
                                            ),
                                            child: Text(
                                              '${item.quantity} ${item.unitName}',
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                color: AppColors.gold,
                                                fontSize: 14,
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
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderItem {
  final String productName;
  final String brandName;
  final String unitName;
  final int quantity;
  final String? batchLocation;

  _OrderItem({
    required this.productName,
    required this.brandName,
    required this.unitName,
    required this.quantity,
    this.batchLocation,
  });
}
