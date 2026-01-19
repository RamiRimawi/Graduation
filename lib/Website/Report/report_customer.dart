import 'package:flutter/material.dart';
import '../sidebar.dart';
import '../../supabase_config.dart';
import 'report_customer_detail.dart';
import '../Notifications/notification_bell_widget.dart';

class ReportCustomerPage extends StatelessWidget {
  const ReportCustomerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ReportCustomerPageContent();
  }
}

// 🎨 الألوان
class AppColors {
  static const white = Color(0xFFFFFFFF);
  static const blue = Color(0xFF50B2E7);
  static const card = Color(0xFF2D2D2D);
  static const cardAlt = Color(0xFF262626);
  static const dark = Color(0xFF202020);
  static const grey = Color(0xFF999999);
  static const gold = Color(0xFFB7A447);
}

class ReportCustomerPageContent extends StatefulWidget {
  const ReportCustomerPageContent({super.key});

  @override
  State<ReportCustomerPageContent> createState() =>
      _ReportCustomerPageContentState();
}

class _ReportCustomerPageContentState extends State<ReportCustomerPageContent> {
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _filteredCustomers = [];
  bool _loading = true;
  final TextEditingController _searchController = TextEditingController();
  String _sortColumn = 'customer_id';
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _searchController.addListener(_filterCustomers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    try {
      final result = await supabase.from('customer').select('''
            customer_id,
            name,
            mobile_number,
            address,
            balance_debit,
            customer_city:customer_city(name)
          ''');

      if (mounted) {
        setState(() {
          _customers = List<Map<String, dynamic>>.from(result);
          _filteredCustomers = _customers;
          _loading = false;
          _sortCustomers();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
      print('Error loading customers: $e');
    }
  }

  void _filterCustomers() {
    final query = _searchController.text.toLowerCase();
    if (!mounted) return;
    setState(() {
      if (query.isEmpty) {
        _filteredCustomers = _customers;
      } else {
        _filteredCustomers = _customers.where((customer) {
          final name = customer['name']?.toString().toLowerCase() ?? '';
          return name.startsWith(query);
        }).toList();
      }
      _sortCustomers();
    });
  }

  void _sortCustomers() {
    _filteredCustomers.sort((a, b) {
      dynamic aValue = a[_sortColumn];
      dynamic bValue = b[_sortColumn];

      if (_sortColumn == 'customer_id') {
        aValue = aValue as int? ?? 0;
        bValue = bValue as int? ?? 0;
      } else {
        aValue = aValue?.toString().toLowerCase() ?? '';
        bValue = bValue?.toString().toLowerCase() ?? '';
      }

      final comparison = aValue.compareTo(bValue);
      return _sortAscending ? comparison : -comparison;
    });
  }

  void _onHeaderTap(String column) {
    if (!mounted) return;
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = true;
      }
      _sortCustomers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Row(
        children: [
          const Sidebar(activeIndex: 5),
          Expanded(
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: width > 800 ? 40 : 20,
                  vertical: 22,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔹 Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          'Customer Report',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        NotificationBellWidget(),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 🔹 Top section
                    Row(
                      children: const [
                        Expanded(
                          child: _BuyingCustomersCard(
                            title: "Top 3 Buying Customers",
                            isTop: true,
                          ),
                        ),
                        SizedBox(width: 20),
                        Expanded(
                          child: _BuyingCustomersCard(
                            title: "Lowest 3 Buying Customers",
                            isTop: false,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // 🔹 Reports each customer
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 🔹 Title + Search bar
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Customer Reports',
                                  style: TextStyle(
                                    color: AppColors.blue,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 22,
                                  ),
                                ),
                                _SearchField(
                                  hint: 'Customer Name',
                                  icon: Icons.manage_search_rounded,
                                  controller: _searchController,
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            Row(
                              children: [
                                _SortableHeader(
                                  'Customer ID #',
                                  flex: 2,
                                  isActive: _sortColumn == 'customer_id',
                                  isAscending: _sortAscending,
                                  onTap: () => _onHeaderTap('customer_id'),
                                ),
                                _SortableHeader(
                                  'Customer Name',
                                  flex: 4,
                                  isActive: _sortColumn == 'name',
                                  isAscending: _sortAscending,
                                  onTap: () => _onHeaderTap('name'),
                                ),
                                _HeaderText('Mobile Number', flex: 3),
                                _HeaderText('Location', flex: 3),
                                _HeaderText(
                                  'Balance Debit',
                                  flex: 2,
                                  alignEnd: true,
                                  color: AppColors.blue,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: 1,
                              color: Colors.white.withOpacity(0.2),
                            ),
                            const SizedBox(height: 10),

                            // 🔹 Customer Rows
                            Expanded(
                              child: _loading
                                  ? const Center(
                                      child: CircularProgressIndicator(
                                        color: AppColors.blue,
                                      ),
                                    )
                                  : _filteredCustomers.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'No customers found',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 16,
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount: _filteredCustomers.length,
                                      itemBuilder: (context, index) {
                                        final customer =
                                            _filteredCustomers[index];

                                        final cityData =
                                            customer['customer_city'];
                                        final cityName = cityData is Map
                                            ? (cityData['name']?.toString() ??
                                                  '')
                                            : '';
                                        final address =
                                            customer['address']?.toString() ??
                                            '';
                                        final location =
                                            cityName.isNotEmpty &&
                                                address.isNotEmpty
                                            ? '$cityName - $address'
                                            : cityName.isNotEmpty
                                            ? cityName
                                            : address.isNotEmpty
                                            ? address
                                            : 'N/A';

                                        return _CustomerRow(
                                          index: index,
                                          id: customer['customer_id']
                                              .toString(),
                                          name:
                                              customer['name']?.toString() ??
                                              'N/A',
                                          mobile:
                                              customer['mobile_number']
                                                  ?.toString() ??
                                              'N/A',
                                          location: location,
                                          balanceDebit:
                                              customer['balance_debit']
                                                  ?.toString() ??
                                              '0',
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 🔹 Search Field صغير
class _SearchField extends StatelessWidget {
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  const _SearchField({
    required this.hint,
    required this.icon,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(28),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: AppColors.white, fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.grey, fontSize: 13),
          prefixIcon: Icon(icon, color: AppColors.white, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
        ),
      ),
    );
  }
}

// 🔹 Top/Lowest Buying Customers Card
class _BuyingCustomersCard extends StatefulWidget {
  final String title;
  final bool isTop;
  const _BuyingCustomersCard({required this.title, required this.isTop});

  @override
  State<_BuyingCustomersCard> createState() => _BuyingCustomersCardState();
}

class _BuyingCustomersCardState extends State<_BuyingCustomersCard> {
  List<Map<String, dynamic>> _customers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    try {
      // Get current month start and end dates
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1).toIso8601String();
      final monthEnd = DateTime(now.year, now.month + 1, 0).toIso8601String();

      // Fetch all customer orders for this month
      final orders = await supabase
          .from('customer_order')
          .select('''
            customer_id,
            total_cost,
            customer:customer_id(name)
          ''')
          .gte('order_date', monthStart)
          .lte('order_date', monthEnd);

      // Group and aggregate by customer
      final Map<int, Map<String, dynamic>> customerStats = {};
      for (var order in orders as List) {
        final customerId = order['customer_id'] as int;
        final totalPrice = (order['total_cost'] as num?)?.toDouble() ?? 0.0;
        final customerData = order['customer'] as Map?;
        final customerName = customerData?['name']?.toString() ?? '';

        if (!customerStats.containsKey(customerId)) {
          customerStats[customerId] = {
            'customer_id': customerId,
            'customer_name': customerName,
            'total_profit': 0.0,
            'num_of_orders': 0,
          };
        }

        customerStats[customerId]!['total_profit'] =
            (customerStats[customerId]!['total_profit'] as double) + totalPrice;
        customerStats[customerId]!['num_of_orders'] =
            (customerStats[customerId]!['num_of_orders'] as int) + 1;
      }

      // Convert to list and sort by profit
      final customerList = customerStats.values.toList();
      customerList.sort((a, b) {
        final profitA = (a['total_profit'] as double);
        final profitB = (b['total_profit'] as double);
        return widget.isTop
            ? profitB.compareTo(profitA)
            : profitA.compareTo(profitB);
      });

      final top3 = customerList.take(3).toList();

      if (!mounted) return;
      setState(() {
        _customers = top3;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
      print('Error loading customers: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${widget.title} ',
                  style: const TextStyle(
                    color: AppColors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const TextSpan(
                  text: '(this month)',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: const [
              _HeaderText('Customer Name', flex: 4),
              _HeaderText('Total Profit', flex: 1, color: AppColors.blue),
              _HeaderText(
                'Number of Orders',
                flex: 1,
                color: AppColors.blue,
                alignEnd: true,
              ),
            ],
          ),
          const SizedBox(height: 5),
          Container(height: 1, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 10),

          // Loading or Data Rows
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: AppColors.blue),
              ),
            )
          else if (_customers.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No data available',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            )
          else
            ...List.generate(_customers.length, (i) {
              final customer = _customers[i];
              final bg = i.isEven ? AppColors.dark : AppColors.cardAlt;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(
                        customer['customer_name']?.toString() ?? 'N/A',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '\$${(customer['total_profit'] as double?)?.toStringAsFixed(2) ?? '0.00'}',
                          style: const TextStyle(
                            color: AppColors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          customer['num_of_orders']?.toString() ?? '0',
                          style: const TextStyle(
                            color: AppColors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

// 🔹 Customer Row
class _CustomerRow extends StatefulWidget {
  final int index;
  final String id, name, mobile, location, balanceDebit;
  const _CustomerRow({
    required this.index,
    required this.id,
    required this.name,
    required this.mobile,
    required this.location,
    required this.balanceDebit,
  });

  @override
  State<_CustomerRow> createState() => _CustomerRowState();
}

class _CustomerRowState extends State<_CustomerRow> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.index.isEven ? AppColors.cardAlt : AppColors.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => CustomerDetailDialog(
              customerId: widget.id,
              customerName: widget.name,
              mobile: widget.mobile,
              location: widget.location,
              balanceDebit: widget.balanceDebit,
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: isHovered ? AppColors.blue : Colors.transparent,
              width: 2,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              _cell(widget.id, flex: 2),
              _cell(widget.name, flex: 4),
              _cell(widget.mobile, flex: 3),
              _cell(widget.location, flex: 3),
              _cell(
                '\$${widget.balanceDebit}',
                flex: 2,
                alignEnd: true,
                color: AppColors.blue,
                isBold: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cell(
    String text, {
    int flex = 1,
    Color color = Colors.white,
    bool alignEnd = false,
    bool isBold = false,
  }) {
    return Expanded(
      flex: flex,
      child: Align(
        alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            fontSize: 14,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

// 🔹 Header Text
class _HeaderText extends StatelessWidget {
  final String text;
  final int flex;
  final bool alignEnd;
  final Color color;
  const _HeaderText(
    this.text, {
    this.flex = 1,
    this.alignEnd = false,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Align(
        alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// 🔹 Sortable Header Text
class _SortableHeader extends StatelessWidget {
  final String text;
  final int flex;
  final bool isActive;
  final bool isAscending;
  final VoidCallback onTap;

  const _SortableHeader(
    this.text, {
    this.flex = 1,
    required this.isActive,
    required this.isAscending,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                text,
                style: TextStyle(
                  color: isActive ? AppColors.blue : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 4),
              if (isActive)
                Icon(
                  isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 14,
                  color: AppColors.blue,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
