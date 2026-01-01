import 'package:flutter/material.dart';
import 'report_page.dart';
import '../../supabase_config.dart';

// 🔹 Archive Table
class ArchiveTable extends StatefulWidget {
  final String productId;
  const ArchiveTable({super.key, required this.productId});

  @override
  State<ArchiveTable> createState() => _ArchiveTableState();
}

class _ArchiveTableState extends State<ArchiveTable> {
  List<List<String>> _rows = [];
  List<List<String>> _filteredRows = [];
  bool _loading = true;
  final TextEditingController _searchController = TextEditingController();

  // Filter variables
  final Set<String> _selectedTypes = {}; // 'In', 'Out'
  String _selectedInventory = '';
  DateTime? _fromDate;
  DateTime? _toDate;
  final GlobalKey _filterButtonKey = GlobalKey();
  OverlayEntry? _filterOverlay;
  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();
  List<String> _inventories = [];
  bool _inventoryExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadArchiveRows();
    _fetchInventories();
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

  Future<void> _loadArchiveRows() async {
    try {
      final rows = <List<String>>[];

      // ✅ Fetch Stock-OUT orders (customer orders)
      final customerItems = await supabase
          .from('customer_order_description')
          .select(
            'customer_order_id, customer_order:customer_order_id(order_date, order_status, customer_id, customer:customer_id(name))',
          )
          .eq('product_id', int.parse(widget.productId));

      // Process customer orders (Stock-OUT)
      for (final item in customerItems) {
        // Only include delivered orders
        if (item['customer_order'] is Map) {
          final orderStatus = item['customer_order']['order_status']
              ?.toString()
              .toLowerCase();
          if (orderStatus != 'delivered') continue;
        }

        final orderId = item['customer_order_id']?.toString() ?? '';
        String orderDateStr = '';
        String customerName = 'Unknown';
        String inventoryName = '—';

        if (item['customer_order'] is Map) {
          final rawDate = item['customer_order']['order_date'];
          if (rawDate is String && rawDate.isNotEmpty) {
            try {
              final dt = DateTime.parse(rawDate);
              orderDateStr = '${dt.month}/${dt.day}/${dt.year}';
            } catch (_) {
              orderDateStr = rawDate;
            }
          }

          if (item['customer_order']['customer'] is Map) {
            customerName =
                item['customer_order']['customer']['name']?.toString() ??
                'Unknown';
          }
        }

        // Fetch inventory for this order
        try {
          final invRows = await supabase
              .from('customer_order_inventory')
              .select('inventory_id')
              .eq('customer_order_id', orderId);

          if (invRows.isNotEmpty) {
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
            if (inventoryNames.isNotEmpty) {
              inventoryName = inventoryNames.join(', ');
            }
          }
        } catch (e) {
          print('Error fetching inventory for customer order $orderId: $e');
        }

        rows.add([orderId, customerName, inventoryName, 'Out', orderDateStr]);
      }

      // ✅ Fetch Stock-IN orders: batch → supplier_order_inventory → supplier_order
      final batchRows = await supabase
          .from('batch')
          .select('batch_id')
          .eq('product_id', int.parse(widget.productId));

      // Collect unique supplier_order_ids from supplier_order_inventory
      final supplierOrderIds = <int>{};
      for (final batch in batchRows) {
        final batchId = batch['batch_id'];
        if (batchId != null) {
          final invRows = await supabase
              .from('supplier_order_inventory')
              .select('supplier_order_id')
              .eq('batch_id', batchId);

          for (var inv in invRows) {
            final soId = inv['supplier_order_id'];
            if (soId is int) supplierOrderIds.add(soId);
          }
        }
      }

      if (supplierOrderIds.isNotEmpty) {
        // Fetch supplier orders by ids
        final supplierOrders = await supabase
            .from('supplier_order')
            .select(
              'order_id, order_date, order_status, supplier:supplier_id(name)',
            )
            .inFilter('order_id', supplierOrderIds.toList());

        for (final order in supplierOrders) {
          final orderStatus = order['order_status']?.toString().toLowerCase();
          if (orderStatus != 'delivered') continue;

          final supplierOrderId = order['order_id'] as int?;
          if (supplierOrderId == null) continue;

          final orderId = supplierOrderId.toString();
          String orderDateStr = '';
          String supplierName = 'Unknown';
          String inventoryName = '—';

          final rawDate = order['order_date'];
          if (rawDate is String && rawDate.isNotEmpty) {
            try {
              final dt = DateTime.parse(rawDate);
              orderDateStr = '${dt.month}/${dt.day}/${dt.year}';
            } catch (_) {
              orderDateStr = rawDate;
            }
          }

          if (order['supplier'] is Map) {
            supplierName = order['supplier']['name']?.toString() ?? 'Unknown';
          }

          // Fetch inventory for this supplier order
          try {
            final invRows = await supabase
                .from('supplier_order_inventory')
                .select('inventory_id')
                .eq('supplier_order_id', supplierOrderId);

            if (invRows.isNotEmpty) {
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
              if (inventoryNames.isNotEmpty) {
                inventoryName = inventoryNames.join(', ');
              }
            }
          } catch (e) {
            print('Error fetching inventory for supplier order $orderId: $e');
          }

          rows.add([orderId, supplierName, inventoryName, 'In', orderDateStr]);
        }
      }

      // Sort by date descending (most recent first)
      rows.sort((a, b) {
        try {
          final dateA = DateTime.parse(a[3].split('/').reversed.join('-'));
          final dateB = DateTime.parse(b[3].split('/').reversed.join('-'));
          return dateB.compareTo(dateA);
        } catch (_) {
          return 0;
        }
      });

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
      print('Error loading archive rows: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 🔹 Search + Filter bar ABOVE the archive box (matches checks_page UI)
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              width: 260,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(40),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.search_rounded,
                    color: AppColors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 13,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Enter Name or Order ID',
                        hintStyle: TextStyle(
                          color: AppColors.grey,
                          fontSize: 13,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
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
        const SizedBox(height: 10),
        // 🔹 Archive box with table
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _ArchiveTableWidget(
                  headers: const [
                    'Order ID #',
                    'Name',
                    'Inventory #',
                    'Type',
                    'Date',
                  ],
                  rows: _filteredRows,
                  columnFlex: const [
                    2,
                    3,
                    3,
                    2,
                    4,
                  ], // تقليل المسافة بين أول 3 أعمدة
                ),
        ),
      ],
    );
  }

  void _filterRows() {
    final q = _searchController.text.trim().toLowerCase();

    List<List<String>> filtered = List.from(_rows);

    // Apply Type filter
    if (_selectedTypes.isNotEmpty) {
      filtered = filtered.where((r) {
        final type = r.length > 3 ? r[3] : '';
        return _selectedTypes.contains(type);
      }).toList();
    }

    // Apply Inventory filter
    if (_selectedInventory.isNotEmpty) {
      filtered = filtered.where((r) {
        final inventory = r.length > 2 ? r[2].toLowerCase() : '';
        return inventory.contains(_selectedInventory.toLowerCase());
      }).toList();
    }

    // Apply Date range filter
    if (_fromDate != null || _toDate != null) {
      filtered = filtered.where((r) {
        try {
          final dateStr = r.length > 4 ? r[4] : '';
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

    // Apply search filter
    if (q.isNotEmpty) {
      filtered = filtered.where((r) {
        final orderId = r.isNotEmpty ? r[0].toLowerCase() : '';
        final name = r.length > 1 ? r[1].toLowerCase() : '';
        return orderId.startsWith(q) || name.startsWith(q);
      }).toList();
    }

    setState(() => _filteredRows = filtered);
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

                        // Type filter (checkboxes)
                        Text(
                          'Type',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(children: _buildTypeCheckboxes(setOverlayState)),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: () {
                                setOverlayState(() {
                                  _inventoryExpanded = !_inventoryExpanded;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF232427),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColors.blue,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _selectedInventory.isEmpty
                                            ? 'Any inventory'
                                            : _selectedInventory,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      _inventoryExpanded
                                          ? Icons.expand_less
                                          : Icons.expand_more,
                                      color: AppColors.blue,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (_inventoryExpanded)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                constraints: const BoxConstraints(
                                  maxHeight: 200,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF232427),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColors.blue,
                                    width: 1,
                                  ),
                                ),
                                child: ListView(
                                  shrinkWrap: true,
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        setState(() => _selectedInventory = '');
                                        _filterRows();
                                        setOverlayState(() {
                                          _inventoryExpanded = false;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        child: Text(
                                          'Any inventory',
                                          style: TextStyle(
                                            color: _selectedInventory.isEmpty
                                                ? AppColors.blue
                                                : Colors.white,
                                            fontSize: 14,
                                            fontWeight:
                                                _selectedInventory.isEmpty
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    ),
                                    ..._inventories.map((inv) {
                                      final isSelected =
                                          _selectedInventory == inv;
                                      return InkWell(
                                        onTap: () {
                                          setState(
                                            () => _selectedInventory = inv,
                                          );
                                          _filterRows();
                                          setOverlayState(() {
                                            _inventoryExpanded = false;
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                          child: Text(
                                            inv,
                                            style: TextStyle(
                                              color: isSelected
                                                  ? AppColors.blue
                                                  : Colors.white,
                                              fontSize: 14,
                                              fontWeight: isSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // From Date
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

                        // To Date
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
                                  _selectedTypes.clear();
                                  _selectedInventory = '';
                                  _fromDate = null;
                                  _toDate = null;
                                  _filterRows();
                                });
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

  List<Widget> _buildTypeCheckboxes(StateSetter setOverlayState) {
    final types = ['In', 'Out'];
    return types.map((type) {
      final isSelected = _selectedTypes.contains(type);
      return Expanded(
        child: InkWell(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedTypes.remove(type);
              } else {
                _selectedTypes.add(type);
              }
              _filterRows();
            });
            setOverlayState(() {});
          },
          child: Row(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.blue : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? AppColors.blue : Colors.white54,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: isSelected
                    ? const Center(
                        child: Icon(Icons.check, size: 14, color: Colors.black),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                type,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  void _closeFilterPopup() {
    _filterOverlay?.remove();
    _filterOverlay = null;
  }
}

// 🔹 Round Icon Button (same UI as checks_page.dart)
class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  // ignore: unused_element_parameter
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

  const _ArchiveTableWidget({
    required this.headers,
    required this.rows,
    this.columnFlex,
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
                  final isLast = index == headers.length - 1; // Date column
                  final flex = columnFlex != null && index < columnFlex!.length
                      ? columnFlex![index]
                      : 1;
                  return Expanded(
                    flex: flex,
                    child: Align(
                      alignment: isLast
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Text(
                        header,
                        style: TextStyle(
                          color: isLast ? AppColors.blue : AppColors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 6),
              // White line under header
              Container(
                height: 2,
                width: double.infinity,
                color: AppColors.white.withOpacity(0.2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Data rows with alternating backgrounds
        ...rows.asMap().entries.map((entry) {
          final index = entry.key;
          final row = entry.value;
          return _ArchiveTableRow(
            key: ValueKey(index),
            cells: row,
            isEven: index % 2 == 0,
            columnFlex: columnFlex,
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

  const _ArchiveTableRow({
    super.key,
    required this.cells,
    required this.isEven,
    this.columnFlex,
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
            final isLast = index == widget.cells.length - 1; // Date column
            final flex =
                widget.columnFlex != null && index < widget.columnFlex!.length
                ? widget.columnFlex![index]
                : 1;

            return Expanded(
              flex: flex,
              child: Align(
                alignment: isLast
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Text(
                  cell,
                  style: TextStyle(
                    color: isLast ? AppColors.blue : AppColors.white,
                    fontSize: 13,
                    fontWeight: isLast ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
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
