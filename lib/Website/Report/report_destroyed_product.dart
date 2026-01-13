import 'package:flutter/material.dart';
import '../sidebar.dart';
import '../../supabase_config.dart';
import '../Damaged_Product/meeting_details_dialog.dart';

class ReportDestroyedProductPage extends StatelessWidget {
  const ReportDestroyedProductPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ReportDestroyedProductPageContent();
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

class ReportDestroyedProductPageContent extends StatefulWidget {
  const ReportDestroyedProductPageContent({super.key});

  @override
  State<ReportDestroyedProductPageContent> createState() =>
      _ReportDestroyedProductPageContentState();
}

class _ReportDestroyedProductPageContentState
    extends State<ReportDestroyedProductPageContent> {
  List<Map<String, dynamic>> _meetings = [];
  List<Map<String, dynamic>> _filteredMeetings = [];
  bool _loading = true;
  final TextEditingController _searchController = TextEditingController();
  int? _hoveredRow;

  @override
  void initState() {
    super.initState();
    _loadMeetings();
    _searchController.addListener(_filterMeetings);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMeetings() async {
    try {
      final result = await supabase
          .from('damaged_products_meeting')
          .select('''
            meeting_id,
            meeting_address,
            meeting_time,
            meeting_topics,
            result_of_meeting
          ''')
          .order('meeting_time', ascending: false);

      if (mounted) {
        setState(() {
          _meetings = List<Map<String, dynamic>>.from(result);
          _filteredMeetings = _meetings;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
      print('Error loading meetings: $e');
    }
  }

  void _filterMeetings() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredMeetings = _meetings;
      } else {
        _filteredMeetings = _meetings.where((meeting) {
          final topics =
              meeting['meeting_topics']?.toString().toLowerCase() ?? '';
          final address =
              meeting['meeting_address']?.toString().toLowerCase() ?? '';
          return topics.contains(query) || address.contains(query);
        }).toList();
      }
    });
  }

  String _formatDateTime(String? dateTime) {
    if (dateTime == null) return 'N/A';
    try {
      final dt = DateTime.parse(dateTime);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTime;
    }
  }

  void _showMeetingDetails(Map<String, dynamic> meeting) {
    showDialog(
      context: context,
      builder: (context) =>
          MeetingDetailsDialog(meetingId: meeting['meeting_id']),
    );
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
                          'Destroyed Product Report',
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
                          child: _DestroyedProductsCard(
                            title: "Top 3 Destroyed Products",
                            isTop: true,
                          ),
                        ),
                        SizedBox(width: 20),
                        Expanded(
                          child: _DestroyedProductsCard(
                            title: "Lowest 3 Destroyed Products",
                            isTop: false,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // 🔹 Reports each destroyed product
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
                                  'Destroyed Products Meetings',
                                  style: TextStyle(
                                    color: AppColors.blue,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 22,
                                  ),
                                ),
                                _SearchField(
                                  hint: 'Search Meeting',
                                  icon: Icons.manage_search_rounded,
                                  controller: _searchController,
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            Row(
                              children: const [
                                _HeaderText('ID #', flex: 1),
                                _HeaderText('Meeting Topics', flex: 3),
                                _HeaderText('Address', flex: 3),
                                _HeaderText('Date & Time', flex: 2),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: 1,
                              color: Colors.white.withOpacity(0.2),
                            ),
                            const SizedBox(height: 10),

                            // 🔹 Meetings Rows
                            Expanded(
                              child: _loading
                                  ? const Center(
                                      child: CircularProgressIndicator(
                                        color: AppColors.blue,
                                      ),
                                    )
                                  : _filteredMeetings.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'No meetings found',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 16,
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount: _filteredMeetings.length,
                                      itemBuilder: (context, index) {
                                        final meeting =
                                            _filteredMeetings[index];
                                        return _MeetingRow(
                                          index: index,
                                          meetingId: meeting['meeting_id']
                                              .toString(),
                                          topics:
                                              meeting['meeting_topics']
                                                  ?.toString() ??
                                              'N/A',
                                          address:
                                              meeting['meeting_address']
                                                  ?.toString() ??
                                              'N/A',
                                          dateTime: _formatDateTime(
                                            meeting['meeting_time'],
                                          ),
                                          onTap: () =>
                                              _showMeetingDetails(meeting),
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

// 🔹 Top/Lowest Destroyed Products Card
class _DestroyedProductsCard extends StatefulWidget {
  final String title;
  final bool isTop;
  const _DestroyedProductsCard({required this.title, required this.isTop});

  @override
  State<_DestroyedProductsCard> createState() => _DestroyedProductsCardState();
}

class _DestroyedProductsCardState extends State<_DestroyedProductsCard> {
  List<Map<String, dynamic>> _products = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      // Fetch all damaged products
      final damagedProducts = await supabase.from('damaged_products').select('''
            product_id,
            quantity,
            batch(product:product_id(name))
          ''');

      // Group and aggregate by product
      final Map<int, Map<String, dynamic>> productStats = {};
      for (var item in damagedProducts as List) {
        final productId = item['product_id'] as int;
        final quantity = item['quantity'] as int;
        final batchData = item['batch'] as Map?;
        final productData = batchData?['product'] as Map?;
        final productName = productData?['name']?.toString() ?? '';

        if (!productStats.containsKey(productId)) {
          productStats[productId] = {
            'product_id': productId,
            'product_name': productName,
            'total_destroyed_qty': 0,
            'num_of_records': 0,
          };
        }

        productStats[productId]!['total_destroyed_qty'] =
            (productStats[productId]!['total_destroyed_qty'] as int) + quantity;
        productStats[productId]!['num_of_records'] =
            (productStats[productId]!['num_of_records'] as int) + 1;
      }

      // Convert to list and sort
      final productList = productStats.values.toList();
      productList.sort((a, b) {
        final qtyA = (a['total_destroyed_qty'] as int);
        final qtyB = (b['total_destroyed_qty'] as int);
        return widget.isTop ? qtyB.compareTo(qtyA) : qtyA.compareTo(qtyB);
      });

      final top3 = productList.take(3).toList();

      if (!mounted) return;
      setState(() {
        _products = top3;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
      print('Error loading destroyed products: $e');
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
                  text: '(all time)',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: const [
              _HeaderText('Product Name', flex: 4),
              _HeaderText('Total Destroyed', flex: 1, color: AppColors.blue),
              _HeaderText(
                'Number of Records',
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
                          product['total_destroyed_qty']?.toString() ?? '0',
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
                          product['num_of_records']?.toString() ?? '0',
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

// 🔹 Meeting Row
class _MeetingRow extends StatefulWidget {
  final int index;
  final String meetingId, topics, address, dateTime;
  final VoidCallback onTap;

  const _MeetingRow({
    required this.index,
    required this.meetingId,
    required this.topics,
    required this.address,
    required this.dateTime,
    required this.onTap,
  });

  @override
  State<_MeetingRow> createState() => _MeetingRowState();
}

class _MeetingRowState extends State<_MeetingRow> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.index.isEven ? AppColors.cardAlt : AppColors.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
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
              _cell('#${widget.meetingId}', flex: 1),
              _cell(widget.topics, flex: 3),
              _cell(widget.address, flex: 3),
              _cell(widget.dateTime, flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cell(String text, {int flex = 1, Color color = Colors.white}) {
    return Expanded(
      flex: flex,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
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
