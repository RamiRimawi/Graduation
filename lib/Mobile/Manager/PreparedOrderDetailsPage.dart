import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../manager_theme.dart';
import 'order_item.dart';
import 'SelectDeliveryDriverSheet.dart';
import 'order_service.dart';

class PreparedOrderDetailsPage extends StatefulWidget {
  final int orderId;

  const PreparedOrderDetailsPage({super.key, required this.orderId});

  @override
  State<PreparedOrderDetailsPage> createState() =>
      _PreparedOrderDetailsPageState();
}

class _PreparedOrderDetailsPageState extends State<PreparedOrderDetailsPage> {
  bool _loading = true;
  String _customerName = '';
  List<_OrderPart> _parts = [];

  @override
  void initState() {
    super.initState();
    _fetchOrderDetails();
  }

  Future<void> _fetchOrderDetails() async {
    try {
      final supabase = Supabase.instance.client;

      // Fetch order with customer
      final orderResponse = await supabase
          .from('customer_order')
          .select('customer:customer_id(name)')
          .eq('customer_order_id', widget.orderId)
          .single();

      _customerName = orderResponse['customer']['name'] as String? ?? 'Unknown';

      // Fetch order inventory (products with staff, batch, inventory)
      final inventoryResponse = await supabase
          .from('customer_order_inventory')
          .select('*')
          .eq('customer_order_id', widget.orderId);

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

      // Fetch staff details separately
      final staffIds = inventoryResponse
          .map((row) => row['prepared_by'] as int?)
          .where((id) => id != null)
          .toSet()
          .toList();

      final staffResponse = await supabase
          .from('storage_staff')
          .select(
            'storage_staff_id, name, accounts!storage_staff_storage_staff_id_fkey(profile_image)',
          )
          .inFilter('storage_staff_id', staffIds);

      final staffMap = {
        for (var s in staffResponse) s['storage_staff_id'] as int: s,
      };

      // Fetch inventory details to get inventory names
      final inventoryIds = inventoryResponse
          .map((row) => row['inventory_id'] as int?)
          .where((id) => id != null)
          .toSet()
          .toList();

      final inventoriesResponse = await supabase
          .from('inventory')
          .select('inventory_id, inventory_name')
          .inFilter('inventory_id', inventoryIds);

      final inventoryMap = {
        for (var inv in inventoriesResponse) inv['inventory_id'] as int: inv,
      };

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

      // Group by staff (each staff = one part)
      final Map<int, _OrderPart> partsByStaff = {};

      for (final row in inventoryResponse) {
        final productId = row['product_id'] as int?;
        final staffId = row['prepared_by'] as int?;
        final batchId = row['batch_id'] as int?;
        final inventoryId = row['inventory_id'] as int?;

        if (productId == null || staffId == null) continue;

        final product = productMap[productId];
        final staff = staffMap[staffId];
        final inventory = inventoryId != null
            ? inventoryMap[inventoryId]
            : null;
        final batch = batchId != null ? batchMap[batchId] : null;

        if (product == null || staff == null) continue;

        final staffName = staff['name'] as String? ?? 'Unknown';

        String? staffImage;
        final account = staff['accounts'];
        if (account is List && account.isNotEmpty) {
          staffImage = account.first['profile_image'] as String?;
        } else if (account is Map<String, dynamic>) {
          staffImage = account['profile_image'] as String?;
        }

        // Inventory name for staff header
        final inventoryName =
            inventory?['inventory_name'] as String? ?? 'Unknown';

        // Storage location for each item row
        final storageLocation =
            batch?['storage_location_descrption'] as String?;

        // Create or get part for this staff
        if (!partsByStaff.containsKey(staffId)) {
          partsByStaff[staffId] = _OrderPart(
            staffName: staffName,
            staffImage: staffImage,
            inventoryLocation: inventoryName,
            items: [],
          );
        }

        // Add item to this part
        final brandId = product['brand_id'] as int?;
        final unitId = product['unit_id'] as int?;
        final brand = brandId != null ? brandMap[brandId] : null;
        final unit = unitId != null ? unitMap[unitId] : null;

        partsByStaff[staffId]!.items.add(
          _OrderItemWithBatch(
            item: OrderItem(
              product['product_id'] as int,
              product['name'] as String? ?? 'Unknown',
              brand?['name'] as String? ?? 'Unknown',
              unit?['unit_name'] as String? ?? 'Unit',
              row['quantity'] as int? ?? 0,
            ),
            batchNumber: storageLocation,
          ),
        );
      }

      setState(() {
        _parts = partsByStaff.values.toList();
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error fetching prepared order: $e');
      setState(() => _loading = false);
    }
  }

  void _openDriverSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SelectDeliveryDriverSheet(
        onSelected: (driverId, driverName) async {
          // Close the sheet first
          Navigator.of(context).pop();

          // Assign driver to order
          final ok = await OrderService.assignDeliveryDriver(
            orderId: widget.orderId,
            driverId: driverId,
          );

          // Show feedback if still mounted
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  ok ? "Sent to $driverName" : "Failed to assign $driverName",
                ),
              ),
            );
            // Return to previous page with result
            Navigator.of(context).pop(ok);
          }
        },
      ),
    );
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

              // Parts
              Expanded(
                child: _parts.isEmpty
                    ? const Center(
                        child: Text(
                          'No items found',
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _parts.length,
                        itemBuilder: (_, i) {
                          final part = _parts[i];
                          return _PartCard(
                            part: part,
                            partIndex: i,
                            totalParts: _parts.length,
                          );
                        },
                      ),
              ),

              const SizedBox(height: 16),

              // Send to Delivery Button
              GestureDetector(
                onTap: () => _openDriverSelector(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.gold, AppColors.yellow],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_shipping, color: Colors.white, size: 22),
                      SizedBox(width: 10),
                      Text(
                        'Send to Delivery',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
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

class _PartCard extends StatelessWidget {
  final _OrderPart part;
  final int partIndex;
  final int totalParts;

  const _PartCard({
    required this.part,
    required this.partIndex,
    required this.totalParts,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gold.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Part header (if split)
          if (totalParts > 1) ...[
            Text(
              'Part ${partIndex + 1}',
              style: const TextStyle(
                color: AppColors.gold,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Staff info
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage:
                    part.staffImage != null && part.staffImage!.isNotEmpty
                    ? NetworkImage(part.staffImage!)
                    : const AssetImage('assets/images/Logo.png')
                          as ImageProvider,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Prepared By:',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      part.staffName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      part.inventoryLocation,
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Container(height: 1, color: Colors.white24),
          const SizedBox(height: 12),

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

          // Items
          ...part.items.map((itemWithBatch) {
            final item = itemWithBatch.item;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.bgDark.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.brand,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 4,
                    child: Text(
                      itemWithBatch.batchNumber ?? 'No Batch',
                      style: TextStyle(
                        color: itemWithBatch.batchNumber != null
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
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        '${item.qty} ${item.unit}',
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
          }),
        ],
      ),
    );
  }
}

class _OrderPart {
  final String staffName;
  final String? staffImage;
  final String inventoryLocation;
  final List<_OrderItemWithBatch> items;

  _OrderPart({
    required this.staffName,
    this.staffImage,
    required this.inventoryLocation,
    required this.items,
  });
}

class _OrderItemWithBatch {
  final OrderItem item;
  final String? batchNumber;

  _OrderItemWithBatch({required this.item, this.batchNumber});
}
