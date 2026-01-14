import 'package:flutter/material.dart';
import '../sidebar.dart';
import '../../supabase_config.dart';
import '../Damaged_Product/meeting_details_dialog.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

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

  void _showGenerateReportDialog() {
    showDialog(context: context, builder: (context) => _GenerateReportDialog());
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
                            // 🔹 Title + Search bar + Generate Report button
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Destroyed Products Meetings',
                                    style: TextStyle(
                                      color: AppColors.blue,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 22,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton.icon(
                                  onPressed: _showGenerateReportDialog,
                                  icon: const Icon(
                                    Icons.picture_as_pdf,
                                    size: 18,
                                  ),
                                  label: const Text('Generate Report'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.blue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Flexible(
                                  child: _SearchField(
                                    hint: 'Search Meeting',
                                    icon: Icons.manage_search_rounded,
                                    controller: _searchController,
                                  ),
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

// 🔹 Search Field صغير (focusable with blue border)
class _SearchField extends StatefulWidget {
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  const _SearchField({
    required this.hint,
    required this.icon,
    required this.controller,
  });

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFocused = _focusNode.hasFocus;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 180, maxWidth: 280),
      child: Container(
        height: 42,
        child: TextField(
          focusNode: _focusNode,
          controller: widget.controller,
          style: const TextStyle(color: AppColors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: const TextStyle(color: AppColors.grey, fontSize: 13),
            prefixIcon: Icon(widget.icon, color: AppColors.white, size: 20),
            filled: true,
            fillColor: AppColors.card,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(28),
              borderSide: BorderSide(color: AppColors.grey, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(28),
              borderSide: BorderSide(color: AppColors.grey, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(28),
              borderSide: BorderSide(color: AppColors.blue, width: 2),
            ),
          ),
          cursorColor: AppColors.blue,
          onTap: () => setState(() {}),
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

// 🔹 Generate Report Dialog
class _GenerateReportDialog extends StatefulWidget {
  const _GenerateReportDialog();

  @override
  State<_GenerateReportDialog> createState() => _GenerateReportDialogState();
}

class _GenerateReportDialogState extends State<_GenerateReportDialog> {
  final _fromDateController = TextEditingController();
  final _toDateController = TextEditingController();
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _showError = false;
  bool _generating = false;

  @override
  void dispose() {
    _fromDateController.dispose();
    _toDateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    DateTime? selectedDate = isFromDate ? _fromDate : _toDate;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        int selectedYear = selectedDate?.year ?? DateTime.now().year;
        int selectedMonth = selectedDate?.month ?? DateTime.now().month;
        int selectedDay = selectedDate?.day ?? DateTime.now().day;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final daysInMonth = DateTime(
              selectedYear,
              selectedMonth + 1,
              0,
            ).day;
            if (selectedDay > daysInMonth) selectedDay = daysInMonth;

            return Dialog(
              backgroundColor: AppColors.card,
              child: Container(
                width: 300,
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isFromDate ? 'Select From Date' : 'Select To Date',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        // Day
                        Expanded(
                          child: _buildDropdown(
                            value: selectedDay,
                            items: List.generate(daysInMonth, (i) => i + 1),
                            onChanged: (val) =>
                                setDialogState(() => selectedDay = val!),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Month
                        Expanded(
                          child: _buildDropdown(
                            value: selectedMonth,
                            items: List.generate(12, (i) => i + 1),
                            onChanged: (val) =>
                                setDialogState(() => selectedMonth = val!),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Year
                        Expanded(
                          child: _buildDropdown(
                            value: selectedYear,
                            items: List.generate(27, (i) => 2000 + i),
                            onChanged: (val) =>
                                setDialogState(() => selectedYear = val!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: AppColors.grey),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () {
                            final picked = DateTime(
                              selectedYear,
                              selectedMonth,
                              selectedDay,
                            );
                            Navigator.pop(context);
                            if (mounted) {
                              setState(() {
                                if (isFromDate) {
                                  _fromDate = picked;
                                  _fromDateController.text = DateFormat(
                                    'yyyy-MM-dd',
                                  ).format(picked);
                                  _showError = false;
                                } else {
                                  _toDate = picked;
                                  _toDateController.text = DateFormat(
                                    'yyyy-MM-dd',
                                  ).format(picked);
                                }
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.blue,
                          ),
                          child: const Text(
                            'OK',
                            style: TextStyle(color: AppColors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDropdown({
    required int value,
    required List<int> items,
    required ValueChanged<int?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.dark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.grey.withOpacity(0.3)),
      ),
      child: DropdownButton<int>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        dropdownColor: AppColors.dark,
        style: const TextStyle(color: AppColors.white, fontSize: 14),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(item.toString().padLeft(2, '0')),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Future<void> _generateReport() async {
    if (_fromDate == null) {
      setState(() {
        _showError = true;
      });
      return;
    }

    setState(() {
      _generating = true;
    });

    try {
      // Use today's date if to date is not specified
      final toDate = _toDate ?? DateTime.now();

      // Fetch destroyed products data within date range
      final meetingsResult = await supabase
          .from('damaged_products_meeting')
          .select('''
            meeting_id,
            meeting_address,
            meeting_time,
            meeting_topics,
            result_of_meeting
          ''')
          .gte('meeting_time', _fromDate!.toIso8601String())
          .lte('meeting_time', toDate.toIso8601String())
          .order('meeting_time', ascending: false);

      final meetings = List<Map<String, dynamic>>.from(meetingsResult);

      // Extract meeting IDs
      final meetingIds = meetings.map((m) => m['meeting_id']).toList();

      // Fetch damaged products for these meetings
      List<Map<String, dynamic>> damagedProducts = [];
      if (meetingIds.isNotEmpty) {
        final damagedProductsResult = await supabase
            .from('damaged_products')
            .select('''
              meeting_id,
              quantity,
              reason,
              batch(product:product_id(name, selling_price, brand:brand_id(name), category:category_id(name)))
            ''')
            .inFilter('meeting_id', meetingIds);

        damagedProducts = List<Map<String, dynamic>>.from(
          damagedProductsResult,
        );
      }

      // Generate PDF
      final pdf = await _createPDF(
        meetings,
        damagedProducts,
        _fromDate!,
        toDate,
      );

      // Show PDF preview/download
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('Error generating report: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _generating = false;
        });
      }
    }
  }

  Future<pw.Document> _createPDF(
    List<Map<String, dynamic>> meetings,
    List<Map<String, dynamic>> damagedProducts,
    DateTime fromDate,
    DateTime toDate,
  ) async {
    final pdf = pw.Document();

    // Calculate statistics
    final totalMeetings = meetings.length;
    final totalDestroyedQty = damagedProducts.fold<int>(
      0,
      (sum, item) => sum + (item['quantity'] as int? ?? 0),
    );

    // Calculate total losses
    double totalLosses = 0;
    for (var item in damagedProducts) {
      final quantity = item['quantity'] as int? ?? 0;
      final batchData = item['batch'] as Map?;
      final productData = batchData?['product'] as Map?;
      final sellingPrice = productData?['selling_price'] as num? ?? 0;
      totalLosses += quantity * sellingPrice;
    }

    // Group products by name
    final Map<String, int> productQuantities = {};
    for (var item in damagedProducts) {
      final batchData = item['batch'] as Map?;
      final productData = batchData?['product'] as Map?;
      final productName = productData?['name']?.toString() ?? 'Unknown';
      productQuantities[productName] =
          (productQuantities[productName] ?? 0) +
          (item['quantity'] as int? ?? 0);
    }

    // Get top 3 destroyed products
    final topProducts = productQuantities.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top3 = topProducts.take(3).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            // Title
            pw.Container(
              alignment: pw.Alignment.center,
              child: pw.Column(
                children: [
                  pw.Text(
                    'DESTROYED PRODUCTS REPORT',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Period: ${DateFormat('dd/MM/yyyy').format(fromDate)} - ${DateFormat('dd/MM/yyyy').format(toDate)}',
                    style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Generated on: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 30),

            // Executive Summary
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'EXECUTIVE SUMMARY',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.SizedBox(height: 12),
                  pw.Text(
                    'This report provides a comprehensive analysis of destroyed products during the specified period. '
                    'It includes detailed information about meetings held to address product damage issues, '
                    'the total quantity of products destroyed, and key statistics to help improve quality control measures.',
                    style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.5),
                  ),
                  pw.SizedBox(height: 16),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatBox('Total Meetings', totalMeetings.toString()),
                      _buildStatBox(
                        'Total Destroyed',
                        '$totalDestroyedQty units',
                      ),
                      _buildStatBox(
                        'Unique Products',
                        productQuantities.length.toString(),
                      ),
                      _buildStatBox(
                        'Total Losses',
                        '-\$${totalLosses.toStringAsFixed(2)}',
                        isLoss: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 24),

            // Top Destroyed Products
            pw.Text(
              'TOP DESTROYED PRODUCTS',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                children: top3.map((entry) {
                  return pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 4),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          entry.key,
                          style: const pw.TextStyle(fontSize: 11),
                        ),
                        pw.Text(
                          '${entry.value} units',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.red700,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            pw.SizedBox(height: 24),

            // Meetings and their Damaged Products
            pw.Text(
              'MEETINGS AND DAMAGED PRODUCTS DETAILS',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),
            pw.SizedBox(height: 16),

            // Group damaged products by meeting_id
            ...meetings.map((meeting) {
              final meetingId = meeting['meeting_id'];
              final meetingProducts = damagedProducts
                  .where((item) => item['meeting_id'] == meetingId)
                  .toList();
              final dateTime = meeting['meeting_time'] != null
                  ? DateFormat(
                      'dd/MM/yyyy HH:mm',
                    ).format(DateTime.parse(meeting['meeting_time']))
                  : 'N/A';

              // Calculate meeting total losses
              double meetingLoss = 0;
              for (var item in meetingProducts) {
                final quantity = item['quantity'] as int? ?? 0;
                final batchData = item['batch'] as Map?;
                final productData = batchData?['product'] as Map?;
                final sellingPrice = productData?['selling_price'] as num? ?? 0;
                meetingLoss += quantity * sellingPrice;
              }

              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Meeting Header
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blue100,
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(
                        color: PdfColors.blue300,
                        width: 1.5,
                      ),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              'Meeting #$meetingId',
                              style: pw.TextStyle(
                                fontSize: 13,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.blue900,
                              ),
                            ),
                            pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.end,
                              children: [
                                pw.Text(
                                  dateTime,
                                  style: pw.TextStyle(
                                    fontSize: 11,
                                    color: PdfColors.grey800,
                                  ),
                                ),
                                pw.SizedBox(height: 2),
                                pw.Text(
                                  'Loss: -\$${meetingLoss.toStringAsFixed(2)}',
                                  style: pw.TextStyle(
                                    fontSize: 11,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.red700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 6),
                        pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Topics: ',
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.grey800,
                              ),
                            ),
                            pw.Expanded(
                              child: pw.Text(
                                meeting['meeting_topics']?.toString() ?? 'N/A',
                                style: const pw.TextStyle(
                                  fontSize: 10,
                                  color: PdfColors.grey800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 4),
                        pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Address: ',
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.grey800,
                              ),
                            ),
                            pw.Expanded(
                              child: pw.Text(
                                meeting['meeting_address']?.toString() ?? 'N/A',
                                style: const pw.TextStyle(
                                  fontSize: 10,
                                  color: PdfColors.grey800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (meeting['result_of_meeting'] != null &&
                            meeting['result_of_meeting']
                                .toString()
                                .isNotEmpty) ...[
                          pw.SizedBox(height: 4),
                          pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'Result: ',
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.grey800,
                                ),
                              ),
                              pw.Expanded(
                                child: pw.Text(
                                  meeting['result_of_meeting']?.toString() ??
                                      '',
                                  style: const pw.TextStyle(
                                    fontSize: 10,
                                    color: PdfColors.grey800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 8),

                  // Products Table for this meeting
                  if (meetingProducts.isNotEmpty)
                    pw.Table.fromTextArray(
                      headerStyle: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                        fontSize: 10,
                      ),
                      cellStyle: const pw.TextStyle(fontSize: 9),
                      headerDecoration: const pw.BoxDecoration(
                        color: PdfColors.blue800,
                      ),
                      cellHeight: 22,
                      cellAlignments: {
                        0: pw.Alignment.centerLeft,
                        1: pw.Alignment.centerLeft,
                        2: pw.Alignment.centerLeft,
                        3: pw.Alignment.center,
                        4: pw.Alignment.centerRight,
                        5: pw.Alignment.centerRight,
                      },
                      headers: [
                        'Product',
                        'Brand',
                        'Reason',
                        'Qty',
                        'Price',
                        'Loss',
                      ],
                      data: meetingProducts.map((item) {
                        final batchData = item['batch'] as Map?;
                        final productData = batchData?['product'] as Map?;
                        final brandData = productData?['brand'] as Map?;
                        final quantity = item['quantity'] as int? ?? 0;
                        final sellingPrice =
                            productData?['selling_price'] as num? ?? 0;
                        final loss = quantity * sellingPrice;
                        return [
                          productData?['name']?.toString() ?? 'N/A',
                          brandData?['name']?.toString() ?? 'N/A',
                          item['reason']?.toString() ?? 'N/A',
                          quantity.toString(),
                          '\$${sellingPrice.toStringAsFixed(2)}',
                          '-\$${loss.toStringAsFixed(2)}',
                        ];
                      }).toList(),
                    )
                  else
                    pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey200,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        'No damaged products recorded for this meeting',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontStyle: pw.FontStyle.italic,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ),

                  pw.SizedBox(height: 15),
                  // Separator line between meetings
                  pw.Container(height: 1, color: PdfColors.grey400),
                  pw.SizedBox(height: 15),
                ],
              );
            }).toList(),
          ];
        },
      ),
    );

    return pdf;
  }

  pw.Widget _buildStatBox(String label, String value, {bool isLoss = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColors.blue300, width: 1.5),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: isLoss ? PdfColors.red700 : PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 500,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with close button
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.blue,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Generate Report',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                    splashRadius: 20,
                  ),
                ],
              ),
            ),

            // Body
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // From Date Field
                  const Text(
                    'From Date *',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _fromDateController,
                    readOnly: true,
                    onTap: () => _selectDate(context, true),
                    decoration: InputDecoration(
                      hintText: 'Select from date',
                      hintStyle: const TextStyle(color: AppColors.grey),
                      filled: true,
                      fillColor: AppColors.dark,
                      suffixIcon: const Icon(
                        Icons.calendar_today,
                        color: AppColors.blue,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: _showError ? Colors.red : AppColors.grey,
                          width: 2,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: _showError ? Colors.red : AppColors.grey,
                          width: 2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: _showError ? Colors.red : AppColors.blue,
                          width: 2,
                        ),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  if (_showError)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        'From date is required',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  const SizedBox(height: 20),

                  // To Date Field
                  const Text(
                    'To Date',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _toDateController,
                    readOnly: true,
                    onTap: () => _selectDate(context, false),
                    decoration: InputDecoration(
                      hintText: 'Select to date (defaults to today)',
                      hintStyle: const TextStyle(color: AppColors.grey),
                      filled: true,
                      fillColor: AppColors.dark,
                      suffixIcon: const Icon(
                        Icons.calendar_today,
                        color: AppColors.blue,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AppColors.grey,
                          width: 2,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AppColors.grey,
                          width: 2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AppColors.blue,
                          width: 2,
                        ),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 30),

                  // Generate Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _generating ? null : _generateReport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        disabledBackgroundColor: AppColors.grey,
                      ),
                      child: _generating
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Generate',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
