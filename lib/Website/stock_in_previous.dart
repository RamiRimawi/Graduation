import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'Orders_stock_in_previous_popup.dart';
import 'sidebar.dart';
import 'stock_out_page.dart';
import 'stock_in_page.dart';
import 'stock_in_receives.dart';
import 'create_stock_in_page.dart';
import '../supabase_config.dart';
import 'dart:ui' as ui;

// 🔹 Round Icon Button (matches other order pages)
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
        color: AppColors.card,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 20, color: AppColors.gold),
          ),
        ),
      ),
    );
  }
}

// 🔹 Search Field widget (matches other order pages)
class _SearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String>? onChanged;
  const _SearchField({required this.hint, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      style: const TextStyle(fontSize: 13, color: AppColors.white),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.gold),
        filled: true,
        fillColor: AppColors.card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.2),
        ),
      ),
    );
  }
}

class AppColors {
  static const white = Color(0xFFFFFFFF);
  static const gold = Color(0xFFB7A447);
  static const bgDark = Color(0xFF202020);
  static const card = Color(0xFF2D2D2D);
  static const cardAlt = Color(0xFF262626);
  static const divider = Color(0xFF6F6F6F);
  static const blue = Color(0xFF50B2E7);
}

class StockInPreviousPage extends StatefulWidget {
  const StockInPreviousPage({super.key});

  @override
  State<StockInPreviousPage> createState() => _StockInPreviousPageState();
}

class _StockInPreviousPageState extends State<StockInPreviousPage> {
  int stockTab = 1; // ✅ Stock-in selected
  int currentTab = 2; // ✅ Previous tab selected
  int? hoveredRow;

  List<Map<String, dynamic>> allOrders = [];
  List<Map<String, dynamic>> filteredOrders = [];
  bool isLoading = true;
  String searchQuery = '';

  // Filter variables
  String _selectedInventory = '';
  DateTime? _fromDate;
  DateTime? _toDate;
  final GlobalKey _filterButtonKey = GlobalKey();
  OverlayEntry? _filterOverlay;
  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();
  List<String> _inventories = [];
  bool _isInventoryDropdownExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadPreviousOrders();
    _fetchInventories();
  }

  @override
  void dispose() {
    _filterOverlay?.remove();
    _filterOverlay = null;
    _fromDateController.dispose();
    _toDateController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _loadPreviousOrders() async {
    setState(() => isLoading = true);

    try {
      // Query for Previous tab: Rejected (all days), Delivered
      final ordersResponse = await supabase
          .from('supplier_order')
          .select('''
            order_id,
            supplier_id,
            order_date,
            order_status,
            receives_by_id,
            supplier:supplier_id (
              name
            )
          ''')
          .or('order_status.eq.Rejected,order_status.eq.Delivered')
          .order('order_date', ascending: false);

      final orders = (ordersResponse as List).cast<Map<String, dynamic>>();

      // Get inventory names for delivered orders, null for rejected
      for (var order in orders) {
        if (order['order_status'] == 'Delivered') {
          try {
            // Get all inventory_ids for this order
            final invRows = await supabase
                .from('supplier_order_inventory')
                .select('inventory_id')
                .eq('supplier_order_id', order['order_id']);

            if (invRows != null && invRows is List && invRows.isNotEmpty) {
              // Get all inventory names, deduplicated
              Set<String> inventoryNames = {};
              for (var inv in invRows) {
                if (inv['inventory_id'] != null) {
                  final invInfo = await supabase
                      .from('inventory')
                      .select('inventory_name')
                      .eq('inventory_id', inv['inventory_id'])
                      .maybeSingle();
                  if (invInfo != null && invInfo['inventory_name'] != null) {
                    inventoryNames.add(invInfo['inventory_name']);
                  }
                }
              }
              order['inventory_name'] = inventoryNames.isNotEmpty
                  ? inventoryNames.join(', ')
                  : null;
            } else {
              order['inventory_name'] = null;
            }
          } catch (e) {
            // Error fetching inventory for order
            order['inventory_name'] = null;
          }
        } else if (order['order_status'] == 'Rejected') {
          order['inventory_name'] = null;
        }
      }

      if (!mounted) return;
      setState(() {
        allOrders = orders;
        filteredOrders = orders;
        isLoading = false;
      });
    } catch (e) {
      // Error loading previous orders
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchInventories() async {
    try {
      final data = await supabase
          .from('inventory')
          .select('inventory_name')
          .order('inventory_name');

      final names = <String>[];
      for (final row in data) {
        final name = (row['inventory_name'] ?? '').toString().trim();
        if (name.isNotEmpty) {
          names.add(name);
        }
      }

      final unique = names.toSet().toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

      setState(() {
        _inventories = unique;
      });
    } catch (e) {
      debugPrint('Error loading inventories: $e');
    }
  }

  void _filterOrders(String query) {
    setState(() {
      searchQuery = query;
    });
  }

  List<Map<String, dynamic>> get _filteredOrders {
    Iterable<Map<String, dynamic>> filtered = allOrders;

    // Inventory filter
    if (_selectedInventory.isNotEmpty) {
      filtered = filtered.where((order) {
        final inventories = order['inventory_name'] as String?;
        return inventories != null && inventories.contains(_selectedInventory);
      });
    }

    // Date range filter
    if (_fromDate != null || _toDate != null) {
      filtered = filtered.where((order) {
        final parsed = DateTime.parse(order['order_date']);
        if (_fromDate != null && parsed.isBefore(_fromDate!)) return false;
        if (_toDate != null) {
          final toDateEnd = DateTime(
            _toDate!.year,
            _toDate!.month,
            _toDate!.day,
            23,
            59,
            59,
            999,
          );
          if (parsed.isAfter(toDateEnd)) return false;
        }
        return true;
      });
    }

    // Search by supplier name
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      filtered = filtered.where((order) {
        final supplierName =
            order['supplier']['name']?.toString().toLowerCase() ?? '';
        return supplierName.startsWith(q);
      });
    }

    return filtered.toList(growable: false);
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
                      border: Border.all(color: AppColors.gold, width: 1.5),
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
                          'Filter Orders',
                          style: TextStyle(
                            color: AppColors.gold,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Divider(color: Color(0xFF3D3D3D), height: 1),
                        const SizedBox(height: 16),

                        // Inventory dropdown
                        Text(
                          'Inventory Name',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () {
                                setOverlayState(() {
                                  _isInventoryDropdownExpanded =
                                      !_isInventoryDropdownExpanded;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF232427),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColors.gold,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _selectedInventory.isEmpty
                                            ? 'Any inventory'
                                            : _selectedInventory,
                                        style: TextStyle(
                                          color: _selectedInventory.isEmpty
                                              ? Colors.white54
                                              : Colors.white,
                                          fontSize: 14,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Icon(
                                      _isInventoryDropdownExpanded
                                          ? Icons.expand_less
                                          : Icons.expand_more,
                                      color: AppColors.gold,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (_isInventoryDropdownExpanded) ...[
                              const SizedBox(height: 4),
                              Container(
                                constraints: const BoxConstraints(
                                  maxHeight: 200,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF232427),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColors.gold,
                                    width: 1,
                                  ),
                                ),
                                child: ListView(
                                  shrinkWrap: true,
                                  padding: EdgeInsets.zero,
                                  children: [
                                    _buildInventoryItem(
                                      '',
                                      'Any inventory',
                                      setOverlayState,
                                      isDefault: true,
                                    ),
                                    ..._inventories.map(
                                      (name) => _buildInventoryItem(
                                        name,
                                        name,
                                        setOverlayState,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 16),

                        // From Date
                        _DateInputField(
                          label: 'From Date',
                          controller: _fromDateController,
                          onDateChanged: (date) {
                            setState(() => _fromDate = date);
                            setOverlayState(() {});
                          },
                          onClear: () {
                            _fromDateController.clear();
                            setState(() => _fromDate = null);
                            setOverlayState(() {});
                          },
                        ),

                        const SizedBox(height: 16),

                        // To Date
                        _DateInputField(
                          label: 'To Date',
                          controller: _toDateController,
                          onDateChanged: (date) {
                            setState(() => _toDate = date);
                            setOverlayState(() {});
                          },
                          onClear: () {
                            _toDateController.clear();
                            setState(() => _toDate = null);
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
                                  _selectedInventory = '';
                                });
                                setOverlayState(() {});
                              },
                              child: const Text(
                                'Clear Filter',
                                style: TextStyle(
                                  color: AppColors.gold,
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
    _isInventoryDropdownExpanded = false;
  }

  Widget _buildInventoryItem(
    String value,
    String label,
    StateSetter setOverlayState, {
    bool isDefault = false,
  }) {
    final isSelected = _selectedInventory == value;
    return InkWell(
      onTap: () {
        setState(() => _selectedInventory = value);
        setOverlayState(() {
          _isInventoryDropdownExpanded = false;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.gold.withOpacity(0.1)
              : Colors.transparent,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? AppColors.gold
                : (isDefault ? Colors.white54 : Colors.white),
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    final topPadding = height * 0.06;

    return Scaffold(
      body: Row(
        children: [
          const Sidebar(activeIndex: 1),
          Expanded(
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.only(top: topPadding),
                child: Column(
                  children: [
                    // 🔹 العنوان + التوغّل + Create order
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: width > 800 ? 60 : 24,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Orders',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          Row(
                            children: [
                              _StockToggle(
                                selected: stockTab,
                                onChanged: (i) {
                                  if (i == 0) {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const OrdersPage(),
                                      ),
                                    );
                                  } else {
                                    setState(() => stockTab = i);
                                  }
                                },
                              ),
                              const SizedBox(width: 16),
                              _CreateOrderButton(
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const CreateStockInPage(),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 12),
                              // 🔔 زر الإشعارات
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Material(
                                    color: Colors.transparent,
                                    shape: const CircleBorder(),
                                    child: InkWell(
                                      onTap: () {
                                        // TODO: ممكن تضيف صفحة Notifications هنا لو حاب
                                      },
                                      customBorder: const CircleBorder(),
                                      child: const Padding(
                                        padding: EdgeInsets.all(8),
                                        child: Icon(
                                          Icons.notifications_none_rounded,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    right: 6,
                                    top: 6,
                                    child: Container(
                                      width: 7,
                                      height: 7,
                                      decoration: const BoxDecoration(
                                        color: AppColors.blue, // 🔹 لون النقطة
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 🔹 Tabs + Search/Filter + Table
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: width > 800 ? 60 : 24,
                        ),
                        child: Column(
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: _TopTabs(
                                current: currentTab,
                                onTap: (index) {
                                  setState(() => currentTab = index);

                                  if (index == 0) {
                                    // Today  -> صفحة Stock-in العادية
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const StockInPage(),
                                      ),
                                    );
                                  } else if (index == 1) {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const OrdersStockInReceivesPage(),
                                      ),
                                    );
                                  } else {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const StockInPage(),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            // --- Search field and filter button (matches other orders pages) ---
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 250,
                                  child: _SearchField(
                                    hint: 'Supplier Name',
                                    onChanged: _filterOrders,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  key: _filterButtonKey,
                                  child: _RoundIconButton(
                                    icon: Icons.filter_alt_rounded,
                                    onTap: _toggleFilterPopup,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const _TableHeader(),
                            const SizedBox(height: 6),

                            // 🔹 جدول الطلبات
                            Expanded(
                              child: isLoading
                                  ? const Center(
                                      child: CircularProgressIndicator(
                                        color: AppColors.blue,
                                      ),
                                    )
                                  : filteredOrders.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'No previous orders found',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 16,
                                        ),
                                      ),
                                    )
                                  : ListView.separated(
                                      itemCount: _filteredOrders.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(height: 6),
                                      itemBuilder: (context, i) {
                                        final order = _filteredOrders[i];
                                        final orderId = order['order_id']
                                            .toString();
                                        final supplierName =
                                            order['supplier']['name'] ??
                                            'Unknown';
                                        final inventoryName =
                                            order['inventory_name'] ?? '-';
                                        final orderDate = DateTime.parse(
                                          order['order_date'],
                                        );
                                        final date = _formatDate(orderDate);
                                        final bg = i.isEven
                                            ? AppColors.card
                                            : AppColors.cardAlt;
                                        final isHovered = hoveredRow == i;

                                        return MouseRegion(
                                          onEnter: (_) =>
                                              setState(() => hoveredRow = i),
                                          onExit: (_) =>
                                              setState(() => hoveredRow = null),
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                            onTap: () {
                                              showDialog(
                                                context: context,
                                                builder: (_) =>
                                                    OrdersStockInPreviousPopup(
                                                      orderId: orderId,
                                                    ),
                                              );
                                            },
                                            child: AnimatedContainer(
                                              duration: const Duration(
                                                milliseconds: 200,
                                              ),
                                              decoration: BoxDecoration(
                                                color: bg,
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                                border: isHovered
                                                    ? Border.all(
                                                        color: AppColors.blue,
                                                        width: 2,
                                                      )
                                                    : null,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 12,
                                                  ),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    flex: 2,
                                                    child: Text(
                                                      orderId,
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 4,
                                                    child: Text(
                                                      supplierName,
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 8,
                                                    child: Align(
                                                      alignment:
                                                          Alignment.centerLeft,
                                                      child: Text(
                                                        inventoryName,
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 3,
                                                    child: Align(
                                                      alignment:
                                                          Alignment.centerRight,
                                                      child: Text(
                                                        date,
                                                        style: const TextStyle(
                                                          color: AppColors.gold,
                                                          fontSize: 15,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                      ),
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

// 🔹 هيدر الجدول (Order / Supplier / Inventory / Date)
class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: const [
            _HeaderCell(text: 'Order ID #', flex: 2),
            _HeaderCell(text: 'Supplier Name', flex: 4),
            _HeaderCell(text: 'Inventory ', flex: 8),
            _HeaderCell(text: 'Date', flex: 3, alignEnd: true),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 1,
          color: AppColors.divider.withAlpha((.5 * 255).toInt()),
        ),
      ],
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final int flex;
  final bool alignEnd;
  const _HeaderCell({
    required this.text,
    required this.flex,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Align(
        alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// Popup for order details (matching Orders_stock_out_previous_popup.dart)
class _OrderDetailsPopup extends StatefulWidget {
  final String orderId;
  const _OrderDetailsPopup({Key? key, required this.orderId}) : super(key: key);

  @override
  State<_OrderDetailsPopup> createState() => _OrderDetailsPopupState();
}

class _OrderDetailsPopupState extends State<_OrderDetailsPopup> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _orderData;
  List<Map<String, dynamic>> _products = [];

  @override
  void initState() {
    super.initState();
    _fetchOrderDetails();
  }

  Future<void> _fetchOrderDetails() async {
    try {
      final orderIdInt = int.tryParse(widget.orderId) ?? 0;
      // Fetch order main details with all related data
      final orderResponse = await supabase
          .from('supplier_order')
          .select('''
            order_id,
            order_date,
            delivered_date,
            order_status,
            receives_by_id,
            supplier:supplier_id(name),
            storage_staff:receives_by_id(name),
            inventory: supplier_order_inventory:supplier_order_id (
              inventory_id,
              inventory:inventory_id(inventory_name)
            )
          ''')
          .eq('order_id', orderIdInt)
          .single();

      // Fetch inventory breakdown from supplier_order_inventory
      final inventoryData = await supabase
          .from('supplier_order_inventory')
          .select('''
            inventory_id,
            batch_id,
            quantity,
            inventory:inventory_id(inventory_name)
          ''')
          .eq('supplier_order_id', orderIdInt);

      setState(() {
        _orderData = orderResponse;
        _products = inventoryData;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.7,
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 700),
        decoration: BoxDecoration(
          color: AppColors.bgDark,
          borderRadius: BorderRadius.circular(20),
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              )
            : _buildOrderContent(),
      ),
    );
  }

  Widget _buildOrderContent() {
    if (_orderData == null) return const SizedBox();
    final supplier = _orderData!['supplier'] as Map?;
    final storageStaff = _orderData!['storage_staff'] as Map?;
    final orderDate = _orderData!['order_date'] != null
        ? DateTime.parse(_orderData!['order_date'])
        : null;
    final deliveredDate = _orderData!['delivered_date'] != null
        ? DateTime.parse(_orderData!['delivered_date'])
        : null;
    final status = _orderData!['order_status'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.bgDark,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Details',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Order #${widget.orderId}',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.gold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
              ),
            ],
          ),
        ),
        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle('Supplier & Order Information'),
                            const SizedBox(height: 12),
                            _buildInfoGrid([
                              _InfoItem(
                                'Supplier Name',
                                supplier?['name'] ?? 'N/A',
                                icon: Icons.person,
                              ),
                              _InfoItem(
                                'Order Date',
                                orderDate != null
                                    ? '${orderDate.day}/${orderDate.month}/${orderDate.year}'
                                    : 'N/A',
                                icon: Icons.calendar_today,
                              ),
                              _InfoItem(
                                'Delivered Date',
                                deliveredDate != null
                                    ? '${deliveredDate.day}/${deliveredDate.month}/${deliveredDate.year}'
                                    : 'N/A',
                                icon: Icons.check_circle,
                              ),
                              _InfoItem(
                                'Status',
                                status,
                                icon: Icons.info_outline,
                              ),
                            ]),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle('Staff Information'),
                            const SizedBox(height: 12),
                            _buildInfoGrid([
                              _InfoItem(
                                'Received By',
                                storageStaff?['name'] ?? 'N/A',
                                icon: Icons.inventory_2,
                              ),
                            ]),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('Inventories (${_products.length})'),
                const SizedBox(height: 12),
                ..._products.map((inv) => _buildInventoryCard(inv)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );
  }

  Widget _buildInfoGrid(List<_InfoItem> items) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: items.map((item) {
        return SizedBox(
          width: (MediaQuery.of(context).size.width * 0.7 - 72) / 2,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(item.icon, color: AppColors.blue, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.white.withOpacity(0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.value,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: item.valueColor ?? Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInventoryCard(Map<String, dynamic> inv) {
    final inventory = inv['inventory'] as Map?;
    final inventoryName = inventory?['inventory_name'] ?? 'Unknown';
    final quantity = inv['quantity'] ?? 0;
    final batchId = inv['batch_id'];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  inventoryName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildInventoryDetail(
                'Quantity',
                '$quantity units',
                Icons.shopping_cart,
              ),
              const SizedBox(width: 16),
              if (batchId != null)
                _buildInventoryDetail(
                  'Batch',
                  '$batchId',
                  Icons.confirmation_number,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryDetail(String label, String value, IconData icon) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.white.withOpacity(0.5)),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.white.withOpacity(0.5),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// 🔹 Date input with auto-format (DD/MM/YYYY)
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
              color: _errorText != null ? Colors.red : AppColors.gold,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today, color: AppColors.gold, size: 16),
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

// 🔹 Stock-out / Stock-in toggle
class _StockToggle extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;
  const _StockToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: ShapeDecoration(
        color: const Color(0xFF1B1B1B),
        shape: StadiumBorder(
          side: BorderSide(color: AppColors.gold.withAlpha((.5 * 255).toInt())),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _pill(
            context,
            'Stock-out',
            Icons.logout_rounded,
            selected == 0,
            () => onChanged(0),
          ),
          _pill(
            context,
            'Stock-in',
            Icons.login_rounded,
            selected == 1,
            () => onChanged(1),
          ),
        ],
      ),
    );
  }

  Widget _pill(
    BuildContext ctx,
    String label,
    IconData icon,
    bool selected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: ShapeDecoration(
          color: selected ? AppColors.card : Colors.transparent,
          shape: const StadiumBorder(),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.white),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// 🔹 زر Create order (نفس زر Stock-out)
class _CreateOrderButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _CreateOrderButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const ShapeDecoration(
        shape: StadiumBorder(),
        gradient: LinearGradient(
          colors: [Color(0xFFFFE14D), Color(0xFFFFE14D)],
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onPressed,
          customBorder: const StadiumBorder(),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Row(
              children: [
                Icon(Icons.add_box_rounded, color: Colors.black87),
                SizedBox(width: 8),
                Text(
                  'Create order',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 🔹 تبويبات Today / Updated / Previous بنفس الستايل
class _TopTabs extends StatelessWidget {
  final int current;
  final ValueChanged<int> onTap;
  const _TopTabs({required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const tabs = ['Today', 'Receives', 'Previous'];

    return Row(
      children: List.generate(tabs.length, (i) {
        final active = current == i;
        return Padding(
          padding: const EdgeInsets.only(right: 22),
          child: InkWell(
            onTap: () => onTap(i),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tabs[i],
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white.withAlpha(
                      ((active ? 1 : .7) * 255).toInt(),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  height: 3,
                  width: active ? _textWidth(tabs[i], context) : 0,
                  decoration: BoxDecoration(
                    color: active ? AppColors.blue : Colors.transparent,
                    borderRadius: const BorderRadius.all(Radius.circular(4)),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  double _textWidth(String text, BuildContext context) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
      maxLines: 1,
      textDirection: ui.TextDirection.ltr,
    )..layout();
    return textPainter.width;
  }
}

class _InfoItem {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;
  _InfoItem(this.label, this.value, {required this.icon, this.valueColor});
}
