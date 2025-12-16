import 'package:flutter/material.dart';
import 'sidebar.dart';
import 'report_product_detail.dart';
import '../supabase_config.dart';

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

class ReportPageContent extends StatefulWidget {
  const ReportPageContent({super.key});

  @override
  State<ReportPageContent> createState() => _ReportPageContentState();
}

class _ReportPageContentState extends State<ReportPageContent> {
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  bool _loading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    try {
      final result = await supabase.from('product').select('''
            product_id,
            name,
            selling_price,
            total_quantity,
            brand:brand_id(name),
            category:category_id(name)
          ''');

      if (mounted) {
        setState(() {
          _products = List<Map<String, dynamic>>.from(result);
          _filteredProducts = _products;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
      print('Error loading products: $e');
    }
  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = _products;
      } else {
        _filteredProducts = _products.where((product) {
          final name = product['name']?.toString().toLowerCase() ?? '';
          return name.startsWith(query);
        }).toList();
      }
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
                          color: AppColors.cardAlt,
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
                                  controller: _searchController,
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
                              child: _loading
                                  ? const Center(
                                      child: CircularProgressIndicator(
                                        color: AppColors.blue,
                                      ),
                                    )
                                  : _filteredProducts.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'No products found',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 16,
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount: _filteredProducts.length,
                                      itemBuilder: (context, index) {
                                        final product =
                                            _filteredProducts[index];
                                        final brandData = product['brand'];
                                        final categoryData =
                                            product['category'];

                                        return _ProductRow(
                                          id: product['product_id'].toString(),
                                          name:
                                              product['name']?.toString() ??
                                              'N/A',
                                          brand: brandData is Map
                                              ? (brandData['name']
                                                        ?.toString() ??
                                                    'N/A')
                                              : 'N/A',
                                          category: categoryData is Map
                                              ? (categoryData['name']
                                                        ?.toString() ??
                                                    'N/A')
                                              : 'N/A',
                                          price:
                                              '\$${product['selling_price']?.toString() ?? '0'}',
                                          qty:
                                              product['total_quantity']
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

// 🔹 Top/Lowest Selling Products Card
class _SellingProductsCard extends StatefulWidget {
  final String title;
  final bool isTop;
  const _SellingProductsCard({required this.title, required this.isTop});

  @override
  State<_SellingProductsCard> createState() => _SellingProductsCardState();
}

class _SellingProductsCardState extends State<_SellingProductsCard> {
  List<Map<String, dynamic>> _products = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      // Get current month start and end dates
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(
        now.year,
        now.month + 1,
        1,
      ).subtract(const Duration(days: 1));

      // First, get all order descriptions for this month with customer orders
      final orderDescriptions = await supabase
          .from('customer_order_description')
          .select('''
            quantity,
            product_id,
            customer_order!inner(order_date)
          ''')
          .gte('customer_order.order_date', monthStart.toIso8601String())
          .lte('customer_order.order_date', monthEnd.toIso8601String());

      // Group by product_id and calculate totals
      final Map<int, Map<String, dynamic>> productStats = {};

      for (var item in orderDescriptions) {
        final productId = item['product_id'] as int;
        final quantity = item['quantity'] as int;

        if (!productStats.containsKey(productId)) {
          productStats[productId] = {
            'product_id': productId,
            'total_sold_qty': 0,
            'num_of_sales': 0,
          };
        }

        productStats[productId]!['total_sold_qty'] =
            (productStats[productId]!['total_sold_qty'] as int) + quantity;
        productStats[productId]!['num_of_sales'] =
            (productStats[productId]!['num_of_sales'] as int) + 1;
      }

      // Get product details and combine with stats
      final List<Map<String, dynamic>> productList = [];
      for (var stats in productStats.values) {
        final productId = stats['product_id'];
        final product = await supabase
            .from('product')
            .select('name')
            .eq('product_id', productId)
            .single();

        productList.add({
          'product_id': productId,
          'product_name': product['name'],
          'total_sold_qty': stats['total_sold_qty'],
          'num_of_sales': stats['num_of_sales'],
        });
      }

      // Sort by total_sold_qty
      productList.sort((a, b) {
        final qtyA = a['total_sold_qty'] as int;
        final qtyB = b['total_sold_qty'] as int;
        return widget.isTop ? qtyB.compareTo(qtyA) : qtyA.compareTo(qtyB);
      });

      // Take top/lowest 3
      final top3 = productList.take(3).toList();

      if (mounted) {
        setState(() {
          _products = top3;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
      print('Error loading products: $e');
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

          // Loading or Data Rows
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: AppColors.blue),
              ),
            )
          else if (_products.isEmpty)
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
            ...List.generate(_products.length, (i) {
              final product = _products[i];
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
                        product['product_name']?.toString() ?? 'N/A',
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
                          product['total_sold_qty']?.toString() ?? '0',
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
                          product['num_of_sales']?.toString() ?? '0',
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
