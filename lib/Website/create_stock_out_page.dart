import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'sidebar.dart';
import '../supabase_config.dart';
import 'add_product_order.dart';

class CreateStockOutPage extends StatefulWidget {
  const CreateStockOutPage({super.key});

  @override
  State<CreateStockOutPage> createState() => _CreateStockOutPageState();
}

class _CreateStockOutPageState extends State<CreateStockOutPage> {
  String? selectedCustomerId;
  Map<String, dynamic>? selectedCustomer;
  final TextEditingController discountController = TextEditingController();
  int? hoveredIndex;
  
  List<Map<String, dynamic>> allCustomers = [];
  List<Map<String, dynamic>> filteredCustomers = [];
  List<Map<String, dynamic>> allProducts = [];
  Set<int> selectedProductIds = {};
  bool isLoadingCustomers = true;
  bool isLoadingProducts = false;
  
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
  
  double get discount {
    final discountPercent = double.tryParse(discountController.text) ?? 0;
    return subtotal * (discountPercent / 100);
  }
  
  double get totalPrice {
    return subtotal + taxAmount - discount;
  }

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    // لا نحمل المنتجات عند فتح الصفحة - الجدول يبدأ فاضي
    discountController.addListener(() {
      setState(() {}); // Rebuild when discount changes
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
    );
  }

  void _changeQuantityForHovered(int delta) {
    if (hoveredIndex == null || hoveredIndex == 0) {
      _showMessage('Hover a product row to modify quantity');
      return;
    }
    final int idx = hoveredIndex! - 1; // account for header row
    if (idx < 0 || idx >= allProducts.length) return;
    setState(() {
      final product = allProducts[idx];
      final int current = (product['quantity'] ?? 0) is int
          ? product['quantity'] ?? 0
          : int.tryParse(product['quantity'].toString()) ?? 0;
      int updated = current + delta;
      if (updated < 0) updated = 0;
      product['quantity'] = updated;
    });
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

  Future<List<Map<String, dynamic>>> _loadAvailableProducts() async {
    try {
      final response = await supabase
          .from('product')
          .select('''
            product_id,
            name,
            selling_price,
            brand:brand_id(name),
            unit:unit_id(unit_name),
            total_quantity
          ''')
          .eq('is_active', true)
          .order('name');

      final allProductsFromDB = List<Map<String, dynamic>>.from(response);
      
      // فلتر المنتجات: إظهار فقط المنتجات غير الموجودة في الجدول
      final availableProducts = allProductsFromDB.where((product) {
        return !allProducts.any((p) => p['product_id'] == product['product_id']);
      }).toList();
      
      return availableProducts;
    } catch (e) {
      print('Error loading products: $e');
      return [];
    }
  }

  Future<void> _sendOrder() async {
    try {
      // حساب المجاميع
      final totalCost = subtotal;
      final totalBalance = totalPrice;
      
      // إنشاء الطلب في customer_order
      final orderResponse = await supabase
          .from('customer_order')
          .insert({
            'customer_id': int.parse(selectedCustomerId!),
            'total_cost': totalCost,
            'tax_percent': taxPercent,
            'total_balance': totalBalance,
            'order_date': DateTime.now().toIso8601String(),
            'order_status': 'Pinned',
          })
          .select('customer_order_id')
          .single();
      
      final orderId = orderResponse['customer_order_id'];
      
      // إضافة تفاصيل المنتجات المحددة فقط في customer_order_description
      for (var product in allProducts) {
        if (selectedProductIds.contains(product['product_id'])) { // فقط المنتجات المحددة
          final quantity = product['quantity'] ?? 0;
          if (quantity > 0) {
            await supabase.from('customer_order_description').insert({
              'customer_order_id': orderId,
              'product_id': product['product_id'],
              'quantity': quantity,
              'delivered_quantity': 0,
              'total_price': (product['selling_price'] ?? 0) * quantity,
            });
          }
        }
      }
      
      if (mounted) {
        _showMessage('Order sent successfully!');
        // حذف المنتجات المرسلة من الجدول
        setState(() {
          allProducts.removeWhere((p) => selectedProductIds.contains(p['product_id']));
          selectedProductIds.clear();
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
      // حساب المجاميع
      final totalCost = subtotal;
      final totalBalance = totalPrice;
      
      // إنشاء الطلب في customer_order مع حالة Hold
      final orderResponse = await supabase
          .from('customer_order')
          .insert({
            'customer_id': int.parse(selectedCustomerId!),
            'total_cost': totalCost,
            'tax_percent': taxPercent,
            'total_balance': totalBalance,
            'order_date': DateTime.now().toIso8601String(),
            'order_status': 'Hold',
          })
          .select('customer_order_id')
          .single();
      
      final orderId = orderResponse['customer_order_id'];
      
      // إضافة تفاصيل المنتجات المحددة فقط في customer_order_description
      for (var product in allProducts) {
        if (selectedProductIds.contains(product['product_id'])) {
          final quantity = product['quantity'] ?? 0;
          if (quantity > 0) {
            await supabase.from('customer_order_description').insert({
              'customer_order_id': orderId,
              'product_id': product['product_id'],
              'quantity': quantity,
              'delivered_quantity': 0,
              'total_price': (product['selling_price'] ?? 0) * quantity,
            });
          }
        }
      }
      
      if (mounted) {
        _showMessage('Order saved as Hold!');
        // حذف المنتجات المحفوظة من الجدول
        setState(() {
          allProducts.removeWhere((p) => selectedProductIds.contains(p['product_id']));
          selectedProductIds.clear();
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
                                onPressed: () => Navigator.pop(context),
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
                                            dropdownColor: const Color(0xFF2D2D2D),
                                            value: selectedCustomerId,
                                            hint: const Text(
                                              "Select Customer",
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 14,
                                              ),
                                            ),
                                            items: filteredCustomers.map((customer) {
                                              return DropdownMenuItem<String>(
                                                value: customer['customer_id'].toString(),
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
                                                selectedCustomer = filteredCustomers
                                                    .firstWhere((c) => c['customer_id'].toString() == value);
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
                              style: const TextStyle(color: Colors.white, fontSize: 15),
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
                            child: isLoadingProducts
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF50B2E7),
                                    ),
                                  )
                                : allProducts.isEmpty
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
                                        padding: const EdgeInsets.symmetric(
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
                                            _HeaderCell(text: 'Brand', flex: 3),
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
                                          ],
                                        ),
                                      ),
                                      // 🔹 خط تحت العناوين
                                      Container(
                                        height: 1.5,
                                        color: Colors.white24,
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 4,
                                        ),
                                      ),
                                    ],
                                  );
                                }

                                final product = allProducts[index - 1];
                                final productId = product['product_id'];
                                final productName = product['name'] ?? 'Unknown';
                                final brandName = product['brand']?['name'] ?? '-';
                                final sellingPrice = product['selling_price'] ?? 0;
                                final unitName = product['unit']?['unit_name'] ?? 'pcs';
                                final quantity = product['quantity'] ?? 0;
                                final totalProductPrice = sellingPrice * quantity;
                                final isSelected = selectedProductIds.contains(productId);
                                
                                final bgColor = isSelected 
                                    ? const Color(0xFF4D2D2D)
                                    : (index % 2 == 0)
                                        ? const Color(0xFF2D2D2D)
                                        : const Color(0xFF262626);

                                return MouseRegion(
                                  onEnter: (_) =>
                                      setState(() => hoveredIndex = index),
                                  onExit: (_) =>
                                      setState(() => hoveredIndex = null),
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        if (isSelected) {
                                          selectedProductIds.remove(productId);
                                        } else {
                                          selectedProductIds.add(productId);
                                        }
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      margin: const EdgeInsets.only(bottom: 8),
                                      decoration: BoxDecoration(
                                        color: bgColor,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFFC34239)
                                              : hoveredIndex == index
                                                  ? const Color(0xFF50B2E7)
                                                  : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      child: Row(
                                        children: [
                                          Checkbox(
                                            value: isSelected,
                                            onChanged: (val) {
                                              setState(() {
                                                if (val == true) {
                                                  selectedProductIds.add(productId);
                                                } else {
                                                  selectedProductIds.remove(productId);
                                                }
                                              });
                                            },
                                            activeColor: const Color(0xFFC34239),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Center(
                                              child: Text(
                                                productId.toString(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
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
                                                fontWeight: FontWeight.w600,
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
                                                fontWeight: FontWeight.w600,
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
                                                fontWeight: FontWeight.w600,
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
                                                color: quantity > 0 
                                                    ? const Color(0xFFB7A447)
                                                    : const Color(0xFF6F6F6F),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  SizedBox(
                                                    width: 40,
                                                    child: TextFormField(
                                                      key: ValueKey('quantity_$productId'),
                                                      initialValue: quantity == 0 ? '' : quantity.toString(),
                                                      keyboardType: TextInputType.number,
                                                      inputFormatters: [
                                                        FilteringTextInputFormatter.digitsOnly,
                                                      ],
                                                      textAlign: TextAlign.center,
                                                      style: const TextStyle(
                                                        color: Colors.black,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 14,
                                                      ),
                                                      decoration: const InputDecoration(
                                                        border: InputBorder.none,
                                                        contentPadding: EdgeInsets.zero,
                                                        isDense: true,
                                                        hintText: '0',
                                                        hintStyle: TextStyle(
                                                          color: Colors.black54,
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                      onChanged: (value) {
                                                        setState(() {
                                                          product['quantity'] = int.tryParse(value) ?? 0;
                                                        });
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    unitName,
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
                                          flex: 3,
                                          child: Center(
                                            child: Text(
                                              "\$${totalProductPrice.toStringAsFixed(2)}",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(width: 40),

                          const SizedBox(width: 40),

                          // ===== BUTTONS COLUMN =====
                          Expanded(
                            flex: 3,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
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
                                              for (var product in selectedProducts) {
                                                final existingIndex = allProducts.indexWhere(
                                                  (p) => p['product_id'] == product['product_id']
                                                );
                                                if (existingIndex >= 0) {
                                                  // المنتج موجود - زيادة الكمية فقط
                                                  allProducts[existingIndex]['quantity'] = 
                                                    (allProducts[existingIndex]['quantity'] ?? 0) + (product['quantity'] ?? 0);
                                                } else {
                                                  // منتج جديد - إضافة للجدول (ليس للداتا بيس)
                                                  allProducts.add({
                                                    'product_id': product['product_id'],
                                                    'name': product['name'],
                                                    'brand': product['brand'],
                                                    'selling_price': product['selling_price'] ?? 0,
                                                    'unit': product['unit'] ?? {'unit_name': 'pcs'},
                                                    'quantity': product['quantity'] ?? 0,
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
                                _ActionButton(
                                  color: const Color(0xFFC34239),
                                  icon: Icons.delete_forever_rounded,
                                  label: 'Remove Product',
                                  textColor: Colors.white,
                                  width: 220,
                                  onTap: () {
                                    if (selectedProductIds.isEmpty) {
                                      _showMessage('Select products to remove');
                                      return;
                                    }
                                    setState(() {
                                      allProducts.removeWhere((p) => 
                                        selectedProductIds.contains(p['product_id'])
                                      );
                                      selectedProductIds.clear();
                                    });
                                  },
                                ),
                                const SizedBox(height: 20),
                                _ActionButton(
                                  color:
                                      const Color(0xFF4287AD),
                                  icon: Icons.send_rounded,
                                  label: 'Send Order',
                                  textColor: Colors.black,
                                  width: 220,
                                  onTap: (selectedCustomerId == null || selectedProductIds.isEmpty)
                                      ? null
                                      : () async {
                                          await _sendOrder();
                                        },
                                ),
                                const SizedBox(height: 20),
                                _ActionButton(
                                  color:  const Color(0xFF6F6F6F),
                                  icon: Icons.pause_circle_filled_rounded,
                                  label: 'Hold',
                                  textColor:  Colors.white,
                                  width: 220,
                                  onTap: (selectedCustomerId == null || selectedProductIds.isEmpty)
                                      ? null
                                      : () async {
                                          await _holdOrder();
                                        },
                                ),
                                const SizedBox(height: 30),
                                const Divider(color: Colors.white24),
                                const SizedBox(height: 18),
                                // ✅ Discount + TextField
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      "Discount:",
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    SizedBox(
                                      width: 80,
                                      height: 32,
                                      child: TextField(
                                        controller: discountController,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly,
                                        ],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                        decoration: InputDecoration(
                                          suffixText: "%",
                                          suffixStyle: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                          ),
                                          hintText: "0",
                                          hintStyle: const TextStyle(
                                            color: Colors.white54,
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 0,
                                              ),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: Color(0xFFB7A447),
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: Color(0xFFB7A447),
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Total Price : \$${totalPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
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
