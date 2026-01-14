import 'package:flutter/material.dart';
import 'report_page.dart';
import '../../supabase_config.dart';
import '../Orders/Orders_stock_in_previous_popup.dart' as orders;
import '../Payment/Payment_archive_page.dart' as payment_archive;
import 'report_supplier_generate_dialog.dart';

// ============================================================================
// 🔹 Supplier Detail Dialog (Popup)
// ============================================================================

class SupplierDetailDialog extends StatefulWidget {
  final String supplierId;
  final String supplierName;
  final String mobile;
  final String location;
  final String creditorBalance;

  const SupplierDetailDialog({
    super.key,
    required this.supplierId,
    required this.supplierName,
    required this.mobile,
    required this.location,
    required this.creditorBalance,
  });

  @override
  State<SupplierDetailDialog> createState() => _SupplierDetailDialogState();
}

class _SupplierDetailDialogState extends State<SupplierDetailDialog> {
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
                                widget.supplierName,
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
                                    value: widget.supplierId,
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
                                    label: 'Creditor Balance',
                                    value: '\$${widget.creditorBalance}',
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
                              builder: (_) => GenerateSupplierReportDialog(
                                supplierId: widget.supplierId,
                                supplierName: widget.supplierName,
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
                      ? _StatisticsContent(supplierId: widget.supplierId)
                      : _ArchiveContent(
                          supplierId: widget.supplierId,
                          supplierName: widget.supplierName,
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
  final String supplierId;
  const _StatisticsContent({required this.supplierId});

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

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    try {
      final supplierId = int.parse(widget.supplierId);

      // Fetch all delivered orders for this supplier
      final orders = await supabase
          .from('supplier_order')
          .select('order_id, order_date, total_cost')
          .eq('supplier_id', supplierId)
          .eq('order_status', 'Delivered')
          .order('order_date');

      _totalOrders = orders.length;
      _totalSpent = 0;

      if (orders.isNotEmpty) {
        // Calculate total spent
        for (final order in orders) {
          final cost = (order['total_cost'] as num?)?.toDouble() ?? 0;
          _totalSpent += cost;
        }

        // First and last order dates
        final firstDate = DateTime.parse(orders.first['order_date']);
        final lastDate = DateTime.parse(orders.last['order_date']);
        _firstOrderDate =
            '${firstDate.month}/${firstDate.day}/${firstDate.year}';
        _lastOrderDate = '${lastDate.month}/${lastDate.day}/${lastDate.year}';
      }

      // Fetch returned checks count
      final returnedChecks = await supabase
          .from('supplier_checks')
          .select('check_id')
          .eq('supplier_id', supplierId)
          .eq('status', 'Returned');
      _returnedChecks = returnedChecks.length;

      // Fetch top products
      final orderItems = await supabase
          .from('supplier_order_description')
          .select('''
            product_id,
            quantity,
            product:product_id(name),
            supplier_order:order_id(order_status)
          ''')
          .eq('supplier_order.supplier_id', supplierId);

      // Group by product
      final Map<int, Map<String, dynamic>> productStats = {};
      for (final item in orderItems) {
        // Only count delivered orders
        if (item['supplier_order'] is Map) {
          final status = item['supplier_order']['order_status']?.toString();
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
      print('Error loading supplier statistics: $e');
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
                        icon: Icons.shopping_bag_outlined,
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
                title: 'Top 5 Products Supplied',
                child: _TopProductsTable(products: _topProducts),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              flex: 3,
              child: _SectionCard(
                title: '',
                hideTitle: true,
                child: _SpendingChart(supplierId: widget.supplierId),
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
          icon: Icons.shopping_bag_outlined,
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
          title: 'Top 5 Products Supplied',
          child: _TopProductsTable(products: _topProducts),
        ),
        const SizedBox(height: 18),
        _SectionCard(
          title: '',
          hideTitle: true,
          child: _SpendingChart(supplierId: widget.supplierId),
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
            'No products supplied yet',
            style: TextStyle(color: AppColors.grey, fontSize: 14),
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
              flex: 5,
              child: Text(
                'Product Name',
                style: TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Total Quantity',
                  style: TextStyle(
                    color: AppColors.blue,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(height: 1, color: Colors.white.withOpacity(0.2)),
        const SizedBox(height: 10),
        // Rows
        ...List.generate(products.length, (i) {
          final product = products[i];
          final bg = i.isEven ? AppColors.cardAlt : AppColors.dark;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text(
                    product['product_name']?.toString() ?? 'Unknown',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      product['total_quantity']?.toString() ?? '0',
                      style: const TextStyle(
                        color: AppColors.blue,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
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

// 🔹 Spending Chart with Year Selector
class _SpendingChart extends StatefulWidget {
  final String supplierId;
  const _SpendingChart({required this.supplierId});

  @override
  State<_SpendingChart> createState() => _SpendingChartState();
}

class _SpendingChartState extends State<_SpendingChart>
    with SingleTickerProviderStateMixin {
  int selectedYear = DateTime.now().year;
  List<double> monthlySpending = List.filled(12, 0);
  bool loading = true;
  late AnimationController _animationController;
  late List<Animation<double>> _barAnimations;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _barAnimations = List.generate(12, (i) {
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(i * 0.08, 1.0, curve: Curves.easeOutCubic),
        ),
      );
    });
    _loadSpendingData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSpendingData() async {
    setState(() => loading = true);
    try {
      final supplierId = int.parse(widget.supplierId);
      final yearStart = DateTime(selectedYear, 1, 1).toIso8601String();
      final yearEnd = DateTime(
        selectedYear,
        12,
        31,
        23,
        59,
        59,
      ).toIso8601String();

      final orders = await supabase
          .from('supplier_order')
          .select('order_date, total_cost')
          .eq('supplier_id', supplierId)
          .eq('order_status', 'Delivered')
          .gte('order_date', yearStart)
          .lte('order_date', yearEnd);

      final spending = List.filled(12, 0.0);
      for (final order in orders) {
        final date = DateTime.parse(order['order_date']);
        final monthIndex = date.month - 1;
        final cost = (order['total_cost'] as num?)?.toDouble() ?? 0;
        spending[monthIndex] += cost;
      }

      if (mounted) {
        setState(() {
          monthlySpending = spending;
          loading = false;
        });
        _animationController.forward(from: 0);
      }
    } catch (e) {
      print('Error loading spending data: $e');
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Monthly Spending',
              style: TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            // Year selector dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.cardAlt,
                borderRadius: BorderRadius.circular(20),
              ),
              child: DropdownButton<int>(
                value: selectedYear,
                underline: const SizedBox(),
                dropdownColor: AppColors.cardAlt,
                icon: const Icon(Icons.arrow_drop_down, color: AppColors.blue),
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                items: List.generate(10, (i) {
                  final year = DateTime.now().year - i;
                  return DropdownMenuItem<int>(
                    value: year,
                    child: Text(year.toString()),
                  );
                }),
                onChanged: (year) {
                  if (year != null) {
                    setState(() => selectedYear = year);
                    _loadSpendingData();
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(color: AppColors.blue),
            ),
          )
        else
          SizedBox(
            height: 200,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(12, (i) {
                    final maxSpending = monthlySpending.reduce(
                      (a, b) => a > b ? a : b,
                    );
                    final height = maxSpending > 0
                        ? (monthlySpending[i] / maxSpending) * 180
                        : 0.0;
                    final animatedHeight = height * _barAnimations[i].value;

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              height: animatedHeight,
                              decoration: BoxDecoration(
                                color: AppColors.blue,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              [
                                'J',
                                'F',
                                'M',
                                'A',
                                'M',
                                'J',
                                'J',
                                'A',
                                'S',
                                'O',
                                'N',
                                'D',
                              ][i],
                              style: const TextStyle(
                                color: AppColors.grey,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
      ],
    );
  }
}

// ============================================================================
// 🔹 ARCHIVE TAB
// ============================================================================

class _ArchiveContent extends StatefulWidget {
  final String supplierId;
  final String supplierName;
  final String selectedSubTab;

  const _ArchiveContent({
    required this.supplierId,
    required this.supplierName,
    required this.selectedSubTab,
  });

  @override
  State<_ArchiveContent> createState() => _ArchiveContentState();
}

class _ArchiveContentState extends State<_ArchiveContent> {
  // Archive Orders data
  List<List<String>> _orderRows = [];
  List<List<String>> _filteredRows = [];

  // Archive Payments data
  List<List<String>> _paymentRows = [];
  List<List<String>> _filteredPaymentRows = [];
  List<Map<String, dynamic>> _paymentData = []; // Store full payment data
  List<Map<String, dynamic>> _filteredPaymentData = [];

  bool _loading = false;

  // Date filter
  DateTime? _fromDate;
  DateTime? _toDate;

  final GlobalKey _filterButtonKey = GlobalKey();
  OverlayEntry? _filterOverlay;

  @override
  void initState() {
    super.initState();
    if (widget.selectedSubTab == 'Orders') {
      _loadArchiveRows();
    } else {
      _loadPaymentRows();
    }
  }

  @override
  void didUpdateWidget(_ArchiveContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedSubTab != widget.selectedSubTab) {
      if (widget.selectedSubTab == 'Orders') {
        if (_orderRows.isEmpty) {
          _loadArchiveRows();
        }
      } else {
        if (_paymentRows.isEmpty) {
          _loadPaymentRows();
        }
      }
    }
  }

  @override
  void dispose() {
    _filterOverlay?.remove();
    super.dispose();
  }

  Future<void> _loadArchiveRows() async {
    setState(() => _loading = true);
    try {
      final supplierId = int.parse(widget.supplierId);

      final orders = await supabase
          .from('supplier_order')
          .select('order_id, order_date, total_cost')
          .eq('supplier_id', supplierId)
          .eq('order_status', 'Delivered')
          .order('order_date', ascending: false);

      final rows = <List<String>>[];
      for (final order in orders) {
        final orderId = order['order_id'].toString();
        final orderDate = order['order_date']?.toString() ?? '';
        final totalCost = order['total_cost']?.toString() ?? '0';

        final date = orderDate.isNotEmpty ? DateTime.parse(orderDate) : null;
        final formattedDate = date != null
            ? '${date.day}/${date.month}/${date.year}'
            : '';

        rows.add([orderId, formattedDate, '\$$totalCost']);
      }

      if (mounted) {
        setState(() {
          _orderRows = rows;
          _filteredRows = rows;
          _loading = false;
        });
      }
    } catch (e) {
      print('Error loading archive rows: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadPaymentRows() async {
    setState(() => _loading = true);
    try {
      final supplierId = int.parse(widget.supplierId);

      // Fetch outgoing payments
      final payments = await supabase
          .from('outgoing_payment')
          .select('''
            payment_voucher_id,
            amount,
            date_time,
            description,
            payment_method,
            check_id,
            supplier_id,
            supplier_checks!check_id (
              check_id,
              bank_id,
              bank_branch,
              check_image,
              exchange_rate,
              exchange_date,
              status,
              description,
              banks!bank_id (
                bank_name
              ),
              branches!bank_branch (
                address
              )
            )
          ''')
          .eq('supplier_id', supplierId)
          .order('date_time', ascending: false);

      final rows = <List<String>>[];
      final paymentDataList = <Map<String, dynamic>>[];

      for (final payment in payments) {
        final paymentId = payment['payment_voucher_id'].toString();
        final paymentMethod = payment['payment_method']?.toString() ?? 'cash';
        final amount = payment['amount']?.toString() ?? '0';
        final dateTime = payment['date_time']?.toString() ?? '';
        final description = payment['description']?.toString() ?? '';
        final checkDetails = payment['supplier_checks'];

        final date = dateTime.isNotEmpty ? DateTime.parse(dateTime) : null;
        final formattedDate = date != null
            ? '${date.day}/${date.month}/${date.year}'
            : '';

        final methodLabel = paymentMethod.replaceAll('_', ' ').toUpperCase();

        rows.add([
          paymentId,
          methodLabel,
          description,
          '\$$amount',
          formattedDate,
        ]);

        // Store full payment data
        paymentDataList.add({
          'payment_voucher_id': paymentId,
          'payment_method': paymentMethod,
          'amount': payment['amount'],
          'date': formattedDate,
          'date_time': dateTime,
          'description': description,
          'check_details': checkDetails,
          'supplier_id': supplierId,
          'supplier_name': widget.supplierName, // Will be fetched from parent
        });
      }

      // Fetch returned supplier checks
      final returnedChecks = await supabase
          .from('supplier_checks')
          .select('''
            check_id,
            exchange_rate,
            exchange_date,
            status,
            description,
            supplier_id,
            banks:bank_id ( bank_name ),
            branches:bank_branch ( address ),
            check_image
          ''')
          .eq('supplier_id', supplierId)
          .eq('status', 'Returned')
          .order('exchange_date', ascending: false);

      for (final check in returnedChecks) {
        final checkId = 'RC-${check['check_id']}';
        final exchangeRate = check['exchange_rate']?.toString() ?? '0';
        final exchangeDate = check['exchange_date']?.toString() ?? '';
        final description = check['description']?.toString() ?? '';

        final date = exchangeDate.isNotEmpty
            ? DateTime.parse(exchangeDate)
            : null;
        final formattedDate = date != null
            ? '${date.day}/${date.month}/${date.year}'
            : '';

        rows.add([
          checkId,
          'RETURNED CHECK',
          description,
          '\$$exchangeRate',
          formattedDate,
        ]);

        paymentDataList.add({
          'payment_voucher_id': checkId,
          'payment_method': 'returned_check',
          'amount': check['exchange_rate'],
          'date': formattedDate,
          'date_time': exchangeDate,
          'description': description,
          'check_details': check,
          'supplier_id': supplierId,
          'supplier_name': widget.supplierName, // Will be fetched from parent
        });
      }

      if (mounted) {
        setState(() {
          _paymentRows = rows;
          _filteredPaymentRows = rows;
          _paymentData = paymentDataList;
          _filteredPaymentData = paymentDataList;
          _loading = false;
        });
      }
    } catch (e) {
      print('Error loading payment rows: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _filterRows() {
    if (widget.selectedSubTab == 'Orders') {
      // Filter orders by date range
      List<List<String>> tempRows = _orderRows;

      if (_fromDate != null || _toDate != null) {
        tempRows = tempRows.where((row) {
          if (row.length < 2) return false;
          final dateStr = row[1]; // Date column
          final dateParts = dateStr.split('/');
          if (dateParts.length != 3) return false;

          try {
            final day = int.parse(dateParts[0]);
            final month = int.parse(dateParts[1]);
            final year = int.parse(dateParts[2]);
            final rowDate = DateTime(year, month, day);

            if (_fromDate != null && rowDate.isBefore(_fromDate!)) {
              return false;
            }
            if (_toDate != null && rowDate.isAfter(_toDate!)) {
              return false;
            }
            return true;
          } catch (e) {
            return false;
          }
        }).toList();
      }

      if (mounted) {
        setState(() {
          _filteredRows = tempRows;
        });
      }
    } else {
      // Filter payments by date range
      List<List<String>> tempRows = _paymentRows;
      List<Map<String, dynamic>> tempData = _paymentData;

      if (_fromDate != null || _toDate != null) {
        final filteredIndices = <int>[];
        for (int i = 0; i < tempRows.length; i++) {
          final row = tempRows[i];
          if (row.length < 5) continue;
          final dateStr = row[4]; // Date column (last position)
          final dateParts = dateStr.split('/');
          if (dateParts.length != 3) continue;

          try {
            final day = int.parse(dateParts[0]);
            final month = int.parse(dateParts[1]);
            final year = int.parse(dateParts[2]);
            final rowDate = DateTime(year, month, day);

            if (_fromDate != null && rowDate.isBefore(_fromDate!)) {
              continue;
            }
            if (_toDate != null && rowDate.isAfter(_toDate!)) {
              continue;
            }
            filteredIndices.add(i);
          } catch (e) {
            continue;
          }
        }

        tempRows = filteredIndices.map((i) => tempRows[i]).toList();
        tempData = filteredIndices.map((i) => tempData[i]).toList();
      }

      if (mounted) {
        setState(() {
          _filteredPaymentRows = tempRows;
          _filteredPaymentData = tempData;
        });
      }
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
    final RenderBox? renderBox =
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
              child: Container(
                width: 300,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D2D),
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
                    Text(
                      'Filter Options',
                      style: TextStyle(
                        color: AppColors.blue,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: Color(0xFF3D3D3D), height: 1),
                    const SizedBox(height: 16),
                    Text(
                      'Date Range',
                      style: TextStyle(
                        color: AppColors.blue,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDatePicker(
                      label: 'From Date',
                      date: _fromDate,
                      onDateSelected: (date) {
                        setState(() {
                          _fromDate = date;
                          _filterRows();
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildDatePicker(
                      label: 'To Date',
                      date: _toDate,
                      onDateSelected: (date) {
                        setState(() {
                          _toDate = date;
                          _filterRows();
                        });
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
                            setState(() {
                              _fromDate = null;
                              _toDate = null;
                              _filterRows();
                            });
                            _closeFilterPopup();
                          },
                          child: Text(
                            'Clear All',
                            style: TextStyle(
                              color: AppColors.blue,
                              fontWeight: FontWeight.w700,
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
        ],
      ),
    );

    Overlay.of(context).insert(_filterOverlay!);
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime? date,
    required ValueChanged<DateTime?> onDateSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              onDateSelected(picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF232427),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.blue, width: 1),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: AppColors.blue,
                  size: 16,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    date != null
                        ? '${date.day}/${date.month}/${date.year}'
                        : 'Select date',
                    style: TextStyle(
                      color: date != null ? Colors.white : Colors.white54,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (date != null)
                  InkWell(
                    onTap: () => onDateSelected(null),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white54,
                      size: 16,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
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
        final isIncoming = false; // Always outgoing for supplier payments

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
                              'Payment ID: ${payment['payment_voucher_id']}',
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
                                    icon: Icons.business,
                                    title: 'Supplier Name',
                                    value:
                                        payment['supplier_name'] ?? 'Unknown',
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
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filter bar
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _RoundIconButton(
              key: _filterButtonKey,
              icon: Icons.filter_alt_rounded,
              onTap: _toggleFilterPopup,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Table
        if (_loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(color: AppColors.blue),
            ),
          )
        else if (widget.selectedSubTab == 'Orders')
          _ArchiveTableWidget(
            headers: const ['Order ID #', 'Order Date', 'Total Cost'],
            rows: _filteredRows,
            columnFlex: const [2, 2, 2],
            onRowTap: (index) {
              final orderId = _filteredRows[index][0];
              showDialog(
                context: context,
                builder: (context) =>
                    orders.OrdersStockInPreviousPopup(orderId: orderId),
              );
            },
          )
        else
          _ArchiveTableWidget(
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
              _showPaymentDetailsDialog(_filteredPaymentData[index]);
            },
          ),
      ],
    );
  }
}

// 🔹 Round Icon Button
class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundIconButton({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.card, width: 3),
      ),
      child: Material(
        color: AppColors.card,
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: List.generate(headers.length, (i) {
            final flex = (columnFlex != null && i < columnFlex!.length)
                ? columnFlex![i]
                : 1;
            final isLastColumn = i == headers.length - 1;
            return Expanded(
              flex: flex,
              child: Align(
                alignment: isLastColumn
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Text(
                  headers[i],
                  style: TextStyle(
                    color: isLastColumn ? AppColors.blue : AppColors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Container(height: 1, color: Colors.white.withOpacity(0.4)),
        const SizedBox(height: 10),

        // Rows
        if (rows.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Text(
                'No records found',
                style: TextStyle(color: AppColors.grey, fontSize: 14),
              ),
            ),
          )
        else
          ...List.generate(rows.length, (index) {
            return _ArchiveTableRow(
              cells: rows[index],
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
    final bgColor = widget.isEven ? AppColors.cardAlt : AppColors.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: _isHovered ? AppColors.blue : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: List.generate(widget.cells.length, (i) {
              final flex =
                  (widget.columnFlex != null && i < widget.columnFlex!.length)
                  ? widget.columnFlex![i]
                  : 1;
              final isLastColumn = i == widget.cells.length - 1;
              final isBlueColumn =
                  (widget.cells.length == 5 && (i == 3 || i == 4)) ||
                  (widget.cells.length == 3 && i == 2);

              return Expanded(
                flex: flex,
                child: Align(
                  alignment: isLastColumn
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Text(
                    widget.cells[i],
                    style: TextStyle(
                      color: isBlueColumn ? AppColors.blue : AppColors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
