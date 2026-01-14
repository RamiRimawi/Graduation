import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import 'report_page.dart';
import '../../supabase_config.dart';

class GenerateSupplierReportDialog extends StatefulWidget {
  final String supplierId;
  final String supplierName;

  const GenerateSupplierReportDialog({
    super.key,
    required this.supplierId,
    required this.supplierName,
  });

  @override
  State<GenerateSupplierReportDialog> createState() =>
      _GenerateSupplierReportDialogState();
}

class _GenerateSupplierReportDialogState
    extends State<GenerateSupplierReportDialog> {
  bool _includeOrders = true;
  bool _includePayments = true;
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.picture_as_pdf,
                    color: AppColors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Generate Report',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Supplier Report Options',
                        style: TextStyle(
                          color: AppColors.grey,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close,
                    color: AppColors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Divider(color: Color(0xFF3D3D3D), height: 1),
            const SizedBox(height: 24),

            // Supplier Name
            Text(
              'Supplier: ${widget.supplierName}',
              style: const TextStyle(
                color: AppColors.blue,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 20),

            // Include Options
            const Text(
              'Include in Report:',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            // Orders Checkbox
            _buildCheckbox(
              label: 'Orders',
              value: _includeOrders,
              onChanged: (val) => setState(() => _includeOrders = val ?? true),
            ),
            const SizedBox(height: 8),

            // Payments Checkbox
            _buildCheckbox(
              label: 'Payments',
              value: _includePayments,
              onChanged: (val) =>
                  setState(() => _includePayments = val ?? true),
            ),

            const SizedBox(height: 24),

            // Date Range
            const Text(
              'Date Range (Optional):',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildDateField(
                    label: 'From',
                    date: _fromDate,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _fromDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => _fromDate = picked);
                      }
                    },
                    onClear: () => setState(() => _fromDate = null),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDateField(
                    label: 'To',
                    date: _toDate,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _toDate ?? DateTime.now(),
                        firstDate: _fromDate ?? DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => _toDate = picked);
                      }
                    },
                    onClear: () => setState(() => _toDate = null),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.white,
                      side: BorderSide(color: AppColors.grey.withOpacity(0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _generateReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Generate',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
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
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.cardAlt,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: value ? AppColors.blue : Colors.transparent,
            width: 1.5,
          ),
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
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.grey,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.cardAlt,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.blue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: AppColors.blue,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    date != null
                        ? '${date.day}/${date.month}/${date.year}'
                        : 'Select',
                    style: TextStyle(
                      color: date != null ? AppColors.white : AppColors.grey,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (date != null)
                  InkWell(
                    onTap: onClear,
                    child: Icon(Icons.close, color: AppColors.grey, size: 16),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _generateReport() async {
    // Validate at least one option is selected
    if (!_includeOrders && !_includePayments) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select at least one option (Orders or Payments)',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!mounted) return;

    // Capture the navigator context before closing this dialog
    final navigatorContext = Navigator.of(context);

    // Close this dialog first
    Navigator.pop(context);

    // Show loading indicator in parent context
    navigatorContext.push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (loadingContext) => WillPopScope(
          onWillPop: () async => false,
          child: Scaffold(
            backgroundColor: Colors.black.withOpacity(0.5),
            body: const Center(
              child: CircularProgressIndicator(color: AppColors.blue),
            ),
          ),
        ),
      ),
    );

    try {
      print('Starting supplier report generation...');
      final pdf = pw.Document();

      // Fetch supplier data
      final supplierId = int.parse(widget.supplierId);
      Map<String, dynamic>? supplierData;
      try {
        print('Fetching supplier data...');
        supplierData = await supabase
            .from('supplier')
            .select('name, mobile_number, address, creditor_balance')
            .eq('supplier_id', supplierId)
            .single()
            .timeout(const Duration(seconds: 30));
        print('Supplier data fetched successfully');
      } catch (e) {
        print('Error fetching supplier data: $e');
        throw Exception('Failed to fetch supplier data: $e');
      }

      // Fetch orders if selected
      List<Map<String, dynamic>> orders = [];
      if (_includeOrders) {
        try {
          print('Fetching orders...');
          dynamic queryBuilder = supabase
              .from('supplier_order')
              .select('order_id, order_date, total_cost, order_status')
              .eq('supplier_id', supplierId)
              .eq('order_status', 'Delivered');

          if (_fromDate != null) {
            queryBuilder = queryBuilder.gte(
              'order_date',
              _fromDate!.toIso8601String(),
            );
          }
          if (_toDate != null) {
            queryBuilder = queryBuilder.lte(
              'order_date',
              _toDate!.toIso8601String(),
            );
          }

          queryBuilder = queryBuilder
              .order('order_date', ascending: false)
              .limit(100);
          final ordersData = await queryBuilder.timeout(
            const Duration(seconds: 30),
          );
          orders = ordersData != null
              ? List<Map<String, dynamic>>.from(ordersData)
              : [];
          print('Found ${orders.length} orders');

          if (orders.length >= 100) {
            print(
              'WARNING: Order limit reached (100). Consider using date filters.',
            );
          }

          // Fetch order details for each order
          print('Fetching order details for ${orders.length} orders...');
          for (var i = 0; i < orders.length; i++) {
            var order = orders[i];
            try {
              if (i % 10 == 0) {
                print('Processing order ${i + 1}/${orders.length}...');
              }
              final orderDetails = await supabase
                  .from('supplier_order_description')
                  .select(
                    'quantity, price_per_product, product:product_id(name)',
                  )
                  .eq('order_id', order['order_id'])
                  .timeout(const Duration(seconds: 30));
              order['items'] = orderDetails ?? [];
            } catch (e) {
              print(
                'Error fetching order details for order ${order['order_id']}: $e',
              );
              order['items'] = [];
            }
          }
          print('Order details fetched successfully');
        } catch (e) {
          print('Error fetching orders: $e');
          orders = [];
        }
      }
      // Fetch payments if selected
      Map<String, List<Map<String, dynamic>>> payments = {
        'cash': [],
        'check': [],
        'returned': [],
      };

      if (_includePayments) {
        try {
          print('Fetching payments...');
          dynamic paymentQueryBuilder = supabase
              .from('outgoing_payment')
              .select('''
              payment_voucher_id,
              amount,
              date_time,
              description,
              payment_method,
              supplier_checks!check_id (
                check_id,
                bank_id,
                exchange_rate,
                exchange_date,
                check_image,
                banks!inner(bank_name)
              )
            ''')
              .eq('supplier_id', supplierId);

          if (_fromDate != null) {
            paymentQueryBuilder = paymentQueryBuilder.gte(
              'date_time',
              _fromDate!.toIso8601String(),
            );
          }
          if (_toDate != null) {
            paymentQueryBuilder = paymentQueryBuilder.lte(
              'date_time',
              _toDate!.toIso8601String(),
            );
          }

          paymentQueryBuilder = paymentQueryBuilder
              .order('date_time', ascending: false)
              .limit(100);
          final paymentData = await paymentQueryBuilder.timeout(
            const Duration(seconds: 30),
          );
          print('Payments fetched, processing...');

          if (paymentData != null) {
            for (var payment in paymentData) {
              if (payment != null) {
                final method = (payment['payment_method'] ?? 'cash')
                    .toString()
                    .toLowerCase();
                if (method == 'cash') {
                  payments['cash']!.add(payment);
                } else if (method == 'check' || method == 'endorsed_check') {
                  payments['check']!.add(payment);
                }
              }
            }
          }

          // Fetch returned checks
          try {
            print('Fetching returned checks...');
            dynamic returnedQueryBuilder = supabase
                .from('supplier_checks')
                .select('''
              check_id,
              exchange_rate,
              exchange_date,
              description,
              check_image,
              banks!inner(bank_name)
            ''')
                .eq('supplier_id', supplierId)
                .eq('status', 'Returned');

            if (_fromDate != null) {
              returnedQueryBuilder = returnedQueryBuilder.gte(
                'exchange_date',
                _fromDate!.toIso8601String(),
              );
            }
            if (_toDate != null) {
              returnedQueryBuilder = returnedQueryBuilder.lte(
                'exchange_date',
                _toDate!.toIso8601String(),
              );
            }

            returnedQueryBuilder = returnedQueryBuilder
                .order('exchange_date', ascending: false)
                .limit(100);
            final returnedData = await returnedQueryBuilder.timeout(
              const Duration(seconds: 30),
            );
            payments['returned'] = returnedData != null
                ? List<Map<String, dynamic>>.from(returnedData)
                : [];
            print('Found ${payments['returned']!.length} returned checks');
          } catch (e) {
            print('Error fetching returned checks: $e');
            payments['returned'] = [];
          }
        } catch (e) {
          print('Error fetching payments: $e');
        }
      }

      // Validate data before generating PDF
      if (supplierData == null) {
        throw Exception('Supplier data not found');
      }

      // Generate PDF pages
      try {
        print('Building PDF pages...');
        await _buildPdfPages(pdf, supplierData, orders, payments);
        print('PDF pages built successfully');
      } catch (e) {
        print('Error building PDF: $e');
        throw Exception('Failed to build PDF: $e');
      }

      // Show PDF preview
      print('Closing loading dialog...');
      navigatorContext.pop(); // Close loading route

      print('Showing PDF preview...');
      try {
        print('Calling Printing.layoutPdf...');
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async {
            print('PDF layout callback invoked');
            final bytes = await pdf.save();
            print('PDF saved, ${bytes.length} bytes');
            return bytes;
          },
        );
        print('PDF preview shown successfully');
      } catch (e) {
        print('Error displaying PDF: $e');
        throw Exception('Failed to display PDF: $e');
      }
    } catch (e) {
      print('Report generation error: $e');
      navigatorContext.pop(); // Close loading route

      // Show error in scaffold messenger of parent route
      ScaffoldMessenger.of(navigatorContext.context).showSnackBar(
        SnackBar(
          content: Text('Error generating report: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _buildPdfPages(
    pw.Document pdf,
    Map<String, dynamic> supplierData,
    List<Map<String, dynamic>> orders,
    Map<String, List<Map<String, dynamic>>> payments,
  ) async {
    // Pre-load all check images
    print('Pre-loading check images...');
    for (var payment in payments['check']!) {
      final checkDetails = payment['supplier_checks'];
      if (checkDetails?['check_image'] != null) {
        checkDetails['check_image_widget'] = await _loadCheckImage(
          checkDetails['check_image'],
        );
      }
    }
    for (var check in payments['returned']!) {
      if (check['check_image'] != null) {
        check['check_image_widget'] = await _loadCheckImage(
          check['check_image'],
        );
      }
    }
    print('Check images loaded');

    // First Page - Summary
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'SUPPLIER REPORT',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Generated: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                    style: const pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 30),

            // Supplier Information
            pw.Text(
              'Supplier Information',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 15),
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Supplier ID:', widget.supplierId),
                  _buildInfoRow('Name:', supplierData['name'] ?? 'N/A'),
                  _buildInfoRow(
                    'Mobile:',
                    supplierData['mobile_number'] ?? 'N/A',
                  ),
                  _buildInfoRow('Address:', supplierData['address'] ?? 'N/A'),
                  _buildInfoRow(
                    'Balance Credit:',
                    '\$${supplierData['creditor_balance'] ?? '0'}',
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 30),

            // Report Summary
            pw.Text(
              'Report Summary',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 15),

            // Date Range
            if (_fromDate != null || _toDate != null)
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                margin: const pw.EdgeInsets.only(bottom: 12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue50,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: PdfColors.blue200),
                ),
                child: pw.Row(
                  children: [
                    pw.Text(
                      'Date Range: ',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      '${_fromDate != null ? '${_fromDate!.day}/${_fromDate!.month}/${_fromDate!.year}' : 'All'} - ${_toDate != null ? '${_toDate!.day}/${_toDate!.month}/${_toDate!.year}' : 'All'}',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),

            // Orders Summary
            if (_includeOrders)
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                margin: const pw.EdgeInsets.only(bottom: 12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue50,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: PdfColors.blue200),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'ORDERS',
                      style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Total Orders:',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                        pw.Text(
                          '${orders.length}',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 5),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Total Amount:',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                        pw.Text(
                          '\$${orders.fold<double>(0, (sum, order) => sum + ((order['total_cost'] as num?)?.toDouble() ?? 0)).toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // Payments Summary
            if (_includePayments)
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green50,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: PdfColors.green200),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'PAYMENTS',
                      style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green900,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Cash Payments:',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                        pw.Text(
                          '${payments['cash']!.length}',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 5),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Check Payments:',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                        pw.Text(
                          '${payments['check']!.length}',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 5),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Returned Checks:',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                        pw.Text(
                          '${payments['returned']!.length}',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 10),
                    pw.Divider(color: PdfColors.green300),
                    pw.SizedBox(height: 5),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Total Payments:',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          '\$${_calculateTotalPayments(payments).toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.green900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );

    // Orders Section
    if (_includeOrders && orders.isNotEmpty) {
      // Add Orders Section Title Page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => pw.Center(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(30),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.circular(15),
                border: pw.Border.all(color: PdfColors.blue200, width: 2),
              ),
              child: pw.Column(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Text(
                    'ORDERS SECTION',
                    style: pw.TextStyle(
                      fontSize: 32,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.SizedBox(height: 15),
                  pw.Text(
                    'Total Orders: ${orders.length}',
                    style: pw.TextStyle(fontSize: 18, color: PdfColors.blue800),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      for (var i = 0; i < orders.length; i++) {
        final order = orders[i];
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (context) => _buildOrderPage(order, i + 1, orders.length),
          ),
        );
      }
    }

    // Payments Section
    if (_includePayments) {
      // Add Payments Section Title Page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => pw.Center(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(30),
              decoration: pw.BoxDecoration(
                color: PdfColors.green50,
                borderRadius: pw.BorderRadius.circular(15),
                border: pw.Border.all(color: PdfColors.green200, width: 2),
              ),
              child: pw.Column(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Text(
                    'PAYMENT SECTION',
                    style: pw.TextStyle(
                      fontSize: 32,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green900,
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    'Cash Payments: ${payments['cash']!.length}',
                    style: pw.TextStyle(
                      fontSize: 16,
                      color: PdfColors.green800,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Check Payments: ${payments['check']!.length}',
                    style: pw.TextStyle(
                      fontSize: 16,
                      color: PdfColors.green800,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Returned Checks: ${payments['returned']!.length}',
                    style: pw.TextStyle(
                      fontSize: 16,
                      color: PdfColors.green800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Cash Payments
      if (payments['cash']!.isNotEmpty) {
        // Add Cash Section Title Page
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (context) => pw.Center(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(25),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green50,
                  borderRadius: pw.BorderRadius.circular(12),
                  border: pw.Border.all(color: PdfColors.green300, width: 2),
                ),
                child: pw.Column(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Text(
                      'CASH PAYMENTS',
                      style: pw.TextStyle(
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green900,
                      ),
                    ),
                    pw.SizedBox(height: 12),
                    pw.Text(
                      'Total: ${payments['cash']!.length}',
                      style: pw.TextStyle(
                        fontSize: 16,
                        color: PdfColors.green800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        for (var i = 0; i < payments['cash']!.length; i++) {
          pdf.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a4,
              build: (context) => _buildCashPaymentPage(
                payments['cash']![i],
                i + 1,
                payments['cash']!.length,
              ),
            ),
          );
        }
      }

      // Check Payments
      if (payments['check']!.isNotEmpty) {
        // Add Check Section Title Page
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (context) => pw.Center(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(25),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue50,
                  borderRadius: pw.BorderRadius.circular(12),
                  border: pw.Border.all(color: PdfColors.blue300, width: 2),
                ),
                child: pw.Column(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Text(
                      'CHECK PAYMENTS',
                      style: pw.TextStyle(
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.SizedBox(height: 12),
                    pw.Text(
                      'Total: ${payments['check']!.length}',
                      style: pw.TextStyle(
                        fontSize: 16,
                        color: PdfColors.blue800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        for (var i = 0; i < payments['check']!.length; i++) {
          pdf.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a4,
              build: (context) => _buildCheckPaymentPage(
                payments['check']![i],
                i + 1,
                payments['check']!.length,
              ),
            ),
          );
        }
      }

      // Returned Checks
      if (payments['returned']!.isNotEmpty) {
        // Add Returned Check Section Title Page
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (context) => pw.Center(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(25),
                decoration: pw.BoxDecoration(
                  color: PdfColors.red50,
                  borderRadius: pw.BorderRadius.circular(12),
                  border: pw.Border.all(color: PdfColors.red300, width: 2),
                ),
                child: pw.Column(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Text(
                      'RETURNED CHECKS',
                      style: pw.TextStyle(
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.red900,
                      ),
                    ),
                    pw.SizedBox(height: 12),
                    pw.Text(
                      'Total: ${payments['returned']!.length}',
                      style: pw.TextStyle(
                        fontSize: 16,
                        color: PdfColors.red800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        for (var i = 0; i < payments['returned']!.length; i++) {
          pdf.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a4,
              build: (context) => _buildReturnedCheckPage(
                payments['returned']![i],
                i + 1,
                payments['returned']!.length,
              ),
            ),
          );
        }
      }
    }
  }

  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  double _calculateTotalPayments(
    Map<String, List<Map<String, dynamic>>> payments,
  ) {
    double total = 0;
    for (var payment in payments['cash']!) {
      total += (payment['amount'] as num?)?.toDouble() ?? 0;
    }
    for (var payment in payments['check']!) {
      total += (payment['amount'] as num?)?.toDouble() ?? 0;
    }
    for (var check in payments['returned']!) {
      total += (check['exchange_rate'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }

  pw.Widget _buildOrderPage(
    Map<String, dynamic> order,
    int orderNum,
    int totalOrders,
  ) {
    final orderDate = order['order_date'] != null
        ? DateTime.parse(order['order_date'])
        : null;
    final items = (order['items'] as List<dynamic>?) ?? [];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Order Header
        pw.Container(
          padding: const pw.EdgeInsets.all(15),
          decoration: pw.BoxDecoration(
            color: PdfColors.blue50,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'ORDER #${order['order_id']}',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Order ${orderNum} of ${totalOrders}',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Date: ${orderDate != null ? '${orderDate.day}/${orderDate.month}/${orderDate.year}' : 'N/A'}',
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Status: ${order['order_status'] ?? 'N/A'}',
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 20),

        // Order Items Table
        pw.Text(
          'Order Items',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            // Header
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildTableCell('Product', isHeader: true),
                _buildTableCell('Quantity', isHeader: true),
                _buildTableCell('Price', isHeader: true),
                _buildTableCell('Total', isHeader: true),
              ],
            ),
            // Items
            ...items.map((item) {
              final productName = item['product']?['name'] ?? 'Unknown';
              final quantity = item['quantity']?.toString() ?? '0';
              final pricePerProduct =
                  item['price_per_product']?.toString() ?? '0';
              final totalPrice =
                  item['quantity'] != null && item['price_per_product'] != null
                  ? (item['quantity'] * item['price_per_product'])
                        .toStringAsFixed(2)
                  : '0';

              return pw.TableRow(
                children: [
                  _buildTableCell(productName),
                  _buildTableCell(quantity),
                  _buildTableCell('\$$pricePerProduct'),
                  _buildTableCell('\$$totalPrice'),
                ],
              );
            }),
          ],
        ),

        pw.SizedBox(height: 20),

        // Order Total
        pw.Container(
          padding: const pw.EdgeInsets.all(15),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Order Total:',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                '\$${order['total_cost']?.toString() ?? '0'}',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildCashPaymentPage(
    Map<String, dynamic> payment,
    int paymentNum,
    int totalPayments,
  ) {
    final paymentDate = payment['date_time'] != null
        ? DateTime.parse(payment['date_time'])
        : null;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Payment Header
        pw.Container(
          padding: const pw.EdgeInsets.all(15),
          decoration: pw.BoxDecoration(
            color: PdfColors.green50,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'CASH PAYMENT',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green900,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                'Payment ${paymentNum} of ${totalPayments}',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 20),

        // Payment Details
        pw.Container(
          padding: const pw.EdgeInsets.all(15),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildInfoRow(
                'Payment Voucher ID:',
                payment['payment_voucher_id']?.toString() ?? 'N/A',
              ),
              _buildInfoRow(
                'Amount:',
                '\$${payment['amount']?.toString() ?? '0'}',
              ),
              _buildInfoRow(
                'Date:',
                paymentDate != null
                    ? '${paymentDate.day}/${paymentDate.month}/${paymentDate.year}'
                    : 'N/A',
              ),
              _buildInfoRow(
                'Time:',
                paymentDate != null
                    ? '${paymentDate.hour}:${paymentDate.minute.toString().padLeft(2, '0')}'
                    : 'N/A',
              ),
              _buildInfoRow('Method:', 'Cash'),
              if (payment['description'] != null &&
                  payment['description'].toString().isNotEmpty)
                _buildInfoRow(
                  'Description:',
                  payment['description'].toString(),
                ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildCheckPaymentPage(
    Map<String, dynamic> payment,
    int paymentNum,
    int totalPayments,
  ) {
    final paymentDate = payment['date_time'] != null
        ? DateTime.parse(payment['date_time'])
        : null;
    final checkDetails = payment['supplier_checks'];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Payment Header
        pw.Container(
          padding: const pw.EdgeInsets.all(15),
          decoration: pw.BoxDecoration(
            color: PdfColors.blue50,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'CHECK PAYMENT',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                'Payment ${paymentNum} of ${totalPayments}',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 20),

        // Payment Details
        pw.Container(
          padding: const pw.EdgeInsets.all(15),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildInfoRow(
                'Payment Voucher ID:',
                payment['payment_voucher_id']?.toString() ?? 'N/A',
              ),
              _buildInfoRow(
                'Amount:',
                '\$${payment['amount']?.toString() ?? '0'}',
              ),
              _buildInfoRow(
                'Date:',
                paymentDate != null
                    ? '${paymentDate.day}/${paymentDate.month}/${paymentDate.year}'
                    : 'N/A',
              ),
              _buildInfoRow('Method:', 'Check'),
              if (checkDetails != null) ...[
                pw.SizedBox(height: 10),
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Check Details',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                pw.SizedBox(height: 8),
                _buildInfoRow(
                  'Check ID:',
                  checkDetails['check_id']?.toString() ?? 'N/A',
                ),
                _buildInfoRow(
                  'Bank:',
                  checkDetails['banks']?['bank_name'] ?? 'N/A',
                ),
                _buildInfoRow(
                  'Exchange Rate:',
                  '\$${checkDetails['exchange_rate']?.toString() ?? '0'}',
                ),
                if (checkDetails['exchange_date'] != null)
                  _buildInfoRow(
                    'Exchange Date:',
                    DateTime.parse(
                          checkDetails['exchange_date'],
                        ).day.toString() +
                        '/' +
                        DateTime.parse(
                          checkDetails['exchange_date'],
                        ).month.toString() +
                        '/' +
                        DateTime.parse(
                          checkDetails['exchange_date'],
                        ).year.toString(),
                  ),
              ],
            ],
          ),
        ),

        // Check Image will be added if available
        if (checkDetails?['check_image_widget'] != null) ...[
          pw.SizedBox(height: 20),
          pw.Text(
            'Check Image',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
          ),
          pw.SizedBox(height: 10),
          checkDetails['check_image_widget'],
        ],
      ],
    );
  }

  pw.Widget _buildReturnedCheckPage(
    Map<String, dynamic> check,
    int checkNum,
    int totalChecks,
  ) {
    final checkDate = check['exchange_date'] != null
        ? DateTime.parse(check['exchange_date'])
        : null;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Check Header
        pw.Container(
          padding: const pw.EdgeInsets.all(15),
          decoration: pw.BoxDecoration(
            color: PdfColors.red50,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'RETURNED CHECK',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.red900,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                'Check ${checkNum} of ${totalChecks}',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 20),

        // Check Details
        pw.Container(
          padding: const pw.EdgeInsets.all(15),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildInfoRow(
                'Check ID:',
                check['check_id']?.toString() ?? 'N/A',
              ),
              _buildInfoRow(
                'Amount:',
                '\$${check['exchange_rate']?.toString() ?? '0'}',
              ),
              _buildInfoRow(
                'Exchange Date:',
                checkDate != null
                    ? '${checkDate.day}/${checkDate.month}/${checkDate.year}'
                    : 'N/A',
              ),
              _buildInfoRow('Bank:', check['banks']?['bank_name'] ?? 'N/A'),
              _buildInfoRow('Status:', 'Returned'),
              if (check['description'] != null &&
                  check['description'].toString().isNotEmpty)
                _buildInfoRow('Description:', check['description'].toString()),
            ],
          ),
        ),

        // Check Image will be added if available
        if (check['check_image_widget'] != null) ...[
          pw.SizedBox(height: 20),
          pw.Text(
            'Check Image',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
          ),
          pw.SizedBox(height: 10),
          check['check_image_widget'],
        ],
      ],
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 11 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  Future<pw.Widget> _loadCheckImage(String imageUrl) async {
    try {
      print('Loading check image from: $imageUrl');

      // If it's a Supabase storage path, get the public URL
      String fullUrl = imageUrl;
      if (!imageUrl.startsWith('http')) {
        fullUrl = supabase.storage.from('check-images').getPublicUrl(imageUrl);
      }

      print('Full image URL: $fullUrl');
      final response = await http.get(Uri.parse(fullUrl));

      if (response.statusCode == 200) {
        print('Image loaded successfully, ${response.bodyBytes.length} bytes');
        return pw.Container(
          height: 200,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.ClipRRect(
            horizontalRadius: 8,
            verticalRadius: 8,
            child: pw.Image(
              pw.MemoryImage(response.bodyBytes),
              fit: pw.BoxFit.contain,
            ),
          ),
        );
      } else {
        print('Failed to load image, status code: ${response.statusCode}');
        return _buildImagePlaceholder('Failed to load image');
      }
    } catch (e) {
      print('Error loading check image: $e');
      return _buildImagePlaceholder('Error loading image');
    }
  }

  pw.Widget _buildImagePlaceholder(String message) {
    return pw.Container(
      height: 200,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
        color: PdfColors.grey100,
      ),
      child: pw.Center(
        child: pw.Text(
          message,
          textAlign: pw.TextAlign.center,
          style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 10),
        ),
      ),
    );
  }
}
