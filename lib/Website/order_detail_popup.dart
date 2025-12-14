import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../supabase_config.dart';

// Custom input formatter to allow only one decimal point
class _DecimalInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    // Only allow one decimal point
    if (text.contains('.') && text.indexOf('.') != text.lastIndexOf('.')) {
      return oldValue;
    }
    // Prevent leading decimal point
    if (text.startsWith('.')) {
      return oldValue;
    }
    return newValue;
  }
}

class OrderDetailPopup {
  static void show(
    BuildContext context, {
    required String orderType, // "in" أو "out"
    required String status, // "NEW" أو "UPDATE" أو "HOLD"
    required List<Map<String, dynamic>> products,
    String? partyName,
    String? location,
    DateTime? orderDate,
    num? taxPercent,
    num? totalPrice,
    int? orderId,
    VoidCallback? onOrderUpdated,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      builder: (_) => _OrderDetailDialog(
        orderType: orderType,
        status: status,
        products: products,
        partyName: partyName,
        location: location,
        orderDate: orderDate,
        taxPercent: taxPercent,
        totalPrice: totalPrice,
        orderId: orderId,
        onOrderUpdated: onOrderUpdated,
      ),
    );
  }
}

class _OrderDetailDialog extends StatefulWidget {
  final String orderType;
  final String status;
  final List<Map<String, dynamic>> products;
  final String? partyName;
  final String? location;
  final DateTime? orderDate;
  final num? taxPercent;
  final num? totalPrice;
  final int? orderId; // Add order ID to track which order to update
  final VoidCallback? onOrderUpdated;

  const _OrderDetailDialog({
    required this.orderType,
    required this.status,
    required this.products,
    this.partyName,
    this.location,
    this.orderDate,
    this.taxPercent,
    this.totalPrice,
    this.orderId,
    this.onOrderUpdated,
  });

  @override
  State<_OrderDetailDialog> createState() => _OrderDetailDialogState();
}

class _OrderDetailDialogState extends State<_OrderDetailDialog> {
  late List<Map<String, dynamic>> _products;
  late Map<int, int> _originalQuantities; // Track original quantities
  late Map<int, int>
  _productAvailableQty; // Store available quantity for each product
  late Set<int> _insufficientProducts; // Products with insufficient stock
  double _discountValue = 0.0;
  late TextEditingController _discountCtrl;

  @override
  void initState() {
    super.initState();
    _products = List<Map<String, dynamic>>.from(widget.products);
    _productAvailableQty = {};
    _insufficientProducts = {};
    _discountCtrl = TextEditingController();
    // Store original quantities to detect changes
    _originalQuantities = {};
    for (final product in _products) {
      final productId = _getProductId(product['id']);
      final quantity = (product['quantity'] ?? 0) as int;
      _originalQuantities[productId] = quantity;
    }
    // Validate inventory on init (only for stock-out orders)
    if (widget.orderType != 'in') {
      _validateInventory();
    }
    _discountCtrl.addListener(() {
      final value = double.tryParse(_discountCtrl.text) ?? 0.0;
      setState(() {
        _discountValue = value;
      });
    });
  }

  Future<void> _validateInventory() async {
    for (final product in _products) {
      // Handle product ID as either String or int
      final productIdValue = product['id'];
      final productId = productIdValue is int
          ? productIdValue
          : int.tryParse(productIdValue.toString()) ?? 0;
      try {
        final response = await supabase
            .from('product')
            .select('total_quantity')
            .eq('product_id', productId)
            .single();

        final availableQty = response['total_quantity'] as int?;
        final requestedQty = (product['quantity'] ?? 0) as int;

        if (availableQty != null) {
          _productAvailableQty[productId] = availableQty;

          if (requestedQty > availableQty) {
            setState(() {
              _insufficientProducts.add(productId);
            });
          }
        }
      } catch (e) {
        // Handle error silently or log it
      }
    }
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final suffix = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}-${dt.month}-${dt.year}';
  }

  String _formatMoney(num? value) {
    if (value == null) return '-';
    return '${value.toStringAsFixed(2)}\$';
  }

  int _getProductId(dynamic productIdValue) {
    if (productIdValue is int) return productIdValue;
    return int.tryParse(productIdValue.toString()) ?? 0;
  }

  num _calculateSubtotal() {
    num sum = 0;
    for (final p in _products) {
      final quantity = (p['quantity'] ?? 0) as num;
      final priceStr = p['price']?.toString() ?? '0';
      final price =
          num.tryParse(priceStr.replaceAll(RegExp(r'[^0-9.-]'), '')) ?? 0;
      sum += price * quantity;
    }
    return sum;
  }

  bool _hasQuantityChanged() {
    for (final product in _products) {
      final productId = _getProductId(product['id']);
      final currentQty = (product['quantity'] ?? 0) as int;
      final originalQty = _originalQuantities[productId] ?? 0;
      if (currentQty != originalQty) {
        return true;
      }
    }
    return false;
  }

  Map<String, dynamic> _calculateUpdatedPrices() {
    // Calculate subtotal with new quantities
    final subtotal = _calculateSubtotal();
    final discount = _discountValue;
    // Calculate tax
    final taxPercent = widget.taxPercent ?? 0;
    final taxAmount = subtotal * taxPercent / 100;
    // Calculate total with tax and discount
    final totalBalance = subtotal + taxAmount - discount;
    // Map of product IDs to their new total prices
    final Map<int, num> productTotals = {};
    for (final product in _products) {
      final productId = _getProductId(product['id']);
      final quantity = (product['quantity'] ?? 0) as num;
      final priceStr = product['price']?.toString() ?? '0';
      final price =
          num.tryParse(priceStr.replaceAll(RegExp(r'[^0-9.-]'), '')) ?? 0;
      productTotals[productId] = price * quantity;
    }
    return {
      'subtotal': subtotal,
      'tax_amount': taxAmount,
      'total_balance': totalBalance,
      'discount_value': discount,
      'product_totals': productTotals, // Map of product_id -> total_price
    };
  }

  String _calculateTotal() {
    final subtotal = _calculateSubtotal();
    final taxPercent = widget.taxPercent ?? 0;
    final taxAmount = subtotal * taxPercent / 100;
    final total = subtotal + taxAmount - _discountValue;
    return total <= 0 ? '-' : _formatMoney(total);
  }

  Future<void> _handleSendOrder(BuildContext context) async {
    try {
      // Skip inventory validation for stock-in orders
      if (widget.orderType != 'in') {
        // First, validate that all products have sufficient quantity in stock
        final insufficientProducts = <String>[];

        for (final product in _products) {
          final productId = _getProductId(product['id']);
          final requestedQty = (product['quantity'] ?? 0) as int;

          if (requestedQty <= 0) {
            insufficientProducts.add(
              '${product['name']}: Quantity must be greater than 0',
            );
            continue;
          }

          // Fetch product total_quantity from database
          final response = await supabase
              .from('product')
              .select('total_quantity')
              .eq('product_id', productId)
              .single();

          final availableQty = response['total_quantity'] as int?;

          if (availableQty == null || availableQty < requestedQty) {
            insufficientProducts.add(
              '${product['name']}: Insufficient stock (Available: $availableQty, Requested: $requestedQty)',
            );
          }
        }

        // If any products don't have enough stock, show error and don't proceed
        if (insufficientProducts.isNotEmpty) {
          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Insufficient Stock:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  ...insufficientProducts.map((msg) => Text('• $msg')).toList(),
                ],
              ),
              backgroundColor: Colors.red.shade700,
              duration: const Duration(seconds: 5),
            ),
          );
          return;
        }
      }

      if (!mounted) return;

      // Check if we need to update the order
      if (widget.orderId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error: Order ID not found'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      // All products have sufficient quantity, proceed with order update
      final quantityChanged = _hasQuantityChanged();
      final priceData = _calculateUpdatedPrices();
      final productTotals = priceData['product_totals'] as Map<int, num>;
      final discountValue = priceData['discount_value'] as double;
      // Update the database
      if (quantityChanged || discountValue > 0) {
        // Update customer_order table with new totals, discount, and status
        await supabase
            .from('customer_order')
            .update({
              'order_status': 'Pinned',
              'total_cost': priceData['subtotal'],
              'total_balance': priceData['total_balance'],
              'discount_value': discountValue,
              'last_action_by': 'System', // You should pass the actual user
              'last_action_time': DateTime.now().toIso8601String(),
            })
            .eq('customer_order_id', widget.orderId!);
        // Update customer_order_description for each product with changed quantity
        for (final product in _products) {
          final productId = _getProductId(product['id']);
          final newQty = (product['quantity'] ?? 0) as int;
          final originalQty = _originalQuantities[productId] ?? 0;
          // Only update if quantity changed
          if (newQty != originalQty) {
            await supabase
                .from('customer_order_description')
                .update({
                  'quantity': newQty,
                  'total_price': productTotals[productId],
                  'last_action_by': 'System', // You should pass the actual user
                  'last_action_time': DateTime.now().toIso8601String(),
                })
                .eq('customer_order_id', widget.orderId!)
                .eq('product_id', productId);
          }
        }
        // Notify parent to refresh lists
        widget.onOrderUpdated?.call();
        // Close dialog first
        if (!mounted) return;
        Navigator.pop(context);
        // Show success message in parent context
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Order updated to "Pinned" status.\n'
              'New Total: ${_formatMoney(priceData['total_balance'])}',
            ),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        // No quantity or discount changes, just update status to Pinned
        await supabase
            .from('customer_order')
            .update({
              'order_status': 'Pinned',
              'last_action_by': 'System', // You should pass the actual user
              'last_action_time': DateTime.now().toIso8601String(),
            })
            .eq('customer_order_id', widget.orderId!);
        // Notify parent to refresh lists
        widget.onOrderUpdated?.call();
        // Close dialog first
        if (!mounted) return;
        Navigator.pop(context);
        // Show success message in parent context
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Order status updated to "Pinned"'),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing order: $e'),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isCustomerOut = widget.orderType == "out";
    final bool isNew = widget.status == "NEW";
    final bool isHold = widget.status == "HOLD";
    final bool showDiscountField = isCustomerOut && (isNew || isHold);
    final bool showLaterButton = isNew;

    final orderDateValue = widget.orderDate ?? DateTime.now();
    final totalText = _calculateTotal();
    final taxText = widget.taxPercent != null
        ? '${widget.taxPercent.toString()}%'
        : '-';

    // discountCtrl is now a state variable

    return Stack(
      children: [
        // ---------- خلفية مغبشة ----------
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(color: Colors.black.withOpacity(0.3)),
        ),

        // ---------- محتوى الـ Popup ----------
        Center(
          child: Material(
            // ✅ إصلاح الخطأ هنا
            color: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 1000,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D2D),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ------------------------- العنوان -------------------------
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Order Detail',
                              style: GoogleFonts.roboto(
                                color: const Color(0xFFB7A447),
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: widget.status == "NEW"
                                    ? Colors.yellow.shade600
                                    : widget.status == "HOLD"
                                    ? Colors.orange.shade600
                                    : Colors.orangeAccent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                widget.status == "HOLD"
                                    ? "HOLD"
                                    : widget.status,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // -------------------- بيانات العميل / المورد --------------------
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            widget.orderType == "in"
                                ? "Supplier Name: ${widget.partyName ?? '-'}"
                                : "Customer: ${widget.partyName ?? '-'}",
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                        if (widget.orderType == "out") ...[
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "City : ${(widget.location?.split(' - ').isNotEmpty ?? false) ? widget.location!.split(' - ')[0] : '-'}",
                                  style: const TextStyle(fontSize: 15),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Quarter : ${(widget.location?.split(' - ').length ?? 0) > 1 ? widget.location!.split(' - ')[1] : '-'}",
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ],
                            ),
                          ),
                        ] else
                          const Spacer(flex: 3),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Date : ${_formatDate(orderDateValue)}",
                                style: const TextStyle(fontSize: 15),
                              ),
                              Text(
                                "Time : ${_formatTime(orderDateValue)}",
                                style: const TextStyle(fontSize: 15),
                              ),
                            ],
                          ),
                        ),
                        if (isCustomerOut)
                          Expanded(
                            flex: 2,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                "Tax percent : $taxText",
                                style: const TextStyle(fontSize: 15),
                              ),
                            ),
                          )
                        else
                          const Spacer(flex: 2),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // ------------------------- الجدول -------------------------
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Row(
                            children: const [
                              Expanded(
                                flex: 1,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text("Product ID #"),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Center(child: Text("Product Name")),
                              ),
                              Expanded(
                                flex: 2,
                                child: Center(child: Text("Brand")),
                              ),
                              Expanded(
                                flex: 2,
                                child: Center(child: Text("Price per product")),
                              ),
                              Expanded(
                                flex: 2,
                                child: Center(child: Text("Quantity")),
                              ),
                              Expanded(
                                flex: 2,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Text("Total Price"),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(color: Colors.white24, height: 0),

                        // الصفوف
                        for (final product in _products)
                          Column(
                            children: [
                              Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF252525),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 1,
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          product["id"].toString(),
                                          style: const TextStyle(
                                            color: Colors.amberAccent,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Center(
                                        child: Text(
                                          product["name"],
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Center(
                                        child: Text(
                                          product["brand"],
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Center(
                                        child: Text(
                                          product["price"],
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),

                                    // ------- Quantity with editable field -------
                                    Expanded(
                                      flex: 2,
                                      child: Center(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                (widget.orderType != 'in' &&
                                                    _insufficientProducts
                                                        .contains(
                                                          _getProductId(
                                                            product["id"],
                                                          ),
                                                        ))
                                                ? Colors.red.shade700
                                                : (product["quantity"] ?? 0) > 0
                                                ? const Color(0xFFB7A447)
                                                : const Color(0xFF6F6F6F),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            border:
                                                (widget.orderType != 'in' &&
                                                    _insufficientProducts
                                                        .contains(
                                                          _getProductId(
                                                            product["id"],
                                                          ),
                                                        ))
                                                ? Border.all(
                                                    color: Colors.red.shade300,
                                                    width: 2,
                                                  )
                                                : null,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              SizedBox(
                                                width: 40,
                                                child: TextFormField(
                                                  key: ValueKey(
                                                    'qty_${product["id"]}',
                                                  ),
                                                  initialValue:
                                                      product["quantity"] ==
                                                              0 ||
                                                          product["quantity"]
                                                              is! num
                                                      ? ''
                                                      : product["quantity"]
                                                            .toString(),
                                                  keyboardType:
                                                      TextInputType.number,
                                                  cursorColor: Colors.white,
                                                  inputFormatters: [
                                                    FilteringTextInputFormatter
                                                        .digitsOnly,
                                                  ],
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                  decoration:
                                                      const InputDecoration(
                                                        border:
                                                            InputBorder.none,
                                                        contentPadding:
                                                            EdgeInsets.zero,
                                                        isDense: true,
                                                        hintText: '0',
                                                        hintStyle: TextStyle(
                                                          color: Colors.black54,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                  onChanged: (value) {
                                                    setState(() {
                                                      final newQty =
                                                          int.tryParse(value) ??
                                                          0;
                                                      product["quantity"] =
                                                          newQty;

                                                      // Update the total for this product
                                                      final priceStr =
                                                          product['price']
                                                              ?.toString() ??
                                                          '0';
                                                      final price =
                                                          num.tryParse(
                                                            priceStr.replaceAll(
                                                              RegExp(
                                                                r'[^0-9.-]',
                                                              ),
                                                              '',
                                                            ),
                                                          ) ??
                                                          0;
                                                      final newTotal =
                                                          price * newQty;
                                                      product["total"] =
                                                          _formatMoney(
                                                            newTotal,
                                                          );

                                                      // Check if this product now has sufficient stock
                                                      // Handle product ID as either String or int
                                                      final productIdValue =
                                                          product['id'];
                                                      final productId =
                                                          productIdValue is int
                                                          ? productIdValue
                                                          : int.tryParse(
                                                                  productIdValue
                                                                      .toString(),
                                                                ) ??
                                                                0;
                                                      final availableQty =
                                                          _productAvailableQty[productId] ??
                                                          0;

                                                      // Check if this product now has sufficient stock (only for stock-out orders)
                                                      if (widget.orderType !=
                                                          'in') {
                                                        if (newQty >
                                                            availableQty) {
                                                          _insufficientProducts
                                                              .add(productId);
                                                        } else {
                                                          _insufficientProducts
                                                              .remove(
                                                                productId,
                                                              );
                                                        }
                                                      }
                                                    });
                                                  },
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                product["unit_name"] ?? 'pcs',
                                                style: TextStyle(
                                                  color: Colors.white
                                                      .withOpacity(0.9),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),

                                    Expanded(
                                      flex: 2,
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          product["total"].toString(),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Show warning message if product has insufficient stock (only for stock-out orders)
                              if (widget.orderType != 'in' &&
                                  _insufficientProducts.contains(
                                    _getProductId(product["id"]),
                                  ))
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 4,
                                    bottom: 8,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade900.withOpacity(
                                        0.3,
                                      ),
                                      border: Border.all(
                                        color: Colors.red.shade700,
                                        width: 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.warning_rounded,
                                          color: Colors.red.shade300,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Insufficient stock! Available: ${_productAvailableQty[_getProductId(product["id"])] ?? 0}, '
                                            'Requested: ${product["quantity"] ?? 0}',
                                            style: TextStyle(
                                              color: Colors.red.shade300,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ------------------------- Discount + Total -------------------------
                    Align(
                      alignment: Alignment.centerRight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (showDiscountField) ...[
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  "Discount",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: 140,
                                  height: 35,
                                  child: TextField(
                                    controller: _discountCtrl,
                                    style: const TextStyle(color: Colors.white),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'[0-9.]'),
                                      ),
                                      _DecimalInputFormatter(),
                                    ],
                                    decoration: InputDecoration(
                                      hintText: "Discount value",
                                      hintStyle: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 13,
                                      ),
                                      filled: true,
                                      fillColor: const Color(0xFF232427),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 8,
                                          ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFB7A447),
                                          width: 1.5,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(22),
                                        borderSide: const BorderSide(
                                          color: Color.fromARGB(
                                            255,
                                            255,
                                            222,
                                            74,
                                          ),
                                          width: 1.8,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                          ],
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                "Total Price : ",
                                style: TextStyle(
                                  color: Color(0xFFB7A447),
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                totalText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ------------------------- الأزرار -------------------------
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.status == "NEW") ...[
                          _OrderButton(
                            label: "Later",
                            color: Colors.grey.shade600,
                            icon: Icons.access_time,
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 14),
                        ],
                        _OrderButton(
                          label: widget.status == "UPDATE"
                              ? "Reject Update"
                              : "Reject Order",
                          color: Colors.red.shade700,
                          icon: Icons.cancel_outlined,
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 14),
                        _OrderButton(
                          label: widget.status == "UPDATE"
                              ? "Accept Update"
                              : widget.status == "HOLD"
                              ? "Send Order"
                              : "Send Order",
                          color: Colors.yellow.shade600,
                          icon: Icons.send_rounded,
                          onPressed: () => _handleSendOrder(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ------------------------ زر داخل الـ popup ------------------------
class _OrderButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onPressed;

  const _OrderButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.black),
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ------------------------ Read-Only Order Detail Popup ------------------------
class ReadOnlyOrderDetailPopup {
  static void show(
    BuildContext context, {
    required String orderType, // "in" or "out"
    required String status,
    required List<Map<String, dynamic>> products,
    String? partyName,
    String? location,
    DateTime? orderDate,
    num? taxPercent,
    num? totalPrice,
    int? orderId,
    Map<String, dynamic>? manager,
    Map<String, dynamic>? storageStaff,
    Map<String, dynamic>? deliveryDriver,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      builder: (_) => _ReadOnlyOrderDetailDialog(
        orderType: orderType,
        status: status,
        products: products,
        partyName: partyName,
        location: location,
        orderDate: orderDate,
        taxPercent: taxPercent,
        totalPrice: totalPrice,
        orderId: orderId,
        manager: manager,
        storageStaff: storageStaff,
        deliveryDriver: deliveryDriver,
      ),
    );
  }
}

class _ReadOnlyOrderDetailDialog extends StatelessWidget {
  final String orderType;
  final String status;
  final List<Map<String, dynamic>> products;
  final String? partyName;
  final String? location;
  final DateTime? orderDate;
  final num? taxPercent;
  final num? totalPrice;
  final int? orderId;
  final Map<String, dynamic>? manager;
  final Map<String, dynamic>? storageStaff;
  final Map<String, dynamic>? deliveryDriver;

  const _ReadOnlyOrderDetailDialog({
    required this.orderType,
    required this.status,
    required this.products,
    this.partyName,
    this.location,
    this.orderDate,
    this.taxPercent,
    this.totalPrice,
    this.orderId,
    this.manager,
    this.storageStaff,
    this.deliveryDriver,
  });
  Widget _buildActorRow() {
    // Show actors based on status
    List<Widget> children = [];
    final statusLower = status.toLowerCase();
    if (statusLower == 'sended to manager' && manager != null) {
      children.add(_actorTile('Manager', manager!['name'] ?? '-'));
    } else if ((statusLower == 'preparing' || statusLower == 'prepared')) {
      if (manager != null)
        children.add(_actorTile('Manager', manager!['name'] ?? '-'));
      if (storageStaff != null)
        children.add(_actorTile('Storage Staff', storageStaff!['name'] ?? '-'));
    } else if (statusLower == 'delivery' || statusLower == 'delivered') {
      if (manager != null)
        children.add(_actorTile('Manager', manager!['name'] ?? '-'));
      if (storageStaff != null)
        children.add(_actorTile('Storage Staff', storageStaff!['name'] ?? '-'));
      if (deliveryDriver != null)
        children.add(
          _actorTile('Delivery Driver', deliveryDriver!['name'] ?? '-'),
        );
    }
    if (children.isEmpty) return SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: children),
    );
  }

  Widget _actorTile(String label, String name) {
    return Padding(
      padding: const EdgeInsets.only(right: 18.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
          Text(name, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final suffix = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}-${dt.month}-${dt.year}';
  }

  String _formatMoney(num? value) {
    if (value == null) return '-';
    return '${value.toStringAsFixed(2)}\$';
  }

  @override
  Widget build(BuildContext context) {
    final bool isCustomerOut = orderType == "out";
    final orderDateValue = orderDate ?? DateTime.now();
    final taxText = taxPercent != null ? '${taxPercent.toString()}%' : '-';
    final totalText = totalPrice != null ? _formatMoney(totalPrice) : '-';

    return Stack(
      children: [
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(color: Colors.black.withOpacity(0.3)),
        ),
        Center(
          child: Material(
            color: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 1000,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D2D),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Order Detail',
                              style: GoogleFonts.roboto(
                                color: const Color(0xFFB7A447),
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blueGrey.shade200,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                status,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Actor info
                    _buildActorRow(),
                    // Party info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            orderType == "in"
                                ? "Supplier Name: " + (partyName ?? '-')
                                : "Customer: " + (partyName ?? '-'),
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                        if (orderType == "out") ...[
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "City : " +
                                      ((location?.split(' - ').isNotEmpty ??
                                              false)
                                          ? location!.split(' - ')[0]
                                          : '-'),
                                  style: const TextStyle(fontSize: 15),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Quarter : " +
                                      ((location?.split(' - ').length ?? 0) > 1
                                          ? location!.split(' - ')[1]
                                          : '-'),
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ],
                            ),
                          ),
                        ] else
                          const Spacer(flex: 3),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Date : ${_formatDate(orderDateValue)}",
                                style: const TextStyle(fontSize: 15),
                              ),
                              Text(
                                "Time : ${_formatTime(orderDateValue)}",
                                style: const TextStyle(fontSize: 15),
                              ),
                            ],
                          ),
                        ),
                        if (isCustomerOut)
                          Expanded(
                            flex: 2,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                "Tax percent : $taxText",
                                style: const TextStyle(fontSize: 15),
                              ),
                            ),
                          )
                        else
                          const Spacer(flex: 2),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Product table
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Row(
                            children: const [
                              Expanded(
                                flex: 1,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text("Product ID #"),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Center(child: Text("Product Name")),
                              ),
                              Expanded(
                                flex: 2,
                                child: Center(child: Text("Brand")),
                              ),
                              Expanded(
                                flex: 2,
                                child: Center(child: Text("Price per product")),
                              ),
                              Expanded(
                                flex: 2,
                                child: Center(child: Text("Quantity")),
                              ),
                              Expanded(
                                flex: 2,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Text("Total Price"),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(color: Colors.white24, height: 0),
                        for (final product in products)
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF252525),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      product["id"].toString(),
                                      style: const TextStyle(
                                        color: Colors.amberAccent,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Center(
                                    child: Text(
                                      product["name"],
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Center(
                                    child: Text(
                                      product["brand"],
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Center(
                                    child: Text(
                                      product["price"],
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Center(
                                    child: Text(
                                      product["quantity"].toString(),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      product["total"].toString(),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Total
                    Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Total Price : ",
                            style: TextStyle(
                              color: Color(0xFFB7A447),
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            totalText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Only close button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade600,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.black),
                          label: const Text(
                            'Close',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
