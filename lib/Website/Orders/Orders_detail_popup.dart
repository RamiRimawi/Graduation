import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../supabase_config.dart';

// Helper functions to get accountant information
Future<int?> getAccountantId() async {
  final prefs = await SharedPreferences.getInstance();
  final id = prefs.getInt('accountant_id');
  if (id != null) return id;
  // If not found in prefs, get from DB where is_active = true and type = 'Accountant'
  final response = await supabase
      .from('accounts')
      .select('user_id')
      .eq('is_active', true)
      .eq('type', 'Accountant')
      .maybeSingle();
  return response != null ? response['user_id'] as int? : null;
}

Future<String?> getAccountantName(int accountantId) async {
  final response = await supabase
      .from('accountant')
      .select('name')
      .eq('accountant_id', accountantId)
      .maybeSingle();
  return response != null ? response['name'] as String? : null;
}

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
    num? discountValue,
    int? orderId,
    String? updateDescription,
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
        discountValue: discountValue,
        orderId: orderId,
        updateDescription: updateDescription,
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
  final num? discountValue;
  final int? orderId; // Add order ID to track which order to update
  final VoidCallback? onOrderUpdated;
  final String? updateDescription;

  const _OrderDetailDialog({
    required this.orderType,
    required this.status,
    required this.products,
    this.partyName,
    this.location,
    this.orderDate,
    this.taxPercent,
    this.totalPrice,
    this.discountValue,
    this.orderId,
    this.updateDescription,
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
    // Initialize discount value from widget parameter
    _discountValue = (widget.discountValue ?? 0.0).toDouble();
    // Format the discount value properly for display
    final discountText = _discountValue > 0
        ? (_discountValue % 1 == 0
              ? _discountValue.toInt().toString()
              : _discountValue.toString())
        : '';
    _discountCtrl = TextEditingController(text: discountText);
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
    // For UPDATE status, don't apply tax or discount
    if (widget.status == "UPDATE") {
      // Calculate product totals for UPDATE status
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
        'total_balance': subtotal,
        'product_totals': productTotals,
      };
    }
    // Only apply discount when discount field is shown (NEW/HOLD status)
    final discount =
        (widget.orderType == "out" &&
            (widget.status == "NEW" || widget.status == "HOLD"))
        ? _discountValue
        : 0;
    // Calculate tax
    final taxPercent = widget.taxPercent ?? 0;
    final taxAmount = subtotal * taxPercent / 100;
    // Calculate total_balance as: total_cost * (1 + tax_percent/100) - discount
    final totalBalance = (subtotal * (1 + taxPercent / 100)) - discount;
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
    // For UPDATE status, show only subtotal (no tax/discount) since accountant is reviewing quantity changes
    if (widget.status == "UPDATE") {
      return subtotal <= 0 ? '-' : _formatMoney(subtotal);
    }
    final taxPercent = widget.taxPercent ?? 0;
    final taxAmount = subtotal * taxPercent / 100;
    // Only apply discount when discount field is shown (NEW/HOLD status)
    final discount =
        (widget.orderType == "out" &&
            (widget.status == "NEW" || widget.status == "HOLD"))
        ? _discountValue
        : 0;
    // Calculate total_balance as: total_cost * (1 + tax_percent/100) - discount
    final total = (subtotal * (1 + taxPercent / 100)) - discount;
    return total <= 0 ? '-' : _formatMoney(total);
  }

  // ============= HANDLERS FOR "IN" ORDERS (NEW) =============
  Future<void> _handleRejectNewIn(BuildContext context) async {
    try {
      if (widget.orderId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error: Order ID not found'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      // Delete from supplier_order_description first (foreign key)
      await supabase
          .from('supplier_order_description')
          .delete()
          .eq('order_id', widget.orderId!);

      // Delete from supplier_order
      await supabase
          .from('supplier_order')
          .delete()
          .eq('order_id', widget.orderId!);

      // Notify parent to refresh
      widget.onOrderUpdated?.call();

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Order deleted successfully'),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting order: $e'),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _handleLaterNewIn(BuildContext context) async {
    try {
      if (widget.orderId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error: Order ID not found'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      // Get accountant information
      final accountantId = await getAccountantId();
      String? accountantName;
      if (accountantId != null) {
        accountantName = await getAccountantName(accountantId);
      }
      accountantName ??= 'System';

      final quantityChanged = _hasQuantityChanged();
      final priceData = _calculateUpdatedPrices();
      final productTotals = priceData['product_totals'] as Map<int, num>;

      // Update supplier_order to Hold
      await supabase
          .from('supplier_order')
          .update({
            'order_status': 'Hold',
            'total_cost': priceData['subtotal'],
            'total_balance':
                priceData['subtotal'], // no tax for supplier orders
            'last_tracing_by': accountantName,
            'last_tracing_time': DateTime.now().toIso8601String(),
          })
          .eq('order_id', widget.orderId!);

      // Update quantities if changed
      if (quantityChanged) {
        for (final product in _products) {
          final productId = _getProductId(product['id']);
          final currentQty = (product['quantity'] ?? 0) as int;
          final originalQty = _originalQuantities[productId] ?? 0;
          if (currentQty != originalQty) {
            await supabase
                .from('supplier_order_description')
                .update({
                  'quantity': currentQty,
                  'total_price': productTotals[productId],
                  'last_tracing_by': accountantName,
                  'last_tracing_time': DateTime.now().toIso8601String(),
                })
                .eq('order_id', widget.orderId!)
                .eq('product_id', productId);
          }
        }
      }

      widget.onOrderUpdated?.call();

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Order set to Hold'),
          backgroundColor: Colors.orange.shade700,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error setting order to Hold: $e'),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _handleLaterNewOut(BuildContext context) async {
    try {
      if (widget.orderId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error: Order ID not found'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      // Get accountant information
      final accountantId = await getAccountantId();
      String? accountantName;
      if (accountantId != null) {
        accountantName = await getAccountantName(accountantId);
      }
      accountantName ??= 'System';

      final quantityChanged = _hasQuantityChanged();
      final priceData = _calculateUpdatedPrices();
      final productTotals = priceData['product_totals'] as Map<int, num>;
      final discountValue = priceData['discount_value'] as double;

      // Update customer_order to Hold
      await supabase
          .from('customer_order')
          .update({
            'order_status': 'Hold',
            'total_cost': priceData['subtotal'],
            'total_balance': priceData['total_balance'],
            'discount_value': discountValue,
            'last_action_by': accountantName,
            'last_action_time': DateTime.now().toIso8601String(),
          })
          .eq('customer_order_id', widget.orderId!);

      // Update quantities if changed
      if (quantityChanged) {
        for (final product in _products) {
          final productId = _getProductId(product['id']);
          final currentQty = (product['quantity'] ?? 0) as int;
          final originalQty = _originalQuantities[productId] ?? 0;
          if (currentQty != originalQty) {
            await supabase
                .from('customer_order_description')
                .update({
                  'quantity': currentQty,
                  'total_price': productTotals[productId],
                  'last_action_by': accountantName,
                  'last_action_time': DateTime.now().toIso8601String(),
                })
                .eq('customer_order_id', widget.orderId!)
                .eq('product_id', productId);
          }
        }
      }

      widget.onOrderUpdated?.call();

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Order set to Hold'),
          backgroundColor: Colors.white70,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error setting order to Hold: $e'),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _handleSendNewIn(BuildContext context) async {
    try {
      if (widget.orderId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error: Order ID not found'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      // Get accountant information
      final accountantId = await getAccountantId();
      String? accountantName;
      if (accountantId != null) {
        accountantName = await getAccountantName(accountantId);
      }
      accountantName ??= 'System';

      final quantityChanged = _hasQuantityChanged();
      final priceData = _calculateUpdatedPrices();
      final productTotals = priceData['product_totals'] as Map<int, num>;

      // Update supplier_order to Sent
      await supabase
          .from('supplier_order')
          .update({
            'order_status': 'Sent',
            'total_cost': priceData['subtotal'],
            'total_balance':
                priceData['subtotal'], // no tax for supplier orders
            'last_tracing_by': accountantName,
            'last_tracing_time': DateTime.now().toIso8601String(),
          })
          .eq('order_id', widget.orderId!);

      // Update quantities if changed
      if (quantityChanged) {
        for (final product in _products) {
          final productId = _getProductId(product['id']);
          final currentQty = (product['quantity'] ?? 0) as int;
          final originalQty = _originalQuantities[productId] ?? 0;
          if (currentQty != originalQty) {
            await supabase
                .from('supplier_order_description')
                .update({
                  'quantity': currentQty,
                  'total_price': productTotals[productId],
                  'last_tracing_by': accountantName,
                  'last_tracing_time': DateTime.now().toIso8601String(),
                })
                .eq('order_id', widget.orderId!)
                .eq('product_id', productId);
          }
        }
      }

      widget.onOrderUpdated?.call();

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Order sent successfully'),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending order: $e'),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // ============= HANDLERS FOR "IN" ORDERS (UPDATE) =============
  Future<void> _handleAcceptUpdateIn(BuildContext context) async {
    try {
      if (widget.orderId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error: Order ID not found'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      // Get accountant information
      final accountantId = await getAccountantId();
      String? accountantName;
      if (accountantId != null) {
        accountantName = await getAccountantName(accountantId);
      }
      accountantName ??= 'System';

      final nowIso = DateTime.now().toIso8601String().split('.').first;

      // Apply updated quantities to actual quantities
      for (final product in _products) {
        final productId = _getProductId(product['id']);
        final updatedQty = product['updated_quantity'];

        if (updatedQty != null) {
          await supabase
              .from('supplier_order_description')
              .update({
                'quantity': updatedQty,
                'updated_quantity':
                    null, // Clear updated_quantity after applying
                'last_tracing_by': accountantName,
                'last_tracing_time': nowIso,
              })
              .eq('order_id', widget.orderId!)
              .eq('product_id', productId);
        }
      }

      // Update supplier_order to Sent
      await supabase
          .from('supplier_order')
          .update({
            'order_status': 'Sent',
            'accountant_id': accountantId,
            'updated_description': null, // Clear description after applying
            'last_tracing_by': accountantName,
            'last_tracing_time': nowIso,
          })
          .eq('order_id', widget.orderId!);

      widget.onOrderUpdated?.call();

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Update accepted, order set to Sent'),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error accepting update: $e'),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _handleRejectUpdateIn(BuildContext context) async {
    try {
      if (widget.orderId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error: Order ID not found'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      // Get accountant information
      final accountantId = await getAccountantId();
      String? accountantName;
      if (accountantId != null) {
        accountantName = await getAccountantName(accountantId);
      }
      accountantName ??= 'System';

      // Update supplier_order to Rejected
      await supabase
          .from('supplier_order')
          .update({
            'order_status': 'Rejected',
            'last_tracing_by': accountantName,
            'last_tracing_time': DateTime.now().toIso8601String(),
          })
          .eq('order_id', widget.orderId!);

      widget.onOrderUpdated?.call();

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Update rejected'),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error rejecting update: $e'),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // ============= ORIGINAL HANDLER FOR "OUT" ORDERS =============
  Future<void> _handleSendOrder(BuildContext context) async {
    try {
      // Get accountant information
      final accountantId = await getAccountantId();
      String? accountantName;
      if (accountantId != null) {
        accountantName = await getAccountantName(accountantId);
      }
      accountantName ??= 'System'; // Fallback if name not found

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
                  ...insufficientProducts.map((msg) => Text('• $msg')),
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
              'last_action_by': accountantName,
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
                  'last_action_by': accountantName,
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
        // No quantity or discount changes, but still update totals with correct formula
        await supabase
            .from('customer_order')
            .update({
              'order_status': 'Pinned',
              'total_cost': priceData['subtotal'],
              'total_balance': priceData['total_balance'],
              'discount_value': discountValue,
              'last_action_by': accountantName,
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
            content: Text(
              'Order status updated to "Pinned"\n'
              'Total: ${_formatMoney(priceData['total_balance'])}',
            ),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 3),
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

  // ============= HANDLERS FOR "OUT" ORDERS (UPDATE STATUS) =============

  /// Reject Update: Set status to Canceled, update_action = "Rejected by {accountant}"
  Future<void> _handleRejectUpdateOut(BuildContext context) async {
    try {
      if (widget.orderId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error: Order ID not found'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      final accountantId = await getAccountantId();
      String? accountantName;
      if (accountantId != null) {
        accountantName = await getAccountantName(accountantId);
      }
      accountantName ??= 'Accountant';

      final now = DateTime.now().toIso8601String();

      await supabase
          .from('customer_order')
          .update({
            'order_status': 'Canceled',
            'update_action': 'Rejected by $accountantName',
            'last_action_by': accountantName,
            'last_action_time': now,
          })
          .eq('customer_order_id', widget.orderId!);

      widget.onOrderUpdated?.call();

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Order update rejected and canceled'),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error rejecting update: $e'),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /// Send to Customer: Show confirmation with editable description, set status to "Updated to Customer"
  Future<void> _handleSendToCustomerOut(BuildContext context) async {
    final descriptionController = TextEditingController(
      text: widget.updateDescription ?? '',
    );

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text(
          'Send to Customer',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Update Description',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: const Color(0xFFB7A447)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Are you sure you want to send this update to customer?',
              style: TextStyle(color: Colors.white70),
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
            style: ElevatedButton.styleFrom(
              foregroundColor: const Color(0xFFB7A447),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      if (widget.orderId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error: Order ID not found'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      final accountantId = await getAccountantId();
      String? accountantName;
      if (accountantId != null) {
        accountantName = await getAccountantName(accountantId);
      }
      accountantName ??= 'Accountant';

      final now = DateTime.now().toIso8601String();

      await supabase
          .from('customer_order')
          .update({
            'order_status': 'Updated to Customer',
            'update_description': descriptionController.text.trim(),
            'last_action_by': accountantName,
            'last_action_time': now,
          })
          .eq('customer_order_id', widget.orderId!);

      widget.onOrderUpdated?.call();

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Update sent to customer'),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending to customer: $e'),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /// Accept Update: Set status to Pinned, update_action = "Accepted by {accountant}",
  /// recalculate costs, update quantities from updated_quantity
  Future<void> _handleAcceptUpdateOut(BuildContext context) async {
    try {
      if (widget.orderId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error: Order ID not found'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      final accountantId = await getAccountantId();
      String? accountantName;
      if (accountantId != null) {
        accountantName = await getAccountantName(accountantId);
      }
      accountantName ??= 'Accountant';

      final now = DateTime.now().toIso8601String();

      // Calculate new totals based on current quantities in _products
      final priceData = _calculateUpdatedPrices();
      final productTotals = priceData['product_totals'] as Map<int, num>;

      // Update customer_order_description for products with updated_quantity
      for (final product in _products) {
        final productId = _getProductId(product['id']);
        final updatedQty = product['updated_quantity'];

        if (updatedQty != null) {
          // Use the current quantity from the editable field
          final newQty = (product['quantity'] ?? 0) as int;

          await supabase
              .from('customer_order_description')
              .update({
                'quantity': newQty,
                'total_price': productTotals[productId],
                'updated_quantity':
                    null, // Clear updated_quantity after accepting
                'last_action_by': accountantName,
                'last_action_time': now,
              })
              .eq('customer_order_id', widget.orderId!)
              .eq('product_id', productId);
        }
      }

      // Update customer_order with new totals and status
      await supabase
          .from('customer_order')
          .update({
            'order_status': 'Pinned',
            'update_action': 'Accepted by $accountantName',
            'total_cost': priceData['subtotal'],
            'total_balance': priceData['total_balance'],
            'last_action_by': accountantName,
            'last_action_time': now,
          })
          .eq('customer_order_id', widget.orderId!);

      widget.onOrderUpdated?.call();

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order update accepted and set to Pinned.'),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error accepting update: $e'),
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

                    // Display update description for UPDATE status (moved here below title)
                    if (widget.status == "UPDATE" &&
                        widget.updateDescription != null &&
                        widget.updateDescription!.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3A3A3A),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFB7A447),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(
                                  Icons.info_outline,
                                  color: Color(0xFFB7A447),
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Update Description:',
                                  style: TextStyle(
                                    color: Color(0xFFB7A447),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.updateDescription!,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

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
                                          product["name"].toString(),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Center(
                                        child: Text(
                                          product["brand"].toString(),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Center(
                                        child: Text(
                                          product["price"].toString(),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),

                                    // ------- Quantity with editable field -------
                                    Expanded(
                                      flex: 2,
                                      child: Center(
                                        child:
                                            ((widget.orderType == 'out' ||
                                                    widget.orderType == 'in') &&
                                                widget.status == 'UPDATE' &&
                                                product['updated_quantity'] !=
                                                    null)
                                            ? Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.transparent,
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    // Connected red box for original quantity (now on left)
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 4,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            const Color.fromARGB(
                                                              255,
                                                              171,
                                                              67,
                                                              67,
                                                            ),
                                                        borderRadius:
                                                            const BorderRadius.only(
                                                              topLeft:
                                                                  Radius.circular(
                                                                    6,
                                                                  ),
                                                              bottomLeft:
                                                                  Radius.circular(
                                                                    6,
                                                                  ),
                                                            ),
                                                        border: Border.all(
                                                          color: const Color(
                                                            0xFFB7A447,
                                                          ),
                                                          width: 1,
                                                        ),
                                                      ),
                                                      child: Text(
                                                        '${product['original_quantity']}',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                    // Updated quantity with unit (now on right) - Read-only for 'in' orders
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 4,
                                                            vertical: 4,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: const Color(
                                                          0xFFB7A447,
                                                        ),
                                                        borderRadius:
                                                            const BorderRadius.only(
                                                              topRight:
                                                                  Radius.circular(
                                                                    6,
                                                                  ),
                                                              bottomRight:
                                                                  Radius.circular(
                                                                    6,
                                                                  ),
                                                            ),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          SizedBox(
                                                            width: 40,
                                                            child:
                                                                widget.orderType ==
                                                                    'in'
                                                                ? Center(
                                                                    child: Text(
                                                                      (product['updated_quantity'] ??
                                                                              product['quantity'] ??
                                                                              0)
                                                                          .toString(),
                                                                      style: const TextStyle(
                                                                        color: Colors
                                                                            .black,
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        fontSize:
                                                                            14,
                                                                      ),
                                                                    ),
                                                                  )
                                                                : TextFormField(
                                                                    key: ValueKey(
                                                                      'qty_${product["id"]}',
                                                                    ),
                                                                    initialValue:
                                                                        (product['updated_quantity'] ??
                                                                                product['quantity'] ??
                                                                                0)
                                                                            .toString(),
                                                                    keyboardType:
                                                                        TextInputType
                                                                            .number,
                                                                    cursorColor:
                                                                        Colors
                                                                            .white,
                                                                    inputFormatters: [
                                                                      FilteringTextInputFormatter
                                                                          .digitsOnly,
                                                                    ],
                                                                    textAlign:
                                                                        TextAlign
                                                                            .center,
                                                                    style: const TextStyle(
                                                                      color: Colors
                                                                          .black,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      fontSize:
                                                                          14,
                                                                    ),
                                                                    decoration: const InputDecoration(
                                                                      border: InputBorder
                                                                          .none,
                                                                      contentPadding:
                                                                          EdgeInsets
                                                                              .zero,
                                                                      isDense:
                                                                          true,
                                                                    ),
                                                                    onChanged: (value) {
                                                                      setState(() {
                                                                        final newQty =
                                                                            int.tryParse(
                                                                              value,
                                                                            ) ??
                                                                            0;
                                                                        product["quantity"] =
                                                                            newQty;

                                                                        // Update total price
                                                                        final priceStr =
                                                                            product['price']?.toString() ??
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
                                                                            price *
                                                                            newQty;
                                                                        product["total"] =
                                                                            _formatMoney(
                                                                              newTotal,
                                                                            );
                                                                      });
                                                                    },
                                                                  ),
                                                          ),
                                                          const SizedBox(
                                                            width: 4,
                                                          ),
                                                          Text(
                                                            product["unit_name"] ??
                                                                'pcs',
                                                            style: TextStyle(
                                                              color: Colors
                                                                  .white
                                                                  .withOpacity(
                                                                    0.9,
                                                                  ),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            : Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 4,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      (widget.orderType !=
                                                              'in' &&
                                                          _insufficientProducts
                                                              .contains(
                                                                _getProductId(
                                                                  product["id"],
                                                                ),
                                                              ))
                                                      ? Colors.red.shade700
                                                      : (product["quantity"] ??
                                                                0) >
                                                            0
                                                      ? const Color(0xFFB7A447)
                                                      : const Color(0xFF6F6F6F),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  border:
                                                      (widget.orderType !=
                                                              'in' &&
                                                          _insufficientProducts
                                                              .contains(
                                                                _getProductId(
                                                                  product["id"],
                                                                ),
                                                              ))
                                                      ? Border.all(
                                                          color: Colors
                                                              .red
                                                              .shade300,
                                                          width: 2,
                                                        )
                                                      : null,
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    SizedBox(
                                                      width: 40,
                                                      child:
                                                          (widget.orderType ==
                                                                  'in' &&
                                                              widget.status ==
                                                                  'UPDATE')
                                                          ? Center(
                                                              child: Text(
                                                                product["quantity"]
                                                                    .toString(),
                                                                style: const TextStyle(
                                                                  color: Colors
                                                                      .black,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 14,
                                                                ),
                                                              ),
                                                            )
                                                          : TextFormField(
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
                                                                  TextInputType
                                                                      .number,
                                                              cursorColor:
                                                                  Colors.white,
                                                              inputFormatters: [
                                                                FilteringTextInputFormatter
                                                                    .digitsOnly,
                                                              ],
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              style: const TextStyle(
                                                                color: Colors
                                                                    .black,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 14,
                                                              ),
                                                              decoration: const InputDecoration(
                                                                border:
                                                                    InputBorder
                                                                        .none,
                                                                contentPadding:
                                                                    EdgeInsets
                                                                        .zero,
                                                                isDense: true,
                                                                hintText: '0',
                                                                hintStyle: TextStyle(
                                                                  color: Colors
                                                                      .black54,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 14,
                                                                ),
                                                              ),
                                                              onChanged: (value) {
                                                                setState(() {
                                                                  final newQty =
                                                                      int.tryParse(
                                                                        value,
                                                                      ) ??
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
                                                                      price *
                                                                      newQty;
                                                                  product["total"] =
                                                                      _formatMoney(
                                                                        newTotal,
                                                                      );

                                                                  // Check if this product now has sufficient stock
                                                                  // Handle product ID as either String or int
                                                                  final productIdValue =
                                                                      product['id'];
                                                                  final productId =
                                                                      productIdValue
                                                                          is int
                                                                      ? productIdValue
                                                                      : int.tryParse(
                                                                              productIdValue.toString(),
                                                                            ) ??
                                                                            0;
                                                                  final availableQty =
                                                                      _productAvailableQty[productId] ??
                                                                      0;

                                                                  // Check if this product now has sufficient stock (only for stock-out orders)
                                                                  if (widget
                                                                          .orderType !=
                                                                      'in') {
                                                                    if (newQty >
                                                                        availableQty) {
                                                                      _insufficientProducts
                                                                          .add(
                                                                            productId,
                                                                          );
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
                                                      product["unit_name"] ??
                                                          'pcs',
                                                      style: TextStyle(
                                                        color: Colors.white
                                                            .withOpacity(0.9),
                                                        fontWeight:
                                                            FontWeight.w600,
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
                        if (widget.orderType == 'in' &&
                            widget.status == "NEW") ...[
                          _OrderButton(
                            label: "Later",
                            color: Colors.grey.shade600,
                            icon: Icons.access_time,
                            onPressed: () => _handleLaterNewIn(context),
                          ),
                          const SizedBox(width: 14),
                        ] else if (widget.orderType != 'in' &&
                            widget.status == "NEW") ...[
                          _OrderButton(
                            label: "Later",
                            color: Colors.grey.shade600,
                            icon: Icons.access_time,
                            onPressed: () => _handleLaterNewOut(context),
                          ),
                          const SizedBox(width: 14),
                        ],
                        // Add "Send to Customer" button for OUT orders with UPDATE status
                        if (widget.orderType == 'out' &&
                            widget.status == "UPDATE") ...[
                          _OrderButton(
                            label: "Send to Customer",
                            color: Colors.yellow.shade600,
                            icon: Icons.send_rounded,
                            onPressed: () => _handleSendToCustomerOut(context),
                          ),
                          const SizedBox(width: 14),
                        ],
                        _OrderButton(
                          label: widget.status == "UPDATE"
                              ? "Reject Update"
                              : "Reject Order",
                          color: Colors.red.shade700,
                          icon: Icons.cancel_outlined,
                          onPressed: () {
                            if (widget.orderType == 'in' &&
                                (widget.status == 'NEW' ||
                                    widget.status == 'HOLD')) {
                              _handleRejectNewIn(context);
                            } else if (widget.orderType == 'in' &&
                                widget.status == 'UPDATE') {
                              _handleRejectUpdateIn(context);
                            } else if (widget.orderType == 'out' &&
                                widget.status == 'UPDATE') {
                              _handleRejectUpdateOut(context);
                            } else {
                              Navigator.pop(context);
                            }
                          },
                        ),
                        const SizedBox(width: 14),
                        _OrderButton(
                          label: widget.status == "UPDATE"
                              ? "Accept Update"
                              : widget.status == "HOLD"
                              ? "Send Order"
                              : "Send Order",
                          color: Colors.green.shade600,
                          icon: widget.status == "UPDATE"
                              ? Icons.check
                              : Icons.send_rounded,
                          onPressed: () {
                            if (widget.orderType == 'in' &&
                                (widget.status == 'NEW' ||
                                    widget.status == 'HOLD')) {
                              _handleSendNewIn(context);
                            } else if (widget.orderType == 'in' &&
                                widget.status == 'UPDATE') {
                              _handleAcceptUpdateIn(context);
                            } else if (widget.orderType == 'out' &&
                                widget.status == 'UPDATE') {
                              _handleAcceptUpdateOut(context);
                            } else {
                              _handleSendOrder(context);
                            }
                          },
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
      if (manager != null) {
        children.add(_actorTile('Manager', manager!['name'] ?? '-'));
      }
      if (storageStaff != null) {
        children.add(_actorTile('Storage Staff', storageStaff!['name'] ?? '-'));
      }
    } else if (statusLower == 'delivery' || statusLower == 'delivered') {
      if (manager != null) {
        children.add(_actorTile('Manager', manager!['name'] ?? '-'));
      }
      if (storageStaff != null) {
        children.add(_actorTile('Storage Staff', storageStaff!['name'] ?? '-'));
      }
      if (deliveryDriver != null) {
        children.add(
          _actorTile('Delivery Driver', deliveryDriver!['name'] ?? '-'),
        );
      }
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
                                ? "Supplier Name: ${partyName ?? '-'}"
                                : "Customer: ${partyName ?? '-'}",
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
                                  "City : ${(location?.split(' - ').isNotEmpty ?? false) ? location!.split(' - ')[0] : '-'}",
                                  style: const TextStyle(fontSize: 15),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Quarter : ${(location?.split(' - ').length ?? 0) > 1 ? location!.split(' - ')[1] : '-'}",
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
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
                                if (orderType == 'in' &&
                                    status.toLowerCase() == 'delivered' &&
                                    (product['inventories'] != null &&
                                        (product['inventories'] as List)
                                            .isNotEmpty))
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: 8,
                                      left: 8,
                                      right: 8,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Inventory allocations:',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        ...List<Widget>.from(
                                          (product['inventories'] as List).map(
                                            (inv) => Row(
                                              children: [
                                                const Text(
                                                  '• ',
                                                  style: TextStyle(
                                                    color: Colors.white54,
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    '${inv['inventory']}: ${inv['quantity']}',
                                                    style: const TextStyle(
                                                      color: Colors.white70,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
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
