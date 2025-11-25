import 'package:flutter/material.dart';
import 'report_page.dart';
import 'archive_table.dart';

// ============================================================================
// 🔹 Product Detail Dialog (Popup)
// ============================================================================

class ProductDetailDialog extends StatefulWidget {
  final String productId;
  final String productName;
  final String brand;
  final String category;
  final String price;
  final String quantity;

  const ProductDetailDialog({
    super.key,
    required this.productId,
    required this.productName,
    required this.brand,
    required this.category,
    required this.price,
    required this.quantity,
  });

  @override
  State<ProductDetailDialog> createState() => _ProductDetailDialogState();
}

class _ProductDetailDialogState extends State<ProductDetailDialog> {
  String selectedTab = 'Statistics';

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 1200;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(12),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isWide ? 1400 : width - 40,
          maxHeight: MediaQuery.of(context).size.height - 40,
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
                color: AppColors.dark,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  // title + tabs
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // title
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text:
                                    '${widget.productName} (${widget.brand}) ',
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const TextSpan(
                                text: 'Report',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        // tabs
                        Row(
                          children: [
                            _TabButton(
                              label: 'Statistics',
                              isActive: selectedTab == 'Statistics',
                              onTap: () =>
                                  setState(() => selectedTab = 'Statistics'),
                            ),
                            const SizedBox(width: 18),
                            _TabButton(
                              label: 'Archive',
                              isActive: selectedTab == 'Archive',
                              onTap: () =>
                                  setState(() => selectedTab = 'Archive'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // close
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.white,
                      size: 24,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // 🔹 Content
            Expanded(
              child: Container(
                color: AppColors.dark,
                child: selectedTab == 'Statistics'
                    ? SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                        child: isWide
                            ? _buildWideLayout()
                            : _buildNarrowLayout(),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                        child: const ArchiveTable(),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================  LAYOUTS  ======================

  Widget _buildWideLayout() {
    return Column(
      children: [
        // top row: inventory + suppliers
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: _SectionCard(
                title: 'Product Stock in inventory',
                child: _InventoryTable(),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              flex: 2,
              child: _SectionCard(
                title: 'Main Suppliers',
                child: _SuppliersTable(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        // bottom row: customers + profit chart
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _SectionCard(
                title: 'Top 5 Buying Customers',
                child: _CustomersTable(),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              flex: 5,
              child: _SectionCard(
                title: 'Total profit',
                child: _ProfitChart(),
                hideTitle: true, // العنوان موجود في _ProfitChart
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
        _SectionCard(
          title: 'Product Stock in inventory',
          child: _InventoryTable(),
        ),
        const SizedBox(height: 18),
        _SectionCard(title: 'Main Suppliers', child: _SuppliersTable()),
        const SizedBox(height: 20),
        _SectionCard(title: 'Top 5 Buying Customers', child: _CustomersTable()),
        const SizedBox(height: 18),
        _SectionCard(title: 'Total profit', child: _ProfitChart()),
      ],
    );
  }
}

// ===================  SMALL WIDGETS  ====================

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

// 🔹 Section Card
class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final bool hideTitle; // لإخفاء العنوان (مثل Total profit)

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
                color: AppColors.blue,
                fontWeight: FontWeight.w800,
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

// ===================  TABLES  ====================

// 🔹 Inventory Table
class _InventoryTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final inventoryData = [
      ('1', 'Floor 2, Aisle 5, Shelf 3', '600'),
      ('2', 'Floor 2, Aisle 2, Shelf 5', '200'),
      ('3', 'Floor 2, Aisle 2, Shelf 5', '12'),
    ];

    return _TableWidget(
      headers: const ['Inventory #', 'Location Description', 'Quantity'],
      rows: inventoryData.map((row) => [row.$1, row.$2, row.$3]).toList(),
      blueColumnIndex: 2, // Quantity column should be blue
      columnFlex: const [3, 5, 2], // تكبير عمود Inventory #
    );
  }
}

// 🔹 Suppliers Table
class _SuppliersTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final suppliersData = [
      ('Kareem Manasra', '600'),
      ('Ammar Shobaki', '200'),
      ('Ata Musleh', '12'),
    ];

    return _TableWidget(
      headers: const ['Supplier Name', '# of order'],
      rows: suppliersData.map((row) => [row.$1, row.$2]).toList(),
      blueColumnIndex: 1, // # of order column should be blue
    );
  }
}

// 🔹 Customers Table
class _CustomersTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final customersData = [
      ('Kareem Manasra', '851651'),
      ('Ammar Shobaki', '595161'),
      ('Ata Musleh', '565161'),
      ('Ameer Yasin', '256519'),
      ('Ahmad Nizar', '231651'),
    ];

    return _TableWidget(
      headers: const ['Customer Name', 'Quantity Purchased'],
      rows: customersData.map((row) => [row.$1, row.$2]).toList(),
      blueColumnIndex: 1, // Quantity Purchased column should be blue
    );
  }
}

// ===================  PROFIT CHART  ====================
// 🔹 Total profit chart with animation + hover highlight + tooltip
class _ProfitChart extends StatefulWidget {
  @override
  State<_ProfitChart> createState() => _ProfitChartState();
}

class _ProfitChartState extends State<_ProfitChart>
    with SingleTickerProviderStateMixin {
  String selectedYear = '2026';

  // القيم بوحدة K
  final profitData = [13, 14, 14, 15, 16, 16, 17, 17, 16, 18, 18, 20]; // in K
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

  // إعدادات الرسم
  static const int _tickCount = 5; // عدد القيم على محور Y (0..max)
  static const double _barMaxHeight = 180;

  int? _hoveredIndex;

  late final AnimationController _controller;
  late final Animation<double> _animation; // من 0 → 1 عند الفتح

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

    // تشغيل الأنيميشن عند فتح الـ popup
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // أكبر قيمة في البيانات (مثلاً 20K)
    final double maxData = profitData
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    // نخلي السقف أقرب مضاعف لـ 5K عشان الشكل يكون أنظف
    final double maxY = ((maxData / 5).ceil() * 5).toDouble();

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final anim = _animation.value; // بين 0 و 1

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // العنوان + اختيار السنة
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Total profit',
                  style: TextStyle(
                    color: AppColors.blue,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 17,
                    vertical: 0,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E), // نفس الخلفية
                    borderRadius: BorderRadius.circular(25), // أصغر وانعم
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
                      size: 16, // صغّر السهم
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14, // حجم الخط أصغر
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    items: const ['2024', '2025', '2026']
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
                          _controller.forward(from: 0);
                        });
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
                      children: List.generate(_tickCount, (index) {
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
                          children: List.generate(_tickCount, (index) {
                            final step = maxY / (_tickCount - 1);
                            final value = index * step;
                            return Text(
                              value == 0 ? '0' : '${value.toInt()}K',
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
                                  final v = profitData[index].toDouble();
                                  final targetHeight =
                                      (v / maxY) * _barMaxHeight;

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
                                          '${profitData[index]}K - ${months[index]}',
                                      waitDuration: const Duration(
                                        milliseconds: 150,
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          // العمود نفسه
                                          SizedBox(
                                            height: _barMaxHeight + 24,
                                            child: Align(
                                              alignment: Alignment.bottomCenter,
                                              child: AnimatedContainer(
                                                duration: const Duration(
                                                  milliseconds: 230,
                                                ),
                                                curve: Curves.easeOutCubic,
                                                width: barWidth,
                                                height: barHeight,
                                                decoration: BoxDecoration(
                                                  color: AppColors.blue
                                                      .withOpacity(opacity),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  boxShadow:
                                                      isHovered && barHeight > 0
                                                      ? [
                                                          BoxShadow(
                                                            color: AppColors
                                                                .blue
                                                                .withOpacity(
                                                                  0.4,
                                                                ),
                                                            blurRadius: 10,
                                                            spreadRadius: 1,
                                                            offset:
                                                                const Offset(
                                                                  0,
                                                                  2,
                                                                ),
                                                          ),
                                                        ]
                                                      : [],
                                                ),
                                              ),
                                            ),
                                          ),

                                          const SizedBox(height: 4),

                                          // القيمة تحت العمود
                                          Opacity(
                                            opacity: anim,
                                            child: Text(
                                              '${profitData[index]}K',
                                              style: TextStyle(
                                                color: isHovered
                                                    ? AppColors.white
                                                    : AppColors.white
                                                          .withOpacity(0.9),
                                                fontSize: 10,
                                                fontWeight: isHovered
                                                    ? FontWeight.w600
                                                    : FontWeight.w400,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),

                            const SizedBox(height: 6),

                            // أسماء الشهور تحت
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: months.map((m) {
                                return Text(
                                  m,
                                  style: const TextStyle(
                                    color: AppColors.grey,
                                    fontSize: 10,
                                  ),
                                );
                              }).toList(),
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
// ===================  GENERIC TABLE WIDGETS  ====================

class _TableWidget extends StatelessWidget {
  final List<String> headers;
  final List<List<String>> rows;
  final int? blueColumnIndex; // Index of column that should be blue
  final List<int>? columnFlex; // Flex values for each column (for sizing)

  const _TableWidget({
    required this.headers,
    required this.rows,
    this.blueColumnIndex,
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
                  final isLast = index == headers.length - 1;
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
                          color: index == blueColumnIndex
                              ? AppColors.blue
                              : AppColors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 6),
              // 🔹 الخط الأزرق تحت الهيدر مثل الصورة
              Container(
                height: 2,
                width: double.infinity,
                color: AppColors.white.withOpacity(0.2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Data rows with hover effect and alternating backgrounds
        ...rows.asMap().entries.map((entry) {
          final index = entry.key;
          final row = entry.value;
          return _HoverableTableRow(
            key: ValueKey(index),
            cells: row,
            blueColumnIndex: blueColumnIndex,
            isEven: index % 2 == 0,
            columnFlex: columnFlex,
          );
        }),
      ],
    );
  }
}

// 🔹 Hoverable Table Row
class _HoverableTableRow extends StatefulWidget {
  final List<String> cells;
  final int? blueColumnIndex;
  final bool isEven;
  final List<int>? columnFlex;

  const _HoverableTableRow({
    super.key,
    required this.cells,
    this.blueColumnIndex,
    required this.isEven,
    this.columnFlex,
  });

  @override
  State<_HoverableTableRow> createState() => _HoverableTableRowState();
}

class _HoverableTableRowState extends State<_HoverableTableRow> {
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
            final isBlueColumn =
                widget.blueColumnIndex != null &&
                index == widget.blueColumnIndex;
            final isLast = index == widget.cells.length - 1;
            // Get flex from widget
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
                    color: isBlueColumn ? AppColors.blue : AppColors.white,
                    fontSize: 13,
                    fontWeight: isBlueColumn || isLast
                        ? FontWeight.bold
                        : FontWeight.w500,
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
