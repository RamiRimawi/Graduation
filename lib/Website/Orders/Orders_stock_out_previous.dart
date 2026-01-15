import 'package:flutter/material.dart';
import '../../supabase_config.dart';
import '../sidebar.dart';
import 'Orders_stock_in_page.dart';
import 'Orders_stock_out_page.dart'; // عشان نرجع لصفحة Today
import 'Orders_stock_out_receives.dart'; // عشان نروح لصفحة Receives
import 'Orders_create_stock_out_page.dart';
import 'Orders_stock_out_previous_popup.dart'; // Popup for order details
import 'orders_header.dart';

// 🎨 الألوان نفس الباليت
class AppColors {
  static const white = Color(0xFFFFFFFF);
  static const gold = Color(0xFFB7A447);
  static const bgDark = Color(0xFF202020);
  static const card = Color(0xFF2D2D2D);
  static const cardAlt = Color(0xFF262626);
  static const divider = Color(0xFF6F6F6F);
  static const blue = Color(0xFF50B2E7);
}

class OrderPreviousRow {
  final String id;
  final String customerName;
  final String deliveryDriver;
  final String date;
  OrderPreviousRow({
    required this.id,
    required this.customerName,
    required this.deliveryDriver,
    required this.date,
  });
}

class StockOutPrevious extends StatefulWidget {
  const StockOutPrevious({super.key});

  @override
  State<StockOutPrevious> createState() => _StockOutPreviousState();
}

class _StockOutPreviousState extends State<StockOutPrevious> {
  int stockTab = 0; // Stock-out selected
  int currentTab = 2; // Previous tab selected
  int? hoveredRow;
  bool _loading = true;
  String? _error;
  List<OrderPreviousRow> _previousOrders = [];
  List<String> _drivers = [];
  String _searchQuery = '';
  String _selectedDriver = '';
  DateTime? _fromDate;
  DateTime? _toDate;
  final GlobalKey _filterButtonKey = GlobalKey();
  OverlayEntry? _filterOverlay;
  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();
  bool _isDriverDropdownExpanded = false;

  @override
  void initState() {
    super.initState();
    _fetchPreviousOrders();
    _fetchDrivers();
  }

  @override
  void dispose() {
    _filterOverlay?.remove();
    _filterOverlay = null;
    _fromDateController.dispose();
    _toDateController.dispose();
    super.dispose();
  }

  Future<void> _fetchPreviousOrders() async {
    try {
      // Fetch orders with status 'Delivered'
      final data = await supabase
          .from('customer_order')
          .select('''
            customer_order_id,
            order_date,
            customer:customer_id(name),
            delivery_driver:delivered_by_id(name)
          ''')
          .eq('order_status', 'Delivered')
          .order('order_date', ascending: false);

      final ordersList = <OrderPreviousRow>[];

      for (int i = 0; i < data.length; i++) {
        final row = data[i];
        final orderId = (row['customer_order_id'] ?? '').toString();
        final customerName = (row['customer'] is Map)
            ? (row['customer']['name'] ?? 'Unknown')
            : 'Unknown';

        final deliveryDriverName = (row['delivery_driver'] is Map)
            ? (row['delivery_driver']['name'] ?? 'N/A')
            : 'N/A';

        final orderDate = row['order_date'] != null
            ? DateTime.parse(row['order_date'])
            : DateTime.now();
        final date = '${orderDate.day}/${orderDate.month}/${orderDate.year}';

        ordersList.add(
          OrderPreviousRow(
            id: orderId,
            customerName: customerName,
            deliveryDriver: deliveryDriverName,
            date: date,
          ),
        );

        // Update UI every 10 rows or on last row for smooth progressive loading
        if ((i + 1) % 10 == 0 || i == data.length - 1) {
          if (!mounted) return;
          setState(() {
            _previousOrders = List.from(ordersList);
            _loading = false;
            _error = null;
          });
          // Small delay to allow UI to update
          await Future.delayed(const Duration(milliseconds: 10));
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _fetchDrivers() async {
    try {
      final data = await supabase
          .from('delivery_driver')
          .select('name')
          .order('name');

      final names = <String>[];
      for (final row in data) {
        final name = (row['name'] ?? '').toString().trim();
        if (name.isNotEmpty) {
          names.add(name);
        }
      }

      final unique = names.toSet().toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

      if (!mounted) return;
      setState(() {
        _drivers = unique;
      });
    } catch (e) {
      // If drivers fail to load, keep the list empty and allow Any driver option
      debugPrint('Error loading drivers: $e');
    }
  }

  List<OrderPreviousRow> get _filteredOrders {
    Iterable<OrderPreviousRow> filtered = _previousOrders;

    // Driver filter
    if (_selectedDriver.isNotEmpty) {
      filtered = filtered.where(
        (o) => o.deliveryDriver.toLowerCase() == _selectedDriver.toLowerCase(),
      );
    }

    // Date range filter
    if (_fromDate != null || _toDate != null) {
      filtered = filtered.where((o) {
        final parsed = _parseDate(o.date);
        if (parsed == null) return false;
        if (_fromDate != null && parsed.isBefore(_fromDate!)) return false;
        if (_toDate != null && parsed.isAfter(_toDate!)) return false;
        return true;
      });
    }

    // Search by customer name
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where(
        (o) => o.customerName.toLowerCase().startsWith(q),
      );
    }

    return filtered.toList(growable: false);
  }

  List<String> get _driverNames {
    return _drivers;
  }

  DateTime? _parseDate(String dateStr) {
    try {
      final parts = dateStr.split('/');
      if (parts.length != 3) return null;
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      return DateTime(year, month, day);
    } catch (_) {
      return null;
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
                      color: const Color(0xFF2D2D2D),
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

                        // Driver dropdown
                        Text(
                          'Delivery Driver',
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
                                  _isDriverDropdownExpanded =
                                      !_isDriverDropdownExpanded;
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
                                        _selectedDriver.isEmpty
                                            ? 'Any driver'
                                            : _selectedDriver,
                                        style: TextStyle(
                                          color: _selectedDriver.isEmpty
                                              ? Colors.white54
                                              : Colors.white,
                                          fontSize: 14,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Icon(
                                      _isDriverDropdownExpanded
                                          ? Icons.expand_less
                                          : Icons.expand_more,
                                      color: AppColors.gold,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (_isDriverDropdownExpanded) ...[
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
                                    _buildDriverItem(
                                      '',
                                      'Any driver',
                                      setOverlayState,
                                      isDefault: true,
                                    ),
                                    ..._driverNames.map(
                                      (name) => _buildDriverItem(
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
                            setState(() {
                              _fromDate = date;
                            });
                            setOverlayState(() {});
                          },
                          onClear: () {
                            _fromDateController.clear();
                            setState(() {
                              _fromDate = null;
                            });
                            setOverlayState(() {});
                          },
                        ),

                        const SizedBox(height: 16),

                        // To Date
                        _DateInputField(
                          label: 'To Date',
                          controller: _toDateController,
                          onDateChanged: (date) {
                            setState(() {
                              _toDate = date;
                            });
                            setOverlayState(() {});
                          },
                          onClear: () {
                            _toDateController.clear();
                            setState(() {
                              _toDate = null;
                            });
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
                                  _selectedDriver = '';
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
    _isDriverDropdownExpanded = false;
  }

  Widget _buildDriverItem(
    String value,
    String label,
    StateSetter setOverlayState, {
    bool isDefault = false,
  }) {
    final isSelected = _selectedDriver == value;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedDriver = value;
          _isDriverDropdownExpanded = false;
        });
        setOverlayState(() {
          _isDriverDropdownExpanded = false;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.gold.withValues(alpha: 0.1)
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
    final topPadding = height * 0.02;

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
                    // 🔹 HEADER
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: width > 800 ? 60 : 24,
                      ),
                      child: OrdersHeader(
                        stockTab: stockTab,
                        currentTab: currentTab,
                        onStockTabChanged: (i) {
                          if (i == 1) {
                            // الانتقال إلى Stock-in
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const StockInPage(),
                              ),
                            );
                          } else {
                            setState(() => stockTab = i);
                          }
                        },
                        onTabChanged: (index) {
                          setState(() => currentTab = index);
                          if (index == 0) {
                            // Today
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const OrdersPage(),
                              ),
                            );
                          } else if (index == 1) {
                            // Receives
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const OrdersReceivesPage(),
                              ),
                            );
                          }
                        },
                        onCreateOrder: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CreateStockOutPage(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 🔹 Tabs + Table
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: width > 800 ? 60 : 24,
                        ),
                        child: Column(
                          children: [
                            // 🔹 البحث + فلتر
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                SizedBox(
                                  width: 250,
                                  child: _SearchField(
                                    hint: 'Customer Name',
                                    onChanged: (v) {
                                      setState(() {
                                        _searchQuery = v.trim();
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
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

                            _TableHeader(isWide: width > 800),
                            const SizedBox(height: 6),

                            // 🔹 الجدول
                            Expanded(
                              child: _loading
                                  ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  : _error != null
                                  ? Center(
                                      child: Text(
                                        _error!,
                                        style: const TextStyle(
                                          color: Colors.redAccent,
                                        ),
                                      ),
                                    )
                                  : ListView.separated(
                                      itemCount: _filteredOrders.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(height: 6),
                                      itemBuilder: (context, i) {
                                        final row = _filteredOrders[i];
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
                                            onTap: () {
                                              showDialog(
                                                context: context,
                                                builder: (context) =>
                                                    OrderDetailsPopup(
                                                      orderId: row.id,
                                                    ),
                                              );
                                            },
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
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
                                                  // Order ID
                                                  Expanded(
                                                    flex: 2,
                                                    child: Text(
                                                      row.id,
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                      ),
                                                    ),
                                                  ),

                                                  // Customer Name
                                                  Expanded(
                                                    flex: 4,
                                                    child: Text(
                                                      row.customerName,
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),

                                                  // Delivery Driver
                                                  Expanded(
                                                    flex: 8,
                                                    child: Align(
                                                      alignment:
                                                          Alignment.centerLeft,
                                                      child: Text(
                                                        row.deliveryDriver,
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                      ),
                                                    ),
                                                  ),

                                                  // Date (ذهبي)
                                                  Expanded(
                                                    flex: 4,
                                                    child: Align(
                                                      alignment:
                                                          Alignment.centerRight,
                                                      child: Text(
                                                        row.date,
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

// 🔹 حقل البحث
class _SearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String>? onChanged;
  const _SearchField({required this.hint, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.group_outlined, size: 18),
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
          borderSide: const BorderSide(color: Color(0xFFB7A447), width: 1.2),
        ),
      ),
    );
  }
}

// 🔹 زر الفلتر
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

// 🔹 هيدر الجدول (Order ID / Customer / Inventory / Date)
class _TableHeader extends StatelessWidget {
  final bool isWide;
  const _TableHeader({required this.isWide});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _hCell('Order ID #', flex: 2),
            _hCell('Customer Name', flex: 4),
            _hCell('Delivery Driver', flex: 8),
            _hCell('Date', flex: 4, alignEnd: true),
          ],
        ),
        const SizedBox(height: 8),
        Container(height: 1, color: AppColors.divider.withValues(alpha: .5)),
      ],
    );
  }

  Expanded _hCell(String text, {int flex = 1, bool alignEnd = false}) {
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
