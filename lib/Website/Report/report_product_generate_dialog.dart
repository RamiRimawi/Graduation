import 'package:flutter/material.dart';
import 'report_page.dart';
import '../../supabase_config.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class GenerateProductReportDialog extends StatefulWidget {
  final String productId;
  final String productName;

  const GenerateProductReportDialog({
    super.key,
    required this.productId,
    required this.productName,
  });

  @override
  State<GenerateProductReportDialog> createState() =>
      _GenerateProductReportDialogState();
}

class _GenerateProductReportDialogState
    extends State<GenerateProductReportDialog> {
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _includeStockIn = false;
  bool _includeStockOut = false;
  bool _includeDamagedProducts = false;
  bool _isGenerating = false;

  // For validation
  bool _showFromError = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Generate Product Report',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // From Date
            const Text(
              'From Date *',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildDatePicker(
              date: _fromDate,
              onTap: () => _pickDate(isFrom: true),
              showError: _showFromError,
            ),
            if (_showFromError)
              const Padding(
                padding: EdgeInsets.only(top: 6, left: 4),
                child: Text(
                  'From date is required',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            const SizedBox(height: 16),

            // To Date
            const Text(
              'To Date',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildDatePicker(
              date: _toDate,
              onTap: () => _pickDate(isFrom: false),
              showError: false,
            ),
            const SizedBox(height: 20),

            // Checkboxes
            const Text(
              'Include Sections',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            _buildCheckbox(
              label: 'Stock-In Orders',
              value: _includeStockIn,
              onChanged: (val) =>
                  setState(() => _includeStockIn = val ?? false),
            ),
            const SizedBox(height: 8),
            _buildCheckbox(
              label: 'Stock-Out Orders',
              value: _includeStockOut,
              onChanged: (val) =>
                  setState(() => _includeStockOut = val ?? false),
            ),
            const SizedBox(height: 8),
            _buildCheckbox(
              label: 'Damaged Products',
              value: _includeDamagedProducts,
              onChanged: (val) =>
                  setState(() => _includeDamagedProducts = val ?? false),
            ),

            const SizedBox(height: 24),

            // Generate Button
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: _isGenerating ? null : _generateReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isGenerating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: AppColors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Generate',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker({
    required DateTime? date,
    required VoidCallback onTap,
    required bool showError,
  }) {
    final controller = TextEditingController(
      text: date != null ? DateFormat('dd/MM/yyyy').format(date) : '',
    );

    return TextField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      style: const TextStyle(color: AppColors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: 'dd/MM/yyyy',
        hintStyle: const TextStyle(color: AppColors.grey, fontSize: 14),
        suffixIcon: const Icon(
          Icons.calendar_today,
          color: AppColors.blue,
          size: 18,
        ),
        filled: true,
        fillColor: AppColors.dark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: showError ? Colors.red : AppColors.grey.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: showError ? Colors.red : AppColors.grey.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.blue, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }

  Widget _buildCheckbox({
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.dark,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: value ? AppColors.blue : Colors.transparent,
                border: Border.all(
                  color: value ? AppColors.blue : AppColors.grey,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: value
                  ? const Icon(Icons.check, color: AppColors.white, size: 14)
                  : null,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(color: AppColors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate({required bool isFrom}) async {
    DateTime? selectedDate = isFrom ? _fromDate : _toDate;

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
                      isFrom ? 'Select From Date' : 'Select To Date',
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
                            items: List.generate(101, (i) => 2000 + i),
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
                                if (isFrom) {
                                  _fromDate = picked;
                                  _showFromError = false;
                                } else {
                                  _toDate = picked;
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
    // Validate from date
    if (_fromDate == null) {
      setState(() => _showFromError = true);
      return;
    }

    setState(() => _isGenerating = true);

    try {
      // Default to date to today if not set
      final toDate = _toDate ?? DateTime.now();

      // Query product details
      final productData = await supabase
          .from('product')
          .select(
            'name, selling_price, wholesale_price, total_quantity, brand:brand_id(name), category:category_id(name)',
          )
          .eq('product_id', int.parse(widget.productId))
          .single();

      // Query batches for this product with inventory info
      final batchesData = await supabase
          .from('batch')
          .select('''
            batch_id,
            quantity,
            expiry_date,
            production_date,
            inventory:inventory_id(inventory_name)
          ''')
          .eq('product_id', int.parse(widget.productId));

      List<Map<String, dynamic>> stockInOrders = [];
      List<Map<String, dynamic>> stockOutOrders = [];
      List<Map<String, dynamic>> damagedProductsMeetings = [];

      // Query Stock-In orders if selected
      if (_includeStockIn) {
        // Get batch IDs for this product
        final batches = await supabase
            .from('batch')
            .select('batch_id')
            .eq('product_id', int.parse(widget.productId));

        final batchIds = batches.map((b) => b['batch_id'] as int).toList();

        if (batchIds.isNotEmpty) {
          // Get supplier orders via batch with quantities
          final supplierOrderInventory = await supabase
              .from('supplier_order_inventory')
              .select('supplier_order_id, receipt_quantity')
              .inFilter('batch_id', batchIds);

          // Group by supplier_order_id and sum quantities
          final Map<int, int> orderQuantities = {};
          for (final item in supplierOrderInventory) {
            final orderId = item['supplier_order_id'] as int;
            final quantity = (item['receipt_quantity'] as num?)?.toInt() ?? 0;
            orderQuantities[orderId] =
                (orderQuantities[orderId] ?? 0) + quantity;
          }

          final supplierOrderIds = orderQuantities.keys.toList();

          if (supplierOrderIds.isNotEmpty) {
            final orders = await supabase
                .from('supplier_order')
                .select('''
                  order_id,
                  order_date,
                  order_status,
                  total_cost,
                  supplier:supplier_id(name)
                ''')
                .inFilter('order_id', supplierOrderIds)
                .eq('order_status', 'Delivered')
                .gte('order_date', _fromDate!.toIso8601String())
                .lte('order_date', toDate.toIso8601String())
                .order('order_date', ascending: false);

            // Add quantity to each order
            for (final order in orders) {
              final orderId = order['order_id'] as int;
              order['quantity'] = orderQuantities[orderId] ?? 0;
            }

            stockInOrders = List<Map<String, dynamic>>.from(orders);
          }
        }
      }

      // Query Stock-Out orders if selected
      if (_includeStockOut) {
        final orderDescriptions = await supabase
            .from('customer_order_description')
            .select('customer_order_id, delivered_quantity, total_price')
            .eq('product_id', int.parse(widget.productId));

        final customerOrderIds = orderDescriptions
            .map((o) => o['customer_order_id'] as int)
            .toSet()
            .toList();

        if (customerOrderIds.isNotEmpty) {
          final orders = await supabase
              .from('customer_order')
              .select('''
                customer_order_id,
                order_date,
                order_status,
                customer:customer_id(name)
              ''')
              .inFilter('customer_order_id', customerOrderIds)
              .eq('order_status', 'Delivered')
              .gte('order_date', _fromDate!.toIso8601String())
              .lte('order_date', toDate.toIso8601String())
              .order('order_date', ascending: false);

          // Merge quantity and total_price from order_description
          for (final order in orders) {
            final orderId = order['customer_order_id'];
            final desc = orderDescriptions.firstWhere(
              (d) => d['customer_order_id'] == orderId,
              orElse: () => {'delivered_quantity': 0, 'total_price': 0},
            );
            order['quantity'] = desc['delivered_quantity'];
            order['total_price'] = desc['total_price'];
          }

          stockOutOrders = List<Map<String, dynamic>>.from(orders);
        }
      }

      // Query Damaged Products if selected
      if (_includeDamagedProducts) {
        // Get damaged products for this product
        final damagedProducts = await supabase
            .from('damaged_products')
            .select('quantity, reason, meeting_id, batch_id')
            .eq('product_id', int.parse(widget.productId));

        // Get unique meeting IDs
        final meetingIds = damagedProducts
            .map((item) => item['meeting_id'] as int?)
            .where((id) => id != null)
            .toSet()
            .toList();

        // Fetch meeting details
        Map<int, Map<String, dynamic>> meetingsMap = {};
        if (meetingIds.isNotEmpty) {
          final meetings = await supabase
              .from('damaged_products_meeting')
              .select(
                'meeting_id, meeting_topics, meeting_address, meeting_time',
              )
              .inFilter('meeting_id', meetingIds)
              .gte('meeting_time', _fromDate!.toIso8601String())
              .lte('meeting_time', toDate.toIso8601String());

          for (final meeting in meetings) {
            meetingsMap[meeting['meeting_id'] as int] = meeting;
          }
        }

        // Combine damaged products with meeting details
        for (final item in damagedProducts) {
          final meetingId = item['meeting_id'] as int?;
          if (meetingId != null && meetingsMap.containsKey(meetingId)) {
            damagedProductsMeetings.add({
              'quantity': item['quantity'],
              'reason': item['reason'],
              'batch_id': item['batch_id'],
              'meeting': meetingsMap[meetingId],
            });
          }
        }
      }

      // Generate PDF
      final pdf = await _createPDF(
        productData: productData,
        batches: List<Map<String, dynamic>>.from(batchesData),
        stockInOrders: stockInOrders,
        stockOutOrders: stockOutOrders,
        damagedProductsMeetings: damagedProductsMeetings,
      );

      // Show print dialog
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
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
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<pw.Document> _createPDF({
    required Map<String, dynamic> productData,
    required List<Map<String, dynamic>> batches,
    required List<Map<String, dynamic>> stockInOrders,
    required List<Map<String, dynamic>> stockOutOrders,
    required List<Map<String, dynamic>> damagedProductsMeetings,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy');
    final productName = productData['name']?.toString() ?? 'Unknown';
    final brandName =
        (productData['brand'] as Map?)?['name']?.toString() ?? 'N/A';
    final categoryName =
        (productData['category'] as Map?)?['name']?.toString() ?? 'N/A';
    final sellingPrice =
        (productData['selling_price'] as num?)?.toDouble() ?? 0;
    final wholesalePrice =
        (productData['wholesale_price'] as num?)?.toDouble() ?? 0;
    final totalQty = (productData['total_quantity'] as num?)?.toInt() ?? 0;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return [
            // Title
            pw.Header(
              level: 0,
              child: pw.Text(
                'Product Report: $productName',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'Generated: ${dateFormat.format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 20),

            // Executive Summary
            pw.Header(
              level: 1,
              child: pw.Text(
                'Executive Summary',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
            ),
            pw.SizedBox(height: 10),

            // Summary Stats
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildStatBox('Product ID', widget.productId),
                _buildStatBox('Brand', brandName),
                _buildStatBox('Category', categoryName),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildStatBox(
                  'Selling Price',
                  '\$${sellingPrice.toStringAsFixed(2)}',
                ),
                _buildStatBox(
                  'Wholesale Price',
                  '\$${wholesalePrice.toStringAsFixed(2)}',
                ),
                _buildStatBox('Total Quantity', totalQty.toString()),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildStatBox('Total Batches', batches.length.toString()),
                _buildStatBox(
                  'Stock-In Orders',
                  stockInOrders.length.toString(),
                ),
                _buildStatBox(
                  'Stock-Out Orders',
                  stockOutOrders.length.toString(),
                ),
              ],
            ),
            if (_includeDamagedProducts) pw.SizedBox(height: 10),
            if (_includeDamagedProducts)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.start,
                children: [
                  _buildStatBox(
                    'Damaged Products',
                    damagedProductsMeetings.length.toString(),
                  ),
                ],
              ),
            pw.SizedBox(height: 30),

            // Batches Section
            pw.Header(
              level: 1,
              child: pw.Text(
                'Batches',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
            ),
            pw.SizedBox(height: 10),

            if (batches.isEmpty)
              pw.Text('No batches found for the selected date range.'),

            if (batches.isNotEmpty)
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400),
                children: [
                  // Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: [
                      _buildTableHeader('Batch ID'),
                      _buildTableHeader('Quantity'),
                      _buildTableHeader('Production Date'),
                      _buildTableHeader('Expiry Date'),
                      _buildTableHeader('Inventory'),
                    ],
                  ),
                  // Data rows
                  for (final batch in batches)
                    pw.TableRow(
                      children: [
                        _buildTableCell(batch['batch_id']?.toString() ?? ''),
                        _buildTableCell(batch['quantity']?.toString() ?? '0'),
                        _buildTableCell(
                          batch['production_date'] != null
                              ? dateFormat.format(
                                  DateTime.parse(batch['production_date']),
                                )
                              : 'N/A',
                        ),
                        _buildTableCell(
                          batch['expiry_date'] != null
                              ? dateFormat.format(
                                  DateTime.parse(batch['expiry_date']),
                                )
                              : 'N/A',
                        ),
                        _buildTableCell(_formatInventory(batch['inventory'])),
                      ],
                    ),
                ],
              ),

            // Stock-In Orders Section
            if (_includeStockIn) ...[
              pw.SizedBox(height: 30),
              pw.Header(
                level: 1,
                child: pw.Text(
                  'Stock-In Orders',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800,
                  ),
                ),
              ),
              pw.SizedBox(height: 10),
              if (stockInOrders.isEmpty)
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey200,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'No delivered stock-in orders found for the selected date range.',
                      style: const pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ),
                )
              else
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey400),
                  children: [
                    // Header
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey300,
                      ),
                      children: [
                        _buildTableHeader('Order ID'),
                        _buildTableHeader('Supplier'),
                        _buildTableHeader('Quantity'),
                        _buildTableHeader('Date'),
                        _buildTableHeader('Status'),
                        _buildTableHeader('Total Cost'),
                      ],
                    ),
                    // Data rows
                    for (final order in stockInOrders)
                      pw.TableRow(
                        children: [
                          _buildTableCell(order['order_id']?.toString() ?? ''),
                          _buildTableCell(
                            (order['supplier'] as Map?)?['name']?.toString() ??
                                'N/A',
                          ),
                          _buildTableCell(order['quantity']?.toString() ?? '0'),
                          _buildTableCell(
                            order['order_date'] != null
                                ? dateFormat.format(
                                    DateTime.parse(order['order_date']),
                                  )
                                : 'N/A',
                          ),
                          _buildTableCell(
                            order['order_status']?.toString() ?? 'N/A',
                          ),
                          _buildTableCell(
                            '\$${(order['total_cost'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                          ),
                        ],
                      ),
                  ],
                ),
            ],

            // Stock-Out Orders Section
            if (_includeStockOut) ...[
              pw.SizedBox(height: 30),
              pw.Header(
                level: 1,
                child: pw.Text(
                  'Stock-Out Orders',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800,
                  ),
                ),
              ),
              pw.SizedBox(height: 10),
              if (stockOutOrders.isEmpty)
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey200,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'No delivered stock-out orders found for the selected date range.',
                      style: const pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ),
                )
              else
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey400),
                  children: [
                    // Header
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey300,
                      ),
                      children: [
                        _buildTableHeader('Order ID'),
                        _buildTableHeader('Customer'),
                        _buildTableHeader('Date'),
                        _buildTableHeader('Status'),
                        _buildTableHeader('Quantity'),
                        _buildTableHeader('Total Price'),
                      ],
                    ),
                    // Data rows
                    for (final order in stockOutOrders)
                      pw.TableRow(
                        children: [
                          _buildTableCell(
                            order['customer_order_id']?.toString() ?? '',
                          ),
                          _buildTableCell(
                            (order['customer'] as Map?)?['name']?.toString() ??
                                'N/A',
                          ),
                          _buildTableCell(
                            order['order_date'] != null
                                ? dateFormat.format(
                                    DateTime.parse(order['order_date']),
                                  )
                                : 'N/A',
                          ),
                          _buildTableCell(
                            order['order_status']?.toString() ?? 'N/A',
                          ),
                          _buildTableCell(order['quantity']?.toString() ?? '0'),
                          _buildTableCell(
                            '\$${(order['total_price'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                          ),
                        ],
                      ),
                  ],
                ),
            ],

            // Damaged Products Section
            if (_includeDamagedProducts) ...[
              pw.SizedBox(height: 30),
              pw.Header(
                level: 1,
                child: pw.Text(
                  'Damaged Products',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800,
                  ),
                ),
              ),
              pw.SizedBox(height: 10),
              if (damagedProductsMeetings.isEmpty)
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey200,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'No damaged products found for the selected date range.',
                      style: const pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ),
                )
              else
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey400),
                  children: [
                    // Header
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey300,
                      ),
                      children: [
                        _buildTableHeader('Meeting ID'),
                        _buildTableHeader('Meeting Topics'),
                        _buildTableHeader('Meeting Date'),
                        _buildTableHeader('Batch ID'),
                        _buildTableHeader('Quantity'),
                        _buildTableHeader('Reason'),
                      ],
                    ),
                    // Data rows
                    for (final item in damagedProductsMeetings)
                      pw.TableRow(
                        children: [
                          _buildTableCell(
                            (item['meeting'] is Map
                                    ? item['meeting']['meeting_id']?.toString()
                                    : '') ??
                                'N/A',
                          ),
                          _buildTableCell(
                            (item['meeting'] is Map
                                    ? item['meeting']['meeting_topics']
                                          ?.toString()
                                    : '') ??
                                'N/A',
                          ),
                          _buildTableCell(
                            (item['meeting'] is Map &&
                                    item['meeting']['meeting_time'] != null)
                                ? dateFormat.format(
                                    DateTime.parse(
                                      item['meeting']['meeting_time'],
                                    ),
                                  )
                                : 'N/A',
                          ),
                          _buildTableCell(
                            (item['batch'] is Map
                                    ? item['batch']['batch_id']?.toString()
                                    : '') ??
                                'N/A',
                          ),
                          _buildTableCell(item['quantity']?.toString() ?? '0'),
                          _buildTableCell(item['reason']?.toString() ?? 'N/A'),
                        ],
                      ),
                  ],
                ),
            ],
          ];
        },
      ),
    );

    return pdf;
  }

  pw.Widget _buildStatBox(String label, String value) {
    return pw.Container(
      width: 160,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
      ),
    );
  }

  pw.Widget _buildTableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 9)),
    );
  }

  String _formatInventory(dynamic inventory) {
    if (inventory is! Map) return 'N/A';
    final name = inventory['inventory_name']?.toString() ?? 'N/A';
    return name;
  }
}
