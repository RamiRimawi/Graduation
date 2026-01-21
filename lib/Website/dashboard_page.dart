import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../supabase_config.dart';
import 'sidebar.dart';
import 'Orders/Orders_detail_popup.dart';
import 'Orders/Orders_stock_out_page.dart';
import 'Notifications/notification_bell_widget.dart';

const Color gold = Color(0xFFB7A447);
const Color blue = Color(0xFF50B2E7);

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 🔵 الزر الأول (الـ Home) هو الفعّال في هاي الصفحة
          const Sidebar(activeIndex: 0),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: const [NotificationBellWidget()],
                  ),
                  const SizedBox(height: 8),
                  const _TopStepsRow(),
                  const SizedBox(height: 16),
                  const Expanded(child: _MainContent()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                          TOP STEPS ROW (الكروت الأربعة)                   */
/* -------------------------------------------------------------------------- */
const double _cardW = 170;
const double _cardH = 150;
const double _arrowW = 30;

class _TopStepsRow extends StatefulWidget {
  const _TopStepsRow();

  @override
  State<_TopStepsRow> createState() => _TopStepsRowState();
}

class _TopStepsRowState extends State<_TopStepsRow> {
  int pendingCount = 0;
  int preparingCount = 0;
  int preparedCount = 0;
  int deliveringCount = 0;
  int deliveredCount = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrderCounts();
  }

  Future<void> _fetchOrderCounts() async {
    try {
      // Fetch all orders and count by status
      final data = await supabase.from('customer_order').select('order_status');

      // Count orders by status
      int pending = 0;
      int preparing = 0;
      int prepared = 0;
      int delivering = 0;
      int delivered = 0;

      for (final row in data) {
        final status = (row['order_status'] ?? '').toString();
        switch (status) {
          case 'Received':
          case 'Pinned':
          case 'Updated to Accountant':
          case 'Hold':
            pending++;
            break;
          case 'Preparing':
            preparing++;
            break;
          case 'Prepared':
            prepared++;
            break;
          case 'Delivery':
            delivering++;
            break;
          case 'Delivered':
            delivered++;
            break;
        }
      }

      if (mounted) {
        setState(() {
          pendingCount = pending;
          preparingCount = preparing;
          preparedCount = prepared;
          deliveringCount = delivering;
          deliveredCount = delivered;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      // Handle error silently or show snackbar if needed
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _cardH,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _StepCard(
              title: 'Pending',
              icon: FontAwesomeIcons.clipboardList,
              count: isLoading ? 0 : pendingCount,
              isLoading: isLoading,
              onTap: () => _navigateToOrdersWithFilter(context, [
                'Received',
                'Sended to manager',
                'Updated to Accountant',
              ]),
            ),
            _ArrowSpacer(width: _arrowW),
            _StepCard(
              title: 'Preparing',
              icon: FontAwesomeIcons.boxOpen,
              count: isLoading ? 0 : preparingCount,
              isLoading: isLoading,
              onTap: () => _navigateToOrdersWithFilter(context, ['Preparing']),
            ),
            _ArrowSpacer(width: _arrowW),
            _StepCard(
              title: 'Prepared',
              icon: FontAwesomeIcons.clipboardCheck,
              count: isLoading ? 0 : preparedCount,
              isLoading: isLoading,
              onTap: () => _navigateToOrdersWithFilter(context, ['Prepared']),
            ),
            _ArrowSpacer(width: _arrowW),
            _StepCard(
              title: 'Delivering',
              icon: FontAwesomeIcons.truck,
              count: isLoading ? 0 : deliveringCount,
              isLoading: isLoading,
              onTap: () => _navigateToOrdersWithFilter(context, ['Delivery']),
            ),
            _ArrowSpacer(width: _arrowW),
            _StepCard(
              title: 'Delivered',
              icon: FontAwesomeIcons.box,
              count: isLoading ? 0 : deliveredCount,
              isLoading: isLoading,
              onTap: () => _navigateToOrdersWithFilter(context, ['Delivered']),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToOrdersWithFilter(
    BuildContext context,
    List<String> statuses,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrdersPage(initialFilterStatuses: statuses),
      ),
    );
  }
}

class _ArrowSpacer extends StatelessWidget {
  final double width;
  const _ArrowSpacer({required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: _cardH,
      child: const Center(
        child: Icon(
          Icons.arrow_forward_ios_rounded,
          color: Color(0xFF50B2E7),
          size: 20,
        ),
      ),
    );
  }
}

class _StepCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final int count;
  final bool isLoading;
  final VoidCallback? onTap;
  const _StepCard({
    required this.title,
    required this.icon,
    required this.count,
    required this.isLoading,
    this.onTap,
  });

  @override
  State<_StepCard> createState() => _StepCardState();
}

class _StepCardState extends State<_StepCard> {
  bool _hovered = false;

  static const _radius = 18.0;
  static const _anim = Duration(milliseconds: 180);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _cardW,
      height: _cardH,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedScale(
          duration: _anim,
          scale: _hovered ? 1.02 : 1.0,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(_radius),
            child: AnimatedContainer(
              duration: _anim,
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D),
                borderRadius: BorderRadius.circular(_radius),
                boxShadow: [
                  const BoxShadow(
                    color: Colors.black45,
                    offset: Offset(0, 6),
                    blurRadius: 10,
                  ),
                  if (_hovered)
                    BoxShadow(
                      color: gold.withValues(alpha: 0.55),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(widget.icon, size: 26, color: Colors.amberAccent),
                  const SizedBox(height: 6),
                  widget.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.amberAccent,
                            ),
                          ),
                        )
                      : Text(
                          widget.count.toString(),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                  const Text('Order', style: TextStyle(color: Colors.grey)),
                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: Color(0xFFB7A447),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                             MAIN CONTENT AREA                              */
/* -------------------------------------------------------------------------- */
class _MainContent extends StatelessWidget {
  const _MainContent();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final breakpoint = 1000; // Width below which cards stack

        if (width >= breakpoint) {
          // Wide screen - side by side with original proportions
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  width: 350,
                  height: 640,
                  child: _ActiveWorkersCard(),
                ),
                const SizedBox(width: 32),
                const Expanded(
                  child: SizedBox(height: 640, child: _OrdersCard()),
                ),
              ],
            ),
          );
        } else {
          // Narrow screen - stack vertically
          return const SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 400, child: _ActiveWorkersCard()),
                SizedBox(height: 24),
                SizedBox(height: 640, child: _OrdersCard()),
              ],
            ),
          );
        }
      },
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                            ACTIVE WORKERS TABLE                            */
/* -------------------------------------------------------------------------- */
class _ActiveWorkersCard extends StatelessWidget {
  const _ActiveWorkersCard();

  @override
  Widget build(BuildContext context) {
    final workers = <(String, int, String)>[
      ('Ayman', 1, 'assets/images/ayman.jpg'),
      ('Ramadan', 2, 'assets/images/ramadan.jpg'),
      ('Rami', 1, 'assets/images/rami.jpg'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            offset: Offset(0, 6),
            blurRadius: 10,
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Active',
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(
              color: const Color(0xFFB7A447),
              fontSize: 40,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            'worker account',
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(
              color: const Color(0xFFB7A447),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.separated(
              itemCount: workers.length,
              separatorBuilder: (_, __) => const Divider(
                color: Colors.white24,
                thickness: 1,
                height: 16,
              ),
              itemBuilder: (_, i) {
                final w = workers[i];
                return Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundImage: AssetImage(w.$3),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.greenAccent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.black,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        w.$1,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Text(
                      '${w.$2}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                              RECEIVES ORDERS CARD                           */
/* -------------------------------------------------------------------------- */
class _OrdersCard extends StatefulWidget {
  const _OrdersCard();

  @override
  State<_OrdersCard> createState() => _OrdersCardState();
}

class _OrdersCardState extends State<_OrdersCard> {
  static const double _leadIconSpace = 30;

  List<Map<String, dynamic>> receivesOrders = [];
  bool isLoading = true;
  String? error;
  // Hover state tracking (match other pages animation)
  int? hoveredRow;

  @override
  void initState() {
    super.initState();
    _fetchReceivesOrders();
  }

  Future<void> _fetchReceivesOrders() async {
    try {
      if (!mounted) return;
      setState(() => isLoading = true);

      // Fetch customer orders (stock-out receives)
      final customerOrdersResponse = await supabase
          .from('customer_order')
          .select(
            'customer_order_id, order_status, order_date, last_action_by, customer:customer_id(name)',
          )
          .inFilter('order_status', ['Received', 'Updated to Accountant'])
          .order('customer_order_id', ascending: false);

      // Fetch supplier orders (stock-in receives): include Pending and Updated
      // so we can show both in (NEW) and in (UPDATE) receives.
      final supplierOrdersResponse = await supabase
          .from('supplier_order')
          .select('''
            order_id,
            supplier_id,
            order_date,
            order_status,
            created_by_id,
            supplier:supplier_id (
              name
            )
          ''')
          .inFilter('order_status', ['Pending', 'Updated'])
          .order('order_date', ascending: false);

      final List<Map<String, dynamic>> allOrders = [];

      // Process customer orders
      for (final order in customerOrdersResponse) {
        final orderDate = DateTime.parse(order['order_date']);
        final time =
            '${orderDate.hour}:${orderDate.minute.toString().padLeft(2, '0')}';
        final date = '${orderDate.day}/${orderDate.month}';

        String type = 'out (NEW)';
        if (order['order_status'] == 'Updated to Accountant') {
          type = 'out (UPDATE)';
        }

        allOrders.add({
          'id': order['customer_order_id'].toString(),
          'name': (order['customer'] is Map)
              ? (order['customer']['name'] ?? 'Unknown')
              : 'Unknown',
          'type': type,
          'createdBy': order['last_action_by'] ?? 'System',
          'time': time,
          'date': date,
          'orderType': 'customer',
          'orderDate': orderDate,
        });
      }

      // Resolve manager creators for supplier orders
      final supplierOrders = (supplierOrdersResponse as List)
          .cast<Map<String, dynamic>>();
      final Set<int> creatorIds = supplierOrders
          .map((o) => o['created_by_id'])
          .whereType<int>()
          .toSet();

      final Map<int, String> managerNames = {};
      final Map<int, String> accountantNames = {};
      final Set<int> managerIds = {};
      final Set<int> accountantIds = {};

      if (creatorIds.isNotEmpty) {
        // Resolve storage managers
        final managerConditions = creatorIds
            .map((id) => 'storage_manager_id.eq.$id')
            .join(',');
        final managers = await supabase
            .from('storage_manager')
            .select('storage_manager_id, name')
            .or(managerConditions);
        for (final m in managers) {
          final id = m['storage_manager_id'] as int?;
          if (id != null) {
            managerIds.add(id);
            managerNames[id] = m['name']?.toString() ?? 'Manager';
          }
        }

        // Resolve accountants (some created_by_id values may refer to accountants)
        final accountantConditions = creatorIds
            .map((id) => 'accountant_id.eq.$id')
            .join(',');
        final accountants = await supabase
            .from('accountant')
            .select('accountant_id, name')
            .or(accountantConditions);
        for (final a in accountants) {
          final id = a['accountant_id'] as int?;
          if (id != null) {
            accountantIds.add(id);
            accountantNames[id] = a['name']?.toString() ?? 'Accountant';
          }
        }
      }

      // Process supplier orders: include manager-created Pending/Updated
      // If creator lookup fails, still include the order and fall back to
      // `last_tracing_by` or a generic label so "in" rows are visible.
      for (final order in supplierOrders) {
        final creatorId = order['created_by_id'] as int?;

        final orderDate = DateTime.parse(order['order_date']);
        final time =
            '${orderDate.hour}:${orderDate.minute.toString().padLeft(2, '0')}';
        final date = '${orderDate.day}/${orderDate.month}';

        // Determine in type based on status
        String type = 'in (NEW)';
        if (order['order_status'] == 'Updated') {
          type = 'in (UPDATE)';
        }

        // Resolve creator display name, preferring manager then accountant,
        // falling back to `last_tracing_by` or a generic label.
        String createdBy = 'System';
        if (creatorId != null) {
          if (managerNames.containsKey(creatorId)) {
            createdBy = '${managerNames[creatorId]}';
          } else if (accountantNames.containsKey(creatorId)) {
            createdBy = '${accountantNames[creatorId]}';
          } else if (order['last_tracing_by'] != null) {
            createdBy = order['last_tracing_by']?.toString() ?? 'System';
          }
        } else if (order['last_tracing_by'] != null) {
          createdBy = order['last_tracing_by']?.toString() ?? 'System';
        }

        allOrders.add({
          'id': order['order_id'].toString(),
          'name': order['supplier']?['name'] ?? 'Unknown',
          'type': type,
          'createdBy': createdBy,
          'time': time,
          'date': date,
          'orderType': 'supplier',
          'orderDate': orderDate,
        });
      }

      // Sort by order date (most recent first)
      allOrders.sort(
        (a, b) =>
            (b['orderDate'] as DateTime).compareTo(a['orderDate'] as DateTime),
      );

      if (!mounted) return;
      setState(() {
        receivesOrders = allOrders;
        isLoading = false;
        error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            offset: Offset(0, 6),
            blurRadius: 10,
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Receives Order',
            style: GoogleFonts.roboto(
              color: const Color(0xFFB7A447),
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 14),
          _tableHeader(),
          const SizedBox(height: 8),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                ? Center(
                    child: Text(
                      'Error: $error',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  )
                : receivesOrders.isEmpty
                ? const Center(
                    child: Text(
                      'No receives orders found',
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                : ListView.builder(
                    itemCount: receivesOrders.length,
                    itemBuilder: (context, i) {
                      final isHovered = hoveredRow == i;
                      return MouseRegion(
                        onEnter: (_) => setState(() => hoveredRow = i),
                        onExit: (_) => setState(() => hoveredRow = null),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _orderRow(
                            context,
                            receivesOrders[i],
                            isHovered,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _tableHeader() {
    final hStyle = GoogleFonts.roboto(
      color: Colors.grey.shade300,
      fontWeight: FontWeight.w600,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: Row(
            children: [
              const SizedBox(width: _leadIconSpace),
              Expanded(flex: 3, child: Text('Sender', style: hStyle)),
              Expanded(flex: 2, child: Text('Type', style: hStyle)),
              Expanded(flex: 2, child: Text('Created by', style: hStyle)),
              Expanded(
                flex: 1,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text('Time', style: hStyle),
                ),
              ),
              Expanded(
                flex: 1,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text('Date', style: hStyle),
                ),
              ),
            ],
          ),
        ),
        const Divider(color: Colors.white24, thickness: 1, height: 0),
      ],
    );
  }

  Widget _orderRow(
    BuildContext context,
    Map<String, dynamic> order,
    bool isHovered,
  ) {
    final typeColor = order['type'].startsWith('in') ? blue : gold;

    return InkWell(
      onTap: () async {
        // Fetch order details based on order type
        List<Map<String, dynamic>> products = [];
        String orderType = order['orderType'];
        String status = 'NEW';

        if (order['type'].contains('UPDATE')) {
          status = 'UPDATE';
        }

        try {
          if (orderType == 'customer') {
            // Fetch customer order details
            final orderDetails = await supabase
                .from('customer_order')
                .select(
                  'order_date, tax_percent, total_balance, discount_value, update_description, customer:customer_id(name, address, customer_city:customer_city(name))',
                )
                .eq('customer_order_id', int.parse(order['id']))
                .maybeSingle();

            if (orderDetails != null) {
              final items = await supabase
                  .from('customer_order_description')
                  .select(
                    'product_id, quantity, updated_quantity, total_price, product:product_id(name, selling_price, brand:brand_id(name), unit:unit_id(unit_name))',
                  )
                  .eq('customer_order_id', int.parse(order['id']));

              for (final item in items) {
                final product = item['product'] as Map<String, dynamic>?;
                final brand = product?['brand'] as Map<String, dynamic>?;
                final unit = product?['unit'] as Map<String, dynamic>?;
                final quantity = (item['quantity'] ?? 0) as num;
                final updatedQuantity = item['updated_quantity'] as num?;
                final total = (item['total_price'] ?? 0) as num;
                final price = (product?['selling_price'] ?? 0) as num;

                // For UPDATE status, use updated_quantity if available, otherwise use original quantity
                final effectiveQuantity = updatedQuantity ?? quantity;

                products.add({
                  'id': item['product_id']?.toString() ?? '-',
                  'name': product?['name'] ?? 'Unknown',
                  'brand': brand?['name'] ?? '-',
                  'price': price == 0 ? '-' : '${price.toStringAsFixed(2)}\$',
                  'quantity': effectiveQuantity,
                  'updated_quantity': updatedQuantity,
                  'original_quantity': quantity,
                  'total': price * effectiveQuantity == 0
                      ? '-'
                      : '${(price * effectiveQuantity).toStringAsFixed(2)}\$',
                  'unit_name': unit?['unit_name'] ?? 'pcs',
                });
              }

              if (!context.mounted) return;

              OrderDetailPopup.show(
                context,
                orderType: 'out',
                status: status,
                products: products,
                partyName: orderDetails['customer']?['name'] ?? 'Unknown',
                location: _composeLocation(
                  orderDetails['customer']?['customer_city']?['name'],
                  orderDetails['customer']?['address'],
                ),
                orderDate: DateTime.parse(orderDetails['order_date']),
                taxPercent: orderDetails['tax_percent'] as num?,
                totalPrice: orderDetails['total_balance'] as num?,
                discountValue: (orderDetails['discount_value'] ?? 0) as num,
                updateDescription:
                    orderDetails['update_description'] as String?,
                orderId: int.parse(order['id']),
                onOrderUpdated: _fetchReceivesOrders,
              );
            }
          } else {
            // Fetch supplier order details
            final orderDetails = await supabase
                .from('supplier_order')
                .select(
                  'order_date, updated_description, supplier:supplier_id(name)',
                )
                .eq('order_id', int.parse(order['id']))
                .maybeSingle();

            if (orderDetails != null) {
              final items = await supabase
                  .from('supplier_order_description')
                  .select(
                    'product_id, quantity, price_per_product, updated_quantity, product:product_id(name, brand:brand_id(name), unit:unit_id(unit_name))',
                  )
                  .eq('order_id', int.parse(order['id']));

              for (final item in items) {
                final product = item['product'] as Map<String, dynamic>?;
                final brand = product?['brand'] as Map<String, dynamic>?;
                final unit = product?['unit'] as Map<String, dynamic>?;
                final quantity = (item['quantity'] ?? 0) as num;
                final price = (item['price_per_product'] ?? 0) as num;

                products.add({
                  'id': item['product_id']?.toString() ?? '-',
                  'name': product?['name'] ?? 'Unknown',
                  'brand': brand?['name'] ?? '-',
                  'price': price == 0 ? '-' : '${price.toStringAsFixed(2)}\$',
                  'quantity': quantity,
                  'updated_quantity': item['updated_quantity'],
                  'original_quantity': quantity,
                  'total': (price * quantity) == 0
                      ? '-'
                      : '${(price * quantity).toStringAsFixed(2)}\$',
                  'unit_name': unit?['unit_name'] ?? 'pcs',
                });
              }

              if (!context.mounted) return;

              OrderDetailPopup.show(
                context,
                orderType: 'in',
                status: status,
                products: products,
                partyName: orderDetails['supplier']?['name'] ?? 'Unknown',
                orderDate: DateTime.parse(orderDetails['order_date']),
                orderId: int.parse(order['id']),
                updateDescription:
                    orderDetails['updated_description'] as String?,
              );
            }
          }
        } catch (e) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load order details: $e'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: const Color(0xFF252525),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isHovered ? blue : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              offset: Offset(0, 4),
              blurRadius: 8,
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        child: Row(
          children: [
            const Icon(Icons.person, color: Colors.white54, size: 22),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: Text(
                order['name'],
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                order['type'],
                style: TextStyle(fontWeight: FontWeight.bold, color: typeColor),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                order['createdBy'],
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  order['time'],
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  order['date'],
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _composeLocation(String? city, String? address) {
    if ((city == null || city.isEmpty) &&
        (address == null || address.isEmpty)) {
      return '-';
    }
    if (city != null &&
        city.isNotEmpty &&
        address != null &&
        address.isNotEmpty) {
      return '$city - $address';
    }
    return city?.isNotEmpty == true ? city! : address ?? '-';
  }
}
