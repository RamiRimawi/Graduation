import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'order_item.dart';
import 'manager_theme.dart';

class DeliveryOrderDetailsPage extends StatefulWidget {
  final int orderId;

  const DeliveryOrderDetailsPage({super.key, required this.orderId});

  @override
  State<DeliveryOrderDetailsPage> createState() =>
      _DeliveryOrderDetailsPageState();
}

class _DeliveryOrderDetailsPageState extends State<DeliveryOrderDetailsPage> {
  String _customerName = '';
  List<_OrderPart> _parts = [];
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
        if (mounted) {
          setState(() {
            _customerName = customerName;
            _loading = false;
          });
        }
        return;
      }

      // Fetch product details
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

      final brandsResponse = brandIds.isNotEmpty
          ? await supabase
                .from('brand')
                .select('brand_id, name')
                .inFilter('brand_id', brandIds)
          : [];

      final brandMap = {for (var b in brandsResponse) b['brand_id'] as int: b};

      // Fetch unit details
      final unitIds = productsResponse
          .map((p) => p['unit_id'] as int?)
          .where((id) => id != null)
          .toSet()
          .toList();

      final unitsResponse = unitIds.isNotEmpty
          ? await supabase
                .from('unit')
                .select('unit_id, unit_name')
                .inFilter('unit_id', unitIds)
          : [];

      final unitMap = {for (var u in unitsResponse) u['unit_id'] as int: u};

      // Fetch staff details
      final staffIds = inventoryResponse
          .map((row) => row['prepared_by'] as int?)
          .where((id) => id != null)
          .toSet()
          .toList();

      final staffResponse = staffIds.isNotEmpty
          ? await supabase
                .from('storage_staff')
                .select(
                  'storage_staff_id, name, accounts!storage_staff_storage_staff_id_fkey(profile_image)',
                )
                .inFilter('storage_staff_id', staffIds)
          : [];

      final staffMap = {
        for (var s in staffResponse) s['storage_staff_id'] as int: s,
      };

      // Fetch inventory details
      final inventoryIds = inventoryResponse
          .map((row) => row['inventory_id'] as int?)
          .where((id) => id != null)
          .toSet()
          .toList();

      final inventoriesResponse = inventoryIds.isNotEmpty
          ? await supabase
                .from('inventory')
                .select('inventory_id, inventory_name')
                .inFilter('inventory_id', inventoryIds)
          : [];

      final inventoryMap = {
        for (var inv in inventoriesResponse) inv['inventory_id'] as int: inv,
      };

      // Fetch batch details
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

      // Group by staff
      final Map<int, _OrderPart> partsByStaff = {};

      for (final row in inventoryResponse) {
        final productId = row['product_id'] as int?;
        final staffId = row['prepared_by'] as int?;
        final batchId = row['batch_id'] as int?;
        final inventoryId = row['inventory_id'] as int?;

        if (productId == null) continue;

        final product = productMap[productId];
        if (product == null) continue;

        // Handle items without staff assignment
        final effectiveStaffId = staffId ?? -1;
        final staff = staffId != null ? staffMap[staffId] : null;
        final inventory = inventoryId != null
            ? inventoryMap[inventoryId]
            : null;
        final batch = batchId != null ? batchMap[batchId] : null;

        final staffName = staff?['name'] as String? ?? 'Unassigned';
        String? staffImage;
        if (staff != null) {
          final account = staff['accounts'];
          if (account is List && account.isNotEmpty) {
            staffImage = account.first['profile_image'] as String?;
          } else if (account is Map<String, dynamic>) {
            staffImage = account['profile_image'] as String?;
          }
        }

        final inventoryName =
            inventory?['inventory_name'] as String? ?? 'Unknown';
        final storageLocation =
            batch?['storage_location_descrption'] as String?;

        // Create or get part for this staff
        if (!partsByStaff.containsKey(effectiveStaffId)) {
          partsByStaff[effectiveStaffId] = _OrderPart(
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

        // Use prepared_quantity if available, otherwise quantity
        final qty =
            (row['prepared_quantity'] as int?) ??
            (row['quantity'] as int? ?? 0);

        partsByStaff[effectiveStaffId]!.items.add(
          _OrderItemWithBatch(
            item: OrderItem(
              product['product_id'] as int,
              product['name'] as String? ?? 'Unknown',
              brand?['name'] as String? ?? 'Unknown',
              unit?['unit_name'] as String? ?? 'Unit',
              qty,
            ),
            batchNumber: storageLocation,
          ),
        );
      }

      if (mounted) {
        setState(() {
          _customerName = customerName;
          _parts = partsByStaff.values.toList();
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching delivery order details: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
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
                    : null,
                backgroundColor: AppColors.card,
                child: part.staffImage == null || part.staffImage!.isEmpty
                    ? Text(
                        part.staffName.isNotEmpty
                            ? part.staffName.substring(0, 1).toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
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
