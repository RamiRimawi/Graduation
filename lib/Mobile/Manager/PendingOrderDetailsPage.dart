import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../manager_theme.dart';
import 'SelectStaffSheet.dart';
import 'SelectBatchSheet.dart';
import 'order_service.dart';
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

    // Here you would implement the logic to send update to accountant
    // For now, just show a success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Order update sent to accountant for review'),
        backgroundColor: Colors.green,
      ),
    );

    // You might want to navigate back or update the order status
    // Navigator.pop(context, true);
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
  late int? _selectedStaffId;
  late int? _selectedInventoryId;
  late String? _selectedStaffName;
  late Map<int, int> _selectedBatchIds;
  late Map<int, String> _selectedBatchDisplays;
  bool _showOrderDetails = false;

  @override
  void initState() {
    super.initState();
    _selectedStaffId = null;
    _selectedInventoryId = null;
    _selectedStaffName = null;
    _selectedBatchIds = {};
    _selectedBatchDisplays = {};
  }

  void _pickBatchForItem(int itemIndex) {
    if (_selectedInventoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select staff first to lock an inventory'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    final item = widget.orderData.items[itemIndex];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SelectBatchSheet(
        productId: item.productId,
        inventoryId: _selectedInventoryId,
        requiredQty: item.qty,
        onSelected: (batchId, displayText) {
          Navigator.pop(context);
          setState(() {
            _selectedBatchIds[itemIndex] = batchId;
            _selectedBatchDisplays[itemIndex] = displayText;
          });
        },
      ),
    );
  }

  void _confirmAndSend() {
    if (_selectedStaffId == null || _selectedInventoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select staff'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    Navigator.pop(context);
    widget.onConfirm(
      _selectedStaffId!,
      _selectedInventoryId!,
      _selectedBatchIds,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_showOrderDetails) {
      return _buildStaffSelector();
    }
    return _buildOrderDetails();
  }

  Widget _buildStaffSelector() {
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
            'Select Staff',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Choose a staff member to assign this order',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 2),
          ConstrainedBox(
            constraints: BoxConstraints(
              // Allow the staff selector to size to its content but cap height
              // so it doesn't force the modal to full screen.
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: SelectStaffSheet(
              onSelected: (staffId, inventoryId, displayName) {
                setState(() {
                  _selectedStaffId = staffId;
                  _selectedInventoryId = inventoryId;
                  _selectedStaffName = displayName;
                });
              },
              isModal: false,
              preSelectedStaffName: _selectedStaffName,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedStaffId != null
                  ? () {
                      setState(() => _showOrderDetails = true);
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
    );
  }

  Widget _buildOrderDetails() {
    final items = widget.orderData.items;

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
                      onTap: () => setState(() => _showOrderDetails = false),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Order Details',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Staff: $_selectedStaffName',
                            style: const TextStyle(
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
              itemCount: items.length,
              itemBuilder: (_, i) {
                final item = items[i];
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
                        onTap: () => _pickBatchForItem(i),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: _selectedBatchDisplays[i] != null
                                ? AppColors.gold.withOpacity(0.2)
                                : Colors.orange.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _selectedBatchDisplays[i] != null
                                  ? AppColors.gold
                                  : Colors.orange,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.inventory_2,
                                color: _selectedBatchDisplays[i] != null
                                    ? AppColors.gold
                                    : Colors.orange,
                                size: 14,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _selectedBatchDisplays[i] ?? 'Select Batch',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: _selectedBatchDisplays[i] != null
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
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                SizedBox(
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
              ],
            ),
          ),
        ],
      ),
    );
  }
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
                        Icon(Icons.arrow_forward, color: Colors.white, size: 20),
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
