import 'package:flutter/material.dart';
import 'report_page.dart';

// 🔹 Archive Table
class ArchiveTable extends StatelessWidget {
  const ArchiveTable({super.key});

  @override
  Widget build(BuildContext context) {
    final archiveData = [
      ('26', 'Ahmad Nizar', '1', '12/5/2025'),
      ('27', 'Saed Rimawi', '2', '12/5/2020'),
      ('30', 'Akef Al Asmar', '1', '12/5/2025'),
      ('29', 'Nizar Fares', '1', '12/5/2025'),
      ('31', 'Sameer Haj', '1', '12/2/2025'),
      ('28', 'Eyas Barghouthi', '2', '12/1/2024'),
      ('20', 'Sami jaber', '2', '12/5/2026'),
      ('31', 'Sameer Haj', '1', '12/3/2022'),
      ('28', 'Eyas Barghouthi', '2', '12/5/2020'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 Header with filter button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox.shrink(), // Empty space on left
              // Filter button
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
                    // Filter functionality
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Table
          _ArchiveTableWidget(
            headers: const [
              'Order ID #',
              'Customer Name',
              'Inventory #',
              'Date',
            ],
            rows: archiveData
                .map((row) => [row.$1, row.$2, row.$3, row.$4])
                .toList(),
            columnFlex: const [2, 3, 1, 4], // تقليل المسافة بين أول 3 أعمدة
          ),
        ],
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
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
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
