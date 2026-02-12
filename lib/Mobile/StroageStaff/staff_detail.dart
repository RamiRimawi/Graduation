import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: unused_import
import 'staff_home.dart';
import '../../supabase_config.dart';
import 'staff_sync_manager.dart';

class CustomerDetail extends StatefulWidget {
  final String customerName;
  final int customerId;

  const CustomerDetail({
    super.key,
    required this.customerName,
    required this.customerId,
  });

  @override
  State<CustomerDetail> createState() => _CustomerDetailState();
}

class _CustomerDetailState extends State<CustomerDetail> {
  // NEW: حالة الزر (Done أو Send Update)
  bool _saving = false;
  bool _loading = true;
  List<Map<String, dynamic>> products = [];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    try {
      setState(() => _loading = true);
      final prefs = await SharedPreferences.getInstance();
      final String? userIdStr = prefs.getString('current_user_id');
      final int? staffId = userIdStr != null ? int.tryParse(userIdStr) : null;

      if (staffId == null) {
        if (mounted) {
          setState(() {
            products = [];
            _loading = false;
          });
        }
        return;
      }

      // Use sync manager's cache-first strategy
      final fetchedProducts = await StaffSyncManager.instance
          .fetchProductsWithCache(widget.customerId, staffId);

      if (mounted) {
        setState(() {
          products = fetchedProducts;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching products: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  int _allocatedQty(Map<String, dynamic> product) {
    final allocations = List<Map<String, dynamic>>.from(
      product['allocations'] ?? [],
    );
    return allocations.fold<int>(
      0,
      (sum, alloc) => sum + (alloc['prepared_qty'] as int? ?? 0),
    );
  }

  List<Map<String, dynamic>> _normalizeAllocations(
    List<Map<String, dynamic>> allocations,
    int requiredQty,
  ) {
    int remaining = requiredQty;
    final normalized = <Map<String, dynamic>>[];

    for (final alloc in allocations) {
      final available = alloc['available_qty'] as int? ?? remaining;
      if (remaining <= 0) break;
      final take = remaining > available ? available : remaining;
      normalized.add({...alloc, 'prepared_qty': take});
      remaining -= take;
    }

    // If nothing allocated and required > 0, seed an empty allocation to be filled in sheet
    if (normalized.isEmpty && requiredQty > 0 && allocations.isNotEmpty) {
      normalized.add({...allocations.first, 'prepared_qty': 0});
    }

    return normalized;
  }

  String _buildLocationSummary(Map<String, dynamic> product) {
    final allocations = List<Map<String, dynamic>>.from(
      product['allocations'] ?? [],
    );
    if (allocations.isEmpty) return 'No batch selected';

    return allocations
        .map((alloc) {
          final loc = alloc['storage_location'] ?? 'N/A';
          final qty = alloc['prepared_qty'] ?? 0;
          return '$loc • qty($qty)';
        })
        .join('\n');
  }

  Future<List<Map<String, dynamic>>> _fetchAvailableBatches({
    required int productId,
    int? inventoryId,
  }) async {
    // Use sync manager's cache-first strategy
    return await StaffSyncManager.instance.fetchBatchesWithCache(
      productId: productId,
      inventoryId: inventoryId,
    );
  }

  Future<Map<String, dynamic>?> _showBatchPicker({
    required int productId,
    required int? inventoryId,
    required Set<int> excludeBatchIds,
  }) async {
    try {
      final batches = await _fetchAvailableBatches(
        productId: productId,
        inventoryId: inventoryId,
      );

      final filtered = batches.where((b) {
        final bid = b['batch_id'] as int?;
        return bid != null && !excludeBatchIds.contains(bid);
      }).toList();

      if (filtered.isEmpty) {
        _showErrorSnack('No other batches available for this product.');
        return null;
      }

      return await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        backgroundColor: const Color(0xFF2D2D2D),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) {
          return SafeArea(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: filtered.length,
              itemBuilder: (context, idx) {
                final batch = filtered[idx];
                final bid = batch['batch_id'] as int?;
                final qty = batch['quantity'] as int? ?? 0;
                final loc =
                    batch['storage_location_descrption']?.toString() ??
                    'Unknown';
                final inv = batch['inventory_id'] as int?;

                return ListTile(
                  title: Text(
                    'Batch ${bid ?? '-'}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    'Qty: $qty • $loc',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  onTap: () => Navigator.pop(context, {
                    'batch_id': bid,
                    'inventory_id': inv,
                    'storage_location': loc,
                    'available_qty': qty,
                    'prepared_qty': 0,
                  }),
                );
              },
            ),
          );
        },
      );
    } catch (e) {
      _showErrorSnack('Error loading batches: $e');
      return null;
    }
  }

  Future<void> _openAllocationSheet(int index) async {
    final product = products[index];
    final int requiredQty = product['quantity'] as int? ?? 0;
    final int productId = product['product_id'] as int? ?? 0;
    final int? inventoryId = product['inventory_id'] as int?;

    // Create a deep copy to preserve original state
    List<Map<String, dynamic>> allocations =
        (product['allocations'] as List? ?? [])
            .map((alloc) => Map<String, dynamic>.from(alloc as Map))
            .toList();

    // Track validation errors across rebuilds
    Map<int, String?> errors = {};

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF202020),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final total = allocations.fold<int>(
              0,
              (sum, alloc) => sum + (alloc['prepared_qty'] as int? ?? 0),
            );
            final remaining = requiredQty - total;

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white38,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    product['name'] ?? 'Product',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Allocate $requiredQty ${product['unit'] ?? ''}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 320,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: allocations.length,
                      itemBuilder: (context, allocIndex) {
                        final alloc = allocations[allocIndex];
                        final controller = TextEditingController(
                          text: (alloc['prepared_qty'] as int? ?? 0).toString(),
                        );

                        return Card(
                          color: const Color(0xFF2D2D2D),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${alloc['storage_location']} • qty(${alloc['prepared_qty'] ?? 0})',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    allocations.length > 1 && allocIndex > 0
                                        ? IconButton(
                                            onPressed: () {
                                              setModalState(() {
                                                // Return quantity to first batch before deleting
                                                if (allocIndex > 0) {
                                                  final deletedQty =
                                                      allocations[allocIndex]['prepared_qty']
                                                          as int? ??
                                                      0;
                                                  final firstBatchQty =
                                                      allocations[0]['prepared_qty']
                                                          as int? ??
                                                      0;
                                                  allocations[0]['prepared_qty'] =
                                                      firstBatchQty +
                                                      deletedQty;
                                                }
                                                allocations.removeAt(
                                                  allocIndex,
                                                );
                                              });
                                            },
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              color: Colors.white70,
                                            ),
                                          )
                                        : const SizedBox(
                                            width: 48,
                                          ), // Placeholder to maintain layout
                                  ],
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: controller,
                                  keyboardType: TextInputType.number,
                                  enabled:
                                      allocIndex != 0, // Disable first batch
                                  style: TextStyle(
                                    color: allocIndex == 0
                                        ? Colors.white60
                                        : Colors.white,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Qty from this batch',
                                    labelStyle: TextStyle(
                                      color: allocIndex == 0
                                          ? Colors.white38
                                          : Colors.white70,
                                    ),
                                    filled: true,
                                    fillColor: allocIndex == 0
                                        ? const Color(0x20FFFFFF)
                                        : const Color(0x10FFFFFF),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Colors.white38,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFB7A447),
                                        width: 1.5,
                                      ),
                                    ),
                                    disabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Colors.white24,
                                      ),
                                    ),
                                    errorText: errors[allocIndex],
                                    errorStyle: const TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 11,
                                    ),
                                  ),
                                  onChanged: (value) {
                                    final parsed = int.tryParse(value) ?? 0;
                                    setModalState(() {
                                      // Show error if exceeds first batch qty (only for additional batches)
                                      if (allocIndex > 0) {
                                        final firstBatchQty =
                                            allocations[0]['prepared_qty']
                                                as int? ??
                                            0;
                                        if (parsed > firstBatchQty) {
                                          errors[allocIndex] =
                                              'Enter from 0 to $firstBatchQty';
                                        } else {
                                          errors[allocIndex] = null;
                                        }
                                      }

                                      // Store entered value (non-negative)
                                      final newValue = parsed < 0 ? 0 : parsed;

                                      // Update this batch with new value
                                      allocations[allocIndex]['prepared_qty'] =
                                          newValue;

                                      // Auto-calculate first batch as remainder of all other batches
                                      if (allocations.isNotEmpty) {
                                        final totalOthers = allocations
                                            .asMap()
                                            .entries
                                            .where((e) => e.key != 0)
                                            .fold<int>(
                                              0,
                                              (sum, e) =>
                                                  sum +
                                                  (e.value['prepared_qty']
                                                          as int? ??
                                                      0),
                                            );
                                        final firstBatchValue =
                                            requiredQty - totalOthers;
                                        allocations[0]['prepared_qty'] =
                                            firstBatchValue < 0
                                            ? 0
                                            : firstBatchValue;
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final exclude = allocations
                                .map((a) => a['batch_id'] as int? ?? -1)
                                .toSet();

                            final selected = await _showBatchPicker(
                              productId: productId,
                              inventoryId:
                                  null, // Don't filter by inventory - show all available batches
                              excludeBatchIds: exclude,
                            );

                            if (selected != null) {
                              setModalState(() {
                                allocations.add(selected);
                              });
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFB7A447)),
                          ),
                          icon: const Icon(Icons.add, color: Color(0xFFB7A447)),
                          label: const Text(
                            'Add Batch',
                            style: TextStyle(color: Color(0xFFB7A447)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Filter out batches with qty = 0
                            allocations.removeWhere(
                              (alloc) =>
                                  (alloc['prepared_qty'] as int? ?? 0) == 0,
                            );

                            final newTotal = allocations.fold<int>(
                              0,
                              (sum, alloc) =>
                                  sum + (alloc['prepared_qty'] as int? ?? 0),
                            );

                            if (newTotal != requiredQty) {
                              _showErrorSnack(
                                'Allocate full quantity ($newTotal/$requiredQty).',
                              );
                              return;
                            }

                            // Apply changes only when Save is clicked
                            if (mounted) {
                              setState(() {
                                products[index]['allocations'] = allocations;
                              });
                            }
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFB7A447),
                            foregroundColor: const Color(0xFF202020),
                          ),
                          child: const Text(
                            'Save',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showErrorSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _saveUpdates() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? userIdStr = prefs.getString('current_user_id');
      final int? staffId = userIdStr != null ? int.tryParse(userIdStr) : null;

      // Validate all products are properly allocated
      for (final product in products) {
        final requiredQty = product['quantity'] as int? ?? 0;
        final allocations = List<Map<String, dynamic>>.from(
          product['allocations'] ?? [],
        );

        final currentTotal = allocations.fold<int>(
          0,
          (sum, alloc) => sum + (alloc['prepared_qty'] as int? ?? 0),
        );

        final normalized = currentTotal == requiredQty
            ? allocations
            : _normalizeAllocations(allocations, requiredQty);

        products[products.indexOf(product)]['allocations'] = normalized;
        final totalAllocated = normalized.fold<int>(
          0,
          (sum, alloc) => sum + (alloc['prepared_qty'] as int? ?? 0),
        );

        if (totalAllocated != requiredQty) {
          _showErrorSnack(
            'Allocate full quantity for ${product['name']} ($totalAllocated/$requiredQty).',
          );
          setState(() => _saving = false);
          return;
        }
      }

      // Check if online
      if (StaffSyncManager.instance.isOnline) {
        // Process immediately
        await _processSaveUpdates(staffId);
      } else {
        // Queue for later sync
        await StaffSyncManager.instance.queueOrderPreparation(
          customerId: widget.customerId,
          products: products,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error saving updates: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving updates: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _processSaveUpdates(int? staffId) async {
    final prefs = await SharedPreferences.getInstance();
    final staffName = prefs.getString('current_user_name') ?? 'Unknown';
    final now = DateTime.now();

    for (final product in products) {
      final pid = product['product_id'] as int?;
      if (pid == null) continue;

      final requiredQty = product['quantity'] as int? ?? 0;
      final allocations = List<Map<String, dynamic>>.from(
        product['allocations'] ?? [],
      );

      // Check if allocations are already properly distributed (manual adjustments)
      final currentTotal = allocations.fold<int>(
        0,
        (sum, alloc) => sum + (alloc['prepared_qty'] as int? ?? 0),
      );

      final normalized = currentTotal == requiredQty
          ? allocations // Use manual allocations if they sum correctly
          : _normalizeAllocations(
              allocations,
              requiredQty,
            ); // Otherwise normalize

      products[products.indexOf(product)]['allocations'] = normalized;
      final totalAllocated = normalized.fold<int>(
        0,
        (sum, alloc) => sum + (alloc['prepared_qty'] as int? ?? 0),
      );

      if (totalAllocated != requiredQty) {
        if (mounted) {
          _showErrorSnack(
            'Allocate full quantity for ${product['name']} ($totalAllocated/$requiredQty).',
          );
          setState(() => _saving = false);
        }
        return;
      }

      // Remove previous allocations for this staff/product and recreate
      await supabase
          .from('customer_order_inventory')
          .delete()
          .eq('customer_order_id', widget.customerId)
          .eq('product_id', pid)
          .eq('prepared_by', staffId ?? 0);

      for (final alloc in normalized) {
        final picked = alloc['prepared_qty'] as int? ?? 0;
        if (picked <= 0) continue;

        await supabase.from('customer_order_inventory').insert({
          'customer_order_id': widget.customerId,
          'product_id': pid,
          'inventory_id': alloc['inventory_id'],
          'quantity': picked,
          'prepared_by': staffId,
          'batch_id': alloc['batch_id'],
          'prepared_quantity': picked,
          'last_action_by': staffName ?? 'Unknown',
          'last_action_time': now.toIso8601String(),
        });
      }

      // Update quantity in customer_order_description
      await supabase
          .from('customer_order_description')
          .update({
            'last_action_by': staffName ?? 'Unknown',
            'last_action_time': now.toIso8601String(),
          })
          .eq('customer_order_id', widget.customerId)
          .eq('product_id', pid);
    }

    // Check if all items in this order are prepared by their respective staff
    final List<dynamic> allInventoryItems = await supabase
        .from('customer_order_inventory')
        .select('prepared_quantity')
        .eq('customer_order_id', widget.customerId);

    // Check if all items have prepared_quantity set
    bool allItemsPrepared = allInventoryItems.every(
      (item) => item['prepared_quantity'] != null,
    );

    // Only mark order as Prepared if ALL items are prepared
    if (allItemsPrepared) {
      await supabase
          .from('customer_order')
          .update({
            'order_status': 'Prepared',
            'last_action_by': staffName ?? 'Unknown',
            'last_action_time': now.toIso8601String(),
          })
          .eq('customer_order_id', widget.customerId);
    }
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text('Confirm', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to mark this order as prepared?',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _saveUpdates();
            },
            child: const Text(
              'Yes',
              style: TextStyle(color: Color(0xFFB7A447)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF202020),
      body: SafeArea(
        child: Column(
          children: [
            //========== TOP BAR (Back + Name) ==========
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  // دائرة السهم
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D2D2D),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFFB7A447),
                        size: 30,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // اسم الزبون
                  Expanded(
                    child: Text(
                      widget.customerName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            //========== HEADER ROW ==========
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: const [
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Product Name',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Brand',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Quantity',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 16, 8),
              child: Container(height: 1, color: const Color(0xFFFFFFFF)),
            ),

            //========== LIST OF PRODUCTS ==========
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFFE14D),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        final requiredQty = product['quantity'] as int? ?? 0;
                        final allocatedQty = _allocatedQty(product);
                        final unitLabel = product['unit'] ?? 'Unit';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF2D2D2D),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.25),
                                  blurRadius: 1,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // TOP SECTION: Product Name, Brand, Quantity (matching header layout)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 14,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      // Product Name
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          product['name'],
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 2,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      // Brand
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          product['brand'],
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      // Quantity (box + unit)
                                      Flexible(
                                        flex: 2,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Flexible(
                                              child: Container(
                                                constraints:
                                                    const BoxConstraints(
                                                      minWidth: 40,
                                                      maxWidth: 60,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFFB7A447,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                alignment: Alignment.center,
                                                child: TextFormField(
                                                  initialValue: '$requiredQty',
                                                  keyboardType:
                                                      TextInputType.number,
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    color: Color(0xFF202020),
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  decoration:
                                                      const InputDecoration(
                                                        border:
                                                            InputBorder.none,
                                                        contentPadding:
                                                            EdgeInsets.symmetric(
                                                              vertical: 6,
                                                              horizontal: 6,
                                                            ),
                                                        isDense: true,
                                                      ),
                                                  onChanged: (value) {
                                                    final newQty = int.tryParse(
                                                      value,
                                                    );
                                                    if (newQty != null &&
                                                        newQty > 0) {
                                                      products[index]['quantity'] =
                                                          newQty;
                                                      final allocations =
                                                          List<
                                                            Map<String, dynamic>
                                                          >.from(
                                                            product['allocations'] ??
                                                                [],
                                                          );
                                                      products[index]['allocations'] =
                                                          _normalizeAllocations(
                                                            allocations,
                                                            newQty,
                                                          );
                                                    }
                                                  },
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                unitLabel,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // BOTTOM SECTION: Storage Location (Full Width)
                                GestureDetector(
                                  onTap: () => _openAllocationSheet(index),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xB8894D26),
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(20),
                                        bottomRight: Radius.circular(20),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _buildLocationSummary(product),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 2,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Tap to adjust batches',
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
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

            //========== DONE / SEND UPDATE BUTTON ==========
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _showConfirmationDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB7A447),
                    foregroundColor: const Color(0xFF202020),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        ' Done ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_right_alt,
                        size: 50,
                        color: Colors.black,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
