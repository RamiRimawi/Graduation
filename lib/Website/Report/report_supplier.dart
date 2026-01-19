import 'package:flutter/material.dart';
import '../sidebar.dart';
import '../../supabase_config.dart';
import 'report_supplier_detail.dart';
import '../Notifications/notification_bell_widget.dart';

class ReportSupplierPage extends StatelessWidget {
  const ReportSupplierPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ReportSupplierPageContent();
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

class ReportSupplierPageContent extends StatefulWidget {
  const ReportSupplierPageContent({super.key});

  @override
  State<ReportSupplierPageContent> createState() =>
      _ReportSupplierPageContentState();
}

class _ReportSupplierPageContentState extends State<ReportSupplierPageContent> {
  List<Map<String, dynamic>> _suppliers = [];
  List<Map<String, dynamic>> _filteredSuppliers = [];
  bool _loading = true;
  final TextEditingController _searchController = TextEditingController();
  String _sortColumn = 'supplier_id';
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
    _searchController.addListener(_filterSuppliers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSuppliers() async {
    try {
      final result = await supabase.from('supplier').select('''
            supplier_id,
            name,
            mobile_number,
            address,
            creditor_balance,
            supplier_city:supplier_city(name)
          ''');

      if (mounted) {
        setState(() {
          _suppliers = List<Map<String, dynamic>>.from(result);
          _filteredSuppliers = _suppliers;
          _loading = false;
          _sortSuppliers();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
      print('Error loading suppliers: $e');
    }
  }

  void _filterSuppliers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredSuppliers = _suppliers;
      } else {
        _filteredSuppliers = _suppliers.where((supplier) {
          final name = supplier['name']?.toString().toLowerCase() ?? '';
          return name.startsWith(query);
        }).toList();
      }
      _sortSuppliers();
    });
  }

  void _sortSuppliers() {
    _filteredSuppliers.sort((a, b) {
      dynamic aValue = a[_sortColumn];
      dynamic bValue = b[_sortColumn];

      if (_sortColumn == 'supplier_id') {
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
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = true;
      }
      _sortSuppliers();
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
                          'Supplier Report',
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
                          child: _SupplyingSuppliersCard(
                            title: "Top 3 Supply Suppliers",
                            isTop: true,
                          ),
                        ),
                        SizedBox(width: 20),
                        Expanded(
                          child: _SupplyingSuppliersCard(
                            title: "Lowest 3 Supply Suppliers",
                            isTop: false,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // 🔹 Reports each supplier
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
                                  'Supplier Reports',
                                  style: TextStyle(
                                    color: AppColors.blue,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 22,
                                  ),
                                ),
                                _SearchField(
                                  hint: 'Supplier Name',
                                  icon: Icons.manage_search_rounded,
                                  controller: _searchController,
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            Row(
                              children: [
                                _SortableHeader(
                                  'Supplier ID #',
                                  flex: 2,
                                  isActive: _sortColumn == 'supplier_id',
                                  isAscending: _sortAscending,
                                  onTap: () => _onHeaderTap('supplier_id'),
                                ),
                                _SortableHeader(
                                  'Supplier Name',
                                  flex: 4,
                                  isActive: _sortColumn == 'name',
                                  isAscending: _sortAscending,
                                  onTap: () => _onHeaderTap('name'),
                                ),
                                _HeaderText('Mobile Number', flex: 3),
                                _HeaderText('Location', flex: 3),
                                _HeaderText(
                                  'Creditor Balance',
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

                            // 🔹 Supplier Rows
                            Expanded(
                              child: _loading
                                  ? const Center(
                                      child: CircularProgressIndicator(
                                        color: AppColors.blue,
                                      ),
                                    )
                                  : _filteredSuppliers.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'No suppliers found',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 16,
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount: _filteredSuppliers.length,
                                      itemBuilder: (context, index) {
                                        final supplier =
                                            _filteredSuppliers[index];

                                        final cityData =
                                            supplier['supplier_city'];
                                        final cityName = cityData is Map
                                            ? (cityData['name']?.toString() ??
                                                  '')
                                            : '';
                                        final address =
                                            supplier['address']?.toString() ??
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

                                        return _SupplierRow(
                                          index: index,
                                          id: supplier['supplier_id']
                                              .toString(),
                                          name:
                                              supplier['name']?.toString() ??
                                              'N/A',
                                          mobile:
                                              supplier['mobile_number']
                                                  ?.toString() ??
                                              'N/A',
                                          location: location,
                                          creditorBalance:
                                              supplier['creditor_balance']
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

// 🔹 Top/Lowest Supply Suppliers Card
class _SupplyingSuppliersCard extends StatefulWidget {
  final String title;
  final bool isTop;
  const _SupplyingSuppliersCard({required this.title, required this.isTop});

  @override
  State<_SupplyingSuppliersCard> createState() =>
      _SupplyingSuppliersCardState();
}

class _SupplyingSuppliersCardState extends State<_SupplyingSuppliersCard> {
  List<Map<String, dynamic>> _suppliers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  Future<void> _loadSuppliers() async {
    try {
      // Get current month start and end dates
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1).toIso8601String();
      final monthEnd = DateTime(now.year, now.month + 1, 0).toIso8601String();

      // Fetch all supplier orders for this month
      final orders = await supabase
          .from('supplier_order')
          .select('''
            supplier_id,
            total_cost,
            supplier:supplier_id(name)
          ''')
          .gte('order_date', monthStart)
          .lte('order_date', monthEnd);

      // Group and aggregate by supplier
      final Map<int, Map<String, dynamic>> supplierStats = {};
      for (var order in orders as List) {
        final supplierId = order['supplier_id'] as int;
        final totalCost = (order['total_cost'] as num?)?.toDouble() ?? 0.0;
        final supplierData = order['supplier'] as Map?;
        final supplierName = supplierData?['name']?.toString() ?? '';

        if (!supplierStats.containsKey(supplierId)) {
          supplierStats[supplierId] = {
            'supplier_id': supplierId,
            'supplier_name': supplierName,
            'total_supply': 0.0,
            'num_of_orders': 0,
          };
        }

        supplierStats[supplierId]!['total_supply'] =
            (supplierStats[supplierId]!['total_supply'] as double) + totalCost;
        supplierStats[supplierId]!['num_of_orders'] =
            (supplierStats[supplierId]!['num_of_orders'] as int) + 1;
      }

      // Convert to list and sort by total supply
      final supplierList = supplierStats.values.toList();
      supplierList.sort((a, b) {
        final supplyA = (a['total_supply'] as double);
        final supplyB = (b['total_supply'] as double);
        return widget.isTop
            ? supplyB.compareTo(supplyA)
            : supplyA.compareTo(supplyB);
      });

      final top3 = supplierList.take(3).toList();

      if (!mounted) return;
      setState(() {
        _suppliers = top3;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
      print('Error loading suppliers: $e');
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
              _HeaderText('Supplier Name', flex: 4),
              _HeaderText('Total Supply', flex: 1, color: AppColors.blue),
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
          else if (_suppliers.isEmpty)
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
            ...List.generate(_suppliers.length, (i) {
              final supplier = _suppliers[i];
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
                        supplier['supplier_name']?.toString() ?? 'N/A',
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
                          '\$${(supplier['total_supply'] as double?)?.toStringAsFixed(2) ?? '0.00'}',
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
                          supplier['num_of_orders']?.toString() ?? '0',
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

// 🔹 Supplier Row
class _SupplierRow extends StatefulWidget {
  final int index;
  final String id, name, mobile, location, creditorBalance;
  const _SupplierRow({
    required this.index,
    required this.id,
    required this.name,
    required this.mobile,
    required this.location,
    required this.creditorBalance,
  });

  @override
  State<_SupplierRow> createState() => _SupplierRowState();
}

class _SupplierRowState extends State<_SupplierRow> {
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
            builder: (context) => SupplierDetailDialog(
              supplierId: widget.id,
              supplierName: widget.name,
              mobile: widget.mobile,
              location: widget.location,
              creditorBalance: widget.creditorBalance,
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
                '\$${widget.creditorBalance}',
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
