import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../supabase_config.dart';
import '../bottom_navbar.dart';
import 'salesRep_home_page.dart';
import 'salesRep_archive_page.dart';
import 'salesRep_customers_page.dart';
import '../account_page.dart';

class SalesRepCartPage extends StatefulWidget {
  const SalesRepCartPage({super.key});

  @override
  State<SalesRepCartPage> createState() => _SalesRepCartPageState();
}

class _SalesRepCartPageState extends State<SalesRepCartPage> {
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;
  // ignore: unused_field
  int? _orderId; // current cart order id
  int _currentIndex = 1; // Cart tab index

  Color get _bg => const Color(0xFF1A1A1A);
  Color get _card => const Color(0xFF2D2D2D);
  Color get _accent => const Color(0xFFB7A447); // yellow pill
  Color get _muted => Colors.white70;

  double get _total {
    return _items.fold(
      0.0,
      (s, i) => s + (i['price'] as double) * (i['qty'] as int),
    );
  }

  // ===== navigation handler for bottom bar (SalesRep layout indices) =====
  void _onNavTap(int i) {
    setState(() => _currentIndex = i);

    if (i == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SalesRepHomePage()),
      );
    } else if (i == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SalesRepCartPage()),
      );
    } else if (i == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SalesRepArchivePage()),
      );
    } else if (i == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SalesRepCustomersPage()),
      );
    } else if (i == 4) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AccountPage()),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    setState(() {
      _isLoading = true;
      _items = [];
      _orderId = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userIdStr = prefs.getString('current_user_id');
      final salesRepId = userIdStr != null ? int.tryParse(userIdStr) : null;

      if (salesRepId == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Load cart items from local storage only
      final cartJson = prefs.getString('cart_items') ?? '{}';
      final cartMap = jsonDecode(cartJson) as Map<String, dynamic>;

      final parsedItems = cartMap.entries.map<Map<String, dynamic>>((entry) {
        final item = entry.value as Map<String, dynamic>;
        final priceRaw = item['price'];
        final price = priceRaw is num ? priceRaw.toDouble() : 0.0;
        return {
          'product_id': item['product_id'],
          'name': item['name'] ?? '—',
          'brand': item['brand'] ?? '—',
          'price': price,
          'qty': item['qty'] ?? 1,
        };
      }).toList();

      setState(() {
        _orderId = null; // will be set on submit
        _items = parsedItems;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading cart: $e');
      setState(() => _isLoading = false);
    }
  }

  // ignore: unused_element
  void _increaseQty(int index) {
    setState(() {
      _items[index]['qty'] = (_items[index]['qty'] as int) + 1;
    });
    _persistLocalQuantity(index);
  }

  // ignore: unused_element
  void _decreaseQty(int index) {
    setState(() {
      final current = _items[index]['qty'] as int;
      if (current > 1) _items[index]['qty'] = current - 1;
    });
    _persistLocalQuantity(index);
  }

  Future<void> _persistLocalQuantity(int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = prefs.getString('cart_items') ?? '{}';
      final cartMap = jsonDecode(cartJson) as Map<String, dynamic>;
      final productId = _items[index]['product_id'];
      if (productId == null) return;

      final key = productId.toString();
      if (cartMap.containsKey(key)) {
        final item = Map<String, dynamic>.from(cartMap[key] as Map);
        item['qty'] = _items[index]['qty'];
        cartMap[key] = item;
        await prefs.setString('cart_items', jsonEncode(cartMap));
      }
    } catch (e) {
      debugPrint('Error persisting quantity: $e');
    }
  }

  Future<void> _deleteItem(int index) async {
    try {
      final productId = _items[index]['product_id'];
      if (productId == null) return;

      final prefs = await SharedPreferences.getInstance();
      final cartJson = prefs.getString('cart_items') ?? '{}';
      final cartMap = jsonDecode(cartJson) as Map<String, dynamic>;
      final key = productId.toString();

      if (cartMap.containsKey(key)) {
        cartMap.remove(key);
        await prefs.setString('cart_items', jsonEncode(cartMap));
      }

      setState(() {
        _items.removeAt(index);
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Item removed from cart')));
      }
    } catch (e) {
      debugPrint('Error deleting item: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to remove item: $e')));
      }
    }
  }

  void _sendOrder() {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No items to send')));
      return;
    }

    _openCustomerPicker();
  }

  Future<void> _submitOrder(int customerId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userIdStr = prefs.getString('current_user_id');
      final salesRepId = userIdStr != null ? int.tryParse(userIdStr) : null;
      if (salesRepId == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No sales rep id found')));
        return;
      }

      // Fetch sales rep name for auditing fields
      final salesRepRow = await supabase
          .from('sales_representative')
          .select('name')
          .eq('sales_rep_id', salesRepId)
          .maybeSingle();

      final actorName = (salesRepRow?['name'] as String?)?.trim();
      final actionBy = (actorName != null && actorName.isNotEmpty)
          ? actorName
          : 'salesrep_$salesRepId';
      final actionTime = DateTime.now().toIso8601String();

      // Create order and insert items
      double totalCost = _total;
      const int taxPercent = 16;
      double totalBalance = totalCost * (1 + taxPercent / 100);

      debugPrint('💰 Order Calculation:');
      debugPrint('   Total Cost: $totalCost');
      debugPrint('   Tax Percent: $taxPercent');
      debugPrint('   Total Balance: $totalBalance');

      final createOrder = await supabase
          .from('customer_order')
          .insert({
            'customer_id': customerId,
            'sales_rep_id': salesRepId,
            'order_status': 'Received',
            'order_date': actionTime,
            'total_cost': totalCost.toDouble(),
            'tax_percent': taxPercent,
            'total_balance': totalBalance.toDouble(),
            'last_action_by': actionBy,
            'last_action_time': actionTime,
          })
          .select()
          .single();

      debugPrint('✅ Created order: ${createOrder['customer_order_id']}');
      debugPrint('   DB Total Cost: ${createOrder['total_cost']}');
      debugPrint('   DB Tax Percent: ${createOrder['tax_percent']}');
      debugPrint('   DB Total Balance: ${createOrder['total_balance']}');

      final newOrderId = createOrder['customer_order_id'] as int?;

      if (newOrderId != null) {
        for (final item in _items) {
          try {
            await supabase.from('customer_order_description').insert({
              'customer_order_id': newOrderId,
              'product_id': item['product_id'],
              'quantity': item['qty'],
              'total_price': (item['price'] as double) * (item['qty'] as int),
              'last_action_by': actionBy,
              'last_action_time': actionTime,
            });
          } catch (e) {
            debugPrint('Error inserting line item: $e');
          }
        }
      }

      // Clear cart from local storage
      await prefs.remove('cart_items');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order ent and Saved successfully')),
        );
        await _loadCart();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send order: $e')));
      }
    }
  }

  Future<void> _openCustomerPicker() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userIdStr = prefs.getString('current_user_id');
      final salesRepId = userIdStr != null ? int.tryParse(userIdStr) : null;
      if (salesRepId == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No sales rep id found')));
        return;
      }

      final rows = await supabase
          .from('customer')
          .select('customer_id, name')
          .eq('sales_rep_id', salesRepId)
          .order('name');

      final customers = (rows as List)
          .map<Map<String, dynamic>>(
            (e) => {
              'id': e['customer_id'] as int?,
              'name': (e['name'] as String?) ?? '—',
            },
          )
          .where((e) => e['id'] != null)
          .toList();

      int? selectedId = customers.isNotEmpty
          ? customers.first['id'] as int?
          : null;

      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) {
          return AlertDialog(
            backgroundColor: _card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Select Customer',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: DropdownButtonFormField<int>(
                initialValue: selectedId,
                dropdownColor: _card,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF262626),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _accent, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _accent, width: 2),
                  ),
                ),
                items: customers
                    .map(
                      (c) => DropdownMenuItem<int>(
                        value: c['id'] as int,
                        child: Text(c['name'] as String),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  selectedId = v;
                },
              ),
            ),
            actionsPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    if (selectedId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select a customer'),
                        ),
                      );
                      return;
                    }
                    Navigator.pop(context);
                    _submitOrder(selectedId!);
                  },
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      debugPrint('Error opening customer picker: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load customers: $e')));
      }
    }
  }

  // ========== Edit quantity dialog (similar to OrderDetailsPage) ==========
  void _editQuantity(int index) {
    final controller = TextEditingController(text: '${_items[index]['qty']}');

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
                    _items[index]['qty'] = val;
                  });
                  _persistLocalQuantity(index);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFB7A447)),
              )
            : Column(
                children: [
                  const SizedBox(height: 12),

                  // Header labels row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        Row(
                          children: const [
                            Expanded(
                              flex: 3,
                              child: Text(
                                'Name',
                                style: TextStyle(
                                  color: Colors.white,
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
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Price',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 86,
                              child: Text(
                                'Quantity',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFFF9D949),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 40,
                              child: Text(
                                ' ',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Divider(color: Colors.white24, thickness: 1),
                      ],
                    ),
                  ),

                  // Product list
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                      child: _items.isEmpty
                          ? const Center(
                              child: Text(
                                'Cart is empty',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                            )
                          : ListView.separated(
                              itemCount: _items.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, i) {
                                final item = _items[i];
                                return Container(
                                  decoration: BoxDecoration(
                                    color: _card,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      // Name (two lines)
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          item['name'] as String,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),

                                      // Brand
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          item['brand'] as String,
                                          style: TextStyle(
                                            color: _muted,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          textAlign: TextAlign.left,
                                        ),
                                      ),

                                      // Price
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          '${(item['price'] as double).toStringAsFixed(0)}\$',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          textAlign: TextAlign.left,
                                        ),
                                      ),

                                      // Quantity pill + unit (tappable)
                                      SizedBox(
                                        width: 86,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            GestureDetector(
                                              onTap: () => _editQuantity(i),
                                              child: Container(
                                                width: 44,
                                                height: 36,
                                                decoration: BoxDecoration(
                                                  color: _accent,
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                alignment: Alignment.center,
                                                child: Text(
                                                  '${item['qty']}',
                                                  style: const TextStyle(
                                                    color: Color(0xFF202020),
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
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Delete button (X)
                                      SizedBox(
                                        width: 40,
                                        child: IconButton(
                                          onPressed: () => _deleteItem(i),
                                          icon: const Icon(
                                            Icons.close,
                                            color: Color(0xFFFF6B6B),
                                            size: 22,
                                          ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ),

                  // Spacer to visually match screenshot
                  const SizedBox(height: 18),

                  // Total price
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18.0),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Tolat Price : ${_formatNumber(_total)}\$',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Send Order button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0),
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _sendOrder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            SizedBox(width: 12),
                            Text(
                              'S e n d   O r d e r',
                              style: TextStyle(
                                color: Color(0xFF202020),
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2,
                              ),
                            ),
                            SizedBox(width: 12),
                            Icon(Icons.send, color: Color(0xFF202020)),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),
                ],
              ),
      ),

      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }

  String _formatNumber(double v) {
    // simple thousands separator
    final parts = v.toInt().toString().split('').reversed.toList();
    final out = <String>[];
    for (var i = 0; i < parts.length; i++) {
      if (i != 0 && i % 3 == 0) out.add(',');
      out.add(parts[i]);
    }
    return out.reversed.join();
  }
}
