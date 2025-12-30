import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../manager_theme.dart';
import 'StockInOrderDetailsPage.dart';
import 'SelectBatchSheet.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StockInOrderSplitPage extends StatefulWidget {
  final int orderId;
  final String supplierName;
  final List<OrderItem> items;

  const StockInOrderSplitPage({
    super.key,
    required this.orderId,
    required this.supplierName,
    required this.items,
  });

  @override
  State<StockInOrderSplitPage> createState() => _StockInOrderSplitPageState();
}

class _StockInOrderSplitPageState extends State<StockInOrderSplitPage> {
  // Split assignments state
  final List<_StockInSplitAssignment> _splits = [];

  @override
  void initState() {
    super.initState();
    // Initialize with Part 1 containing all items and Part 2 empty
    _splits.add(_StockInSplitAssignment());
    _splits.add(_StockInSplitAssignment());

    // Assign all items to Part 1
    for (int i = 0; i < widget.items.length; i++) {
      _splits[0].quantitiesByItem[i] = widget.items[i].qty;
    }
  }

  void _addSplit() {
    setState(() => _splits.add(_StockInSplitAssignment()));
  }

  void _removeSplit(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          final split = _splits[index];

          // Return all items from this part to Part 1
          split.quantitiesByItem.forEach((itemIndex, qty) {
            final part1CurrentQty = _splits[0].quantitiesByItem[itemIndex] ?? 0;
            _splits[0].quantitiesByItem[itemIndex] = part1CurrentQty + qty;
          });

          // Remove the split
          _splits.removeAt(index);
        });
      }
    });
  }

  void _pickInventoryForSplit(int index) {
    _showInventorySelectionModal(index);
  }

  void _pickBatchForItem(int splitIndex, int itemIndex) {
    final split = _splits[splitIndex];
    if (split.inventoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select inventory for this part first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    final item = widget.items[itemIndex];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SelectBatchSheet(
        productId: item.productId,
        inventoryId: split.inventoryId!,
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

  void _showInventorySelectionModal(int splitIndex) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _InventorySelectionForSplitModal(
        onSelected: (inventoryId, inventoryName) {
          Navigator.pop(context);
          setState(() {
            _splits[splitIndex].inventoryId = inventoryId;
            _splits[splitIndex].inventoryName = inventoryName;
          });
        },
      ),
    );
  }

  int _itemTotal(int itemIndex) => widget.items[itemIndex].qty;

  int _allocatedForItem(int itemIndex, {int excludingSplit = -1}) {
    int sum = 0;
    for (int i = 0; i < _splits.length; i++) {
      if (i == excludingSplit) continue;
      sum += _splits[i].quantitiesByItem[itemIndex] ?? 0;
    }
    return sum;
  }

  int _remainingForItem(int itemIndex, {int excludingSplit = -1}) {
    final total = _itemTotal(itemIndex);
    final allocated = _allocatedForItem(
      itemIndex,
      excludingSplit: excludingSplit,
    );
    final rem = total - allocated;
    return rem < 0 ? 0 : rem;
  }

  void _handleProductDropped(
    Map<String, dynamic> dragData,
    int targetPartIndex,
  ) {
    final itemIndex = dragData['itemIndex'] as int;
    final fromPartIndex = dragData['fromPartIndex'] as int;
    final items = widget.items;

    if (itemIndex >= items.length) return;

    // Calculate available quantity
    int availableQty;
    if (fromPartIndex == -1) {
      availableQty = _remainingForItem(
        itemIndex,
        excludingSplit: targetPartIndex,
      );
    } else {
      availableQty = _splits[fromPartIndex].quantitiesByItem[itemIndex] ?? 0;
    }

    if (availableQty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No ${items[itemIndex].name} available to move'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show quantity dialog
    showDialog(
      context: context,
      builder: (_) => _QuantityDialog(
        productName: items[itemIndex].name,
        maxQty: availableQty,
        currentQty: 0,
        unit: items[itemIndex].unit,
        onConfirm: (qty) {
          setState(() {
            if (fromPartIndex >= 0) {
              final currentQty =
                  _splits[fromPartIndex].quantitiesByItem[itemIndex] ?? 0;
              final newQty = currentQty - qty;
              if (newQty <= 0) {
                _splits[fromPartIndex].quantitiesByItem.remove(itemIndex);
              } else {
                _splits[fromPartIndex].quantitiesByItem[itemIndex] = newQty;
              }
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

  void _removeItemFromPart(int partIndex, int itemIndex) {
    if (partIndex == 0) return;

    setState(() {
      final removedQty = _splits[partIndex].quantitiesByItem[itemIndex] ?? 0;

      _splits[partIndex].quantitiesByItem.remove(itemIndex);

      if (removedQty > 0) {
        final part1CurrentQty = _splits[0].quantitiesByItem[itemIndex] ?? 0;
        _splits[0].quantitiesByItem[itemIndex] = part1CurrentQty + removedQty;
      }
    });
  }

  void _onQuantityChanged(int partIndex, int itemIndex, int newQty) {
    setState(() {
      if (partIndex == 0) {
        // For Part 1, just update the quantity directly
        final originalQty = widget.items[itemIndex].qty;
        if (newQty < 0 || newQty > originalQty) {
          return;
        }
        _splits[0].quantitiesByItem[itemIndex] = newQty;
        return;
      }

      // For other parts, adjust with Part 1
      final currentQty = _splits[partIndex].quantitiesByItem[itemIndex] ?? 0;
      final difference = newQty - currentQty;

      final part1Qty = _splits[0].quantitiesByItem[itemIndex] ?? 0;

      final totalAvailable = part1Qty + currentQty;

      if (newQty < 0 || newQty > totalAvailable) {
        return;
      }

      _splits[partIndex].quantitiesByItem[itemIndex] = newQty;

      final newPart1Qty = part1Qty - difference;
      if (newPart1Qty <= 0) {
        _splits[0].quantitiesByItem.remove(itemIndex);
      } else {
        _splits[0].quantitiesByItem[itemIndex] = newPart1Qty;
      }
    });
  }

  void _sendSplitToBackend() {
    // Validate all parts have inventory and batches
    for (int i = 0; i < _splits.length; i++) {
      if (_splits[i].quantitiesByItem.isEmpty) continue;

      if (_splits[i].inventoryName == null ||
          _splits[i].inventoryName!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Part ${i + 1} must have an inventory assigned'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Check if all items in this part have batch selected
      for (final itemIndex in _splits[i].quantitiesByItem.keys) {
        if (!_splits[i].batchIdByItem.containsKey(itemIndex) ||
            _splits[i].batchIdByItem[itemIndex] == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Part ${i + 1}: Please select batch for ${widget.items[itemIndex].name}',
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }
    }

    _showSplitSummary();
  }

  void _showSplitSummary() {
    final parts = <Map<String, dynamic>>[];

    for (int splitIdx = 0; splitIdx < _splits.length; splitIdx++) {
      final split = _splits[splitIdx];
      if (split.quantitiesByItem.isEmpty) continue;

      final partItems = <Map<String, dynamic>>[];
      split.quantitiesByItem.forEach((itemIndex, qty) {
        final item = widget.items[itemIndex];
        partItems.add({
          'productName': item.name,
          'quantity': qty,
          'unit': item.unit,
        });
      });

      parts.add({
        'partNumber': splitIdx + 1,
        'inventoryName': split.inventoryName ?? 'Unassigned',
        'items': partItems,
      });
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text(
          'Confirm Split Order',
          style: TextStyle(color: AppColors.gold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Supplier: ${widget.supplierName}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...parts.map((p) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.bgDark.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Part ${p['partNumber']} - ${p['inventoryName']}',
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ...(p['items'] as List).map((it) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            '  • ${it['productName']} – ${it['quantity']} ${it['unit']}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _confirmSplitOrder,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Send Split'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSplitOrder() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
      );

      // Get manager info from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final managerIdStr = prefs.getString('current_user_id');
      final managerName = prefs.getString('current_user_name');

      if (managerIdStr == null || managerName == null) {
        if (mounted) Navigator.pop(context); // Close loading
        throw Exception('Manager information not found');
      }

      final managerId = int.parse(managerIdStr);
      final supabase = Supabase.instance.client;

      // Update supplier_order_description with receipt_quantity for each item
      // We need to sum all quantities across splits for each item
      final Map<int, int> totalReceiptByItem = {};
      for (final split in _splits) {
        split.quantitiesByItem.forEach((itemIndex, qty) {
          totalReceiptByItem[itemIndex] =
              (totalReceiptByItem[itemIndex] ?? 0) + qty;
        });
      }

      for (final entry in totalReceiptByItem.entries) {
        final itemIndex = entry.key;
        final totalQty = entry.value;
        final item = widget.items[itemIndex];

        await supabase
            .from('supplier_order_description')
            .update({
              'receipt_quantity': totalQty,
              'last_tracing_by': managerName,
              'last_tracing_time': DateTime.now().toIso8601String(),
            })
            .eq('order_id', widget.orderId)
            .eq('product_id', item.productId);
      }

      // Update supplier_order to Delivered
      await supabase
          .from('supplier_order')
          .update({
            'order_status': 'Delivered',
            'receives_by_id': managerId,
            'last_tracing_by': managerName,
            'last_tracing_time': DateTime.now().toIso8601String(),
          })
          .eq('order_id', widget.orderId);

      // Insert into supplier_order_inventory for each product in each split
      final inventoryInserts = <Map<String, dynamic>>[];

      for (int splitIdx = 0; splitIdx < _splits.length; splitIdx++) {
        final split = _splits[splitIdx];
        if (split.quantitiesByItem.isEmpty) continue;

        for (final entry in split.quantitiesByItem.entries) {
          final itemIndex = entry.key;
          final qty = entry.value;
          final item = widget.items[itemIndex];
          final batchId = split.batchIdByItem[itemIndex];

          inventoryInserts.add({
            'supplier_order_id': widget.orderId,
            'product_id': item.productId,
            'inventory_id': split.inventoryId!,
            'batch_id': batchId,
            'quantity': qty,
          });
        }
      }

      await supabase.from('supplier_order_inventory').insert(inventoryInserts);

      // Close loading and dialogs, show success
      if (mounted) {
        Navigator.pop(context); // Close loading
        Navigator.pop(context); // Close confirmation dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Split order received successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Go back to list
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to receive split order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
                  Expanded(
                    child: Text(
                      'Split Order - ${widget.supplierName}',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Split Parts',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _addSplit,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Part'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Expanded(
                child: ListView.builder(
                  itemCount: _splits.length,
                  itemBuilder: (_, i) {
                    final split = _splits[i];
                    return _StockInSplitPartTable(
                      partIndex: i,
                      split: split,
                      allItems: widget.items,
                      onInventoryTap: () => _pickInventoryForSplit(i),
                      onProductDropped: _handleProductDropped,
                      onRemoveItem: _removeItemFromPart,
                      onQuantityChanged: _onQuantityChanged,
                      onRemovePart: () => _removeSplit(i),
                      getRemainingForItem: _remainingForItem,
                      onPickBatch: _pickBatchForItem,
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              GestureDetector(
                onTap: _sendSplitToBackend,
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
                      const Text(
                        "D  o  n  e",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 8,
                        ),
                      ),
                      Transform.rotate(
                        angle: -0.8,
                        child: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 28,
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

// Stock-In Split Part Table
class _StockInSplitPartTable extends StatelessWidget {
  final int partIndex;
  final _StockInSplitAssignment split;
  final List<OrderItem> allItems;
  final VoidCallback onInventoryTap;
  final Function(Map<String, dynamic>, int) onProductDropped;
  final Function(int, int) onRemoveItem;
  final Function(int, int, int) onQuantityChanged;
  final VoidCallback onRemovePart;
  final int Function(int, {int excludingSplit}) getRemainingForItem;
  final void Function(int partIndex, int itemIndex) onPickBatch;

  const _StockInSplitPartTable({
    required this.partIndex,
    required this.split,
    required this.allItems,
    required this.onInventoryTap,
    required this.onProductDropped,
    required this.onRemoveItem,
    required this.onQuantityChanged,
    required this.onRemovePart,
    required this.getRemainingForItem,
    required this.onPickBatch,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<Map<String, dynamic>>(
      onWillAcceptWithDetails: (details) => partIndex > 0,
      onAcceptWithDetails: (details) {
        if (partIndex > 0) {
          onProductDropped(details.data, partIndex);
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
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  GestureDetector(
                    onTap: onInventoryTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.bgDark,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.inventory_2,
                            color: AppColors.gold,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            split.inventoryName ?? 'Select Inventory',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
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
                      isDraggingOver
                          ? 'Drop here to add'
                          : 'Drag products here',
                      style: TextStyle(
                        color: isDraggingOver ? AppColors.gold : Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ),
                )
              else
                ...split.quantitiesByItem.entries.map((entry) {
                  final itemIndex = entry.key;
                  final qty = entry.value;
                  final item = allItems[itemIndex];

                  if (partIndex == 0) {
                    return Draggable<Map<String, dynamic>>(
                      data: {
                        'itemIndex': itemIndex,
                        'fromPartIndex': partIndex,
                        'quantity': qty,
                      },
                      feedback: Material(
                        color: Colors.transparent,
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
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.open_in_full,
                                color: AppColors.card,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                item.name,
                                style: const TextStyle(
                                  color: AppColors.card,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.5,
                        child: _buildRow(
                          item,
                          qty,
                          itemIndex,
                          partIndex,
                          split,
                        ),
                      ),
                      child: _buildRow(item, qty, itemIndex, partIndex, split),
                    );
                  } else {
                    return _buildRow(item, qty, itemIndex, partIndex, split);
                  }
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
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text(
                      'Delete',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
            onDismissed: (direction) {
              onRemovePart();
            },
            child: partContainer,
          );
        }

        return partContainer;
      },
    );
  }

  Widget _buildRow(
    OrderItem item,
    int qty,
    int itemIndex,
    int partIndex,
    _StockInSplitAssignment split,
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
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
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
              if (partIndex > 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                              key: ValueKey(
                                'qty_${partIndex}_${itemIndex}_$qty',
                              ),
                              controller: TextEditingController.fromValue(
                                TextEditingValue(
                                  text: qty.toString(),
                                  selection: TextSelection.collapsed(
                                    offset: qty.toString().length,
                                  ),
                                ),
                              ),
                              onChanged: (value) {
                                final newQty = int.tryParse(value);
                                if (newQty != null && newQty >= 0) {
                                  onQuantityChanged(
                                    partIndex,
                                    itemIndex,
                                    newQty,
                                  );
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
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isCollapsed: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              item.unit,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
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
                              key: ValueKey(
                                'qty_${partIndex}_${itemIndex}_$qty',
                              ),
                              controller: TextEditingController.fromValue(
                                TextEditingValue(
                                  text: qty.toString(),
                                  selection: TextSelection.collapsed(
                                    offset: qty.toString().length,
                                  ),
                                ),
                              ),
                              onChanged: (value) {
                                final newQty = int.tryParse(value);
                                if (newQty != null && newQty >= 0) {
                                  onQuantityChanged(
                                    partIndex,
                                    itemIndex,
                                    newQty,
                                  );
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
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isCollapsed: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              item.unit,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              if (partIndex > 0) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => onRemoveItem(partIndex, itemIndex),
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
            onTap: () => onPickBatch(partIndex, itemIndex),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: split.batchDisplayByItem[itemIndex] != null
                    ? AppColors.gold.withOpacity(0.2)
                    : Colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: split.batchDisplayByItem[itemIndex] != null
                      ? AppColors.gold
                      : Colors.orange,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.inventory_2,
                    color: split.batchDisplayByItem[itemIndex] != null
                        ? AppColors.gold
                        : Colors.orange,
                    size: 14,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      split.batchDisplayByItem[itemIndex] ?? 'Select Batch',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: split.batchDisplayByItem[itemIndex] != null
                            ? AppColors.gold
                            : Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Inventory Selection Modal for Splits
class _InventorySelectionForSplitModal extends StatefulWidget {
  final Function(int, String) onSelected;

  const _InventorySelectionForSplitModal({required this.onSelected});

  @override
  State<_InventorySelectionForSplitModal> createState() =>
      _InventorySelectionForSplitModalState();
}

class _InventorySelectionForSplitModalState
    extends State<_InventorySelectionForSplitModal> {
  int? _selectedInventoryId;
  String? _selectedInventoryName;

  Future<List<Map<String, dynamic>>> _fetchInventories() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('inventory')
          .select('inventory_id, inventory_name')
          .order('inventory_name');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching inventories: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Inventory',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Choose inventory for this part',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchInventories(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.gold),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'No inventories available',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                final inventories = snapshot.data!;
                return ListView.builder(
                  itemCount: inventories.length,
                  itemBuilder: (context, index) {
                    final inventory = inventories[index];
                    final invId = inventory['inventory_id'] as int;
                    final invName = inventory['inventory_name'] as String;
                    final isSelected = _selectedInventoryId == invId;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedInventoryId = invId;
                          _selectedInventoryName = invName;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.gold.withOpacity(0.2)
                              : AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.gold
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              color: isSelected
                                  ? AppColors.gold
                                  : Colors.white54,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                invName,
                                style: TextStyle(
                                  color: isSelected
                                      ? AppColors.gold
                                      : Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedInventoryId != null
                  ? () {
                      widget.onSelected(
                        _selectedInventoryId!,
                        _selectedInventoryName!,
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                disabledBackgroundColor: Colors.grey[600],
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Select',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Quantity Dialog
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
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Quantity to move',
              labelStyle: const TextStyle(color: Colors.white54),
              suffixText: widget.unit,
              suffixStyle: const TextStyle(color: Colors.white54),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: _hasError ? Colors.red : Colors.white54,
                  width: _hasError ? 2 : 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: _hasError ? Colors.red : AppColors.gold,
                  width: 2,
                ),
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
                    Navigator.pop(context);
                    widget.onConfirm(qty);
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

// Stock-In Split Assignment Data Model
class _StockInSplitAssignment {
  String? inventoryName;
  int? inventoryId;
  final Map<int, int> quantitiesByItem = {};
  final Map<int, int?> batchIdByItem = {};
  final Map<int, String> batchDisplayByItem = {};
  final String id = UniqueKey().toString();
}
