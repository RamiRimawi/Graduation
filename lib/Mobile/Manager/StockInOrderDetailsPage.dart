import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'manager_theme.dart';
import 'SelectBatchSheet.dart';
import 'StockInOrderSplitPage.dart';

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
  int? _supplierId;
  // ignore: unused_field
  String _orderStatus = '';
  // ignore: unused_field
  DateTime? _orderDate;
  List<OrderItem> _items = [];

  // Inventory and batch selections
  int? _selectedInventoryId;
  String? _selectedInventoryName;
  final Map<int, int?> _selectedBatchIds = {};
  final Map<int, String> _selectedBatchDisplays = {};

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
          .select(
            'supplier_id, supplier:supplier_id(name), order_status, order_date',
          )
          .eq('order_id', widget.orderId)
          .single();

      _supplierId = orderResponse['supplier_id'] as int?;
      _supplierName = orderResponse['supplier']['name'] as String? ?? 'Unknown';
      _orderStatus = orderResponse['order_status'] as String? ?? 'Unknown';
      _orderDate = orderResponse['order_date'] != null
          ? DateTime.parse(orderResponse['order_date'] as String)
          : null;

      // Fetch order items from supplier_order_description
      final descriptionResponse = await supabase
          .from('supplier_order_description')
          .select('product_id, quantity')
          .eq('order_id', widget.orderId);

      if (descriptionResponse.isEmpty) {
        setState(() => _loading = false);
        return;
      }

      // Get product IDs
      final productIds = descriptionResponse
          .map((row) => row['product_id'] as int)
          .toList();

      // Fetch product details
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

      Map<int, dynamic> brandMap = {};
      if (brandIds.isNotEmpty) {
        final brandsResponse = await supabase
            .from('brand')
            .select('brand_id, name')
            .inFilter('brand_id', brandIds);

        brandMap = {for (var b in brandsResponse) b['brand_id'] as int: b};
      }

      // Fetch unit details
      final unitIds = productsResponse
          .map((p) => p['unit_id'] as int?)
          .where((id) => id != null)
          .toSet()
          .toList();

      Map<int, dynamic> unitMap = {};
      if (unitIds.isNotEmpty) {
        final unitsResponse = await supabase
            .from('unit')
            .select('unit_id, unit_name')
            .inFilter('unit_id', unitIds);

        unitMap = {for (var u in unitsResponse) u['unit_id'] as int: u};
      }

      // Build items list
      final List<OrderItem> items = [];

      for (final row in descriptionResponse) {
        final productId = row['product_id'] as int?;
        final quantityRaw = row['quantity'];
        final quantity = quantityRaw is int
            ? quantityRaw
            : (quantityRaw is String ? int.tryParse(quantityRaw) ?? 0 : 0);

        if (productId == null) continue;

        final product = productMap[productId];
        if (product == null) continue;

        final brandId = product['brand_id'] as int?;
        final unitId = product['unit_id'] as int?;
        final brand = brandId != null ? brandMap[brandId] : null;
        final unit = unitId != null ? unitMap[unitId] : null;

        items.add(
          OrderItem(
            productId: productId,
            name: product['name'] as String? ?? 'Unknown',
            brand: brand?['name'] as String? ?? 'Unknown',
            unit: unit?['unit_name'] as String? ?? 'Unit',
            qty: quantity,
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

  void _pickBatchForItem(int itemIndex, StateSetter setModalState) {
    if (_selectedInventoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select inventory first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    final item = _items[itemIndex];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SelectBatchSheet(
        productId: item.productId,
        inventoryId: _selectedInventoryId!,
        onSelected: (batchId, displayText) {
          setState(() {
            _selectedBatchIds[itemIndex] = batchId;
            _selectedBatchDisplays[itemIndex] = displayText;
          });
          setModalState(() {
            // This rebuilds the modal to show the selected batch
          });
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _openInventorySelectionModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _InventorySelectionModal(
        onSelected: (inventoryId, inventoryName) {
          Navigator.pop(context);
          setState(() {
            _selectedInventoryId = inventoryId;
            _selectedInventoryName = inventoryName;
          });
          _openBatchSelectionModal();
        },
      ),
    );
  }

  void _openBatchSelectionModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return _BatchSelectionModal(
            items: _items,
            inventoryId: _selectedInventoryId!,
            inventoryName: _selectedInventoryName!,
            selectedBatchDisplays: _selectedBatchDisplays,
            onPickBatch: (itemIndex) =>
                _pickBatchForItem(itemIndex, setModalState),
            onConfirm: _confirmReception,
          );
        },
      ),
    );
  }

  Future<void> _confirmReception() async {
    // Validate that all batches are selected
    for (int i = 0; i < _items.length; i++) {
      if (!_selectedBatchIds.containsKey(i) || _selectedBatchIds[i] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select batch for all products'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

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

      // Update supplier_order_description with receipt_quantity
      for (int i = 0; i < _items.length; i++) {
        final item = _items[i];
        await Supabase.instance.client
            .from('supplier_order_description')
            .update({
              'receipt_quantity': item.qty,
              'last_tracing_by': managerName,
              'last_tracing_time': DateTime.now().toIso8601String(),
            })
            .eq('order_id', widget.orderId)
            .eq('product_id', item.productId);
      }

      // Update supplier_order to Delivered
      await Supabase.instance.client
          .from('supplier_order')
          .update({
            'order_status': 'Delivered',
            'receives_by_id': managerId,
            'last_tracing_by': managerName,
            'last_tracing_time': DateTime.now().toIso8601String(),
          })
          .eq('order_id', widget.orderId);

      // Insert into supplier_order_inventory for each product
      final inventoryInserts = <Map<String, dynamic>>[];
      for (int i = 0; i < _items.length; i++) {
        final item = _items[i];
        final batchId = _selectedBatchIds[i];

        inventoryInserts.add({
          'supplier_order_id': widget.orderId,
          'product_id': item.productId,
          'inventory_id': _selectedInventoryId!,
          'batch_id': batchId,
          'quantity': item.qty,
        });
      }

      await Supabase.instance.client
          .from('supplier_order_inventory')
          .insert(inventoryInserts);
      //Update batch table: add quantity and set supplier info
      final now = DateTime.now().toIso8601String();
      for (int i = 0; i < _items.length; i++) {
        final item = _items[i];
        final batchId = _selectedBatchIds[i]!;

        // Fetch current batch quantity
        final batchData = await Supabase.instance.client
            .from('batch')
            .select('quantity')
            .eq('batch_id', batchId)
            .eq('product_id', item.productId)
            .single();

        final currentQty = (batchData['quantity'] as int?) ?? 0;
        final newQty = currentQty + item.qty;

        // Update batch with new quantity and supplier info
        await Supabase.instance.client
            .from('batch')
            .update({
              'quantity': newQty,
              'supplier_id': _supplierId,
              'last_action_by': managerName,
              'last_action_time': now,
            })
            .eq('batch_id', batchId)
            .eq('product_id', item.productId);
      }

      // Update product table: increment total_quantity
      for (int i = 0; i < _items.length; i++) {
        final item = _items[i];

        // Fetch current product total_quantity
        final productData = await Supabase.instance.client
            .from('product')
            .select('total_quantity')
            .eq('product_id', item.productId)
            .single();

        final currentTotal = (productData['total_quantity'] as int?) ?? 0;
        final newTotal = currentTotal + item.qty;

        // Update product total_quantity
        await Supabase.instance.client
            .from('product')
            .update({'total_quantity': newTotal})
            .eq('product_id', item.productId);
      }

      //
      // Close loading and batch modal, show success
      if (mounted) {
        Navigator.pop(context); // Close loading
        Navigator.pop(context); // Close batch modal
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order received successfully!'),
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
            content: Text('Failed to receive order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openSplitOrderPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StockInOrderSplitPage(
          orderId: widget.orderId,
          supplierName: _supplierName,
          items: _items,
        ),
      ),
    );

    if (result == true && mounted) {
      Navigator.pop(context, true);
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

    final items = _items;

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
                    _supplierName,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Products header
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

              // Products list
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final item = items[i];
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
                      child: Row(
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
                          Expanded(
                            flex: 3,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
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
                                          setState(
                                            () => item.qty =
                                                int.tryParse(v) ?? item.qty,
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
                                  Expanded(
                                    child: Text(
                                      item.unit,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
                  onPressed: _openSplitOrderPage,
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

              // DONE BUTTON
              GestureDetector(
                onTap: _openInventorySelectionModal,
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

// Inventory selection modal for stock-in
class _InventorySelectionModal extends StatefulWidget {
  final void Function(int inventoryId, String inventoryName) onSelected;

  const _InventorySelectionModal({required this.onSelected});

  @override
  State<_InventorySelectionModal> createState() =>
      _InventorySelectionModalState();
}

class _InventorySelectionModalState extends State<_InventorySelectionModal> {
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
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.65,
        child: Column(
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
            const SizedBox(height: 6),
            const Text(
              'Choose where to receive this order',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 12),
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
                  'Next',
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
      ),
    );
  }
}

// Batch selection modal for stock-in
class _BatchSelectionModal extends StatefulWidget {
  final List<OrderItem> items;
  final int inventoryId;
  final String inventoryName;
  final Map<int, String> selectedBatchDisplays;
  final void Function(int itemIndex) onPickBatch;
  final VoidCallback onConfirm;

  const _BatchSelectionModal({
    required this.items,
    required this.inventoryId,
    required this.inventoryName,
    required this.selectedBatchDisplays,
    required this.onPickBatch,
    required this.onConfirm,
  });

  @override
  State<_BatchSelectionModal> createState() => _BatchSelectionModalState();
}

class _BatchSelectionModalState extends State<_BatchSelectionModal> {
  bool _showValidationErrors = false;

  void _handleConfirm() {
    // Check if all items have batch selected
    for (int i = 0; i < widget.items.length; i++) {
      if (!widget.selectedBatchDisplays.containsKey(i) ||
          widget.selectedBatchDisplays[i] == null) {
        setState(() {
          _showValidationErrors = true;
        });
        widget.onConfirm();
        return;
      }
    }
    widget.onConfirm();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Batches for ${widget.inventoryName}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pick a batch for each product',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: widget.items.length,
                itemBuilder: (_, i) {
                  final item = widget.items[i];
                  final display = widget.selectedBatchDisplays[i];

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
                                '${item.qty} ${item.unit}',
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
                          onTap: () => widget.onPickBatch(i),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: display != null
                                  ? AppColors.gold.withOpacity(0.2)
                                  : Colors.orange.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: display != null
                                    ? AppColors.gold
                                    : Colors.orange,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.inventory_2,
                                  color: display != null
                                      ? AppColors.gold
                                      : Colors.orange,
                                  size: 14,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    display ?? 'Select Batch',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: display != null
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
                        if (_showValidationErrors && display == null) ...[
                          const SizedBox(height: 6),
                          const Text(
                            '⚠ You need to select a batch',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Confirm',
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
      ),
    );
  }
}

class OrderItem {
  final int productId;
  final String name;
  final String brand;
  final String unit;
  int qty;

  OrderItem({
    required this.productId,
    required this.name,
    required this.brand,
    required this.unit,
    required this.qty,
  });
}
