import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'sidebar.dart';
import '../supabase_config.dart';
import 'add_product_order.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<int?> getAccountantId() async {
  final prefs = await SharedPreferences.getInstance();
  final id = prefs.getInt('accountant_id');
  if (id != null) return id;
  // If not found in prefs, get from DB where is_active = 'yes'
  final response = await supabase
      .from('user_account_accountant')
      .select('accountant_id')
      .eq('is_active', 'yes')
      .maybeSingle();
  return response != null ? response['accountant_id'] as int? : null;
}

Future<String?> getAccountantName(int accountantId) async {
  final response = await supabase
      .from('accountant')
      .select('name')
      .eq('accountant_id', accountantId)
      .maybeSingle();
  return response != null ? response['name'] as String? : null;
}

class CreateStockOutPage extends StatefulWidget {
  const CreateStockOutPage({super.key});

  @override
  State<CreateStockOutPage> createState() => _CreateStockOutPageState();
}

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

class _CreateStockOutPageState extends State<CreateStockOutPage> {
  String? selectedCustomerId;
  Map<String, dynamic>? selectedCustomer;
  final TextEditingController discountController = TextEditingController();
  int? hoveredIndex;

  List<Map<String, dynamic>> allCustomers = [];
  List<Map<String, dynamic>> filteredCustomers = [];
  List<Map<String, dynamic>> allProducts = [];
  bool isLoadingCustomers = true;

  // Real-time available quantity tracking
  Map<int, int> productAvailableQty = {};
  Set<int> insufficientProducts = {};

  static const int taxPercent = 16;

  double get subtotal {
    double sum = 0;
    for (var product in allProducts) {
      final price = product['selling_price'] ?? 0;
      final quantity = product['quantity'] ?? 0;
      sum += price * quantity;
    }
    return sum;
  }

  double get taxAmount {
    return subtotal * (taxPercent / 100);
  }

  double get discountValue {
    return double.tryParse(discountController.text) ?? 0.0;
  }

  double get totalPrice {
    return subtotal + taxAmount - discountValue;
  }

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    discountController.addListener(() {
      setState(() {});
    });
  }

  // Fetch available quantity for all products in the list
  Future<void> _validateInventory() async {
    Map<int, int> available = {};
    Set<int> insufficient = {};
    for (final product in allProducts) {
      final productId = product['product_id'];
      try {
        final response = await supabase
            .from('product')
            .select('total_quantity')
            .eq('product_id', productId)
            .single();
        final availableQty = response['total_quantity'] as int?;
        available[productId] = availableQty ?? 0;
        final requestedQty = product['quantity'] ?? 0;
        if (availableQty != null && requestedQty > availableQty) {
          insufficient.add(productId);
        }
      } catch (e) {
        // ignore error
      }
    }
    setState(() {
      productAvailableQty = available;
      insufficientProducts = insufficient;
    });
  }

  // Call _validateInventory whenever products or their quantities change
  void _onProductListChanged() {
    _validateInventory();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
    );
  }

  Future<void> _loadCustomers() async {
    setState(() => isLoadingCustomers = true);
    try {
      final response = await supabase
          .from('customer')
          .select('''
            customer_id,
            name,
            address,
            sales_rep_id,
            customer_city:customer_city(name)
          ''')
          .order('name');

      setState(() {
        allCustomers = List<Map<String, dynamic>>.from(response);
        filteredCustomers = allCustomers;
        isLoadingCustomers = false;
      });
    } catch (e) {
      print('Error loading customers: $e');
      setState(() => isLoadingCustomers = false);
    }
  }

  Future<void> _sendOrder() async {
    try {
      // Prepare extra fields for customer_order
      int? salesRepId;
      if (selectedCustomer != null &&
          selectedCustomer!['sales_rep_id'] != null) {
        salesRepId = selectedCustomer!['sales_rep_id'];
      }
      final accountantId = await getAccountantId();
      String? accountantName;
      if (accountantId != null) {
        accountantName = await getAccountantName(accountantId);
      }
      // Check available quantity for each product
      final insufficientProducts = <String>[];
      for (final product in allProducts) {
        final productId = product['product_id'];
        final requestedQty = product['quantity'] ?? 0;
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
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Insufficient Stock'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: insufficientProducts
                  .map((msg) => Text('• $msg'))
                  .toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      // حساب المجاميع
      final totalCost = subtotal;
      final totalBalance = totalPrice;

      // إنشاء الطلب في customer_order مع حالة Pinned وإضافة قيمة الخصم
      final orderData = {
        'customer_id': int.parse(selectedCustomerId!),
        'total_cost': totalCost,
        'tax_percent': taxPercent,
        'total_balance': totalBalance,
        'order_date': DateTime.now().toIso8601String(),
        'order_status': 'Pinned',
        'discount_value': discountValue,
        'last_action_time': DateTime.now().toIso8601String(),
      };
      if (salesRepId != null) orderData['sales_rep_id'] = salesRepId;
      if (accountantId != null) orderData['accountant_id'] = accountantId;
      if (accountantName != null) orderData['last_action_by'] = accountantName;

      final orderResponse = await supabase
          .from('customer_order')
          .insert(orderData)
          .select('customer_order_id')
          .single();

      final orderId = orderResponse['customer_order_id'];

      // إضافة تفاصيل جميع المنتجات في الجدول بدون delivered_quantity
      for (var product in allProducts) {
        final quantity = product['quantity'] ?? 0;
        if (quantity > 0) {
          await supabase.from('customer_order_description').insert({
            'customer_order_id': orderId,
            'product_id': product['product_id'],
            'quantity': quantity,
            'total_price': (product['selling_price'] ?? 0) * quantity,
            'last_action_by': accountantName,
            'last_action_time': DateTime.now().toIso8601String(),
          });
        }
      }

      if (mounted) {
        _showMessage('Order sent successfully!');
        // Reset all fields
        setState(() {
          allProducts.clear();
          selectedCustomerId = null;
          selectedCustomer = null;
          discountController.clear();
          hoveredIndex = null;
          productAvailableQty.clear();
          insufficientProducts.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Failed to send order: $e');
      }
      print('Error sending order: $e');
    }
  }

  Future<void> _holdOrder() async {
    try {
      // Check available quantity for each product
      final insufficientProducts = <String>[];
      for (final product in allProducts) {
        final productId = product['product_id'];
        final requestedQty = product['quantity'] ?? 0;
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
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Insufficient Stock'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: insufficientProducts
                  .map((msg) => Text('• $msg'))
                  .toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      // حساب المجاميع
      final totalCost = subtotal;
      final totalBalance = totalPrice;

      // Prepare extra fields for customer_order
      int? salesRepId;
      if (selectedCustomer != null &&
          selectedCustomer!['sales_rep_id'] != null) {
        salesRepId = selectedCustomer!['sales_rep_id'];
      }
      final accountantId = await getAccountantId();
      String? accountantName;
      if (accountantId != null) {
        accountantName = await getAccountantName(accountantId);
      }

      final orderData = {
        'customer_id': int.parse(selectedCustomerId!),
        'total_cost': totalCost,
        'tax_percent': taxPercent,
        'total_balance': totalBalance,
        'order_date': DateTime.now().toIso8601String(),
        'order_status': 'Hold',
        'discount_value': discountValue,
        'last_action_time': DateTime.now().toIso8601String(),
      };
      if (salesRepId != null) orderData['sales_rep_id'] = salesRepId;
      if (accountantId != null) orderData['accountant_id'] = accountantId;
      if (accountantName != null) orderData['last_action_by'] = accountantName;

      final orderResponse = await supabase
          .from('customer_order')
          .insert(orderData)
          .select('customer_order_id')
          .single();

      final orderId = orderResponse['customer_order_id'];

      // إضافة تفاصيل جميع المنتجات في الجدول بدون delivered_quantity
      for (var product in allProducts) {
        final quantity = product['quantity'] ?? 0;
        if (quantity > 0) {
          await supabase.from('customer_order_description').insert({
            'customer_order_id': orderId,
            'product_id': product['product_id'],
            'quantity': quantity,
            'total_price': (product['selling_price'] ?? 0) * quantity,
            'last_action_by': accountantName,
            'last_action_time': DateTime.now().toIso8601String(),
          });
        }
      }

      if (mounted) {
        _showMessage('Order saved as Hold!');
        // Reset all fields
        setState(() {
          allProducts.clear();
          selectedCustomerId = null;
          selectedCustomer = null;
          discountController.clear();
          hoveredIndex = null;
          productAvailableQty.clear();
          insufficientProducts.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Failed to hold order: $e');
      }
      print('Error holding order: $e');
    }
  }

  @override
  void dispose() {
    discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF202020),
      body: SafeArea(
        child: Row(
          children: [
            const Sidebar(activeIndex: 1),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 35,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ===== HEADER SECTION =====
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // زر الرجوع
                            Container(
                              decoration: const BoxDecoration(
                                color: Color(0xFF2D2D2D),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  if (Navigator.canPop(context)) {
                                    Navigator.pop(context);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(height: 40),
                            // Customer + Drop list
                            Row(
                              children: [
                                const Text(
                                  "Customer :",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  height: 38,
                                  constraints: const BoxConstraints(
                                    minWidth: 200,
                                    maxWidth: 400,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: const Color(0xFFB7A447),
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                    color: const Color(0xFF2D2D2D),
                                  ),
                                  child: isLoadingCustomers
                                      ? const Center(
                                          child: SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Color(0xFFB7A447),
                                            ),
                                          ),
                                        )
                                      : DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            dropdownColor: const Color(
                                              0xFF2D2D2D,
                                            ),
                                            value: selectedCustomerId,
                                            hint: const Text(
                                              "Select Customer",
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 14,
                                              ),
                                            ),
                                            items: filteredCustomers.map((
                                              customer,
                                            ) {
                                              return DropdownMenuItem<String>(
                                                value: customer['customer_id']
                                                    .toString(),
                                                child: Text(
                                                  customer['name'],
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                            onChanged: (value) {
                                              setState(() {
                                                selectedCustomerId = value;
                                                selectedCustomer =
                                                    filteredCustomers
                                                        .firstWhere(
                                                          (c) =>
                                                              c['customer_id']
                                                                  .toString() ==
                                                              value,
                                                        );
                                              });
                                            },
                                            icon: const Icon(
                                              Icons.keyboard_arrow_down_rounded,
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Icon(
                          Icons.notifications_none_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ===== LOCATION / DATE / TAX =====
                    Padding(
                      padding: const EdgeInsets.only(right: 30.0),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedCustomer != null
                                      ? "Location : ${selectedCustomer!['address'] ?? '-'}"
                                      : "Location : -",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  selectedCustomer != null
                                      ? "Customer : ${selectedCustomer!['name'] ?? '-'}"
                                      : "Customer : -",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 220),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Date : ${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  "Time : ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 220),
                            Text(
                              "Tax percent : $taxPercent%",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),
                    const Divider(color: Colors.white24, thickness: 1),
                    const SizedBox(height: 6),

                    // ===== TABLE SECTION =====
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ===== TABLE =====
                          Expanded(
                            flex: 10,
                            child: allProducts.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No products found',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 16,
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: allProducts.length + 1,
                                    itemBuilder: (context, index) {
                                      if (index == 0) {
                                        return Column(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 10,
                                                  ),
                                              child: Row(
                                                children: const [
                                                  _HeaderCell(
                                                    text: 'Product ID #',
                                                    flex: 2,
                                                  ),
                                                  _HeaderCell(
                                                    text: 'Product Name',
                                                    flex: 4,
                                                  ),
                                                  _HeaderCell(
                                                    text: 'Brand',
                                                    flex: 3,
                                                  ),
                                                  _HeaderCell(
                                                    text: 'Price per product',
                                                    flex: 3,
                                                  ),
                                                  _HeaderCell(
                                                    text: 'Quantity',
                                                    flex: 2,
                                                  ),
                                                  _HeaderCell(
                                                    text: 'Total Price',
                                                    flex: 3,
                                                  ),
                                                  // New column for remove icon
                                                  _HeaderCell(
                                                    text: '',
                                                    flex: 1,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // 🔹 خط تحت العناوين
                                            Container(
                                              height: 1.5,
                                              color: Colors.white24,
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 4,
                                                  ),
                                            ),
                                          ],
                                        );
                                      }

                                      final product = allProducts[index - 1];
                                      final productId = product['product_id'];
                                      final productName =
                                          product['name'] ?? 'Unknown';
                                      final brandName =
                                          product['brand']?['name'] ?? '-';
                                      final sellingPrice =
                                          product['selling_price'] ?? 0;
                                      final unitName =
                                          product['unit']?['unit_name'] ??
                                          'pcs';
                                      final quantity = product['quantity'] ?? 0;
                                      final totalProductPrice =
                                          sellingPrice * quantity;

                                      final bgColor = (index % 2 == 0)
                                          ? const Color(0xFF2D2D2D)
                                          : const Color(0xFF262626);

                                      return Column(
                                        children: [
                                          MouseRegion(
                                            onEnter: (_) => setState(
                                              () => hoveredIndex = index,
                                            ),
                                            onExit: (_) => setState(
                                              () => hoveredIndex = null,
                                            ),
                                            child: AnimatedContainer(
                                              duration: const Duration(
                                                milliseconds: 200,
                                              ),
                                              margin: const EdgeInsets.only(
                                                bottom: 8,
                                              ),
                                              decoration: BoxDecoration(
                                                color: bgColor,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: hoveredIndex == index
                                                      ? const Color(0xFF50B2E7)
                                                      : Colors.transparent,
                                                  width: 2,
                                                ),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 12,
                                                  ),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    flex: 2,
                                                    child: Center(
                                                      child: Text(
                                                        productId.toString(),
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 4,
                                                    child: Center(
                                                      child: Text(
                                                        productName,
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 3,
                                                    child: Center(
                                                      child: Text(
                                                        brandName,
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 3,
                                                    child: Center(
                                                      child: Text(
                                                        "\$${sellingPrice.toStringAsFixed(2)}",
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  // ✅ Quantity مع المربع الذهبي
                                                  Expanded(
                                                    flex: 2,
                                                    child: Center(
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 4,
                                                              vertical: 4,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color:
                                                              insufficientProducts
                                                                  .contains(
                                                                    productId,
                                                                  )
                                                              ? Colors
                                                                    .red
                                                                    .shade700
                                                              : (quantity > 0
                                                                    ? const Color(
                                                                        0xFFB7A447,
                                                                      )
                                                                    : const Color(
                                                                        0xFF6F6F6F,
                                                                      )),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                6,
                                                              ),
                                                        ),
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            SizedBox(
                                                              width: 40,
                                                              child: TextFormField(
                                                                key: ValueKey(
                                                                  'quantity_$productId',
                                                                ),
                                                                initialValue:
                                                                    quantity ==
                                                                        0
                                                                    ? ''
                                                                    : quantity
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
                                                                    fontSize:
                                                                        14,
                                                                  ),
                                                                ),
                                                                onChanged: (value) {
                                                                  setState(() {
                                                                    product['quantity'] =
                                                                        int.tryParse(
                                                                          value,
                                                                        ) ??
                                                                        0;
                                                                  });
                                                                  _onProductListChanged();
                                                                },
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              width: 4,
                                                            ),
                                                            Text(
                                                              unitName,
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
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 3,
                                                    child: Center(
                                                      child: Text(
                                                        "\$${totalProductPrice.toStringAsFixed(2)}",
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  // New column for remove icon
                                                  Expanded(
                                                    flex: 1,
                                                    child: Center(
                                                      child: IconButton(
                                                        icon: const Icon(
                                                          Icons.close,
                                                          color: Colors.red,
                                                        ),
                                                        tooltip:
                                                            'Remove product',
                                                        onPressed: () {
                                                          setState(() {
                                                            allProducts
                                                                .removeAt(
                                                                  index - 1,
                                                                );
                                                          });
                                                          _onProductListChanged();
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          // Show warning message if product has insufficient stock
                                          if (insufficientProducts.contains(
                                            productId,
                                          ))
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 4,
                                                bottom: 8,
                                              ),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.red.shade900
                                                      .withOpacity(0.3),
                                                  border: Border.all(
                                                    color: Colors.red.shade700,
                                                    width: 1.5,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.warning,
                                                      color: Colors.red,
                                                      size: 18,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      'Insufficient stock (Available: '
                                                      '${productAvailableQty[productId] ?? '-'}, '
                                                      'Requested: ${product['quantity'] ?? 0})',
                                                      style: const TextStyle(
                                                        color: Colors.red,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                        ],
                                      );
                                    },
                                  ),
                          ),

                          const SizedBox(width: 40),

                          // ===== BUTTONS COLUMN =====
                          Expanded(
                            flex: 3,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const SizedBox(height: 30),
                                _ActionButton(
                                  color: const Color(0xFFB7A447),
                                  icon: Icons.add_box_rounded,
                                  label: 'Add Product',
                                  textColor: Colors.black,
                                  width: 220,
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      barrierDismissible: true,
                                      builder: (_) {
                                        return AddProductPopup(
                                          existingProducts: allProducts,
                                          onClose: () {
                                            Navigator.of(context).pop();
                                          },
                                          onDone: (selectedProducts) {
                                            setState(() {
                                              for (var product
                                                  in selectedProducts) {
                                                final existingIndex =
                                                    allProducts.indexWhere(
                                                      (p) =>
                                                          p['product_id'] ==
                                                          product['product_id'],
                                                    );
                                                if (existingIndex >= 0) {
                                                  // المنتج موجود - زيادة الكمية فقط
                                                  allProducts[existingIndex]['quantity'] =
                                                      (allProducts[existingIndex]['quantity'] ??
                                                          0) +
                                                      (product['quantity'] ??
                                                          0);
                                                } else {
                                                  // منتج جديد - إضافة للجدول (ليس للداتا بيس)
                                                  allProducts.add({
                                                    'product_id':
                                                        product['product_id'],
                                                    'name': product['name'],
                                                    'brand': product['brand'],
                                                    'selling_price':
                                                        product['selling_price'] ??
                                                        0,
                                                    'unit':
                                                        product['unit'] ??
                                                        {'unit_name': 'pcs'},
                                                    'quantity':
                                                        product['quantity'] ??
                                                        0,
                                                  });
                                                }
                                              }
                                            });
                                          },
                                        );
                                      },
                                    );
                                  },
                                ),
                                const SizedBox(height: 20),
                                // Removed 'Remove Product' button
                                _ActionButton(
                                  color: const Color(0xFF4287AD),
                                  icon: Icons.send_rounded,
                                  label: 'Send Order',
                                  textColor: Colors.black,
                                  width: 220,
                                  onTap: selectedCustomerId == null
                                      ? null
                                      : () async {
                                          await _sendOrder();
                                        },
                                ),
                                const SizedBox(height: 20),
                                _ActionButton(
                                  color: const Color(0xFF6F6F6F),
                                  icon: Icons.pause_circle_filled_rounded,
                                  label: 'Hold',
                                  textColor: Colors.white,
                                  width: 220,
                                  onTap: selectedCustomerId == null
                                      ? null
                                      : () async {
                                          await _holdOrder();
                                        },
                                ),
                                const SizedBox(height: 30),
                                const Divider(color: Colors.white24),
                                const SizedBox(height: 18),
                                // ✅ Discount + TextField (value-based, decimal, like order_detail_popup.dart)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      "Discount",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 18),
                                    SizedBox(
                                      width: 140,
                                      height: 40,
                                      child: TextField(
                                        controller: discountController,
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
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: "Discount value",
                                          hintStyle: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 16,
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 8,
                                              ),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: Color(0xFFB7A447),
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: Color(0xFFB7A447),
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16.0,
                                    horizontal: 8.0,
                                  ),
                                  child: Text(
                                    'Total Price : \$${totalPrice.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 24,
                                      letterSpacing: 1.2,
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final int flex;
  const _HeaderCell({required this.text, required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final Color color;
  final Color textColor;
  final IconData icon;
  final String label;
  final double width;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.color,
    required this.icon,
    required this.label,
    required this.textColor,
    this.width = 260,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(40),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
