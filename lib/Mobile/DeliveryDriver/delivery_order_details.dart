import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'route_map_delivery.dart';
import 'signature_confirmation.dart';

class DeliveryOrderDetails extends StatefulWidget {
  final int orderId;
  final String customerName;
  final bool readOnly;
  final int? deliveryDriverId;

  const DeliveryOrderDetails({
    super.key,
    required this.orderId,
    required this.customerName,
    this.readOnly = false,
    this.deliveryDriverId,
  });

  @override
  State<DeliveryOrderDetails> createState() => _DeliveryOrderDetailsState();
}

class _DeliveryOrderDetailsState extends State<DeliveryOrderDetails> {
  bool _loading = true;
  List<_InventoryGroup> _groups = [];
  Map<int, int> _deliveredQty = {}; // productId -> delivered qty
  String? _address;
  double? _lat;
  double? _lng;
  String? _deliveredDate;

  @override
  void initState() {
    super.initState();
    _fetchOrderDetails();
  }

  String _formatDeliveryDate(String? dateString) {
    if (dateString == null) return '';
    
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inMinutes < 1) {
        return 'now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes} minutes ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} hours ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateString;
    }
  }

  Future<void> _fetchOrderDetails() async {
    try {
      final supabase = Supabase.instance.client;

      // Fetch customer info for routing (address + coords)
      final orderInfo = await supabase
          .from('customer_order')
          .select('customer:customer_id(name, address, latitude_location, longitude_location), customer_order_description(product_id, delivered_quantity, delivered_date)')
          .eq('customer_order_id', widget.orderId)
          .single();

      final customer = orderInfo['customer'] as Map<String, dynamic>?;
      _address = customer?['address'] as String?;
      _lat = (customer?['latitude_location'] as num?)?.toDouble();
      _lng = (customer?['longitude_location'] as num?)?.toDouble();

      // Prefill delivered quantities if exist
      final desc = orderInfo['customer_order_description'] as List<dynamic>? ?? [];
      for (final d in desc) {
        final pid = d['product_id'] as int?;
        final dq = d['delivered_quantity'] as int?;
        if (pid != null && dq != null) {
          _deliveredQty[pid] = dq;
        }
        // Get delivered date from first item
        if (_deliveredDate == null) {
          _deliveredDate = d['delivered_date'] as String?;
        }
      }

      // Fetch order inventory (products with inventory)
      final inventoryResponse = await supabase
          .from('customer_order_inventory')
          .select('*')
          .eq('customer_order_id', widget.orderId);

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

      // Group by inventory
      final Map<int, _InventoryGroup> groupsByInventory = {};

      for (final row in inventoryResponse) {
        final productId = row['product_id'] as int?;
        final inventoryId = row['inventory_id'] as int?;

        if (productId == null || inventoryId == null) continue;

        final product = productMap[productId];
        final inventory = inventoryMap[inventoryId];

        if (product == null || inventory == null) continue;

        final inventoryName =
            inventory['inventory_name'] as String? ?? 'Unknown Warehouse';

        // Create or get group for this inventory
        if (!groupsByInventory.containsKey(inventoryId)) {
          groupsByInventory[inventoryId] = _InventoryGroup(
            inventoryName: inventoryName,
            items: [],
          );
        }

        // Add item to this group
        final brandId = product['brand_id'] as int?;
        final unitId = product['unit_id'] as int?;
        final brand = brandId != null ? brandMap[brandId] : null;
        final unit = unitId != null ? unitMap[unitId] : null;

        final qty = row['quantity'] as int? ?? 0;
        final pid = product['product_id'] as int;
        // Initialize delivered qty default to ordered qty if not preset
        _deliveredQty.putIfAbsent(pid, () => qty);

        groupsByInventory[inventoryId]!.items.add(
          _OrderItemData(
            productId: pid,
            productName: product['name'] as String? ?? 'Unknown',
            brand: brand?['name'] as String? ?? 'Unknown',
            unit: unit?['unit_name'] as String? ?? 'Unit',
            quantity: qty,
          ),
        );
      }

      setState(() {
        _groups = groupsByInventory.values.toList();
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error fetching delivery order details: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: const Color(0xFF202020),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFFB7A447)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF202020),
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
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: widget.customerName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (widget.readOnly && _deliveredDate != null)
                            TextSpan(
                              text: ' (Delivered: ${_formatDeliveryDate(_deliveredDate)})',
                              style: const TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Inventory groups
              Expanded(
                child: _groups.isEmpty
                    ? const Center(
                        child: Text(
                          'No items found',
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _groups.length,
                        itemBuilder: (_, i) {
                          final group = _groups[i];
                          return _InventoryCard(
                            group: group,
                            readOnly: widget.readOnly,
                            deliveredQty: _deliveredQty,
                            onQtyChange: (pid, val) {
                              setState(() => _deliveredQty[pid] = val);
                            },
                          );
                        },
                      ),
              ),

              if (!widget.readOnly) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: _openRoute,
                        child: const Text('View Route on Map'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB7A447),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: const Color(0xFF2D2D2D),
                              title: const Text(
                                'Confirm Delivery',
                                style: TextStyle(color: Colors.white),
                              ),
                              content: const Text(
                                'Are you sure you want to confirm this delivery?',
                                style: TextStyle(color: Colors.white70),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _confirmDelivery();
                                  },
                                  child: const Text(
                                    'Confirm',
                                    style: TextStyle(color: Color(0xFFB7A447)),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        child: const Text('Confirm Delivery'),
                      ),
                    ),
                    
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openRoute() async {
    if (_lat == null || _lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer location not available')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RouteMapDeleviry(
          customerName: widget.customerName,
          locationLabel: 'Destination',
          address: _address ?? '',
          latitude: _lat!,
          longitude: _lng!,
          orderId: widget.orderId,
          deliveryDriverId: widget.deliveryDriverId ?? 0,
        ),
      ),
    );
  }

  Future<void> _confirmDelivery() async {
    // Build products list from delivered quantities
    final productsList = _groups.expand((group) {
      return group.items.map((item) {
        return {
          'product_id': item.productId,
          'name': item.productName,
          'quantity': _deliveredQty[item.productId] ?? item.quantity,
          'brand': item.brand,
          'unit': item.unit,
        };
      });
    }).toList();

    // Show signature confirmation dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => SignatureConfirmation(
        customerName: widget.customerName,
        customerId: 0, // Not needed for this flow
        orderId: widget.orderId,
        products: productsList,
        deliveredQuantities: _deliveredQty,
      ),
    );
  }
}

class _InventoryCard extends StatelessWidget {
  final _InventoryGroup group;
  final bool readOnly;
  final Map<int, int> deliveredQty;
  final void Function(int productId, int newValue) onQtyChange;

  const _InventoryCard({
    required this.group,
    required this.readOnly,
    required this.deliveredQty,
    required this.onQtyChange,
  });

  // Insert a line break after the first two words to keep names readable on narrow screens.
  String _formatProductName(String name) {
    final parts = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length <= 2) return name;
    final firstLine = parts.take(2).join(' ');
    final rest = parts.skip(2).join(' ');
    return '$firstLine\n$rest';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFB7A447).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Warehouse name
          Row(
            children: [
              const Icon(
                Icons.warehouse,
                color: Color(0xFFB7A447),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                group.inventoryName,
                style: const TextStyle(
                  color: Color(0xFFB7A447),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
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
                    'Brand',
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
          ...group.items.map((item) {
            final displayName = _formatProductName(item.productName);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF202020).withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Text(
                      displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Text(
                      item.brand,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: readOnly
                          ? Text(
                              '${deliveredQty[item.productId] ?? item.quantity} ${item.unit}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFFB7A447),
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    final currentQty = deliveredQty[item.productId] ?? item.quantity;
                                    final controller = TextEditingController(
                                      text: currentQty.toString(),
                                    );

                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          backgroundColor: const Color(0xFF2D2D2D),
                                          title: const Text(
                                            'Edit Quantity',
                                            style: TextStyle(color: Colors.white),
                                          ),
                                          content: TextField(
                                            controller: controller,
                                            keyboardType: TextInputType.number,
                                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                            style: const TextStyle(color: Colors.white),
                                            decoration: const InputDecoration(
                                              hintText: 'Enter quantity',
                                              hintStyle: TextStyle(color: Colors.white70),
                                              enabledBorder: UnderlineInputBorder(
                                                borderSide: BorderSide(color: Colors.white38),
                                              ),
                                              focusedBorder: UnderlineInputBorder(
                                                borderSide: BorderSide(color: Color(0xFFB7A447)),
                                              ),
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text(
                                                'Cancel',
                                                style: TextStyle(color: Colors.white70),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                final value = int.tryParse(controller.text);
                                                if (value != null) {
                                                  onQtyChange(item.productId, value);
                                                }
                                                Navigator.pop(context);
                                              },
                                              child: const Text(
                                                'Save',
                                                style: TextStyle(color: Color(0xFFB7A447)),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFB7A447),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${deliveredQty[item.productId] ?? item.quantity}',
                                      style: const TextStyle(
                                        color: Color(0xFF202020),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  item.unit,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
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

class _InventoryGroup {
  final String inventoryName;
  final List<_OrderItemData> items;

  _InventoryGroup({
    required this.inventoryName,
    required this.items,
  });
}

class _OrderItemData {
  final int productId;
  final String productName;
  final String brand;
  final String unit;
  final int quantity;

  _OrderItemData({
    required this.productId,
    required this.productName,
    required this.brand,
    required this.unit,
    required this.quantity,
  });
}
