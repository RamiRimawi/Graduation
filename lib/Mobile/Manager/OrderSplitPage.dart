import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../manager_theme.dart';
import 'SelectStaffSheet.dart';
import 'SelectBatchSheet.dart';
import 'order_item.dart';
import 'order_service.dart';

class OrderSplitPage extends StatefulWidget {
  final int orderId;
  final String customerName;
  final List<OrderItem> items;

  const OrderSplitPage({
    super.key,
    required this.orderId,
    required this.customerName,
    required this.items,
  });

  @override
  State<OrderSplitPage> createState() => _OrderSplitPageState();
}

class _OrderSplitPageState extends State<OrderSplitPage> {
  // Split assignments state
  final List<_SplitAssignment> _splits = [];

  @override
  void initState() {
    super.initState();
    // Initialize with Part 1 containing all items and Part 2 empty
    _splits.add(_SplitAssignment());
    _splits.add(_SplitAssignment());

    // Assign all items to Part 1
    for (int i = 0; i < widget.items.length; i++) {
      _splits[0].quantitiesByItem[i] = widget.items[i].qty;
    }
  }

  void _addSplit() {
    setState(() => _splits.add(_SplitAssignment()));
  }

  void _removeSplit(int index) {
    // Use post frame callback to remove after animation completes
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
              });
            },
          ),
        ],
      ),
    );
  }

  void _pickBatchForItem(int splitIndex, int itemIndex) {
    final split = _splits[splitIndex];
    if (split.inventoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select staff (inventory) for this part first'),
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
        inventoryId: split.inventoryId, // Filter by selected inventory
        requiredQty: split.quantitiesByItem[itemIndex] ?? 0,
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
      // From original order - shouldn't happen in this page
      availableQty = _remainingForItem(
        itemIndex,
        excludingSplit: targetPartIndex,
      );
    } else {
      // From another part
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
              // Transfer from another part
              final currentQty =
                  _splits[fromPartIndex].quantitiesByItem[itemIndex] ?? 0;
              final newQty = currentQty - qty;
              if (newQty <= 0) {
                _splits[fromPartIndex].quantitiesByItem.remove(itemIndex);
              } else {
                _splits[fromPartIndex].quantitiesByItem[itemIndex] = newQty;
              }
            }

            // Add to target part
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
    // Can't remove from Part 1
    if (partIndex == 0) return;

    setState(() {
      // Get the quantity being removed
      final removedQty = _splits[partIndex].quantitiesByItem[itemIndex] ?? 0;

      // Remove from current part
      _splits[partIndex].quantitiesByItem.remove(itemIndex);

      // Add back to Part 1
      if (removedQty > 0) {
        final part1CurrentQty = _splits[0].quantitiesByItem[itemIndex] ?? 0;
        _splits[0].quantitiesByItem[itemIndex] = part1CurrentQty + removedQty;
      }
    });
  }

  void _onQuantityChanged(int partIndex, int itemIndex, int newQty) {
    // Can't edit Part 1
    if (partIndex == 0) return;

    setState(() {
      final currentQty = _splits[partIndex].quantitiesByItem[itemIndex] ?? 0;
      final difference = newQty - currentQty;

      // Get Part 1 current quantity
      final part1Qty = _splits[0].quantitiesByItem[itemIndex] ?? 0;

      // Calculate total available (Part 1 + current part)
      final totalAvailable = part1Qty + currentQty;

      // Check if new quantity is valid
      if (newQty < 0 || newQty > totalAvailable) {
        return; // Invalid quantity
      }

      // Update current part (keep row even if qty is 0, only remove with button)
      _splits[partIndex].quantitiesByItem[itemIndex] = newQty;

      // Adjust Part 1 (subtract the difference)
      final newPart1Qty = part1Qty - difference;
      if (newPart1Qty <= 0) {
        _splits[0].quantitiesByItem.remove(itemIndex);
      } else {
        _splits[0].quantitiesByItem[itemIndex] = newPart1Qty;
      }
    });
  }

  void _sendSplitToBackend() {
    final items = widget.items;

    // Validate all splits have staff assigned
    for (int i = 0; i < _splits.length; i++) {
      if (_splits[i].quantitiesByItem.isEmpty) continue;
      if (_splits[i].staffName == null || _splits[i].staffName!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Part ${i + 1} must have a staff member assigned'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // Show batch selection modal
    _showBatchSelectionModal(items);
  }

  void _showBatchSelectionModal(List<OrderItem> items) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SplitBatchSelectionModal(
        orderId: widget.orderId,
        splits: _splits,
        items: items,
        onConfirm: () {
          Navigator.pop(context);
          _showSplitSummary(items);
        },
      ),
    );
  }

  void _showSplitSummary(List<OrderItem> items) {
    final parts = <Map<String, dynamic>>[];

    for (int splitIdx = 0; splitIdx < _splits.length; splitIdx++) {
      final split = _splits[splitIdx];
      if (split.quantitiesByItem.isEmpty) continue;

      final partItems = <Map<String, dynamic>>[];
      split.quantitiesByItem.forEach((itemIndex, qty) {
        final item = items[itemIndex];
        partItems.add({
          'productName': item.name,
          'quantity': qty,
          'unit': item.unit,
        });
      });

      parts.add({
        'partNumber': splitIdx + 1,
        'staffName': split.staffName ?? 'Unassigned',
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
                'Customer: ${widget.customerName}',
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
                        'Part ${p['partNumber']} - ${p['staffName']}',
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
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close confirmation dialog

              // Prepare split data for database
              final splitsData = <Map<String, dynamic>>[];
              for (int i = 0; i < _splits.length; i++) {
                final split = _splits[i];
                if (split.quantitiesByItem.isEmpty) continue;

                // Convert item indices to product IDs with quantities
                final itemsMap = <int, int>{};
                final batchMap = <int, int?>{}; // productId -> batchId
                split.quantitiesByItem.forEach((itemIndex, qty) {
                  final productId = widget.items[itemIndex].productId;
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

              // Save to database
              final success = await OrderService.saveSplitOrder(
                orderId: widget.orderId,
                splits: splitsData,
              );

              if (!mounted) return;

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Order split sent successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(
                  context,
                  true,
                ); // Close split page and return success
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Failed to save split order. Please try again.',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Send Split'),
          ),
        ],
      ),
    );
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
                      'Split Order - ${widget.customerName}',
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

              // ===== SPLIT PARTS SECTION =====
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
                    return _SplitPartTable(
                      partIndex: i,
                      split: split,
                      allItems: widget.items,
                      onStaffTap: () => _pickStaffForSplit(i),
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

              // ===== SEND BUTTON =====
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _sendSplitToBackend,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Send Split Order',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
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

// ===== SPLIT PART TABLE WIDGET =====

class _SplitPartTable extends StatelessWidget {
  final int partIndex;
  final _SplitAssignment split;
  final List<OrderItem> allItems;
  final VoidCallback onStaffTap;
  final Function(Map<String, dynamic>, int) onProductDropped;
  final Function(int, int) onRemoveItem;
  final Function(int, int, int) onQuantityChanged;
  final VoidCallback onRemovePart;
  final int Function(int, {int excludingSplit}) getRemainingForItem;
  final void Function(int partIndex, int itemIndex) onPickBatch;

  const _SplitPartTable({
    required this.partIndex,
    required this.split,
    required this.allItems,
    required this.onStaffTap,
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
                    onTap: onStaffTap,
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
                            Icons.person,
                            color: AppColors.gold,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            split.staffName ?? 'Select Staff',
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

              // Rows
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

                  // Only allow dragging from Part 1
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
                    // Parts 2+ are not draggable
                    return _buildRow(item, qty, itemIndex, partIndex, split);
                  }
                }),
            ],
          ),
        );

        // Only allow dismissing parts 2+
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
    _SplitAssignment split,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
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
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Editable quantity for parts 2+ only
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
                        onQuantityChanged(partIndex, itemIndex, newQty);
                      }
                    },
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                    keyboardType: TextInputType.number,
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
            // Non-editable for Part 1
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

// ===== SPLIT BATCH SELECTION MODAL =====

class _SplitBatchSelectionModal extends StatefulWidget {
  final int orderId;
  final List<_SplitAssignment> splits;
  final List<OrderItem> items;
  final VoidCallback onConfirm;

  const _SplitBatchSelectionModal({
    required this.orderId,
    required this.splits,
    required this.items,
    required this.onConfirm,
  });

  @override
  State<_SplitBatchSelectionModal> createState() =>
      _SplitBatchSelectionModalState();
}

class _SplitBatchSelectionModalState extends State<_SplitBatchSelectionModal> {
  late Map<int, Map<int, String>>
  _selectedBatchDisplays; // splitIdx -> (itemIdx -> display)
  bool _autoSelectionDone = false;

  @override
  void initState() {
    super.initState();
    _selectedBatchDisplays = {};
    for (int i = 0; i < widget.splits.length; i++) {
      _selectedBatchDisplays[i] = Map.from(widget.splits[i].batchDisplayByItem);
    }
    // Auto-select batches for all splits
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_autoSelectionDone) {
        _autoSelectAllBatches();
      }
    });
  }

  Future<void> _autoSelectAllBatches() async {
    _autoSelectionDone = true;
    for (int splitIdx = 0; splitIdx < widget.splits.length; splitIdx++) {
      final split = widget.splits[splitIdx];
      if (split.quantitiesByItem.isEmpty || split.inventoryId == null) continue;

      for (final entry in split.quantitiesByItem.entries) {
        final itemIndex = entry.key;
        final requiredQty = entry.value;

        // Skip if already selected
        if (split.batchIdByItem.containsKey(itemIndex) &&
            split.batchIdByItem[itemIndex] != null) {
          continue;
        }

        await _autoSelectBatchForItem(splitIdx, itemIndex, requiredQty);
      }
    }
  }

  Future<void> _autoSelectBatchForItem(
    int splitIdx,
    int itemIndex,
    int requiredQty,
  ) async {
    try {
      final split = widget.splits[splitIdx];
      final item = widget.items[itemIndex];
      final supabase = Supabase.instance.client;
      final now = DateTime.now();

      // Fetch batches for this product and inventory
      final response = await supabase
          .from('batch')
          .select(
            'batch_id, quantity, storage_location_descrption, production_date, expiry_date',
          )
          .eq('product_id', item.productId)
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
        _selectedBatchDisplays[splitIdx]![itemIndex] = displayText;
        widget.splits[splitIdx].batchIdByItem[itemIndex] = batchId;
        widget.splits[splitIdx].batchDisplayByItem[itemIndex] = displayText;
      });
    } catch (e) {
      debugPrint(
        'Error auto-selecting batch for split $splitIdx item $itemIndex: $e',
      );
    }
  }

  void _pickBatchForItem(int splitIndex, int itemIndex) {
    final split = widget.splits[splitIndex];
    if (split.inventoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select staff for this part first'),
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
        requiredQty: widget.splits[splitIndex].quantitiesByItem[itemIndex],
        isStockOut: true,
        currentlySelectedBatchId:
            widget.splits[splitIndex].batchIdByItem[itemIndex],
        onSelected: (batchId, displayText) {
          Navigator.pop(context);
          setState(() {
            _selectedBatchDisplays[splitIndex]![itemIndex] = displayText;
            widget.splits[splitIndex].batchIdByItem[itemIndex] = batchId;
            widget.splits[splitIndex].batchDisplayByItem[itemIndex] =
                displayText;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select Batches',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Choose batch for each product per part',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
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
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: widget.splits.length,
              itemBuilder: (_, splitIdx) {
                final split = widget.splits[splitIdx];
                if (split.quantitiesByItem.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12, top: 8),
                      child: Text(
                        'Part ${splitIdx + 1} - ${split.staffName}',
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    ...split.quantitiesByItem.entries.map((entry) {
                      final itemIdx = entry.key;
                      final qty = entry.value;
                      final item = widget.items[itemIdx];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFB7A447),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$qty ${item.unit}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: () => _pickBatchForItem(splitIdx, itemIdx),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      _selectedBatchDisplays[splitIdx]![itemIdx] !=
                                          null
                                      ? AppColors.gold.withOpacity(0.2)
                                      : Colors.orange.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color:
                                        _selectedBatchDisplays[splitIdx]![itemIdx] !=
                                            null
                                        ? AppColors.gold
                                        : Colors.orange,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.inventory_2,
                                      color:
                                          _selectedBatchDisplays[splitIdx]![itemIdx] !=
                                              null
                                          ? AppColors.gold
                                          : Colors.orange,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _selectedBatchDisplays[splitIdx]![itemIdx] ??
                                            'Select Batch',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color:
                                              _selectedBatchDisplays[splitIdx]![itemIdx] !=
                                                  null
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
                    }),
                    const SizedBox(height: 12),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.onConfirm,
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
}

// ===== SPLIT ASSIGNMENT DATA MODEL =====

class _SplitAssignment {
  String? staffName; // Display name "Staff - Inventory"
  int? staffId; // FK to storage_staff
  int? inventoryId; // FK to inventory
  final Map<int, int> quantitiesByItem = {};
  final Map<int, int?> batchIdByItem = {}; // item index -> batch_id
  final Map<int, String> batchDisplayByItem = {}; // item index -> display text
  final String id = UniqueKey().toString(); // Unique ID for this split
}
