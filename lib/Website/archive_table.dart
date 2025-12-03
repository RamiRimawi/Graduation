import 'package:flutter/material.dart';
import 'report_page.dart';
import '../supabase_config.dart';

// 🔹 Archive Table
class ArchiveTable extends StatefulWidget {
  final String productId;
  const ArchiveTable({super.key, required this.productId});

  @override
  State<ArchiveTable> createState() => _ArchiveTableState();
}

class _ArchiveTableState extends State<ArchiveTable> {
  List<List<String>> _rows = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadArchiveRows();
  }

  Future<void> _loadArchiveRows() async {
    try {
      await SupabaseConfig.initialize();

      final items = await supabase
          .from('customer_order_description')
          .select(
            'customer_order_id, customer_order:customer_order_id(order_date, customer_id, customer:customer_id(name))',
          )
          .eq('product_id', int.parse(widget.productId));

      final rows = <List<String>>[];
      for (final item in items) {
        final orderId = item['customer_order_id']?.toString() ?? '';
        // Format order_date from customer_order as MM/DD/YYYY like 12/5/2025
        String orderDateStr = '';
        dynamic rawDate;
        if (item['customer_order'] is Map) {
          rawDate = (item['customer_order'] as Map)['order_date'];
        }
        if (rawDate is String && rawDate.isNotEmpty) {
          try {
            final dt = DateTime.parse(rawDate);
            orderDateStr = '${dt.month}/${dt.day}/${dt.year}';
          } catch (_) {
            orderDateStr = rawDate; // fallback
          }
        }
        String customerName = 'Unknown';
        if (item['customer_order'] is Map &&
            item['customer_order']['customer'] is Map) {
          customerName =
              item['customer_order']['customer']['name']?.toString() ??
              'Unknown';
        }
        // Inventory # not available in this relation; show dash
        rows.add([orderId, customerName, '—', orderDateStr]);
      }

      if (mounted) {
        setState(() {
          _rows = rows;
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
        // 🔹 Filter button ABOVE the archive box
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.cardAlt,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(
              Icons.filter_list,
              color: AppColors.blue,
              size: 20,
            ),
            onPressed: () {
              // TODO: Implement filter functionality
            },
          ),
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
                    'Customer Name',
                    'Inventory #',
                    'Date',
                  ],
                  rows: _rows,
                  columnFlex: const [
                    2,
                    3,
                    1,
                    4,
                  ], // تقليل المسافة بين أول 3 أعمدة
                ),
        ),
      ],
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
