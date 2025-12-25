import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../account_page.dart';
import '../bottom_navbar.dart';
import 'staff_home.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerDetail extends StatefulWidget {
  final String customerName;
  final int customerId;

  const CustomerDetail({
    super.key,
    required this.customerName,
    required this.customerId,
  });

  @override
  State<CustomerDetail> createState() => _CustomerDetailState();
}

class _CustomerDetailState extends State<CustomerDetail> {
  int _selectedIndex = 0;

  // NEW: حالة الزر (Done أو Send Update)
  bool _isUpdateMode = false;
  bool _saving = false;
  bool _loading = true;
  List<Map<String, dynamic>> products = const [];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    try {
      setState(() => _loading = true);
      final prefs = await SharedPreferences.getInstance();
      final String? userIdStr = prefs.getString('current_user_id');
      final int? staffId = userIdStr != null ? int.tryParse(userIdStr) : null;

      // Fetch customer_order_inventory items assigned to this staff
      final List<dynamic> inventoryItems = await Supabase.instance.client
          .from('customer_order_inventory')
          .select(
            'product_id, batch_id, batch(product:product_id(name, brand:brand_id(name), unit:unit_id(unit_name)), storage_location_descrption)',
          )
          .eq('customer_order_id', widget.customerId)
          .eq('prepared_by', staffId ?? 0)
          .order('product_id');

      final mapped = inventoryItems.map<Map<String, dynamic>>((row) {
        final batch = row['batch'] as Map?;
        final product = batch?['product'] as Map?;
        final brandMap = product?['brand'] as Map?;
        final unitMap = product?['unit'] as Map?;

        return {
          'product_id': row['product_id'] as int?,
          'name': product?['name']?.toString() ?? 'Unknown',
          'brand': brandMap?['name']?.toString() ?? 'Unknown',
          'quantity': 0, // Will be fetched separately
          'unit': unitMap?['unit_name']?.toString() ?? 'cm',
          'batch_id': row['batch_id'] as int?,
          'storage_location':
              batch?['storage_location_descrption']?.toString() ?? 'N/A',
        };
      }).toList();

      // Fetch quantities from customer_order_description
      if (mapped.isNotEmpty) {
        final List<dynamic> descriptions = await Supabase.instance.client
            .from('customer_order_description')
            .select('product_id, quantity')
            .eq('customer_order_id', widget.customerId)
            .filter(
              'product_id',
              'in',
              mapped.map((m) => m['product_id']).toList(),
            );

        // Map quantities back to products
        for (final item in mapped) {
          final productId = item['product_id'];
          final desc = descriptions.firstWhere(
            (d) => d['product_id'] == productId,
            orElse: () => {'quantity': 0},
          );
          item['quantity'] = (desc['quantity'] as num?)?.toInt() ?? 0;
        }
      }

      if (mounted) {
        setState(() {
          products = mapped;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching products: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onItemTapped(int index) {
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AccountPage()),
      );
      return;
    }
    setState(() => _selectedIndex = index);
  }

  // ======================================
  // دالة تعديل الـ quantity فقط
  // ======================================
  void _editQuantity(int index) {
    final controller = TextEditingController(
      text: products[index]['quantity'].toString(),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2D2D2D),
          title: const Text(
            'Edit Quantity',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Enter quantity',
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
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () {
                final value = int.tryParse(controller.text);
                if (value != null && value > 0) {
                  setState(() {
                    products[index]['quantity'] = value;
                    _isUpdateMode = true; // تفعيل وضع التحديث عند تعديل الكمية
                  });
                }
                Navigator.pop(context);
              },
              child: const Text(
                'Save',
                style: TextStyle(color: Color(0xFFB7A447)),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveUpdates() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? userIdStr = prefs.getString('current_user_id');
      final String? staffName = prefs.getString('current_user_name');
      final int? staffId = userIdStr != null ? int.tryParse(userIdStr) : null;
      final now = DateTime.now();

      for (final product in products) {
        final pid = product['product_id'] as int?;
        final qty = product['quantity'] as int? ?? 0;
        final batchId = product['batch_id'] as int?;
        if (pid == null) continue;

        // Update customer_order_inventory: set prepared_by, batch_id, and prepared_quantity
        await Supabase.instance.client
            .from('customer_order_inventory')
            .update({
              'prepared_by': staffId,
              'batch_id': batchId,
              'prepared_quantity': qty,
              'last_action_by': staffName ?? 'Unknown',
              'last_action_time': now.toIso8601String(),
            })
            .eq('customer_order_id', widget.customerId)
            .eq('product_id', pid);

        // Update quantity in customer_order_description
        await Supabase.instance.client
            .from('customer_order_description')
            .update({
              'quantity': qty,
              'last_action_by': staffName ?? 'Unknown',
              'last_action_time': now.toIso8601String(),
            })
            .eq('customer_order_id', widget.customerId)
            .eq('product_id', pid);
      }

      // Check if all items in this order are prepared by their respective staff
      final List<dynamic> allInventoryItems = await Supabase.instance.client
          .from('customer_order_inventory')
          .select('prepared_quantity')
          .eq('customer_order_id', widget.customerId);

      // Check if all items have prepared_quantity set
      bool allItemsPrepared = allInventoryItems.every(
        (item) => item['prepared_quantity'] != null,
      );

      // Only mark order as Prepared if ALL items are prepared
      if (allItemsPrepared) {
        await Supabase.instance.client
            .from('customer_order')
            .update({
              'order_status': 'Prepared',
              'last_action_by': staffName ?? 'Unknown',
              'last_action_time': now.toIso8601String(),
            })
            .eq('customer_order_id', widget.customerId);
      }

      if (mounted) {
        // Return true to signal successful completion
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error saving updates: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving updates: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text('Confirm', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to mark this order as prepared?',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _saveUpdates();
            },
            child: const Text(
              'Yes',
              style: TextStyle(color: Color(0xFFB7A447)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF202020),
      body: SafeArea(
        child: Column(
          children: [
            //========== TOP BAR (Back + Name) ==========
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  // دائرة السهم
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D2D2D),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFFB7A447),
                        size: 30,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // اسم الزبون
                  Expanded(
                    child: Text(
                      widget.customerName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            //========== HEADER ROW ==========
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: const [
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Product Name',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Brand',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // خط تحت الهيدر
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 16, 8),
              child: Container(height: 1, color: const Color(0xFFFFFFFF)),
            ),

            //========== LIST OF PRODUCTS ==========
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFFE14D),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF2D2D2D),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.25),
                                  blurRadius: 1,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // TOP SECTION: Product Name, Brand, Quantity (matching header layout)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 18,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      // Product Name
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          product['name'],
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      // Brand
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          product['brand'],
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      // Quantity (box + unit)
                                      Expanded(
                                        flex: 2,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            GestureDetector(
                                              onTap: () => _editQuantity(index),
                                              child: Container(
                                                width: 50,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 8,
                                                      horizontal: 12,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFFB7A447,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                alignment: Alignment.center,
                                                child: Text(
                                                  '${product['quantity']}',
                                                  style: const TextStyle(
                                                    color: Color(0xFF202020),
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              product['unit'] ?? 'cm',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // BOTTOM SECTION: Storage Location (Full Width)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xB8894D26),
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(20),
                                      bottomRight: Radius.circular(20),
                                    ),
                                  ),
                                  child: Text(
                                    product['storage_location'],
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            //========== DONE / SEND UPDATE BUTTON ==========
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _showConfirmationDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isUpdateMode
                        ? const Color(0xFF50B2E7) // أزرق في وضع Send Update
                        : const Color(0xFFB7A447), // ذهبي في وضع Done
                    foregroundColor: const Color(0xFF202020),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isUpdateMode ? 'Send  Update' : ' Done ',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_right_alt,
                        size: 50,
                        color: Colors.black, // أبيض مع الأزرق، أسود مع الذهبي
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
