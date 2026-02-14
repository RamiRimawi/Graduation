import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'manager_theme.dart';
import 'SelectStaffSheet.dart';
import 'SelectBatchSheet.dart';
import 'order_service.dart';
import 'order_item.dart';
import 'OrderSplitPage.dart';

class OrderDetailsPage extends StatefulWidget {
  final int orderId;

  const OrderDetailsPage({super.key, required this.orderId});

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  // Order data state
  late Future<OrderData?> _orderDataFuture;
  OrderData? _orderData;

  // Staff selection for non-split order
  int? _selectedStaffId;
  int? _selectedInventoryId;
  String? _selectedStaffName;

  // Batch selections per item (index -> batch)
  final Map<int, int?> _selectedBatchIds = {};
  // ignore: unused_field
  final Map<int, String> _selectedBatchDisplays = {};

  // Track if quantities were modified
  bool _quantitiesModified = false;
  // Keep original quantities to detect changes (productId -> qty)
  final Map<int, int> _originalQuantities = {};

  @override
  void initState() {
    super.initState();
    _orderDataFuture = OrderService.fetchOrderDetails(widget.orderId);
  }

  void _openOrderConfirmationModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _OrderConfirmationModal(
        orderId: widget.orderId,
        orderData: _orderData!,
        onConfirm: (staffId, inventoryId, selectedBatchIds) {
          setState(() {
            _selectedStaffId = staffId;
            _selectedInventoryId = inventoryId;
            _selectedBatchIds.clear();
            _selectedBatchIds.addAll(selectedBatchIds);
          });
          _sendNonSplitOrder();
        },
      ),
    );
  }

  void _openActionSelectorModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ActionSelectorModal(
        onNormalSend: _openOrderConfirmationModal,
        onSendToAccountant: _sendUpdateToAccountant,
      ),
    );
  }

  Future<void> _sendUpdateToAccountant() async {
    if (_orderData == null) return;

    // Prepare map of products that were modified by manager
    final Map<int, int> modified = {};
    for (final item in _orderData!.items) {
      final orig = _originalQuantities[item.productId];
      if (orig == null) continue;
      if (item.qty != orig) modified[item.productId] = item.qty;
    }

    if (modified.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No quantity changes to send to accountant'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final TextEditingController descCtrl = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Send update to Accountant'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Put description field above the confirmation message
            const SizedBox(height: 6),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Update Description',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: descCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.gold),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Are you sure you want to send updated quantities to accountant?',
            ),
          ],
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(foregroundColor: AppColors.gold),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Call service to apply updates
    final success = await OrderService.sendUpdateToAccountant(
      orderId: widget.orderId,
      updatedQuantities: modified,
      updateDescription: descCtrl.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order update sent to accountant for review'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send update. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendNonSplitOrder() async {
    if (_orderData == null ||
        _selectedStaffId == null ||
        _selectedInventoryId == null) {
      return;
    }

    final itemsMap = <int, int>{};
    final batchMap = <int, int?>{};

    for (int i = 0; i < _orderData!.items.length; i++) {
      final item = _orderData!.items[i];
      itemsMap[item.productId] = item.qty;
      batchMap[item.productId] = _selectedBatchIds[i];
    }

    final splitsData = [
      {
        'staffId': _selectedStaffId!,
        'inventoryId': _selectedInventoryId!,
        'items': itemsMap,
        'batches': batchMap,
      },
    ];

    final success = await OrderService.saveSplitOrder(
      orderId: widget.orderId,
      splits: splitsData,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order sent to $_selectedStaffName successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true); // Return true to indicate success
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send order. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openSplitPage() async {
    if (_orderData == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderSplitPage(
          orderId: widget.orderId,
          customerName: _orderData!.customerName,
          items: _orderData!.items,
        ),
      ),
    );

    // If split was successful, close this page and return success
    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<OrderData?>(
      future: _orderDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: AppColors.bgDark,
            body: const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            ),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return Scaffold(
            backgroundColor: AppColors.bgDark,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to load order',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }

        _orderData = snapshot.data;
        // Initialize original quantities to detect manager edits
        if (_orderData != null && _originalQuantities.isEmpty) {
          for (final it in _orderData!.items) {
            _originalQuantities[it.productId] = it.qty;
          }
        }
        return _buildOrderDetailsUI();
      },
    );
  }

  Widget _buildOrderDetailsUI() {
    final customerName = _orderData?.customerName ?? 'Unknown';
    final items = _orderData?.items ?? [];

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    customerName,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              const Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Text(
                      'Product Name',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Brand',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
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
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),
              Container(height: 1, color: Colors.white24),
              const SizedBox(height: 12),

              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final item = items[i];
                    final originalQty = item.qty; // Store original quantity
                    final controller = TextEditingController(
                      text: item.qty.toString(),
                    );

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                flex: 5,
                                child: Text(
                                  item.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
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
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.card,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFB7A447),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      alignment: Alignment.center,
                                      child: TextField(
                                        controller: controller,
                                        onChanged: (v) {
                                          if (v.isNotEmpty) {
                                            final newQty =
                                                int.tryParse(v) ?? item.qty;
                                            if (newQty != originalQty) {
                                              setState(() {
                                                item.qty = newQty;
                                                _quantitiesModified = true;
                                              });
                                            } else {
                                              setState(() => item.qty = newQty);
                                            }
                                          }
                                        },
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                        ),
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                        ],
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          isCollapsed: true,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      item.unit,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),

              // SPLIT BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _openSplitPage,
                  icon: const Icon(
                    Icons.call_split,
                    color: AppColors.gold,
                    size: 20,
                  ),
                  label: const Text(
                    'Split the Order',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: AppColors.gold,
                    side: const BorderSide(color: AppColors.gold, width: 2),
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // SEND BUTTON
              CustomSendButton(
                text: 's  e  n  d',
                onTap: _quantitiesModified
                    ? _openActionSelectorModal
                    : _openOrderConfirmationModal,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderConfirmationModal extends StatefulWidget {
  final int orderId;
  final OrderData orderData;
  final Function(int, int, Map<int, int?>) onConfirm;

  const _OrderConfirmationModal({
    required this.orderId,
    required this.orderData,
    required this.onConfirm,
  });

  @override
  State<_OrderConfirmationModal> createState() =>
      _OrderConfirmationModalState();
}

class _OrderConfirmationModalState extends State<_OrderConfirmationModal> {
  final List<_SplitAssignment> _splits = [];
  bool _showOrderDetails = false;
  bool _showValidationErrors = false;

  @override
  void initState() {
    super.initState();
    // Initialize with Part 1 containing all items
    _splits.add(_SplitAssignment());
    for (int i = 0; i < widget.orderData.items.length; i++) {
      _splits[0].quantitiesByItem[i] = widget.orderData.items[i].qty;
    }
  }

  void _addSplit() {
    setState(() => _splits.add(_SplitAssignment()));
  }

  void _removeSplit(int index) {
    if (index == 0) return; // Can't remove Part 1
    setState(() {
      final split = _splits[index];
      // Return all items from this part to Part 1
      split.quantitiesByItem.forEach((itemIndex, qty) {
        final part1CurrentQty = _splits[0].quantitiesByItem[itemIndex] ?? 0;
        _splits[0].quantitiesByItem[itemIndex] = part1CurrentQty + qty;
      });
      _splits.removeAt(index);
    });
  }

  void _pickStaffForSplit(int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Wrap(
        children: [
          SelectStaffSheet(
            onSelected: (staffId, inventoryId, displayName) {
              Navigator.pop(context);
              setState(() {
                _splits[index].staffId = staffId;
                _splits[index].inventoryId = inventoryId;
                _splits[index].staffName = displayName;
                // Clear batch selections for this part when staff changes
                _splits[index].batchIdByItem.clear();
                _splits[index].batchDisplayByItem.clear();
              });
              // Auto-select batches for this part
              _autoSelectBatchesForPart(index);
            },
            preSelectedStaffName: _splits[index].staffName,
          ),
        ],
      ),
    );
  }

  Future<void> _autoSelectBatchesForPart(int partIndex) async {
    final split = _splits[partIndex];
    if (split.inventoryId == null) return;

    for (final entry in split.quantitiesByItem.entries) {
      final itemIndex = entry.key;
      final requiredQty = entry.value;
      if (requiredQty <= 0) continue;

      final item = widget.orderData.items[itemIndex];
      await _autoSelectBatchForItem(
        partIndex,
        itemIndex,
        item.productId,
        requiredQty,
      );
    }
  }

  Future<void> _autoSelectBatchForItem(
    int partIndex,
    int itemIndex,
    int productId,
    int requiredQty,
  ) async {
    try {
      final split = _splits[partIndex];
      if (split.inventoryId == null) return;

      final supabase = Supabase.instance.client;
      final now = DateTime.now();

      // Fetch batches for this product and inventory
      final response = await supabase
          .from('batch')
          .select(
            'batch_id, quantity, storage_location_descrption, production_date, expiry_date',
          )
          .eq('product_id', productId)
          .eq('inventory_id', split.inventoryId!)
          .order('batch_id');

      final batches = List<Map<String, dynamic>>.from(response);

      // Filter suitable batches
      final suitableBatches = batches.where((batch) {
        final quantity = batch['quantity'] as int;
        if (quantity < requiredQty) return false;

        final expiryDateStr = batch['expiry_date'] as String?;
        if (expiryDateStr != null) {
          final expiryDate = DateTime.parse(expiryDateStr);
          if (expiryDate.isBefore(now)) return false;
        }
        return true;
      }).toList();

      if (suitableBatches.isEmpty) return;

      // Sort by production_date (oldest first)
      suitableBatches.sort((a, b) {
        final aDateStr = a['production_date'] as String?;
        final bDateStr = b['production_date'] as String?;

        if (aDateStr != null && bDateStr == null) return -1;
        if (aDateStr == null && bDateStr != null) return 1;

        if (aDateStr != null && bDateStr != null) {
          final aDate = DateTime.parse(aDateStr);
          final bDate = DateTime.parse(bDateStr);
          return aDate.compareTo(bDate);
        }
        return 0;
      });

      // Select the first suitable batch
      final selectedBatch = suitableBatches.first;
      final batchId = selectedBatch['batch_id'] as int;
      final quantity = selectedBatch['quantity'] as int;
      final location =
          selectedBatch['storage_location_descrption'] as String? ??
          'Unknown Location';
      final displayText = 'Batch #$batchId - $location (Qty: $quantity)';

      setState(() {
        _splits[partIndex].batchIdByItem[itemIndex] = batchId;
        _splits[partIndex].batchDisplayByItem[itemIndex] = displayText;
      });
    } catch (e) {
      debugPrint(
        'Error auto-selecting batch for part $partIndex item $itemIndex: $e',
      );
    }
  }

  void _onQuantityChanged(int partIndex, int itemIndex, int newQty) {
    if (partIndex == 0) return; // Can't edit Part 1 quantities

    setState(() {
      final currentQty = _splits[partIndex].quantitiesByItem[itemIndex] ?? 0;
      final difference = newQty - currentQty;

      final part1Qty = _splits[0].quantitiesByItem[itemIndex] ?? 0;
      final totalAvailable = part1Qty + currentQty;

      if (newQty < 0 || newQty > totalAvailable) return;

      _splits[partIndex].quantitiesByItem[itemIndex] = newQty;

      final newPart1Qty = part1Qty - difference;
      if (newPart1Qty <= 0) {
        _splits[0].quantitiesByItem.remove(itemIndex);
      } else {
        _splits[0].quantitiesByItem[itemIndex] = newPart1Qty;
      }
    });
  }

  void _removeItemFromPart(int partIndex, int itemIndex) {
    if (partIndex == 0) return;

    setState(() {
      final removedQty = _splits[partIndex].quantitiesByItem[itemIndex] ?? 0;
      _splits[partIndex].quantitiesByItem.remove(itemIndex);
      _splits[partIndex].batchIdByItem.remove(itemIndex);
      _splits[partIndex].batchDisplayByItem.remove(itemIndex);

      if (removedQty > 0) {
        final part1CurrentQty = _splits[0].quantitiesByItem[itemIndex] ?? 0;
        _splits[0].quantitiesByItem[itemIndex] = part1CurrentQty + removedQty;
      }
    });
  }

  void _handleProductDropped(
    Map<String, dynamic> dragData,
    int targetPartIndex,
  ) {
    final itemIndex = dragData['itemIndex'] as int;
    final fromPartIndex = dragData['fromPartIndex'] as int;

    if (itemIndex >= widget.orderData.items.length) return;

    int availableQty = _splits[fromPartIndex].quantitiesByItem[itemIndex] ?? 0;
    if (availableQty <= 0) return;

    final item = widget.orderData.items[itemIndex];

    showDialog(
      context: context,
      builder: (_) => _QuantityDialog(
        productName: item.name,
        maxQty: availableQty,
        currentQty: 0,
        unit: item.unit,
        onConfirm: (qty) {
          setState(() {
            final currentQty =
                _splits[fromPartIndex].quantitiesByItem[itemIndex] ?? 0;
            final newQty = currentQty - qty;
            if (newQty <= 0) {
              _splits[fromPartIndex].quantitiesByItem.remove(itemIndex);
            } else {
              _splits[fromPartIndex].quantitiesByItem[itemIndex] = newQty;
            }

            final targetCurrent =
                _splits[targetPartIndex].quantitiesByItem[itemIndex] ?? 0;
            _splits[targetPartIndex].quantitiesByItem[itemIndex] =
                targetCurrent + qty;
          });
        },
      ),
    );
  }

  void _pickBatchForItem(int partIndex, int itemIndex) {
    final split = _splits[partIndex];
    if (split.inventoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select staff for this part first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    final item = widget.orderData.items[itemIndex];
    final requiredQty = split.quantitiesByItem[itemIndex] ?? 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SelectBatchSheet(
        productId: item.productId,
        inventoryId: split.inventoryId,
        requiredQty: requiredQty,
        isStockOut: true,
        currentlySelectedBatchId: split.batchIdByItem[itemIndex],
        onSelected: (batchId, displayText) {
          Navigator.pop(context);
          setState(() {
            split.batchIdByItem[itemIndex] = batchId;
            split.batchDisplayByItem[itemIndex] = displayText;
          });
        },
      ),
    );
  }

  void _confirmAndSend() {
    // Validate all parts with items have staff assigned
    for (int i = 0; i < _splits.length; i++) {
      if (_splits[i].quantitiesByItem.isEmpty) continue;
      if (_splits[i].staffId == null || _splits[i].inventoryId == null) {
        setState(() => _showValidationErrors = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Part ${i + 1} must have a staff member assigned'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // Validate all items have batches selected
    for (int partIdx = 0; partIdx < _splits.length; partIdx++) {
      final split = _splits[partIdx];
      for (final itemIndex in split.quantitiesByItem.keys) {
        if (!split.batchIdByItem.containsKey(itemIndex) ||
            split.batchIdByItem[itemIndex] == null) {
          setState(() => _showValidationErrors = true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Part ${partIdx + 1}: Please select batch for all products',
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }
    }

    // Prepare split data format
    final splitsData = <Map<String, dynamic>>[];
    for (final split in _splits) {
      if (split.quantitiesByItem.isEmpty) continue;

      final itemsMap = <int, int>{};
      final batchMap = <int, int?>{};
      split.quantitiesByItem.forEach((itemIndex, qty) {
        final productId = widget.orderData.items[itemIndex].productId;
        itemsMap[productId] = qty;
        batchMap[productId] = split.batchIdByItem[itemIndex];
      });

      splitsData.add({
        'staffId': split.staffId!,
        'inventoryId': split.inventoryId!,
        'items': itemsMap,
        'batches': batchMap,
      });
    }

    Navigator.pop(context);
    // Use first split data for backward compatibility with onConfirm signature
    // But we'll actually handle it differently in _sendNonSplitOrder
    if (splitsData.length == 1) {
      final firstSplit = splitsData[0];
      final batchesByItemIndex = <int, int?>{};
      for (int i = 0; i < widget.orderData.items.length; i++) {
        final productId = widget.orderData.items[i].productId;
        if (_splits[0].batchIdByItem.containsKey(i)) {
          batchesByItemIndex[i] = _splits[0].batchIdByItem[i];
        }
      }
      widget.onConfirm(
        firstSplit['staffId'],
        firstSplit['inventoryId'],
        batchesByItemIndex,
      );
    } else {
      // Multi-part assignment - need to modify parent method
      // For now, pass splits data through a modified call
      _sendMultiPartOrder(splitsData);
    }
  }

  Future<void> _sendMultiPartOrder(
    List<Map<String, dynamic>> splitsData,
  ) async {
    final success = await OrderService.saveSplitOrder(
      orderId: widget.orderId,
      splits: splitsData,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order sent successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send order. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildOrderDetails();
  }

  Widget _buildOrderDetails() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Split Assignment',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    GestureDetector(
                      onTap: _addSplit,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.add, color: Colors.white, size: 18),
                            SizedBox(width: 4),
                            Text(
                              'Add Part',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Assign products to staff members',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _splits.length,
              itemBuilder: (_, splitIdx) => _buildPartCard(splitIdx),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _confirmAndSend,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Confirm & Send',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartCard(int partIndex) {
    final split = _splits[partIndex];

    return DragTarget<Map<String, dynamic>>(
      onWillAcceptWithDetails: (details) => partIndex > 0,
      onAcceptWithDetails: (details) {
        if (partIndex > 0) {
          _handleProductDropped(details.data, partIndex);
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isDraggingOver = candidateData.isNotEmpty;

        final partContainer = Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDraggingOver
                ? AppColors.gold.withOpacity(0.1)
                : AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: isDraggingOver
                ? Border.all(color: AppColors.gold, width: 2)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Part ${partIndex + 1}',
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: GestureDetector(
                      onTap: () => _pickStaffForSplit(partIndex),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: split.staffName != null
                              ? AppColors.gold.withOpacity(0.2)
                              : Colors.orange.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: split.staffName != null
                                ? AppColors.gold
                                : Colors.orange,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.person,
                              color: split.staffName != null
                                  ? AppColors.gold
                                  : Colors.orange,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                split.staffName ?? 'Select Staff',
                                style: TextStyle(
                                  color: split.staffName != null
                                      ? AppColors.gold
                                      : Colors.orange,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            if (split.staffName != null) ...[],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (split.quantitiesByItem.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      partIndex == 0
                          ? 'Drag products to other parts'
                          : 'Drop products here',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                )
              else
                ...split.quantitiesByItem.entries.map((entry) {
                  final itemIndex = entry.key;
                  final qty = entry.value;
                  final item = widget.orderData.items[itemIndex];

                  return _buildItemRow(item, qty, itemIndex, partIndex, split);
                }).toList(),
            ],
          ),
        );

        if (partIndex > 0) {
          return Dismissible(
            key: ValueKey(split.id),
            direction: DismissDirection.endToStart,
            background: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.centerRight,
              child: const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Remove Part',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.delete, color: Colors.red, size: 24),
                  ],
                ),
              ),
            ),
            onDismissed: (direction) => _removeSplit(partIndex),
            child: partContainer,
          );
        }

        return partContainer;
      },
    );
  }

  Widget _buildItemRow(
    OrderItem item,
    int qty,
    int itemIndex,
    int partIndex,
    _SplitAssignment split,
  ) {
    final batchDisplay = split.batchDisplayByItem[itemIndex];
    final hasBatch = batchDisplay != null;

    return LongPressDraggable<Map<String, dynamic>>(
      data: {'itemIndex': itemIndex, 'fromPartIndex': partIndex},
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.gold.withOpacity(0.9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${item.name} - $qty ${item.unit}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildItemRowContent(
          item,
          qty,
          itemIndex,
          partIndex,
          split,
          batchDisplay,
          hasBatch,
        ),
      ),
      child: _buildItemRowContent(
        item,
        qty,
        itemIndex,
        partIndex,
        split,
        batchDisplay,
        hasBatch,
      ),
    );
  }

  Widget _buildItemRowContent(
    OrderItem item,
    int qty,
    int itemIndex,
    int partIndex,
    _SplitAssignment split,
    String? batchDisplay,
    bool hasBatch,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      item.brand,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              if (partIndex > 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 50,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: TextField(
                        controller: TextEditingController(text: qty.toString()),
                        onChanged: (value) {
                          final newQty = int.tryParse(value);
                          if (newQty != null && newQty >= 0) {
                            _onQuantityChanged(partIndex, itemIndex, newQty);
                          }
                        },
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isCollapsed: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item.unit,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        qty.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item.unit,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

              if (partIndex > 0) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _removeItemFromPart(partIndex, itemIndex),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.remove_circle_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),

          GestureDetector(
            onTap: () => _pickBatchForItem(partIndex, itemIndex),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: hasBatch
                    ? AppColors.gold.withOpacity(0.2)
                    : Colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: hasBatch ? AppColors.gold : Colors.orange,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.inventory_2,
                    color: hasBatch ? AppColors.gold : Colors.orange,
                    size: 12,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      batchDisplay ?? 'Select Batch',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: hasBatch ? AppColors.gold : Colors.orange,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_showValidationErrors && !hasBatch) ...[
            const SizedBox(height: 6),
            const Text(
              '⚠ You need to select a batch',
              style: TextStyle(
                color: Color.fromARGB(255, 225, 56, 56),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ===== QUANTITY DIALOG =====

class _QuantityDialog extends StatefulWidget {
  final String productName;
  final int maxQty;
  final int currentQty;
  final String unit;
  final Function(int) onConfirm;

  const _QuantityDialog({
    required this.productName,
    required this.maxQty,
    required this.currentQty,
    required this.unit,
    required this.onConfirm,
  });

  @override
  State<_QuantityDialog> createState() => _QuantityDialogState();
}

class _QuantityDialogState extends State<_QuantityDialog> {
  late TextEditingController _controller;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.maxQty.toString());
    _controller.addListener(_validateInput);
  }

  void _validateInput() {
    final qty = int.tryParse(_controller.text) ?? 0;
    setState(() {
      _hasError = qty <= 0 || qty > widget.maxQty;
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_validateInput);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.card,
      title: Text(
        widget.productName,
        style: const TextStyle(color: AppColors.gold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available: ${widget.maxQty} ${widget.unit}',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Quantity to move',
              labelStyle: const TextStyle(color: Colors.white54),
              suffixText: widget.unit,
              suffixStyle: const TextStyle(color: Colors.white54),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white24, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.gold, width: 2),
              ),
              errorBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red, width: 2),
              ),
              focusedErrorBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red, width: 2),
              ),
            ),
          ),
          if (_hasError) ...[
            const SizedBox(height: 8),
            Text(
              'You need to enter 1-${widget.maxQty}',
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _hasError
              ? null
              : () {
                  final qty = int.tryParse(_controller.text) ?? 0;
                  if (qty > 0 && qty <= widget.maxQty) {
                    widget.onConfirm(qty);
                    Navigator.pop(context);
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: _hasError ? Colors.grey : AppColors.gold,
            foregroundColor: Colors.black,
            disabledBackgroundColor: Colors.grey,
            disabledForegroundColor: Colors.black54,
          ),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}

// ===== SPLIT ASSIGNMENT DATA MODEL =====

class _SplitAssignment {
  String? staffName;
  int? staffId;
  int? inventoryId;
  final Map<int, int> quantitiesByItem = {};
  final Map<int, int?> batchIdByItem = {};
  final Map<int, String> batchDisplayByItem = {};
  final String id = UniqueKey().toString();
}

class _ActionSelectorModal extends StatelessWidget {
  final VoidCallback onNormalSend;
  final VoidCallback onSendToAccountant;

  const _ActionSelectorModal({
    required this.onNormalSend,
    required this.onSendToAccountant,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final maxHeight = media.size.height * 0.66;

    return SafeArea(
      bottom: false,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.bgDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        // Respect keyboard insets and provide some bottom padding
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + media.viewInsets.bottom),
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              // Limit height so modal never exceeds screen and causes overflow
              maxHeight: maxHeight,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.edit, color: AppColors.gold, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Quantity Updated - Choose Action',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'How would you like to proceed with the updated quantities?',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 24),

                // Option 1: Continue with Edit (text left, icon right)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onNormalSend();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Row(
                      children: const [
                        Expanded(
                          child: Text(
                            'Continue with Edit',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Option 2: Send to Accountant (text left, icon right)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onSendToAccountant();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Row(
                      children: const [
                        Expanded(
                          child: Text(
                            'Send to Accountant',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.account_balance,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CustomSendButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const CustomSendButton({super.key, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: AppColors.gold,
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              text,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 8,
              ),
            ),
            Transform.rotate(
              angle: -0.8,
              child: const Icon(
                Icons.send_rounded,
                color: AppColors.white,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
