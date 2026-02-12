import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'manager_theme.dart';

class SelectBatchSheet extends StatefulWidget {
  final int productId;
  final int? inventoryId; // Optional: filter by inventory
  final int? requiredQty; // Optional: required quantity to check against batch
  final bool isStockOut; // If true, enables auto-selection for stock-out (FIFO)
  final int? currentlySelectedBatchId; // Currently selected batch to highlight
  final void Function(int batchId, String displayText) onSelected;

  const SelectBatchSheet({
    super.key,
    required this.productId,
    this.inventoryId,
    this.requiredQty,
    this.isStockOut = false,
    this.currentlySelectedBatchId,
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
  int? _newlyCreatedBatchId;
  bool _batchWasSelected = false;
  int? _preSelectedBatchId;

  @override
  void initState() {
    super.initState();
    // Initialize pre-selected batch if provided
    if (widget.currentlySelectedBatchId != null) {
      _preSelectedBatchId = widget.currentlySelectedBatchId;
    }
    _fetchBatches();
  }

  @override
  void dispose() {
    // If a batch was created but not selected, delete it
    if (_newlyCreatedBatchId != null && !_batchWasSelected) {
      _deleteUnselectedBatch();
    }
    super.dispose();
  }

  Future<void> _deleteUnselectedBatch() async {
    try {
      await supabase
          .from('batch')
          .delete()
          .eq('batch_id', _newlyCreatedBatchId!)
          .eq('product_id', widget.productId);
      debugPrint('Deleted unselected batch #$_newlyCreatedBatchId');
    } catch (e) {
      debugPrint('Error deleting unselected batch: $e');
    }
  }

  Future<void> _fetchBatches() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      // Build query - include production_date and expiry_date for auto-selection
      var query = supabase
          .from('batch')
          .select(
            'batch_id, quantity, storage_location_descrption, inventory_id, inventory:inventory_id(inventory_name), production_date, expiry_date',
          )
          .eq('product_id', widget.productId);

      // Filter by inventory if specified
      if (widget.inventoryId != null) {
        query = query.eq('inventory_id', widget.inventoryId!);
      }

      final response = await query.order('batch_id');

      setState(() {
        _batches = List<Map<String, dynamic>>.from(response);
        _loading = false;
      });

      // Auto-select batch using FIFO if nothing is selected yet
      if (_preSelectedBatchId == null &&
          widget.isStockOut &&
          widget.requiredQty != null &&
          _batches.isNotEmpty) {
        _autoSelectBatch();
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
      debugPrint('Error fetching batches: $e');
    }
  }

  void _autoSelectBatch() {
    final now = DateTime.now();

    // Filter batches that meet criteria
    final suitableBatches = _batches.where((batch) {
      final quantity = batch['quantity'] as int;

      // Must have enough quantity
      if (quantity < widget.requiredQty!) return false;

      // Check expiry date if present
      final expiryDateStr = batch['expiry_date'] as String?;
      if (expiryDateStr != null) {
        final expiryDate = DateTime.parse(expiryDateStr);
        // Exclude if expired
        if (expiryDate.isBefore(now)) return false;
      }

      return true;
    }).toList();

    if (suitableBatches.isEmpty) return;

    // Sort by production_date (oldest first)
    suitableBatches.sort((a, b) {
      final aDateStr = a['production_date'] as String?;
      final bDateStr = b['production_date'] as String?;

      // Batches with production_date come first
      if (aDateStr != null && bDateStr == null) return -1;
      if (aDateStr == null && bDateStr != null) return 1;

      // If both have production_date, sort by oldest first
      if (aDateStr != null && bDateStr != null) {
        final aDate = DateTime.parse(aDateStr);
        final bDate = DateTime.parse(bDateStr);
        return aDate.compareTo(bDate);
      }

      // If neither has production_date, maintain original order
      return 0;
    });

    // Pre-select the first suitable batch (don't close modal)
    final selectedBatch = suitableBatches.first;
    final batchId = selectedBatch['batch_id'] as int;

    setState(() {
      _preSelectedBatchId = batchId;
    });
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

                  final isPreSelected = _preSelectedBatchId == batchId;

                  return GestureDetector(
                    onTap: () async {
                      if (widget.requiredQty != null &&
                          quantity < widget.requiredQty!) {
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
                              'The selected batch has $quantity units, but ${widget.requiredQty} are required. Do you want to continue?',
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
                        if (shouldContinue != true) return;
                      }

                      _batchWasSelected = true;
                      widget.onSelected(batchId, displayText);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isPreSelected
                            ? AppColors.gold.withOpacity(0.15)
                            : AppColors.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isPreSelected
                              ? AppColors.gold
                              : Colors.white24,
                          width: isPreSelected ? 2 : 1,
                        ),
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
                                  fontSize: 16,
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
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'Qty: $quantity',
                                  style: const TextStyle(
                                    color: AppColors.gold,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Colors.white70,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  location,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.warehouse,
                                color: Colors.white70,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                inventoryName,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

          // Create New Batch Button - ONLY for stock-in orders
          if (widget.inventoryId != null && !widget.isStockOut)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showCreateBatchDialog(context),
                  icon: const Icon(Icons.add_box, color: Colors.black),
                  label: const Text(
                    'Create New Batch',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Future<void> _showCreateBatchDialog(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) => _CreateBatchDialog(
        productId: widget.productId,
        inventoryId: widget.inventoryId!,
      ),
    );

    if (result != null && mounted) {
      // Store the newly created batch ID for cleanup if not selected
      _newlyCreatedBatchId = result['batch_id'] as int;

      // Refresh the batch list to show the newly created batch
      await _fetchBatches();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Batch created successfully! Select it from the list.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}

// Create New Batch Dialog
class _CreateBatchDialog extends StatefulWidget {
  final int productId;
  final int inventoryId;

  const _CreateBatchDialog({
    required this.productId,
    required this.inventoryId,
  });

  @override
  State<_CreateBatchDialog> createState() => _CreateBatchDialogState();
}

class _CreateBatchDialogState extends State<_CreateBatchDialog> {
  final _formKey = GlobalKey<FormState>();
  final _floorController = TextEditingController();
  final _aisleController = TextEditingController();
  final _shelfController = TextEditingController();
  DateTime? _expiryDate;
  DateTime? _productionDate;
  bool _isCreating = false;

  @override
  void dispose() {
    _floorController.dispose();
    _aisleController.dispose();
    _shelfController.dispose();
    super.dispose();
  }

  String _buildStorageLocation() {
    final floor = _floorController.text.trim();
    final aisle = _aisleController.text.trim();
    final shelf = _shelfController.text.trim();
    return 'Floor $floor - Aisle $aisle - Shelf $shelf';
  }

  Future<void> _createBatch() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final managerName = prefs.getString('current_user_name') ?? 'Unknown';
      final storageLocation = _buildStorageLocation();

      final Map<String, dynamic> batchData = {
        'product_id': widget.productId,
        'inventory_id': widget.inventoryId,
        'storage_location_descrption': storageLocation,
        'last_action_by': managerName,
        'last_action_time': DateTime.now().toIso8601String(),
        'quantity': 0, // Initial quantity is 0, will be updated when receiving
      };

      if (_expiryDate != null) {
        batchData['expiry_date'] = _expiryDate!.toIso8601String().split('T')[0];
      }

      if (_productionDate != null) {
        batchData['production_date'] = _productionDate!.toIso8601String().split(
          'T',
        )[0];
      }

      final response = await Supabase.instance.client
          .from('batch')
          .insert(batchData)
          .select('batch_id')
          .single();

      if (mounted) {
        Navigator.pop(context, {
          'batch_id': response['batch_id'] as int,
          'storage_location': storageLocation,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create batch: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  Future<void> _pickDate(bool isExpiry) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.gold,
              onPrimary: Colors.black,
              surface: AppColors.card,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isExpiry) {
          _expiryDate = picked;
        } else {
          _productionDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.bgDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create New Batch',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Fill in the batch storage location details',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 24),

                // Storage Location Section
                const Text(
                  'Storage Location *',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),

                // Floor
                TextFormField(
                  controller: _floorController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Floor Number',
                    hintText: 'e.g., 1, 2, 3',
                    labelStyle: const TextStyle(color: Colors.white70),
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: AppColors.card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.layers, color: AppColors.gold),
                  ),
                  validator: (value) =>
                      value?.trim().isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 12),

                // Aisle
                TextFormField(
                  controller: _aisleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Aisle Number',
                    hintText: 'e.g., 1, 2, 3',
                    labelStyle: const TextStyle(color: Colors.white70),
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: AppColors.card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(
                      Icons.view_week,
                      color: AppColors.gold,
                    ),
                  ),
                  validator: (value) =>
                      value?.trim().isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 12),

                // Shelf
                TextFormField(
                  controller: _shelfController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Shelf Number',
                    hintText: 'e.g., 1, 2, 3',
                    labelStyle: const TextStyle(color: Colors.white70),
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: AppColors.card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(
                      Icons.shelves,
                      color: AppColors.gold,
                    ),
                  ),
                  validator: (value) =>
                      value?.trim().isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 24),

                // Optional Dates Section
                const Text(
                  'Optional Dates',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),

                // Production Date
                InkWell(
                  onTap: () => _pickDate(false),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: AppColors.gold),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Production Date',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _productionDate != null
                                    ? '${_productionDate!.day}/${_productionDate!.month}/${_productionDate!.year}'
                                    : 'Not set',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Expiry Date
                InkWell(
                  onTap: () => _pickDate(true),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.event_busy, color: AppColors.gold),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Expiry Date',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _expiryDate != null
                                    ? '${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}'
                                    : 'Not set',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isCreating
                          ? null
                          : () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isCreating ? null : _createBatch,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isCreating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Text(
                              'Create',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
