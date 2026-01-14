import 'package:flutter/material.dart';
import 'report_page.dart';
import '../../supabase_config.dart';
import '../Orders/Orders_stock_out_previous_popup.dart' as orders;
import '../Payment/Payment_archive_page.dart' as payment_archive;
import 'report_customer_generate_dialog.dart';

// ============================================================================
// 🔹 Customer Detail Dialog (Popup)
// ============================================================================

class CustomerDetailDialog extends StatefulWidget {
  final String customerId;
  final String customerName;
  final String mobile;
  final String location;
  final String balanceDebit;

  const CustomerDetailDialog({
    super.key,
    required this.customerId,
    required this.customerName,
    required this.mobile,
    required this.location,
    required this.balanceDebit,
  });

  @override
  State<CustomerDetailDialog> createState() => _CustomerDetailDialogState();
}

class _CustomerDetailDialogState extends State<CustomerDetailDialog> {
  String selectedTab = 'Statistics';
  String selectedSubTab = 'Orders'; // 'Orders' or 'Payments'

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 1200;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isWide ? 1400 : width - 40,
            maxHeight: MediaQuery.of(context).size.height - 100,
          ),
          decoration: BoxDecoration(
            color: AppColors.dark,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              // 🔹 Header with title and tabs
              Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 8, 8),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.customerName,
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _InfoChip(
                                    label: 'ID',
                                    value: widget.customerId,
                                  ),
                                  const SizedBox(width: 12),
                                  _InfoChip(
                                    label: 'Mobile',
                                    value: widget.mobile,
                                  ),
                                  const SizedBox(width: 12),
                                  _InfoChip(
                                    label: 'Location',
                                    value: widget.location,
                                  ),
                                  const SizedBox(width: 12),
                                  _InfoChip(
                                    label: 'Balance Debit',
                                    value: '\$${widget.balanceDebit}',
                                    isBlue: true,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Generate Report button
                        ElevatedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              barrierColor: Colors.black.withOpacity(0.7),
                              builder: (_) => GenerateCustomerReportDialog(
                                customerId: widget.customerId,
                                customerName: widget.customerName,
                              ),
                            );
                          },
                          icon: const Icon(Icons.picture_as_pdf, size: 18),
                          label: const Text('Generate Report'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // 🔹 Tabs
                    Row(
                      children: [
                        _TabButton(
                          label: 'Statistics',
                          isActive: selectedTab == 'Statistics',
                          onTap: () =>
                              setState(() => selectedTab = 'Statistics'),
                        ),
                        const SizedBox(width: 30),
                        _TabButton(
                          label: 'Archive',
                          isActive: selectedTab == 'Archive',
                          onTap: () => setState(() => selectedTab = 'Archive'),
                        ),
                        if (selectedTab == 'Archive') ...[
                          const SizedBox(width: 30),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.cardAlt,
                              borderRadius: BorderRadius.circular(40),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: () => setState(
                                      () => selectedSubTab = 'Orders',
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: selectedSubTab == 'Orders'
                                            ? Colors.black.withOpacity(0.6)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      child: Text(
                                        'Orders',
                                        style: TextStyle(
                                          color: selectedSubTab == 'Orders'
                                              ? AppColors.blue
                                              : AppColors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: () => setState(
                                      () => selectedSubTab = 'Payments',
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: selectedSubTab == 'Payments'
                                            ? Colors.black.withOpacity(0.6)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      child: Text(
                                        'Payments',
                                        style: TextStyle(
                                          color: selectedSubTab == 'Payments'
                                              ? AppColors.blue
                                              : AppColors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              // 🔹 Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
                  child: selectedTab == 'Statistics'
                      ? _StatisticsContent(customerId: widget.customerId)
                      : _ArchiveContent(
                          customerId: widget.customerId,
                          selectedSubTab: selectedSubTab,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 🔹 Info Chip
class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final bool isBlue;

  const _InfoChip({
    required this.label,
    required this.value,
    this.isBlue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cardAlt,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: AppColors.grey,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isBlue ? AppColors.blue : AppColors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// 🔹 Tab Button
class _TabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? AppColors.blue : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? AppColors.white : AppColors.grey,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 🔹 STATISTICS TAB
// ============================================================================

class _StatisticsContent extends StatefulWidget {
  final String customerId;
  const _StatisticsContent({required this.customerId});

  @override
  State<_StatisticsContent> createState() => _StatisticsContentState();
}

class _StatisticsContentState extends State<_StatisticsContent> {
  bool _loading = true;
  int _totalOrders = 0;
  double _totalSpent = 0;
  int _returnedChecks = 0;
  String _firstOrderDate = '—';
  String _lastOrderDate = '—';
  List<Map<String, dynamic>> _topProducts = [];
  List<double> _monthlySpending = List.filled(12, 0);

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    try {
      final customerId = int.parse(widget.customerId);

      // Fetch all delivered orders for this customer
      final orders = await supabase
          .from('customer_order')
          .select('customer_order_id, order_date, total_balance')
          .eq('customer_id', customerId)
          .eq('order_status', 'Delivered')
          .order('order_date');

      _totalOrders = orders.length;
      _totalSpent = 0;

      if (orders.isNotEmpty) {
        // Calculate total spent
        for (final order in orders) {
          final balance = (order['total_balance'] as num?)?.toDouble() ?? 0;
          _totalSpent += balance;
        }

        // First and last order dates
        final firstDate = DateTime.parse(orders.first['order_date']);
        final lastDate = DateTime.parse(orders.last['order_date']);
        _firstOrderDate =
            '${firstDate.month}/${firstDate.day}/${firstDate.year}';
        _lastOrderDate = '${lastDate.month}/${lastDate.day}/${lastDate.year}';

        // Monthly spending for current year
        final currentYear = DateTime.now().year;
        final monthlySpending = List.filled(12, 0.0);
        for (final order in orders) {
          final date = DateTime.parse(order['order_date']);
          if (date.year == currentYear) {
            final monthIndex = date.month - 1;
            final balance = (order['total_balance'] as num?)?.toDouble() ?? 0;
            monthlySpending[monthIndex] += balance;
          }
        }
        _monthlySpending = monthlySpending;
      }

      // Fetch returned checks count
      final returnedChecks = await supabase
          .from('customer_checks')
          .select('check_id')
          .eq('customer_id', customerId)
          .eq('status', 'Returned');
      _returnedChecks = returnedChecks.length;

      // Fetch top products
      final orderItems = await supabase
          .from('customer_order_description')
          .select('''
            product_id,
            quantity,
            product:product_id(name),
            customer_order:customer_order_id(order_status)
          ''')
          .eq('customer_order.customer_id', customerId);

      // Group by product
      final Map<int, Map<String, dynamic>> productStats = {};
      for (final item in orderItems) {
        // Only count delivered orders
        if (item['customer_order'] is Map) {
          final status = item['customer_order']['order_status']?.toString();
          if (status != 'Delivered') continue;
        }

        final productId = item['product_id'] as int?;
        if (productId == null) continue;

        final quantity = (item['quantity'] as num?)?.toInt() ?? 0;
        final productName = (item['product'] is Map)
            ? (item['product']['name']?.toString() ?? 'Unknown')
            : 'Unknown';

        if (!productStats.containsKey(productId)) {
          productStats[productId] = {
            'product_name': productName,
            'total_quantity': 0,
          };
        }

        productStats[productId]!['total_quantity'] =
            (productStats[productId]!['total_quantity'] as int) + quantity;
      }

      // Sort by quantity and take top 5
      final sortedProducts = productStats.values.toList()
        ..sort(
          (a, b) => (b['total_quantity'] as int).compareTo(
            a['total_quantity'] as int,
          ),
        );

      _topProducts = sortedProducts.take(5).toList();

      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    } catch (e) {
      print('Error loading customer statistics: $e');
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: AppColors.blue),
        ),
      );
    }

    final width = MediaQuery.of(context).size.width;
    final isWide = width > 1200;

    return isWide ? _buildWideLayout() : _buildNarrowLayout();
  }

  Widget _buildWideLayout() {
    return Column(
      children: [
        // Top row: Key metrics with Returned Checks spanning two rows
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Expanded(
                      child: _MetricCard(
                        title: 'Total Orders',
                        value: _totalOrders.toString(),
                        icon: Icons.shopping_cart_outlined,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Expanded(
                      child: _MetricCard(
                        title: 'First Order',
                        value: _firstOrderDate,
                        icon: Icons.calendar_today,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Expanded(
                      child: _MetricCard(
                        title: 'Total Spent',
                        value: '\$${_totalSpent.toStringAsFixed(2)}',
                        icon: Icons.attach_money,
                        isBlue: true,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Expanded(
                      child: _MetricCard(
                        title: 'Last Order',
                        value: _lastOrderDate,
                        icon: Icons.event,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: _TallMetricCard(
                  title: 'Returned Checks',
                  value: _returnedChecks.toString(),
                  icon: Icons.assignment_return,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        // Bottom row: Top products and spending chart
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _SectionCard(
                title: 'Top 5 Products Purchased',
                child: _TopProductsTable(products: _topProducts),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              flex: 3,
              child: _SectionCard(
                title: '',
                hideTitle: true,
                child: _SpendingChart(customerId: widget.customerId),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    return Column(
      children: [
        _MetricCard(
          title: 'Total Orders',
          value: _totalOrders.toString(),
          icon: Icons.shopping_cart_outlined,
        ),
        const SizedBox(height: 12),
        _MetricCard(
          title: 'Total Spent',
          value: '\$${_totalSpent.toStringAsFixed(2)}',
          icon: Icons.attach_money,
          isBlue: true,
        ),
        const SizedBox(height: 12),
        _MetricCard(
          title: 'Returned Checks',
          value: _returnedChecks.toString(),
          icon: Icons.assignment_return,
        ),
        const SizedBox(height: 12),
        _MetricCard(
          title: 'First Order',
          value: _firstOrderDate,
          icon: Icons.calendar_today,
        ),
        const SizedBox(height: 12),
        _MetricCard(
          title: 'Last Order',
          value: _lastOrderDate,
          icon: Icons.event,
        ),
        const SizedBox(height: 18),
        _SectionCard(
          title: 'Top 5 Products Purchased',
          child: _TopProductsTable(products: _topProducts),
        ),
        const SizedBox(height: 18),
        _SectionCard(
          title: '',
          hideTitle: true,
          child: _SpendingChart(customerId: widget.customerId),
        ),
      ],
    );
  }
}

// 🔹 Metric Card
class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final bool isBlue;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    this.isBlue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isBlue
                  ? AppColors.blue.withOpacity(0.2)
                  : AppColors.cardAlt,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isBlue ? AppColors.blue : AppColors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.grey,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: isBlue ? AppColors.blue : AppColors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 🔹 Tall Metric Card (Spans Two Rows)
class _TallMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _TallMetricCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.red, size: 48),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.grey,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

// 🔹 Section Card
class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final bool hideTitle;

  const _SectionCard({
    required this.title,
    required this.child,
    this.hideTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!hideTitle) ...[
            Text(
              title,
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}

// 🔹 Top Products Table
class _TopProductsTable extends StatelessWidget {
  final List<Map<String, dynamic>> products;
  const _TopProductsTable({required this.products});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'No products purchased yet',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return Column(
      children: [
        // Header
        Row(
          children: const [
            Expanded(
              flex: 3,
              child: Text(
                'Product Name',
                style: TextStyle(
                  color: AppColors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Quantity',
                  style: TextStyle(
                    color: AppColors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(height: 1, color: Colors.white.withOpacity(0.2)),
        const SizedBox(height: 8),
        // Rows
        ...products.asMap().entries.map((entry) {
          final index = entry.key;
          final product = entry.value;
          final bg = index.isEven ? AppColors.dark : AppColors.cardAlt;

          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    product['product_name']?.toString() ?? 'Unknown',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      product['total_quantity']?.toString() ?? '0',
                      style: const TextStyle(
                        color: AppColors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// 🔹 Spending Chart
class _SpendingChart extends StatefulWidget {
  final String customerId;
  const _SpendingChart({required this.customerId});

  @override
  State<_SpendingChart> createState() => _SpendingChartState();
}

class _SpendingChartState extends State<_SpendingChart>
    with SingleTickerProviderStateMixin {
  int? _hoveredIndex;
  late final AnimationController _controller;
  late final Animation<double> _animation;
  String selectedYear = DateTime.now().year.toString();
  List<double> monthlySpending = List.filled(12, 0);
  bool _loading = true;

  final months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _loadSpendingData();
  }

  Future<void> _loadSpendingData() async {
    try {
      final customerId = int.parse(widget.customerId);

      // Fetch all delivered orders for this customer in selected year
      final orders = await supabase
          .from('customer_order')
          .select('customer_order_id, order_date, total_balance')
          .eq('customer_id', customerId)
          .eq('order_status', 'Delivered')
          .order('order_date');

      final spending = List.filled(12, 0.0);

      for (final order in orders) {
        final date = DateTime.parse(order['order_date']);
        if (date.year.toString() == selectedYear) {
          final monthIndex = date.month - 1;
          final balance = (order['total_balance'] as num?)?.toDouble() ?? 0;
          spending[monthIndex] += balance;
        }
      }

      if (mounted) {
        setState(() {
          monthlySpending = spending;
          _loading = false;
        });
        _controller.forward(from: 0);
      }
    } catch (e) {
      print('Error loading spending data: $e');
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final maxData = monthlySpending.isEmpty
        ? 0.0
        : monthlySpending.reduce((a, b) => a > b ? a : b);
    final maxY = maxData <= 0 ? 20.0 : ((maxData / 5).ceil() * 5).toDouble();

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final anim = _animation.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + Year selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Monthly Spending',
                  style: TextStyle(
                    color: AppColors.blue,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                Container(
                  height: 35,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 26,
                    vertical: 0,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 6,
                        offset: const Offset(1, 2),
                      ),
                    ],
                  ),
                  child: DropdownButton<String>(
                    value: selectedYear,
                    dropdownColor: AppColors.card,
                    underline: const SizedBox(),
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: AppColors.white,
                      size: 16,
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    items:
                        List.generate(
                              DateTime.now().year - 2022 + 1,
                              (index) => (2022 + index).toString(),
                            )
                            .map(
                              (year) => DropdownMenuItem(
                                value: year,
                                child: Center(child: Text(year)),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedYear = value;
                          _loading = true;
                        });
                        _loadSpendingData();
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // الرسم
            SizedBox(
              height: 280,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // GRID الخلفي
                  Positioned.fill(
                    child: Column(
                      children: List.generate(5, (index) {
                        return Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: Colors.white.withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  // المحاور + الأعمدة
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // محور Y (0 – maxY)
                      SizedBox(
                        width: 40,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(5, (index) {
                            final step = maxY / (5 - 1);
                            final value = index * step;
                            String label;
                            if (value == 0) {
                              label = '0';
                            } else if (value >= 1000) {
                              label =
                                  '${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)}K';
                            } else {
                              label = value.toStringAsFixed(0);
                            }
                            return Text(
                              label,
                              style: const TextStyle(
                                color: AppColors.grey,
                                fontSize: 10,
                              ),
                            );
                          }).reversed.toList(),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // الأعمدة + أسماء الشهور
                      Expanded(
                        child: Column(
                          children: [
                            // الأعمدة نفسها
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: List.generate(months.length, (index) {
                                  final v = monthlySpending[index].toDouble();
                                  final targetHeight = (v / maxY) * 180;

                                  // ارتفاع الأساس مع الأنيميشن (من 0 → القيمة)
                                  final baseHeight =
                                      targetHeight * anim.clamp(0, 1);

                                  final bool isHovered = _hoveredIndex == index;

                                  final double barHeight = isHovered
                                      ? baseHeight + 12
                                      : baseHeight;
                                  final double barWidth = isHovered ? 32 : 28;
                                  final double opacity = isHovered ? 1.0 : 0.85;

                                  return MouseRegion(
                                    onEnter: (_) =>
                                        setState(() => _hoveredIndex = index),
                                    onExit: (_) =>
                                        setState(() => _hoveredIndex = null),
                                    child: Tooltip(
                                      message:
                                          '${monthlySpending[index].toStringAsFixed(2)} - ${months[index]}',
                                      waitDuration: const Duration(
                                        milliseconds: 150,
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          // Spending label ABOVE the bar
                                          Opacity(
                                            opacity: anim,
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 6,
                                              ),
                                              child: Text(
                                                '\$ ${monthlySpending[index].toInt()} ',
                                                style: TextStyle(
                                                  color: isHovered
                                                      ? AppColors.white
                                                      : AppColors.white
                                                            .withOpacity(0.9),
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                          // The bar itself
                                          AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 250,
                                            ),
                                            curve: Curves.easeOutCubic,
                                            width: barWidth,
                                            height: barHeight,
                                            decoration: BoxDecoration(
                                              color: AppColors.blue.withOpacity(
                                                opacity,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                              boxShadow:
                                                  isHovered && barHeight > 0
                                                  ? [
                                                      BoxShadow(
                                                        color: AppColors.blue
                                                            .withOpacity(0.4),
                                                        blurRadius: 10,
                                                        spreadRadius: 1,
                                                        offset: const Offset(
                                                          0,
                                                          2,
                                                        ),
                                                      ),
                                                    ]
                                                  : [],
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          // Month label under the bar
                                          Text(
                                            months[index],
                                            style: const TextStyle(
                                              color: AppColors.grey,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1;

    for (int i = 0; i <= 5; i++) {
      final y = (size.height / 5) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================================
// 🔹 ARCHIVE TAB
// ============================================================================

class _ArchiveContent extends StatefulWidget {
  final String customerId;
  final String selectedSubTab;
  const _ArchiveContent({
    required this.customerId,
    required this.selectedSubTab,
  });

  @override
  State<_ArchiveContent> createState() => _ArchiveContentState();
}

class _ArchiveContentState extends State<_ArchiveContent> {
  List<List<String>> _rows = [];
  List<List<String>> _filteredRows = [];
  List<List<String>> _paymentRows = [];
  List<List<String>> _filteredPaymentRows = [];
  List<Map<String, dynamic>> _paymentData = []; // Store full payment data
  List<Map<String, dynamic>> _filteredPaymentData = [];
  bool _loading = true;
  final TextEditingController _searchController = TextEditingController();

  // Filter variables
  final Set<String> _selectedStatuses = {}; // 'Pending', 'Delivered', etc.
  DateTime? _fromDate;
  DateTime? _toDate;
  final GlobalKey _filterButtonKey = GlobalKey();
  OverlayEntry? _filterOverlay;
  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadArchiveRows();
    _loadPaymentRows();
    _searchController.addListener(_filterRows);
  }

  @override
  void dispose() {
    _filterOverlay?.remove();
    _filterOverlay = null;
    _searchController.removeListener(_filterRows);
    _searchController.dispose();
    _fromDateController.dispose();
    _toDateController.dispose();
    super.dispose();
  }

  Future<void> _loadArchiveRows() async {
    try {
      final customerId = int.parse(widget.customerId);
      final rows = <List<String>>[];

      // Fetch all delivered orders for this customer
      final orders = await supabase
          .from('customer_order')
          .select('customer_order_id, order_date, total_cost, order_status')
          .eq('customer_id', customerId)
          .eq('order_status', 'Delivered')
          .order('order_date', ascending: false);

      for (final order in orders) {
        final orderId = order['customer_order_id']?.toString() ?? '';
        final rawDate = order['order_date'];
        String orderDateStr = '';
        if (rawDate is String && rawDate.isNotEmpty) {
          try {
            final dt = DateTime.parse(rawDate);
            orderDateStr = '${dt.month}/${dt.day}/${dt.year}';
          } catch (_) {
            orderDateStr = rawDate;
          }
        }

        final totalCost = (order['total_cost'] as num?)?.toDouble() ?? 0;
        final status = order['order_status']?.toString() ?? 'Unknown';

        // Get number of items in this order
        final items = await supabase
            .from('customer_order_description')
            .select('product_id')
            .eq('customer_order_id', orderId);

        final itemCount = items.length.toString();

        rows.add([
          orderId,
          orderDateStr,
          itemCount,
          '\$${totalCost.toStringAsFixed(2)}',
          status,
        ]);
      }

      if (mounted) {
        setState(() {
          _rows = rows;
          _filteredRows = rows;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
      print('Error loading customer archive: $e');
    }
  }

  Future<void> _loadPaymentRows() async {
    try {
      final customerId = int.parse(widget.customerId);
      final rows = <List<String>>[];
      final paymentDataList = <Map<String, dynamic>>[];

      // Fetch incoming payments (cash and checks)
      final payments = await supabase
          .from('incoming_payment')
          .select('''
            payment_id,
            date_time,
            amount,
            payment_method,
            description,
            customer_checks:check_id(
              check_id,
              exchange_rate,
              exchange_date,
              status
            )
          ''')
          .eq('customer_id', customerId)
          .order('date_time', ascending: false);

      for (final payment in payments) {
        final paymentId = payment['payment_id']?.toString() ?? '';
        final rawDate = payment['date_time'];
        String dateStr = '';
        if (rawDate is String && rawDate.isNotEmpty) {
          try {
            final dt = DateTime.parse(rawDate);
            dateStr = '${dt.month}/${dt.day}/${dt.year}';
          } catch (_) {
            dateStr = rawDate;
          }
        }

        final amount = (payment['amount'] as num?)?.toDouble() ?? 0;
        final method = payment['payment_method']?.toString() ?? 'Unknown';
        final description = payment['description']?.toString() ?? '';

        String displayMethod = method;
        if (method.toLowerCase() == 'check' &&
            payment['customer_checks'] is Map) {
          final checkData = payment['customer_checks'] as Map;
          final status = checkData['status']?.toString() ?? '';
          if (status == 'Returned') {
            displayMethod = 'Returned Check';
          } else {
            displayMethod = 'Check';
          }
        }

        rows.add([
          paymentId,
          displayMethod,
          description,
          '\$${amount.toStringAsFixed(2)}',
          dateStr,
        ]);

        paymentDataList.add({
          'payment_id': payment['payment_id'],
          'payment_method': method,
          'amount': amount,
          'date': dateStr,
          'date_time': payment['date_time'],
          'description': description,
          'customer_id': customerId,
          'check_details': payment['customer_checks'],
        });
      }

      // Fetch returned checks separately if not already included
      final returnedChecks = await supabase
          .from('customer_checks')
          .select('check_id, exchange_date, exchange_rate, description')
          .eq('customer_id', customerId)
          .eq('status', 'Returned')
          .order('exchange_date', ascending: false);

      for (final check in returnedChecks) {
        final checkId = check['check_id']?.toString() ?? '';
        final rawDate = check['exchange_date'];
        String dateStr = '';
        if (rawDate is String && rawDate.isNotEmpty) {
          try {
            final dt = DateTime.parse(rawDate);
            dateStr = '${dt.month}/${dt.day}/${dt.year}';
          } catch (_) {
            dateStr = rawDate;
          }
        }

        final amount = (check['exchange_rate'] as num?)?.toDouble() ?? 0;
        final description = check['description']?.toString() ?? '';

        // Check if this returned check is already in the payments list
        final alreadyExists = rows.any(
          (row) => row[0] == checkId && row[2].contains('Returned'),
        );

        if (!alreadyExists) {
          rows.add([
            'CHK-$checkId',
            'Returned Check',
            description,
            '\$${amount.toStringAsFixed(2)}',
            dateStr,
          ]);

          paymentDataList.add({
            'payment_id': 'RC-$checkId',
            'payment_method': 'returned_check',
            'amount': amount,
            'date': dateStr,
            'date_time': check['exchange_date'],
            'description': description,
            'customer_id': customerId,
            'check_details': check,
          });
        }
      }

      if (mounted) {
        setState(() {
          _paymentRows = rows;
          _filteredPaymentRows = rows;
          _paymentData = paymentDataList;
          _filteredPaymentData = paymentDataList;
        });
      }
    } catch (e) {
      print('Error loading payment history: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Filter button row
        Container(
          key: _filterButtonKey,
          child: _RoundIconButton(
            icon: Icons.filter_alt_rounded,
            onTap: _toggleFilterPopup,
          ),
        ),
        const SizedBox(height: 10),
        // Archive box with table
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : widget.selectedSubTab == 'Orders'
              ? _ArchiveTableWidget(
                  headers: const [
                    'Order ID',
                    'Order Date',
                    'Items',
                    'Total Cost',
                    'Status',
                  ],
                  rows: _filteredRows,
                  columnFlex: const [2, 2, 1, 2, 2],
                  onRowTap: (index) {
                    final orderId = _filteredRows[index][0];
                    showDialog(
                      context: context,
                      builder: (context) =>
                          orders.OrderDetailsPopup(orderId: orderId),
                    );
                  },
                )
              : _ArchiveTableWidget(
                  headers: const [
                    'Payment ID',
                    'Method',
                    'Description',
                    'Amount',
                    'Date',
                  ],
                  rows: _filteredPaymentRows,
                  columnFlex: const [2, 2, 3, 2, 2],
                  onRowTap: (index) {
                    final paymentData = _filteredPaymentData[index];
                    _showPaymentDetailsDialog(paymentData);
                  },
                ),
        ),
      ],
    );
  }

  void _filterRows() {
    final q = _searchController.text.trim().toLowerCase();

    // Filter orders
    List<List<String>> filteredOrders = List.from(_rows);

    // Apply Date range filter for orders
    if (_fromDate != null || _toDate != null) {
      filteredOrders = filteredOrders.where((r) {
        try {
          final dateStr = r.length > 1 ? r[1] : '';
          if (dateStr.isEmpty) return false;
          final parts = dateStr.split('/');
          if (parts.length != 3) return false;
          final rowDate = DateTime(
            int.parse(parts[2]),
            int.parse(parts[0]),
            int.parse(parts[1]),
          );

          if (_fromDate != null && rowDate.isBefore(_fromDate!)) return false;
          if (_toDate != null) {
            final toDateEnd = DateTime(
              _toDate!.year,
              _toDate!.month,
              _toDate!.day,
              23,
              59,
              59,
            );
            if (rowDate.isAfter(toDateEnd)) return false;
          }
          return true;
        } catch (_) {
          return false;
        }
      }).toList();
    }

    // Apply search filter for orders
    if (q.isNotEmpty) {
      filteredOrders = filteredOrders.where((r) {
        final orderId = r.isNotEmpty ? r[0].toLowerCase() : '';
        return orderId.startsWith(q);
      }).toList();
    }

    // Filter payments
    List<List<String>> filteredPayments = List.from(_paymentRows);
    List<Map<String, dynamic>> filteredPaymentsData = List.from(_paymentData);

    // Apply Date range filter for payments
    if (_fromDate != null || _toDate != null) {
      final indices = <int>[];
      for (int i = 0; i < filteredPayments.length; i++) {
        final r = filteredPayments[i];
        try {
          final dateStr = r.length > 4 ? r[4] : ''; // Date is in last column
          if (dateStr.isEmpty) continue;
          final parts = dateStr.split('/');
          if (parts.length != 3) continue;
          final rowDate = DateTime(
            int.parse(parts[2]),
            int.parse(parts[0]),
            int.parse(parts[1]),
          );

          if (_fromDate != null && rowDate.isBefore(_fromDate!)) continue;
          if (_toDate != null) {
            final toDateEnd = DateTime(
              _toDate!.year,
              _toDate!.month,
              _toDate!.day,
              23,
              59,
              59,
            );
            if (rowDate.isAfter(toDateEnd)) continue;
          }
          indices.add(i);
        } catch (_) {
          continue;
        }
      }
      filteredPayments = indices.map((i) => filteredPayments[i]).toList();
      filteredPaymentsData = indices
          .map((i) => filteredPaymentsData[i])
          .toList();
    }

    // Apply search filter for payments
    if (q.isNotEmpty) {
      final indices = <int>[];
      for (int i = 0; i < filteredPayments.length; i++) {
        final r = filteredPayments[i];
        final paymentId = r.isNotEmpty ? r[0].toLowerCase() : '';
        final method = r.length > 2 ? r[2].toLowerCase() : '';
        if (paymentId.startsWith(q) || method.contains(q)) {
          indices.add(i);
        }
      }
      filteredPayments = indices.map((i) => filteredPayments[i]).toList();
      filteredPaymentsData = indices
          .map((i) => filteredPaymentsData[i])
          .toList();
    }

    if (mounted) {
      setState(() {
        _filteredRows = filteredOrders;
        _filteredPaymentRows = filteredPayments;
        _filteredPaymentData = filteredPaymentsData;
      });
    }
  }

  void _toggleFilterPopup() {
    if (_filterOverlay != null) {
      _closeFilterPopup();
    } else {
      _showFilterPopup();
    }
  }

  void _showFilterPopup() {
    final renderBox =
        _filterButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _filterOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeFilterPopup,
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            left: offset.dx - 280 + size.width,
            top: offset.dy + size.height + 8,
            child: Material(
              color: Colors.transparent,
              child: StatefulBuilder(
                builder: (context, setOverlayState) => GestureDetector(
                  onTap: () {},
                  child: Container(
                    width: 300,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.blue, width: 1.5),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black54,
                          offset: Offset(0, 4),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Filter Archive',
                          style: TextStyle(
                            color: AppColors.blue,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Divider(color: Color(0xFF3D3D3D), height: 1),
                        const SizedBox(height: 12),
                        // Date From
                        _DateInputField(
                          label: 'From Date',
                          controller: _fromDateController,
                          onDateChanged: (date) {
                            setState(() => _fromDate = date);
                            _filterRows();
                            setOverlayState(() {});
                          },
                          onClear: () {
                            _fromDateController.clear();
                            setState(() => _fromDate = null);
                            _filterRows();
                            setOverlayState(() {});
                          },
                        ),
                        const SizedBox(height: 16),
                        // Date To
                        _DateInputField(
                          label: 'To Date',
                          controller: _toDateController,
                          onDateChanged: (date) {
                            setState(() => _toDate = date);
                            _filterRows();
                            setOverlayState(() {});
                          },
                          onClear: () {
                            _toDateController.clear();
                            setState(() => _toDate = null);
                            _filterRows();
                            setOverlayState(() {});
                          },
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: Color(0xFF3D3D3D), height: 1),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: () {
                                _fromDateController.clear();
                                _toDateController.clear();
                                setState(() {
                                  _fromDate = null;
                                  _toDate = null;
                                });
                                _filterRows();
                                setOverlayState(() {});
                              },
                              child: const Text(
                                'Clear All',
                                style: TextStyle(
                                  color: AppColors.blue,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
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
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_filterOverlay!);
  }

  void _closeFilterPopup() {
    _filterOverlay?.remove();
    _filterOverlay = null;
  }

  void _showPaymentDetailsDialog(Map<String, dynamic> payment) async {
    // For endorsed checks, fetch the customer check details
    Map<String, dynamic>? endorsedCheckDetails;
    final paymentMethodStr = (payment['payment_method'] ?? '')
        .toString()
        .toLowerCase();
    if (paymentMethodStr == 'endorsed_check' ||
        paymentMethodStr == 'endorsed check') {
      final description = payment['description'] ?? '';
      final checkIdMatch = RegExp(r'check #(\d+)').firstMatch(description);
      if (checkIdMatch != null) {
        final checkId = int.tryParse(checkIdMatch.group(1) ?? '');
        if (checkId != null) {
          try {
            final response = await supabase
                .from('customer_checks')
                .select('''
                  check_id,
                  bank_id,
                  bank_branch,
                  check_image,
                  exchange_rate,
                  exchange_date,
                  status,
                  description,
                  endorsed_description,
                  endorsed_to,
                  banks!bank_id (
                    bank_name
                  ),
                  branches!bank_branch (
                    address
                  )
                ''')
                .eq('check_id', checkId)
                .maybeSingle();

            if (response != null) {
              endorsedCheckDetails = response;
            }
          } catch (e) {
            print('Error fetching endorsed check details: $e');
          }
        }
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        final paymentMethod = payment['payment_method'] ?? 'cash';
        final paymentMethodLabel = paymentMethod
            .toString()
            .replaceAll('_', ' ')
            .toUpperCase();
        final isReturnedCheck =
            paymentMethod == 'returned_check' ||
            paymentMethod == 'returned check';
        final isEndorsedCheck =
            paymentMethod == 'endorsed_check' ||
            paymentMethod == 'endorsed check';
        final isCheckPayment =
            paymentMethod == 'check' ||
            paymentMethod == 'returned_check' ||
            paymentMethod == 'returned check' ||
            paymentMethod == 'endorsed_check' ||
            paymentMethod == 'endorsed check';
        final hasEndorsement =
            (payment['check_details']?['endorsed_to']?.toString().isNotEmpty ??
                false) ||
            (payment['check_details']?['endorsed_description']
                    ?.toString()
                    .isNotEmpty ??
                false);
        final isIncoming = true; // Always incoming for customer payments

        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.7,
            constraints: const BoxConstraints(maxWidth: 650, maxHeight: 700),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.blue.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Modern Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.blue.withOpacity(0.1),
                        AppColors.cardAlt,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isIncoming
                              ? Icons.arrow_circle_down
                              : Icons.arrow_circle_up,
                          color: AppColors.blue,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${isIncoming ? 'Incoming' : 'Outgoing'} Payment',
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Payment ID: ${payment['payment_id']}',
                              style: TextStyle(
                                color: AppColors.grey,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.close_rounded,
                          color: AppColors.white.withOpacity(0.7),
                          size: 24,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          hoverColor: AppColors.blue.withOpacity(0.1),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Amount Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.cardAlt,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.blue.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.attach_money,
                                  color: AppColors.blue,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total Amount',
                                      style: TextStyle(
                                        color: AppColors.grey,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      '\$${payment['amount']?.toString() ?? '0'}',
                                      style: const TextStyle(
                                        color: AppColors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isReturnedCheck
                                      ? Colors.redAccent.withOpacity(0.12)
                                      : isEndorsedCheck
                                      ? Colors.orangeAccent.withOpacity(0.12)
                                      : paymentMethod == 'check'
                                      ? AppColors.blue.withOpacity(0.1)
                                      : Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isReturnedCheck
                                        ? Colors.redAccent
                                        : isEndorsedCheck
                                        ? Colors.orangeAccent
                                        : paymentMethod == 'check'
                                        ? AppColors.blue
                                        : Colors.green,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  paymentMethodLabel,
                                  style: TextStyle(
                                    color: isReturnedCheck
                                        ? Colors.redAccent
                                        : isEndorsedCheck
                                        ? Colors.orangeAccent
                                        : paymentMethod == 'check'
                                        ? AppColors.blue
                                        : Colors.green,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Details Grid
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left Column (Name, Payment Method)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildDetailCard(
                                    icon: Icons.person,
                                    title: 'Customer Name',
                                    value:
                                        payment['customer_name'] ?? 'Unknown',
                                  ),
                                  const SizedBox(height: 16),
                                  _buildDetailCard(
                                    icon: Icons.payment,
                                    title: 'Payment Method',
                                    value: paymentMethodLabel,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Right Column (Date, Time)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildDetailCard(
                                    icon: Icons.calendar_today,
                                    title: 'Date',
                                    value: _formatDate(payment['date_time']),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildDetailCard(
                                    icon: Icons.schedule,
                                    title: 'Time',
                                    value: _formatTime(payment['date_time']),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Full-width description section
                        if (payment['description']?.isNotEmpty ?? false) ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.cardAlt,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.blue.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.description,
                                      color: AppColors.blue,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Description',
                                      style: TextStyle(
                                        color: AppColors.blue,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  payment['description'],
                                  style: const TextStyle(
                                    color: AppColors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Check Details Section (checks + returned checks + endorsed checks)
                        if (isEndorsedCheck &&
                            endorsedCheckDetails != null) ...[
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.cardAlt,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.orangeAccent.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.orangeAccent.withOpacity(
                                          0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.swap_horiz,
                                        color: Colors.orangeAccent,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Endorsed Customer Check',
                                            style: TextStyle(
                                              color: Colors.orangeAccent,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Original customer check information',
                                            style: TextStyle(
                                              color: AppColors.grey,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildCheckDetail(
                                        'Check ID',
                                        endorsedCheckDetails['check_id']
                                                ?.toString() ??
                                            'N/A',
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildCheckDetail(
                                        'Bank',
                                        endorsedCheckDetails['banks']?['bank_name'] ??
                                            'N/A',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildCheckDetail(
                                        'Exchange Rate',
                                        endorsedCheckDetails['exchange_rate']
                                                ?.toString() ??
                                            'N/A',
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildCheckDetail(
                                        'Exchange Date',
                                        _formatDate(
                                          endorsedCheckDetails['exchange_date']
                                              ?.toString(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildCheckDetail(
                                        'Status',
                                        endorsedCheckDetails['status'] ?? 'N/A',
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildCheckDetail(
                                        'Branch',
                                        endorsedCheckDetails['branches']?['address'] ??
                                            'N/A',
                                      ),
                                    ),
                                  ],
                                ),
                                if (endorsedCheckDetails['endorsed_description']
                                        ?.toString()
                                        .isNotEmpty ??
                                    false) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: AppColors.card,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.orangeAccent.withOpacity(
                                          0.2,
                                        ),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: const [
                                            Icon(
                                              Icons.info_outline,
                                              color: Colors.orangeAccent,
                                              size: 16,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Endorsement Notes',
                                              style: TextStyle(
                                                color: Colors.orangeAccent,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          endorsedCheckDetails['endorsed_description']
                                                  ?.toString() ??
                                              '',
                                          style: const TextStyle(
                                            color: AppColors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 16),
                                if (endorsedCheckDetails['check_image'] !=
                                    null) ...[
                                  Container(
                                    width: double.infinity,
                                    height: 200,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.orangeAccent.withOpacity(
                                          0.3,
                                        ),
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        endorsedCheckDetails['check_image'],
                                        fit: BoxFit.cover,
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
                                              if (loadingProgress == null) {
                                                return child;
                                              }
                                              return Center(
                                                child:
                                                    CircularProgressIndicator(
                                                      color:
                                                          Colors.orangeAccent,
                                                    ),
                                              );
                                            },
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return Center(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.error,
                                                      color: AppColors.grey,
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      'Failed to load image',
                                                      style: TextStyle(
                                                        color: AppColors.grey,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ] else if (isEndorsedCheck) ...[
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.orangeAccent.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.orangeAccent.withOpacity(0.4),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  color: Colors.orangeAccent,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Check details could not be loaded. This payment was made using an endorsed customer check.',
                                    style: TextStyle(
                                      color: AppColors.white.withOpacity(0.8),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else if (isCheckPayment) ...[
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.cardAlt,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.blue.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.account_balance,
                                      color: AppColors.blue,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Check Information',
                                      style: TextStyle(
                                        color: AppColors.blue,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                if (isReturnedCheck) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.redAccent.withOpacity(
                                          0.4,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.report,
                                          color: Colors.redAccent,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'This check was returned. Review the bank and status details below.',
                                            style: const TextStyle(
                                              color: Colors.redAccent,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 16),
                                if (payment['check_details'] != null) ...[
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildCheckDetail(
                                          'Check ID',
                                          payment['check_details']['check_id']
                                                  ?.toString() ??
                                              'N/A',
                                        ),
                                      ),
                                      Expanded(
                                        child: _buildCheckDetail(
                                          'Bank',
                                          payment['check_details']['banks']?['bank_name'] ??
                                              'N/A',
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildCheckDetail(
                                          'Exchange Rate',
                                          payment['check_details']['exchange_rate']
                                                  ?.toString() ??
                                              'N/A',
                                        ),
                                      ),
                                      Expanded(
                                        child: _buildCheckDetail(
                                          'Exchange Date',
                                          _formatDate(
                                            payment['check_details']['exchange_date']
                                                ?.toString(),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildCheckDetail(
                                          'Status',
                                          payment['check_details']['status'] ??
                                              'N/A',
                                        ),
                                      ),
                                      Expanded(
                                        child: _buildCheckDetail(
                                          'Branch',
                                          payment['check_details']['branches']?['address'] ??
                                              'N/A',
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (hasEndorsement) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: AppColors.card,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppColors.blue.withOpacity(
                                            0.2,
                                          ),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: const [
                                              Icon(
                                                Icons.swap_horiz,
                                                color: AppColors.blue,
                                                size: 18,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                'Endorsement Details',
                                                style: TextStyle(
                                                  color: AppColors.blue,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          _buildCheckDetail(
                                            'Endorsed To',
                                            payment['check_details']['endorsed_to']
                                                    ?.toString() ??
                                                'N/A',
                                          ),
                                          const SizedBox(height: 8),
                                          _buildCheckDetail(
                                            'Notes',
                                            payment['check_details']['endorsed_description']
                                                    ?.toString() ??
                                                'N/A',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  if (payment['check_details']['check_image'] !=
                                      null) ...[
                                    Container(
                                      width: double.infinity,
                                      height: 200,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppColors.blue.withOpacity(
                                            0.2,
                                          ),
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          payment['check_details']['check_image'],
                                          fit: BoxFit.cover,
                                          loadingBuilder:
                                              (
                                                context,
                                                child,
                                                loadingProgress,
                                              ) {
                                                if (loadingProgress == null) {
                                                  return child;
                                                }
                                                return Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                        color: AppColors.blue,
                                                      ),
                                                );
                                              },
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                return Center(
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                        Icons.error,
                                                        color: AppColors.grey,
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        'Failed to load image',
                                                        style: TextStyle(
                                                          color: AppColors.grey,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                        ),
                                      ),
                                    ),
                                  ],
                                ] else ...[
                                  Center(
                                    child: Text(
                                      'Check details not available',
                                      style: TextStyle(
                                        color: AppColors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.blue.withOpacity(0.1), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.blue, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.grey,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }
}

// 🔹 Round Icon Button
class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.card, width: 3),
      ),
      child: Material(
        color: AppColors.cardAlt,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 20, color: AppColors.blue),
          ),
        ),
      ),
    );
  }
}

// 🔹 Archive Table Widget
class _ArchiveTableWidget extends StatelessWidget {
  final List<String> headers;
  final List<List<String>> rows;
  final List<int>? columnFlex;
  final Function(int)? onRowTap;

  const _ArchiveTableWidget({
    required this.headers,
    required this.rows,
    this.columnFlex,
    this.onRowTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                children: headers.asMap().entries.map((entry) {
                  final index = entry.key;
                  final header = entry.value;
                  final flex = columnFlex != null && index < columnFlex!.length
                      ? columnFlex![index]
                      : 1;
                  final isLastColumn = index == headers.length - 1;
                  return Expanded(
                    flex: flex,
                    child: Align(
                      alignment: isLastColumn
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Text(
                        header,
                        style: const TextStyle(
                          color: AppColors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 6),
              Container(height: 1, color: AppColors.white.withOpacity(0.2)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Data rows
        if (rows.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'No orders found',
              style: TextStyle(color: Colors.white70),
            ),
          )
        else
          ...rows.asMap().entries.map((entry) {
            final index = entry.key;
            final row = entry.value;
            return _ArchiveTableRow(
              key: ValueKey(index),
              cells: row,
              isEven: index % 2 == 0,
              columnFlex: columnFlex,
              onTap: onRowTap != null ? () => onRowTap!(index) : null,
            );
          }),
      ],
    );
  }
}

// 🔹 Archive Table Row
class _ArchiveTableRow extends StatefulWidget {
  final List<String> cells;
  final bool isEven;
  final List<int>? columnFlex;
  final VoidCallback? onTap;

  const _ArchiveTableRow({
    super.key,
    required this.cells,
    required this.isEven,
    this.columnFlex,
    this.onTap,
  });

  @override
  State<_ArchiveTableRow> createState() => _ArchiveTableRowState();
}

class _ArchiveTableRowState extends State<_ArchiveTableRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.isEven ? AppColors.dark : AppColors.cardAlt;
    final bgColor = _isHovered ? baseColor.withOpacity(0.95) : baseColor;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.only(top: 6),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(30),
            border: _isHovered
                ? Border.all(color: AppColors.blue, width: 1.5)
                : null,
          ),
          child: Row(
            children: widget.cells.asMap().entries.map((entry) {
              final index = entry.key;
              final cell = entry.value;
              final flex =
                  widget.columnFlex != null && index < widget.columnFlex!.length
                  ? widget.columnFlex![index]
                  : 1;

              // Highlight date column (last column for payments, index 3 for orders)
              // Only highlight if it's exactly the last column (Date) or column 3 (Total Cost for orders)
              final isBlueColumn =
                  (widget.cells.length == 5 && index == 3) ||
                  (widget.cells.length == 5 && index == 4);
              final isLastColumn = index == widget.cells.length - 1;

              return Expanded(
                flex: flex,
                child: Align(
                  alignment: isLastColumn
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Text(
                    cell,
                    style: TextStyle(
                      color: isBlueColumn ? AppColors.blue : AppColors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// 🔹 Date Input Field
class _DateInputField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final ValueChanged<DateTime?> onDateChanged;
  final VoidCallback onClear;

  const _DateInputField({
    required this.label,
    required this.controller,
    required this.onDateChanged,
    required this.onClear,
  });

  @override
  State<_DateInputField> createState() => _DateInputFieldState();
}

class _DateInputFieldState extends State<_DateInputField> {
  String? _errorText;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final text = widget.controller.text;

    // Auto-insert slashes
    if (text.length == 2 && !text.contains('/')) {
      widget.controller.text = '$text/';
      widget.controller.selection = TextSelection.fromPosition(
        TextPosition(offset: widget.controller.text.length),
      );
    } else if (text.length == 5 && text.lastIndexOf('/') == 2) {
      widget.controller.text = '$text/';
      widget.controller.selection = TextSelection.fromPosition(
        TextPosition(offset: widget.controller.text.length),
      );
    }

    if (text.length == 10) {
      final date = _parse(text);
      if (date != null) {
        setState(() => _errorText = null);
        widget.onDateChanged(date);
      } else {
        setState(() => _errorText = 'Invalid date');
        widget.onDateChanged(null);
      }
    } else if (text.isEmpty) {
      setState(() => _errorText = null);
      widget.onDateChanged(null);
    } else if (text.length > 10) {
      setState(() => _errorText = 'Too many characters');
      widget.onDateChanged(null);
    }
  }

  DateTime? _parse(String text) {
    try {
      final parts = text.split('/');
      if (parts.length != 3) return null;
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      final date = DateTime(year, month, day);
      if (date.day != day || date.month != month || date.year != year) {
        return null;
      }
      return date;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF232427),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _errorText != null ? Colors.red : AppColors.blue,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today, color: AppColors.blue, size: 16),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'DD/MM/YYYY',
                    hintStyle: const TextStyle(
                      color: Colors.white54,
                      fontSize: 13,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    errorText: null,
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 10,
                  buildCounter:
                      (
                        context, {
                        required currentLength,
                        required isFocused,
                        maxLength,
                      }) => null,
                ),
              ),
              if (widget.controller.text.isNotEmpty)
                InkWell(
                  onTap: widget.onClear,
                  child: const Icon(
                    Icons.close,
                    color: Colors.white54,
                    size: 16,
                  ),
                ),
            ],
          ),
        ),
        if (_errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 12),
            child: Text(
              _errorText!,
              style: const TextStyle(color: Colors.red, fontSize: 11),
            ),
          ),
      ],
    );
  }
}
