import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../supabase_config.dart';
import '../bottom_navbar.dart';
import '../account_page.dart';

class OrderDetailsPage extends StatefulWidget {
  final int orderId;
  final String customerName;

  const OrderDetailsPage({
    super.key,
    required this.orderId,
    required this.customerName,
  });

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  bool isUpdated = false;
  List<Map<String, dynamic>> products = [];
  bool isLoading = true;
  String supplierName = '';

  @override
  void initState() {
    super.initState();
    _loadSupplierName();
    _loadOrderProducts();
  }

  Future<void> _loadSupplierName() async {
    final prefs = await SharedPreferences.getInstance();
    String name = prefs.getString('name') ?? '';

    // Fallback: fetch supplier name by current_user_id if not in prefs
    if (name.isEmpty) {
      final String? userIdStr = prefs.getString('current_user_id');
      final int? supplierId = userIdStr != null ? int.tryParse(userIdStr) : null;

      if (supplierId != null) {
        final supplier = await supabase
            .from('supplier')
            .select('name')
            .eq('supplier_id', supplierId)
            .maybeSingle();

        if (supplier != null && supplier['name'] != null) {
          name = supplier['name'] as String;
        }
      }
    }

    setState(() {
      supplierName = name.isEmpty ? 'Supplier' : name;
    });
  }

  Future<void> _loadOrderProducts() async {
    try {
      // Fetch all products in this order from supplier_order_description
      final orderItems = await supabase
          .from('supplier_order_description')
          .select('product_id, quantity, price_per_product, receipt_quantity')
          .eq('order_id', widget.orderId);

      final List<Map<String, dynamic>> productsList = [];

      // For each product in the order, fetch product details
      for (final item in orderItems) {
        final productId = item['product_id'];

        // Fetch product info (name, brand_id)
        final productData = await supabase
            .from('product')
            .select('name, brand_id')
            .eq('product_id', productId)
            .maybeSingle();

        if (productData != null) {
          String brandName = '';

          // Fetch brand name if brand_id exists
          if (productData['brand_id'] != null) {
            final brandData = await supabase
                .from('brand')
                .select('name')
                .eq('brand_id', productData['brand_id'])
                .maybeSingle();

            if (brandData != null) {
              brandName = brandData['name'] as String;
            }
          }

          productsList.add({
            'product_id': productId,
            'name': productData['name'] as String,
            'brand': brandName.isEmpty ? 'Unknown' : brandName,
            'quantity': item['quantity'] ?? 0,
            'original_quantity': item['quantity'] ?? 0,
            'price_per_product': item['price_per_product'] ?? 0,
          });
        }
      }

      setState(() {
        products = productsList;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading order products: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------------- TITLE + BACK BUTTON ----------------
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D2D2D),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFFF9D949),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  widget.customerName,
                  style: const TextStyle(
                    color: Color(0xFFF9D949),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            // ---------------- TABLE HEADER ----------------
            Row(
              children: const [
                Expanded(
                  flex: 4,
                  child: Text(
                    "Product Name",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    "Brand",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "Quantity",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ),
              ],
            ),

            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              height: 1,
              color: Colors.white12,
            ),

            // ---------------- PRODUCT LIST ----------------
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFF9D949),
                      ),
                    )
                  : products.isEmpty
                      ? const Center(
                          child: Text(
                            'No products in this order',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            final p = products[index];
                            return _buildRow(p, index);
                          },
                        ),
            ),

            const SizedBox(height: 12),

            // ---------------- SUBMIT BUTTON ----------------
            GestureDetector(
              onTap: isUpdated ? _handleSendUpdate : _handleDone,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: isUpdated
                      ? const Color(0xFF50B2E7)
                      : const Color(0xFFF9D949),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isUpdated ? "Send Update" : "Done",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: isUpdated
                            ? Colors.white
                            : const Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.send,
                      color: isUpdated ? Colors.white : const Color(0xFF1A1A1A),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0,
        onTap: (i) {
          if (i == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AccountPage()),
            );
          }
        },
      ),
    );
  }

  // ============= HANDLE DONE BUTTON =============
  Future<void> _handleDone() async {
    try {
      final nowIso = DateTime.now().toIso8601String().split('.').first; // Trim to seconds
      // Update order status to 'Accepted'
      await supabase
          .from('supplier_order')
          .update({
            'order_status': 'Accepted',
            'last_tracing_by': supplierName,
            'last_tracing_time': nowIso,
          })
          .eq('order_id', widget.orderId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order accepted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error accepting order: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ============= HANDLE SEND UPDATE BUTTON =============
  Future<void> _handleSendUpdate() async {
    try {
      final nowIso = DateTime.now().toIso8601String().split('.').first; // Trim to seconds

      // Update quantities for changed products
      for (final product in products) {
        if (product['quantity'] != product['original_quantity']) {
          await supabase
              .from('supplier_order_description')
              .update({
                'quantity': product['quantity'],
                'last_tracing_by': supplierName,
                'last_tracing_time': nowIso,
              })
              .eq('order_id', widget.orderId)
              .eq('product_id', product['product_id']);
        }
      }

      // Update order status to 'Updated'
      final orderUpdate = await supabase
          .from('supplier_order')
          .update({
            'order_status': 'Updated',
            'last_tracing_by': supplierName,
            'last_tracing_time': nowIso,
          })
          .eq('order_id', widget.orderId)
          .select('order_status')
          .maybeSingle();

      if (orderUpdate == null) {
        throw Exception('Failed to update order status');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error updating order: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ============= EDIT QUANTITY POPUP =============
  void _editQuantity(int index) {
    final controller = TextEditingController(
      text: products[index]['quantity'].toString(),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2D2D2D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Edit Quantity",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: "Enter quantity",
              hintStyle: TextStyle(color: Colors.white70),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white38),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFB7A447)),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () {
                final val = int.tryParse(controller.text);
                if (val != null && val > 0) {
                  setState(() {
                    products[index]['quantity'] = val;
                    isUpdated = true;
                  });
                }
                Navigator.pop(context);
              },
              child: const Text(
                "Save",
                style: TextStyle(color: Color(0xFFB7A447)),
              ),
            ),
          ],
        );
      },
    );
  }

  // ------------------------------------------------------------------
  // ROW COMPONENT (Product Line)
  // ------------------------------------------------------------------
  Widget _buildRow(Map<String, dynamic> p, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Product name
          Expanded(
            flex: 3,
            child: Text(
              p['name'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(width: 8),

          // Brand
          Expanded(
            flex: 2,
            child: Text(
              p['brand'],
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(width: 8),

          // Editable quantity
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => _editQuantity(index),
                child: Container(
                  width: 55,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB7A447),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${p['quantity']}',
                    style: const TextStyle(
                      color: Color(0xFF202020),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'cm',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}