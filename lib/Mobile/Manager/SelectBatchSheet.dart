import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../manager_theme.dart';

class SelectBatchSheet extends StatefulWidget {
  final int productId;
  final int? inventoryId; // Optional: filter by inventory
  final int? requiredQty; // Optional: required quantity to check against batch
  final void Function(int batchId, String displayText) onSelected;

  const SelectBatchSheet({
    super.key,
    required this.productId,
    this.inventoryId,
    this.requiredQty,
    required this.onSelected,
  });

  @override
  State<SelectBatchSheet> createState() => _SelectBatchSheetState();
}

class _SelectBatchSheetState extends State<SelectBatchSheet> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _batches = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchBatches();
  }

  Future<void> _fetchBatches() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      // Build query
      var query = supabase
          .from('batch')
          .select(
            'batch_id, quantity, storage_location_descrption, inventory_id, inventory:inventory_id(inventory_name)',
          )
          .eq('product_id', widget.productId)
          .gt('quantity', 0); // Only show batches with available quantity

      // Filter by inventory if specified
      if (widget.inventoryId != null) {
        query = query.eq('inventory_id', widget.inventoryId!);
      }

      final response = await query.order('batch_id');

      setState(() {
        _batches = List<Map<String, dynamic>>.from(response);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
      debugPrint('Error fetching batches: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.bgDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white38,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Select Batch',
            style: TextStyle(
              color: AppColors.gold,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 20),

          if (_loading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(color: AppColors.yellow),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'Error loading batches:\n$_error',
                    style: const TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _fetchBatches,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          else if (_batches.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    color: Colors.white38,
                    size: 48,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No batches available',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                itemCount: _batches.length,
                itemBuilder: (context, index) {
                  final batch = _batches[index];
                  final batchId = batch['batch_id'] as int;
                  final quantity = batch['quantity'] as int;
                  final location =
                      batch['storage_location_descrption'] as String? ??
                      'Unknown Location';
                  final inventory = batch['inventory'] as Map<String, dynamic>?;
                  final inventoryName =
                      inventory?['inventory_name'] as String? ?? 'Unknown';

                  final displayText =
                      'Batch #$batchId - $location (Qty: $quantity)';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _BatchCard(
                      batchId: batchId,
                      location: location,
                      quantity: quantity,
                      inventoryName: inventoryName,
                      requiredQty: widget.requiredQty,
                      onTap: () {
                        widget.onSelected(batchId, displayText);
                      },
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _BatchCard extends StatelessWidget {
  final int batchId;
  final String location;
  final int quantity;
  final String inventoryName;
  final int? requiredQty;
  final VoidCallback onTap;

  const _BatchCard({
    required this.batchId,
    required this.location,
    required this.quantity,
    required this.inventoryName,
    this.requiredQty,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (requiredQty != null && quantity < requiredQty!) {
          // Show warning dialog
          final shouldContinue = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: AppColors.bgDark,
              title: const Text(
                'Insufficient Quantity',
                style: TextStyle(color: AppColors.gold),
              ),
              content: Text(
                'The selected batch has $quantity units, but $requiredQty are required. Do you want to continue?',
                style: const TextStyle(color: Colors.white),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text(
                    'Continue',
                    style: TextStyle(color: AppColors.gold),
                  ),
                ),
              ],
            ),
          );
          if (shouldContinue == true) {
            onTap();
          }
        } else {
          onTap();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Batch #$batchId',
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Qty: $quantity',
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white70, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    location,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.warehouse, color: Colors.white70, size: 16),
                const SizedBox(width: 6),
                Text(
                  inventoryName,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
