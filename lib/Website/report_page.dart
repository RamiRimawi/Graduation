import 'package:flutter/material.dart';
import 'sidebar.dart';
import 'report_product_detail.dart';

class ReportPage extends StatelessWidget {
  const ReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ReportPageContent();
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

class ReportPageContent extends StatelessWidget {
  const ReportPageContent({super.key});

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
                          'Report Page',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Icon(
                          Icons.notifications_none_rounded,
                          color: AppColors.white,
                          size: 24,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 🔹 Top section
                    Row(
                      children: const [
                        Expanded(
                          child: _SellingProductsCard(
                            title: "Top 3 Selling Products",
                            isTop: true,
                          ),
                        ),
                        SizedBox(width: 20),
                        Expanded(
                          child: _SellingProductsCard(
                            title: "Lowest 3 Selling Products",
                            isTop: false,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // 🔹 Reports each product
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
                              children: const [
                                Text(
                                  'Reports each product',
                                  style: TextStyle(
                                    color: AppColors.blue,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 22,
                                  ),
                                ),
                                _SearchField(
                                  hint: 'Product Name',
                                  icon: Icons.manage_search_rounded,
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            Row(
                              children: const [
                                _HeaderText('Product ID #', flex: 2),
                                _HeaderText('Product Name', flex: 4),
                                _HeaderText('Brand', flex: 3),
                                _HeaderText('Category', flex: 3),
                                _HeaderText('Selling Price', flex: 3),
                                _HeaderText(
                                  'Quantity',
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

                            // 🔹 Product Rows
                            Expanded(
                              child: ListView(
                                children: const [
                                  _ProductRow(
                                    id: '1',
                                    name: 'Hand Shower',
                                    brand: 'GROHE',
                                    category: 'shower',
                                    price: '26\$',
                                    qty: '26',
                                  ),
                                  _ProductRow(
                                    id: '2',
                                    name: 'Wall-Hung Toilet',
                                    brand: 'Royal',
                                    category: 'Toilets',
                                    price: '150\$',
                                    qty: '30',
                                  ),
                                  _ProductRow(
                                    id: '3',
                                    name: 'Kitchen Sink',
                                    brand: 'GROHE',
                                    category: 'Extensions',
                                    price: '200\$',
                                    qty: '30',
                                  ),
                                  _ProductRow(
                                    id: '4',
                                    name: 'Towel Ring',
                                    brand: 'Royal',
                                    category: 'Extensions',
                                    price: '25\$',
                                    qty: '29',
                                  ),
                                  _ProductRow(
                                    id: '5',
                                    name: 'Freestanding Bathtub',
                                    brand: 'Royal',
                                    category: 'Extensions',
                                    price: '10\$',
                                    qty: '31',
                                  ),
                                ],
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
  const _SearchField({required this.hint, required this.icon});

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

// 🔹 Top/Lowest Selling Products Card
class _SellingProductsCard extends StatelessWidget {
  final String title;
  final bool isTop;
  const _SellingProductsCard({required this.title, required this.isTop});

  @override
  Widget build(BuildContext context) {
    final data = isTop
        ? [
            ('Kareem Manasra', '100', '600'),
            ('Ammar Shobaki', '50', '526'),
            ('Ata Musleh', '33', '322'),
          ]
        : [
            ('Kareem Manasra', '100', '2'),
            ('Ammar Shobaki', '50', '4'),
            ('Ata Musleh', '33', '6'),
          ];

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
                  text: '$title ',
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
              _HeaderText('Product Name', flex: 4),
              _HeaderText('Quantity', flex: 1, color: AppColors.blue),
              _HeaderText(
                'Number of Sales',
                flex: 1,
                color: AppColors.blue,
                alignEnd: true,
              ),
            ],
          ),
          const SizedBox(height: 5),
          Container(height: 1, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 10),

          // Rows
          ...List.generate(data.length, (i) {
            final d = data[i];
            final bg = i.isEven ? AppColors.dark : AppColors.cardAlt;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      d.$1,
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
                        d.$2,
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
                        d.$3,
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

// 🔹 Product Row
class _ProductRow extends StatefulWidget {
  final String id, name, brand, category, price, qty;
  const _ProductRow({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.price,
    required this.qty,
  });

  @override
  State<_ProductRow> createState() => _ProductRowState();
}

class _ProductRowState extends State<_ProductRow> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = int.parse(widget.id) % 2 == 0
        ? AppColors.dark
        : AppColors.cardAlt;

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTap: () {
          // 🔹 فتح صفحة التفاصيل (البوب أب)
          showDialog(
            context: context,
            barrierColor: Colors.black.withOpacity(0.6),
            builder: (_) => ProductDetailDialog(
              productId: widget.id,
              productName: widget.name,
              brand: widget.brand,
              category: widget.category,
              price: widget.price,
              quantity: widget.qty,
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
              _cell(widget.brand, flex: 3),
              _cell(widget.category, flex: 3),
              _cell(widget.price, flex: 3),
              _cell(
                widget.qty,
                flex: 2,
                color: AppColors.blue,
                alignEnd: true,
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
