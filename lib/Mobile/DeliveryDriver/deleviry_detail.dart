import 'package:flutter/material.dart';
import '../account_page.dart';
import '../../supabase_config.dart';
import 'route_map_deleviry.dart';
import 'signature_confirmation.dart';
import '../bottom_navbar.dart';

class DeleviryDetail extends StatefulWidget {
  final String customerName;
  final int customerId;
  final int? orderId;
  final int deliveryDriverId;

  const DeleviryDetail({
    super.key,
    required this.customerName,
    required this.customerId,
    this.orderId,
    required this.deliveryDriverId,
  });

  @override
  State<DeleviryDetail> createState() => _DeleviryDetailState();
}

class _DeleviryDetailState extends State<DeleviryDetail> {
  Future<bool?> _showSignaturePopup() async {
    int? orderId = widget.orderId;

    if (orderId == null) {
      final ordersRes =
          await supabase
                  .from('customer_order')
                  .select('customer_order_id')
                  .eq('customer_id', widget.customerId)
                  .order('order_date', ascending: false)
                  .limit(1)
              as List<dynamic>;

      if (ordersRes.isEmpty) return null;
      orderId = ordersRes.first['customer_order_id'] as int;
    }

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => SignatureConfirmation(
        customerName: widget.customerName,
        customerId: widget.customerId,
        orderId: orderId!,
        products: products,
      ),
    );
  }

  int _selectedIndex = 0;

  bool _loading = true;
  List<Map<String, dynamic>> products = [];
  bool _openingMap = false;

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

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    try {
      setState(() {
        _loading = true;
      });

      int? orderId = widget.orderId;

      // Fallback: fetch latest order if not provided
      if (orderId == null) {
        final ordersRes =
            await supabase
                    .from('customer_order')
                    .select('customer_order_id,order_date')
                    .eq('customer_id', widget.customerId)
                    .order('order_date', ascending: false)
                    .limit(1)
                as List<dynamic>;

        if (ordersRes.isEmpty) {
          setState(() {
            products = [];
            _loading = false;
          });
          return;
        }

        orderId = ordersRes.first['customer_order_id'] as int;
      }

      // Fetch product info embedded: product name, brand name and unit name
      final descRes =
          await supabase
                  .from('customer_order_description')
                  .select(
                    'product_id,quantity,product:product_id(name,brand:brand_id(name),unit:unit_id(unit_name))',
                  )
                  .eq('customer_order_id', orderId)
              as List<dynamic>;

      // Fetch prepared quantities from customer_order_inventory for this order
      final invRes =
          await supabase
                  .from('customer_order_inventory')
                  .select('product_id,prepared_quantity')
                  .eq('customer_order_id', orderId)
              as List<dynamic>;

      final Map<int, int> preparedByProduct = {};
      for (final r in invRes) {
        final pid = r['product_id'] as int?;
        final pq = r['prepared_quantity'] as int?;
        if (pid != null && pq != null) preparedByProduct[pid] = pq;
      }

      final List<Map<String, dynamic>> list = [];
      for (final d in descRes) {
        final productIdTop = d['product_id'] as int?;
        final prod = d['product'] as Map<String, dynamic>?;
        final name = prod?['name'] as String? ?? 'Unknown';
        final brandMap = prod?['brand'] as Map<String, dynamic>?;
        final brandName = brandMap?['name'] as String? ?? 'Unknown';
        final unitMap = prod?['unit'] as Map<String, dynamic>?;
        final unitName = unitMap?['unit_name'] as String? ?? 'cm';
        // Prefer prepared_quantity if available, otherwise fall back to description.quantity
        final fallbackQty = (d['quantity'] as int?) ?? 0;
        final qty =
            (productIdTop != null &&
                preparedByProduct.containsKey(productIdTop))
            ? preparedByProduct[productIdTop]
            : fallbackQty;

        list.add({
          'product_id': productIdTop,
          'name': name,
          'brand': brandName,
          'quantity': qty,
          'unit': unitName,
        });
      }

      setState(() {
        products = list;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        products = [];
        _loading = false;
      });
      // ignore: avoid_print
      print('Error fetching delivery details: $e');
    }
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

  Future<void> _confirmDelivery() async {
    try {
      int? orderId = widget.orderId;

      // Fallback: fetch latest order ID for this customer if none was provided
      if (orderId == null) {
        final ordersRes =
            await supabase
                    .from('customer_order')
                    .select('customer_order_id')
                    .eq('customer_id', widget.customerId)
                    .order('order_date', ascending: false)
                    .limit(1)
                as List<dynamic>;

        if (ordersRes.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('No order found')));
          }
          return;
        }

        orderId = ordersRes.first['customer_order_id'] as int;
      }

      // Update all order descriptions with delivered_quantity = quantity
      final descRes =
          await supabase
                  .from('customer_order_description')
                  .select('customer_order_id,product_id,quantity')
                  .eq('customer_order_id', orderId)
              as List<dynamic>;

      // Update each description with delivered_quantity using composite key
      for (final desc in descRes) {
        final productId = desc['product_id'] as int;
        final qty = desc['quantity'] as int;

        await supabase
            .from('customer_order_description')
            .update({
              'delivered_quantity': qty,
              'delivered_date': DateTime.now().toIso8601String(),
            })
            .eq('customer_order_id', orderId)
            .eq('product_id', productId);
      }

      // Note: Order status is updated to 'Delivered' in signature_confirmation.dart
      // Signature confirmation will handle navigation back to home
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to confirm delivery: $e')),
        );
      }
    }
  }

  Future<void> _openRouteOnMap() async {
    if (_openingMap) return;
    setState(() => _openingMap = true);

    try {
      final res = await supabase
          .from('customer')
          .select(
            'name,address,latitude_location,longitude_location,customer_city(name)',
          )
          .eq('customer_id', widget.customerId)
          .maybeSingle();

      debugPrint('Customer data: $res'); // Debug log

      if (res == null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Customer not found')));
        }
        return;
      }

      final lat = res['latitude_location'];
      final lng = res['longitude_location'];
      final rawAddress = (res['address'] as String?) ?? 'Unknown address';
      final customerName = (res['name'] as String?) ?? widget.customerName;

      // Get city name from joined table
      final cityData = res['customer_city'] as Map<String, dynamic>?;
      final cityName = cityData?['name'] as String? ?? '';

      // Format as city-quarter-location
      final address = cityName.isNotEmpty
          ? '$cityName - $rawAddress'
          : rawAddress;

      debugPrint('Coordinates: lat=$lat, lng=$lng'); // Debug log

      if (lat == null || lng == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No coordinates for this customer. Please add location data in database.',
              ),
            ),
          );
        }
        return;
      }

      final latDouble = lat is num ? lat.toDouble() : double.tryParse('$lat');
      final lngDouble = lng is num ? lng.toDouble() : double.tryParse('$lng');

      debugPrint(
        'Parsed coordinates: lat=$latDouble, lng=$lngDouble',
      ); // Debug log

      if (latDouble == null || lngDouble == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid coordinates for this customer'),
            ),
          );
        }
        return;
      }

      if (!mounted) return;

      debugPrint(
        'Opening map with: lat=$latDouble, lng=$lngDouble',
      ); // Debug log

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RouteMapDeleviry(
            customerName: customerName,
            locationLabel: 'Customer Location',
            address: address,
            latitude: latDouble,
            longitude: lngDouble,
            orderId: widget.orderId,
            deliveryDriverId: widget.deliveryDriverId,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error opening map: $e'); // Debug log
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load location: $e')));
      }
    } finally {
      if (mounted) setState(() => _openingMap = false);
    }
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
                  ? const Center(child: CircularProgressIndicator())
                  : products.isEmpty
                  ? const Center(
                      child: Text(
                        'No products found',
                        style: TextStyle(color: Colors.white70),
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
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 18,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Product Name
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      product['name'],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
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
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  // Quantity (box + cm)
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
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFB7A447),
                                              borderRadius:
                                                  BorderRadius.circular(14),
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
                                        const SizedBox(width: 4),
                                        Text(
                                          product['unit'],
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
                          ),
                        );
                      },
                    ),
            ),

            //========== BUTTONS: View Route on Map & Confirm Delivery ==========
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  // View Route on Map Button (Green)
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _openingMap ? null : _openRouteOnMap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF67CD67), // Green
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      child: const Text(
                        'View Route on Map',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Confirm Delivery Button (Gold)
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: const Color(0xFF2D2D2D),
                            title: const Text(
                              'Confirm Delivery',
                              style: TextStyle(color: Colors.white),
                            ),
                            content: const Text(
                              'Are you sure you want to confirm this delivery?',
                              style: TextStyle(color: Colors.white70),
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
                                onPressed: () async {
                                  Navigator.pop(context);
                                  final confirmed = await _showSignaturePopup();
                                  if (confirmed == true) {
                                    _confirmDelivery();
                                  }
                                },
                                child: const Text(
                                  'Confirm',
                                  style: TextStyle(color: Color(0xFFB7A447)),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB7A447), // Gold
                        foregroundColor: const Color(0xFF202020),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      child: const Text(
                        'Confirm Delivery',
                        style: TextStyle(
                          fontSize: 21,
                          color: Color(0xFFFFFFFF),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      //========== BOTTOM NAV BAR ===========
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
