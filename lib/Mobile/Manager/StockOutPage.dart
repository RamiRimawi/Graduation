import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../manager_theme.dart';
import 'PendingOrderDetailsPage.dart';
import 'PreparingOrderDetailsPage.dart';
import 'order_item.dart';
import 'PreparedOrderDetailsPage.dart';
import 'DriverOrdersPage.dart';

// ====================== MODELS ======================

class OrderInfo {
  final int id;
  final String customerName;
  final int inventoryNo;
  final String supplierName;

  OrderInfo({
    required this.id,
    required this.customerName,
    required this.inventoryNo,
    required this.supplierName,
  });
}

class DeliveryDriver {
  final int driverId;
  final String name;
  final int assignedOrders;
  final String image;

  DeliveryDriver({
    required this.driverId,
    required this.name,
    required this.assignedOrders,
    required this.image,
  });
}

// ====================== PAGE ======================

class StockOutPage extends StatefulWidget {
  final int initialIndex;
  const StockOutPage({super.key, this.initialIndex = 0});

  @override
  State<StockOutPage> createState() => _StockOutPageState();
}

class _StockOutPageState extends State<StockOutPage> {
  late final PageController _pageController;
  late int _currentTab;
  List<OrderInfo> _pendingOrders = [];
  List<OrderInfo> _preparingOrders = [];
  List<OrderInfo> _preparedOrders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _fetchPendingOrders();
    _fetchPreparingOrders();
    _fetchPreparedOrders();
    _fetchDeliveryDrivers();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchPendingOrders() async {
    try {
      if (!mounted) return;
      setState(() => _loading = true);
      final response = await Supabase.instance.client
          .from('customer_order')
          .select('customer_order_id, customer:customer_id(name)')
          .eq('order_status', 'Pinned')
          .order('customer_order_id');

      final orders = response.map<OrderInfo>((row) {
        final customer = row['customer'] as Map<String, dynamic>?;
        return OrderInfo(
          id: row['customer_order_id'] as int,
          customerName: customer?['name'] as String? ?? 'Unknown',
          inventoryNo: 1,
          supplierName: customer?['name'] as String? ?? 'Unknown',
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _pendingOrders = orders;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error fetching pending orders: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _fetchPreparingOrders() async {
    try {
      final response = await Supabase.instance.client
          .from('customer_order')
          .select('customer_order_id, customer:customer_id(name)')
          .eq('order_status', 'Preparing')
          .order('customer_order_id');

      final orders = response.map<OrderInfo>((row) {
        final customer = row['customer'] as Map<String, dynamic>?;
        return OrderInfo(
          id: row['customer_order_id'] as int,
          customerName: customer?['name'] as String? ?? 'Unknown',
          inventoryNo: 1,
          supplierName: customer?['name'] as String? ?? 'Unknown',
        );
      }).toList();

      if (mounted) {
        setState(() {
          _preparingOrders = orders;
        });
      }
    } catch (e) {
      debugPrint('Error fetching preparing orders: $e');
    }
  }

  Future<void> _fetchPreparedOrders() async {
    try {
      final response = await Supabase.instance.client
          .from('customer_order')
          .select('customer_order_id, customer:customer_id(name)')
          .eq('order_status', 'Prepared')
          .order('customer_order_id');

      final orders = response.map<OrderInfo>((row) {
        final customer = row['customer'] as Map<String, dynamic>?;
        return OrderInfo(
          id: row['customer_order_id'] as int,
          customerName: customer?['name'] as String? ?? 'Unknown',
          inventoryNo: 1,
          supplierName: customer?['name'] as String? ?? 'Unknown',
        );
      }).toList();

      if (mounted) {
        setState(() {
          _preparedOrders = orders;
        });
      }
    } catch (e) {
      debugPrint('Error fetching prepared orders: $e');
    }
  }

  // Refresh data for a specific tab index before rendering
  void _refreshTab(int index) {
    switch (index) {
      case 0:
        _fetchPendingOrders();
        break;
      case 1:
        _fetchPreparingOrders();
        break;
      case 2:
        _fetchPreparedOrders();
        break;
      case 3:
        _fetchDeliveryDrivers();
        break;
    }
  }

  List<DeliveryDriver> _drivers = [];

  void _onTabSelected(int index) {
    // Refresh data for the selected tab before navigating
    _refreshTab(index);
    setState(() => _currentTab = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  Future<List<Map<String, dynamic>>> _fetchDriverOrders(int driverId) async {
    try {
      final supabase = Supabase.instance.client;

      // Fetch all orders for this driver with Delivery status
      final ordersResponse = await supabase
          .from('customer_order')
          .select('customer_order_id, customer:customer_id(name)')
          .eq('delivered_by_id', driverId)
          .eq('order_status', 'Delivery')
          .order('customer_order_id');

      if (ordersResponse.isEmpty) return [];

      // Get all order IDs
      final orderIds = ordersResponse
          .map((o) => o['customer_order_id'] as int)
          .toList();

      // Fetch all inventory items for these orders
      final inventoryResponse = await supabase
          .from('customer_order_inventory')
          .select('*')
          .inFilter('customer_order_id', orderIds);

      // Fetch product details
      final productIds = inventoryResponse
          .map((i) => i['product_id'] as int)
          .toSet()
          .toList();

      final productsResponse = await supabase
          .from('product')
          .select('*')
          .inFilter('product_id', productIds);

      final brandIds = productsResponse
          .map((p) => p['brand_id'] as int?)
          .where((id) => id != null)
          .toSet()
          .toList();

      final unitIds = productsResponse
          .map((p) => p['unit_id'] as int?)
          .where((id) => id != null)
          .toSet()
          .toList();

      final brandsResponse = brandIds.isNotEmpty
          ? await supabase
                .from('brand')
                .select('*')
                .inFilter('brand_id', brandIds)
          : [];

      final unitsResponse = unitIds.isNotEmpty
          ? await supabase.from('unit').select('*').inFilter('unit_id', unitIds)
          : [];

      // Build maps
      final productMap = {for (var p in productsResponse) p['product_id']: p};
      final brandMap = {for (var b in brandsResponse) b['brand_id']: b};
      final unitMap = {for (var u in unitsResponse) u['unit_id']: u};

      // Build order list with consolidated items
      final List<Map<String, dynamic>> orders = [];

      for (final orderRow in ordersResponse) {
        final orderId = orderRow['customer_order_id'] as int;
        final customer = orderRow['customer'] as Map<String, dynamic>?;
        final customerName = customer?['name'] as String? ?? 'Unknown';

        // Get all items for this order and consolidate by product
        final orderItems = inventoryResponse
            .where((i) => i['customer_order_id'] == orderId)
            .toList();

        // Group by product_id and sum quantities
        final Map<int, double> productQtyMap = {};
        for (final item in orderItems) {
          final productId = item['product_id'] as int;
          final qty = (item['quantity'] as num?)?.toDouble() ?? 0.0;
          productQtyMap[productId] = (productQtyMap[productId] ?? 0.0) + qty;
        }

        // Build OrderItem list
        final List<OrderItem> items = [];
        for (final entry in productQtyMap.entries) {
          final product = productMap[entry.key];
          if (product == null) continue;

          final brandId = product['brand_id'] as int?;
          final unitId = product['unit_id'] as int?;

          final brandName = brandId != null
              ? (brandMap[brandId]?['brand_name'] as String? ?? '')
              : '';
          final unitName = unitId != null
              ? (unitMap[unitId]?['unit_name'] as String? ?? '')
              : '';

          items.add(
            OrderItem(
              entry.key,
              product['product_name'] as String? ?? 'Unknown',
              brandName,
              unitName,
              entry.value.toInt(),
            ),
          );
        }

        orders.add({'id': orderId, 'customer': customerName, 'items': items});
      }

      return orders;
    } catch (e) {
      debugPrint('Error fetching driver orders: $e');
      return [];
    }
  }

  Future<void> _fetchDeliveryDrivers() async {
    try {
      final supabase = Supabase.instance.client;

      // Fetch all drivers using type column for quick access
      final driversResponse = await supabase
          .from('accounts')
          .select(
            'user_id, profile_image, delivery_driver!delivery_driver_delivery_driver_id_fkey(name)',
          )
          .eq('type', 'Delivery Driver');

      // Fetch all orders currently in Delivery status to count per driver
      final ordersResponse = await supabase
          .from('customer_order')
          .select('delivered_by_id')
          .eq('order_status', 'Delivery');

      // Build counts map
      final Map<int, int> countMap = {};
      for (final row in ordersResponse) {
        final id = row['delivered_by_id'] as int?;
        if (id != null) {
          countMap[id] = (countMap[id] ?? 0) + 1;
        }
      }

      // Build drivers list
      final List<DeliveryDriver> drivers = [];
      for (final d in driversResponse) {
        final id = d['user_id'] as int?;
        if (id == null) continue;

        final driverData = (d['delivery_driver'] ?? {}) as Map<String, dynamic>;
        final name = driverData['name'] as String? ?? 'Unknown';
        final profileImage = d['profile_image'] as String?;

        drivers.add(
          DeliveryDriver(
            driverId: id,
            name: name,
            assignedOrders: countMap[id] ?? 0,
            image: profileImage ?? '',
          ),
        );
      }

      if (mounted) {
        setState(() {
          _drivers = drivers;
        });
      }
    } catch (e) {
      debugPrint('Error fetching delivery drivers: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) {
                  // Refresh data when swiping between tabs before rendering
                  _refreshTab(i);
                  setState(() => _currentTab = i);
                },
                children: [
                  _PendingSection(orders: _pendingOrders, isLoading: _loading),
                  _PreparingSection(orders: _preparingOrders),
                  _PreparedSection(orders: _preparedOrders),
                  _DeliverySection(drivers: _drivers),
                ],
              ),
            ),

            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: _StockOutStatusBar(
                currentIndex: _currentTab,
                onChanged: _onTabSelected,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ====================== PENDING SECTION ======================

class _PendingSection extends StatelessWidget {
  final List<OrderInfo> orders;
  final bool isLoading;
  const _PendingSection({required this.orders, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pending Order',
            style: TextStyle(
              color: AppColors.gold,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),

          const _HeaderRow(
            left: 'Order ID #',
            middle: 'Customer Name',
            right: '',
          ),

          const SizedBox(height: 10),

          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.yellow),
                  )
                : orders.isEmpty
                ? const Center(
                    child: Text(
                      'No pending orders',
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                : ListView.separated(
                    itemCount: orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final o = orders[i];
                      return GestureDetector(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OrderDetailsPage(orderId: o.id),
                            ),
                          );

                          // Refresh if order was successfully sent
                          if (result == true && context.mounted) {
                            final stockOutState = context
                                .findAncestorStateOfType<_StockOutPageState>();
                            stockOutState?._fetchPendingOrders();
                            stockOutState?._fetchPreparingOrders();
                          }
                        },
                        child: _OrderCard(
                          left: '${o.id}',
                          middle: o.customerName,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ====================== PREPARING SECTION ======================

class _PreparingSection extends StatelessWidget {
  final List<OrderInfo> orders;
  const _PreparingSection({required this.orders});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Preparing Order',
            style: TextStyle(
              color: AppColors.gold,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),

          const _HeaderRow(
            left: 'Order ID #',
            middle: 'Customer Name',
            right: 'Inventory #',
          ),
          const SizedBox(height: 10),

          Expanded(
            child: ListView.separated(
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final o = orders[i];

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            PreparingOrderDetailsPage(orderId: o.id),
                      ),
                    );
                  },
                  child: _OrderCard(
                    left: '${o.id}',
                    middle: o.customerName,
                    right: '${o.inventoryNo}',
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ====================== PREPARED SECTION ======================

class _PreparedSection extends StatelessWidget {
  final List<OrderInfo> orders;
  const _PreparedSection({required this.orders});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Prepared Order',
            style: TextStyle(
              color: AppColors.gold,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          const _HeaderRow(
            left: 'Order ID #',
            middle: 'Customer Name',
            right: 'Inventory #',
          ),
          const SizedBox(height: 10),

          Expanded(
            child: orders.isEmpty
                ? const Center(
                    child: Text(
                      'No prepared orders',
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                : ListView.separated(
                    itemCount: orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final o = orders[i];

                      return GestureDetector(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PreparedOrderDetailsPage(orderId: o.id),
                            ),
                          );

                          // Refresh if order was sent to delivery
                          if (result == true && context.mounted) {
                            final stockOutState = context
                                .findAncestorStateOfType<_StockOutPageState>();
                            if (stockOutState != null) {
                              await stockOutState._fetchPreparedOrders();
                              await stockOutState._fetchDeliveryDrivers();
                            }
                          }
                        },
                        child: _OrderCard(
                          left: '${o.id}',
                          middle: o.customerName,
                          right: '${o.inventoryNo}',
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ====================== DELIVERY SECTION ======================

class _DeliverySection extends StatelessWidget {
  final List<DeliveryDriver> drivers;

  const _DeliverySection({required this.drivers});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Active Delivery',
            style: TextStyle(
              color: AppColors.gold,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 16),

          Expanded(
            child: ListView.separated(
              itemCount: drivers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (_, i) {
                final d = drivers[i];

                return GestureDetector(
                  onTap: () async {
                    // Show loading indicator
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.yellow,
                        ),
                      ),
                    );

                    // Fetch orders for this driver
                    final orders = await context
                        .findAncestorStateOfType<_StockOutPageState>()
                        ?._fetchDriverOrders(d.driverId);

                    if (context.mounted) {
                      Navigator.pop(context); // Close loading

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DriverOrdersPage(
                            driverName: d.name,
                            assignedOrders: orders ?? [],
                          ),
                        ),
                      );
                    }
                  },
                  child: _DeliveryCard(driver: d),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ====================== SMALL WIDGETS ======================

class _HeaderRow extends StatelessWidget {
  final String left, middle, right;
  const _HeaderRow({
    required this.left,
    required this.middle,
    required this.right,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                left,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.only(left: 42),
                child: Text(
                  middle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: right.isEmpty
                  ? Container()
                  : Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Text(
                        right,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(height: 1, color: Colors.white24),
      ],
    );
  }
}

class _OrderCard extends StatelessWidget {
  final String left, middle;
  final String? right;

  const _OrderCard({required this.left, required this.middle, this.right});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Center(
              child: Text(
                left,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              middle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (right != null)
            SizedBox(
              width: 50,
              child: Text(
                right!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  final DeliveryDriver driver;

  const _DeliveryCard({required this.driver});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.card,
            backgroundImage:
                driver.image.isNotEmpty && driver.image.startsWith('http')
                ? NetworkImage(driver.image)
                : null,
            child: driver.image.isEmpty || !driver.image.startsWith('http')
                ? Text(
                    driver.name.isNotEmpty
                        ? driver.name.substring(0, 1).toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              driver.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          Container(
            width: 70,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.bgDark.withOpacity(.7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${driver.assignedOrders}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Text(
                  'Assign',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StockOutStatusBar extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onChanged;

  const _StockOutStatusBar({
    required this.currentIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const items = [
      _StatusData(Icons.schedule, 'Pending'),
      _StatusData(Icons.engineering, 'Preparing'),
      _StatusData(Icons.check_box_rounded, 'Prepared'),
      _StatusData(Icons.local_shipping_rounded, 'Delivery'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(26),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        children: List.generate(items.length, (i) {
          final active = i == currentIndex;
          final data = items[i];

          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.gold.withOpacity(0.18)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Icon(
                      data.icon,
                      size: 20,
                      color: active ? AppColors.gold : Colors.white,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.label,
                      style: TextStyle(
                        color: active ? AppColors.gold : Colors.white,
                        fontSize: 11,
                        fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _StatusData {
  final IconData icon;
  final String label;
  const _StatusData(this.icon, this.label);
}
