import 'package:flutter/material.dart';
import '../sidebar.dart';
import '../Payment_header.dart';
import '../../supabase_config.dart';

/// صفحة: Payment - Archive (Incoming / Outgoing)
class ArchivePaymentPage extends StatefulWidget {
  const ArchivePaymentPage({super.key});

  @override
  State<ArchivePaymentPage> createState() => _ArchivePaymentPageState();
}

class _ArchivePaymentPageState extends State<ArchivePaymentPage> {
  bool isIncoming = true;
  List<Map<String, dynamic>> incomingPayments = [];
  List<Map<String, dynamic>> outgoingPayments = [];
  List<Map<String, dynamic>> filteredIncomingPayments = [];
  List<Map<String, dynamic>> filteredOutgoingPayments = [];
  bool isLoading = false;
  final TextEditingController _searchController = TextEditingController();

  // Date filter state
  DateTime? _fromDate;
  DateTime? _toDate;
  final GlobalKey _filterButtonKey = GlobalKey();
  OverlayEntry? _filterOverlay;
  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();

  // Hover state tracking
  int? hoveredRow;

  @override
  void initState() {
    super.initState();
    _fetchPayments();
    _searchController.addListener(_filterPayments);
  }

  @override
  void dispose() {
    _filterOverlay?.remove();
    _filterOverlay = null;
    _searchController.dispose();
    _fromDateController.dispose();
    _toDateController.dispose();
    super.dispose();
  }

  void _filterPayments() {
    final query = _searchController.text.toLowerCase();

    // Filter incoming payments
    List<Map<String, dynamic>> tempIncoming = incomingPayments;

    // Apply date filter
    if (_fromDate != null || _toDate != null) {
      tempIncoming = tempIncoming.where((payment) {
        final dateStr = payment['date'] as String;
        final paymentDate = _parseDateString(dateStr);
        if (paymentDate == null) return false;

        if (_fromDate != null && paymentDate.isBefore(_fromDate!)) {
          return false;
        }
        if (_toDate != null && paymentDate.isAfter(_toDate!)) {
          return false;
        }
        return true;
      }).toList();
    }

    // Apply search filter
    if (query.isNotEmpty) {
      tempIncoming = tempIncoming
          .where(
            (payment) =>
                payment['payer'].toString().toLowerCase().startsWith(query),
          )
          .toList();
    }

    // Filter outgoing payments
    List<Map<String, dynamic>> tempOutgoing = outgoingPayments;

    // Apply date filter
    if (_fromDate != null || _toDate != null) {
      tempOutgoing = tempOutgoing.where((payment) {
        final dateStr = payment['date'] as String;
        final paymentDate = _parseDateString(dateStr);
        if (paymentDate == null) return false;

        if (_fromDate != null && paymentDate.isBefore(_fromDate!)) {
          return false;
        }
        if (_toDate != null && paymentDate.isAfter(_toDate!)) {
          return false;
        }
        return true;
      }).toList();
    }

    // Apply search filter
    if (query.isNotEmpty) {
      tempOutgoing = tempOutgoing
          .where(
            (payment) =>
                payment['payee'].toString().toLowerCase().startsWith(query),
          )
          .toList();
    }

    setState(() {
      filteredIncomingPayments = tempIncoming;
      filteredOutgoingPayments = tempOutgoing;
    });
  }

  DateTime? _parseDateString(String dateStr) {
    try {
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<void> _fetchPayments() async {
    setState(() => isLoading = true);
    await Future.wait([_fetchIncomingPayments(), _fetchOutgoingPayments()]);
    setState(() => isLoading = false);
  }

  Future<void> _fetchIncomingPayments() async {
    try {
      final response = await supabase
          .from('incoming_payment')
          .select('''
            payment_id,
            amount,
            date_time,
            description,
            payment_method,
            check_id,
            customer_id,
            customer:customer_id (
              name
            ),
            customer_checks!check_id (
              check_id,
              bank_id,
              bank_branch,
              check_image,
              exchange_rate,
              exchange_date,
              status,
              description,
              endorsed_description,
              endorsed_to,
              banks!bank_id (
                bank_name
              ),
              branches!bank_branch (
                address
              )
            )
          ''')
          .order('date_time', ascending: false);

        final List<Map<String, dynamic>> payments = [];
        for (var payment in response) {
          payments.add({
            'payment_id': payment['payment_id'],
            'payer': payment['customer']?['name'] ?? 'Unknown',
            'payment_method': payment['payment_method'] ?? 'cash',
            'price': '\$${payment['amount']?.toString() ?? '0'}',
            'date': _formatDate(payment['date_time']),
            'description': payment['description'] ?? '',
            'check_details': payment['customer_checks'],
            'customer_id': payment['customer_id'],
            'amount': payment['amount'],
            'date_time': payment['date_time'],
          });
        }

        // Append returned checks as payment_method = returned_check
        await _fetchReturnedIncomingChecks(payments);

        setState(() {
          incomingPayments = payments;
          filteredIncomingPayments = payments;
        });
      
    } catch (e) {
      print('Error fetching incoming payments: $e');
    }
  }

  Future<void> _fetchReturnedIncomingChecks(
    List<Map<String, dynamic>> payments,
  ) async {
    try {
      final response = await supabase
          .from('customer_checks')
          .select('''
            check_id,
            exchange_rate,
            exchange_date,
            status,
            description,
            endorsed_description,
            endorsed_to,
            customer_id,
            customer:customer_id ( name ),
            banks:bank_id ( bank_name ),
            branches:bank_branch ( address ),
            check_image
          ''')
          .eq('status', 'Returned')
          .order('exchange_date', ascending: false);

        for (var check in response) {
          payments.add({
            'payment_id': 'RC-${check['check_id']}',
            'payer': check['customer']?['name'] ?? 'Unknown',
            'payment_method': 'returned_check',
            'price': '\$${check['exchange_rate']?.toString() ?? '0'}',
            'date': _formatDate(check['exchange_date']?.toString()),
            'description': check['description'] ?? '',
            'check_details': check,
            'customer_id': check['customer_id'],
            'amount': check['exchange_rate'],
            'date_time': check['exchange_date'],
          });
        }
      
    } catch (e) {
      print('Error fetching returned incoming checks: $e');
    }
  }

  Future<void> _fetchReturnedOutgoingChecks(
    List<Map<String, dynamic>> payments,
  ) async {
    try {
      final response = await supabase
          .from('supplier_checks')
          .select('''
            check_id,
            exchange_rate,
            exchange_date,
            status,
            description,
            supplier_id,
            supplier:supplier_id ( name ),
            banks:bank_id ( bank_name ),
            branches:bank_branch ( address ),
            check_image
          ''')
          .eq('status', 'Returned')
          .order('exchange_date', ascending: false);

        for (var check in response) {
          payments.add({
            'payment_voucher_id': 'RC-${check['check_id']}',
            'payee': check['supplier']?['name'] ?? 'Unknown',
            'payment_method': 'returned_check',
            'price': '\$${check['exchange_rate']?.toString() ?? '0'}',
            'date': _formatDate(check['exchange_date']?.toString()),
            'description': check['description'] ?? '',
            'check_details': check,
            'supplier_id': check['supplier_id'],
            'amount': check['exchange_rate'],
            'date_time': check['exchange_date'],
          });
        }
      
    } catch (e) {
      print('Error fetching returned outgoing checks: $e');
    }
  }

  Future<void> _fetchOutgoingPayments() async {
    try {
      final response = await supabase
          .from('outgoing_payment')
          .select('''
            payment_voucher_id,
            amount,
            date_time,
            description,
            payment_method,
            check_id,
            supplier_id,
            supplier:supplier_id (
              name
            ),
            supplier_checks!check_id (
              check_id,
              bank_id,
              bank_branch,
              check_image,
              exchange_rate,
              exchange_date,
              status,
              description,
              banks!bank_id (
                bank_name
              ),
              branches!bank_branch (
                address
              )
            )
          ''')
          .order('date_time', ascending: false);

      final List<Map<String, dynamic>> payments = [];
      for (var payment in response) {
        payments.add({
          'payment_voucher_id': payment['payment_voucher_id'],
          'payee': payment['supplier']?['name'] ?? 'Unknown',
          'payment_method': payment['payment_method'] ?? 'cash',
          'price': '\$${payment['amount']?.toString() ?? '0'}',
          'date': _formatDate(payment['date_time']),
          'description': payment['description'] ?? '',
          'check_details': payment['supplier_checks'],
          'supplier_id': payment['supplier_id'],
          'amount': payment['amount'],
          'date_time': payment['date_time'],
        });

        // Append returned supplier checks as payment_method = returned_check
        await _fetchReturnedOutgoingChecks(payments);

        setState(() {
          outgoingPayments = payments;
          filteredOutgoingPayments = payments;
        });
      }
    } catch (e) {
      print('Error fetching outgoing payments: $e');
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  void _showPaymentDetailsDialog(
    Map<String, dynamic> payment,
    bool isIncoming,
  ) async {
    // For endorsed checks, fetch the customer check details
    Map<String, dynamic>? endorsedCheckDetails;
    final paymentMethodStr = (payment['payment_method'] ?? '')
        .toString()
        .toLowerCase();
    if ((paymentMethodStr == 'endorsed_check' ||
            paymentMethodStr == 'endorsed check') &&
        !isIncoming) {
      final description = payment['description'] ?? '';
      final checkIdMatch = RegExp(r'check #(\d+)').firstMatch(description);
      if (checkIdMatch != null) {
        final checkId = int.tryParse(checkIdMatch.group(1) ?? '');
        if (checkId != null) {
          try {
            final response = await supabase
                .from('customer_checks')
                .select('''
                  check_id,
                  bank_id,
                  bank_branch,
                  check_image,
                  exchange_rate,
                  exchange_date,
                  status,
                  description,
                  endorsed_description,
                  endorsed_to,
                  banks!bank_id (
                    bank_name
                  ),
                  branches!bank_branch (
                    address
                  )
                ''')
                .eq('check_id', checkId)
                .maybeSingle();

            if (response != null) {
              endorsedCheckDetails = response;
            }
          } catch (e) {
            print('Error fetching endorsed check details: $e');
          }
        }
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        final paymentMethod = payment['payment_method'] ?? 'cash';
        final paymentMethodLabel = paymentMethod
            .toString()
            .replaceAll('_', ' ')
            .toUpperCase();
        final isReturnedCheck =
            paymentMethod == 'returned_check' ||
            paymentMethod == 'returned check';
        final isEndorsedCheck =
            paymentMethod == 'endorsed_check' ||
            paymentMethod == 'endorsed check';
        final isCheckPayment =
            paymentMethod == 'check' ||
            paymentMethod == 'returned_check' ||
            paymentMethod == 'returned check' ||
            paymentMethod == 'endorsed_check' ||
            paymentMethod == 'endorsed check';
        final hasEndorsement =
            (payment['check_details']?['endorsed_to']?.toString().isNotEmpty ??
                false) ||
            (payment['check_details']?['endorsed_description']
                    ?.toString()
                    .isNotEmpty ??
                false);

        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.7,
            constraints: const BoxConstraints(maxWidth: 650, maxHeight: 700),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.blue.withOpacity(0.2),
                width: 1,
              ),
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
                // Modern Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.blue.withOpacity(0.1),
                        AppColors.cardAlt,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isIncoming
                              ? Icons.arrow_circle_down
                              : Icons.arrow_circle_up,
                          color: AppColors.blue,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${isIncoming ? 'Incoming' : 'Outgoing'} Payment',
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Payment ID: ${isIncoming ? payment['payment_id'] : payment['payment_voucher_id']}',
                              style: TextStyle(
                                color: AppColors.grey,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.close_rounded,
                          color: AppColors.white.withOpacity(0.7),
                          size: 24,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          hoverColor: AppColors.blue.withOpacity(0.1),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Amount Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.cardAlt,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.blue.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.attach_money,
                                  color: AppColors.blue,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total Amount',
                                      style: TextStyle(
                                        color: AppColors.grey,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      '\$${payment['amount']?.toString() ?? '0'}',
                                      style: const TextStyle(
                                        color: AppColors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isReturnedCheck
                                      ? Colors.redAccent.withOpacity(0.12)
                                      : isEndorsedCheck
                                      ? Colors.orangeAccent.withOpacity(0.12)
                                      : paymentMethod == 'check'
                                      ? AppColors.blue.withOpacity(0.1)
                                      : Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isReturnedCheck
                                        ? Colors.redAccent
                                        : isEndorsedCheck
                                        ? Colors.orangeAccent
                                        : paymentMethod == 'check'
                                        ? AppColors.blue
                                        : Colors.green,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  paymentMethodLabel,
                                  style: TextStyle(
                                    color: isReturnedCheck
                                        ? Colors.redAccent
                                        : isEndorsedCheck
                                        ? Colors.orangeAccent
                                        : paymentMethod == 'check'
                                        ? AppColors.blue
                                        : Colors.green,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Details Grid
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left Column (Name, Payment Method)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildDetailCard(
                                    icon: isIncoming
                                        ? Icons.person
                                        : Icons.business,
                                    title: isIncoming
                                        ? 'Customer Name'
                                        : 'Supplier Name',
                                    value: isIncoming
                                        ? payment['payer']
                                        : payment['payee'],
                                  ),
                                  const SizedBox(height: 16),
                                  _buildDetailCard(
                                    icon: Icons.payment,
                                    title: 'Payment Method',
                                    value: paymentMethodLabel,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Right Column (Date, Time)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildDetailCard(
                                    icon: Icons.calendar_today,
                                    title: 'Date',
                                    value: _formatDate(payment['date_time']),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildDetailCard(
                                    icon: Icons.schedule,
                                    title: 'Time',
                                    value: _formatTime(payment['date_time']),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Full-width description section
                        if (payment['description']?.isNotEmpty ?? false) ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.cardAlt,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.blue.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.description,
                                      color: AppColors.blue,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Description',
                                      style: TextStyle(
                                        color: AppColors.blue,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  payment['description'],
                                  style: const TextStyle(
                                    color: AppColors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Check Details Section (checks + returned checks + endorsed checks)
                        if (isEndorsedCheck &&
                            endorsedCheckDetails != null) ...[
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.cardAlt,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.orangeAccent.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.orangeAccent.withOpacity(
                                          0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.swap_horiz,
                                        color: Colors.orangeAccent,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Endorsed Customer Check',
                                            style: TextStyle(
                                              color: Colors.orangeAccent,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Original customer check information',
                                            style: TextStyle(
                                              color: AppColors.grey,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildCheckDetail(
                                        'Check ID',
                                        endorsedCheckDetails['check_id']
                                                ?.toString() ??
                                            'N/A',
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildCheckDetail(
                                        'Bank',
                                        endorsedCheckDetails['banks']?['bank_name'] ??
                                            'N/A',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildCheckDetail(
                                        'Exchange Rate',
                                        endorsedCheckDetails['exchange_rate']
                                                ?.toString() ??
                                            'N/A',
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildCheckDetail(
                                        'Exchange Date',
                                        _formatDate(
                                          endorsedCheckDetails['exchange_date']
                                              ?.toString(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildCheckDetail(
                                        'Status',
                                        endorsedCheckDetails['status'] ?? 'N/A',
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildCheckDetail(
                                        'Branch',
                                        endorsedCheckDetails['branches']?['address'] ??
                                            'N/A',
                                      ),
                                    ),
                                  ],
                                ),
                                if (endorsedCheckDetails['endorsed_description']
                                        ?.toString()
                                        .isNotEmpty ??
                                    false) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: AppColors.card,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.orangeAccent.withOpacity(
                                          0.2,
                                        ),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: const [
                                            Icon(
                                              Icons.info_outline,
                                              color: Colors.orangeAccent,
                                              size: 16,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Endorsement Notes',
                                              style: TextStyle(
                                                color: Colors.orangeAccent,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          endorsedCheckDetails['endorsed_description']
                                                  ?.toString() ??
                                              '',
                                          style: const TextStyle(
                                            color: AppColors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 16),
                                if (endorsedCheckDetails['check_image'] !=
                                    null) ...[
                                  Container(
                                    width: double.infinity,
                                    height: 200,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.orangeAccent.withOpacity(
                                          0.3,
                                        ),
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        endorsedCheckDetails['check_image'],
                                        fit: BoxFit.cover,
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
                                              if (loadingProgress == null)
                                                return child;
                                              return Center(
                                                child:
                                                    CircularProgressIndicator(
                                                      color:
                                                          Colors.orangeAccent,
                                                    ),
                                              );
                                            },
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return Center(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.error,
                                                      color: AppColors.grey,
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      'Failed to load image',
                                                      style: TextStyle(
                                                        color: AppColors.grey,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ] else if (isEndorsedCheck) ...[
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.orangeAccent.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.orangeAccent.withOpacity(0.4),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  color: Colors.orangeAccent,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Check details could not be loaded. This payment was made using an endorsed customer check.',
                                    style: TextStyle(
                                      color: AppColors.white.withOpacity(0.8),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else if (isCheckPayment) ...[
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.cardAlt,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.blue.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.account_balance,
                                      color: AppColors.blue,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Check Information',
                                      style: TextStyle(
                                        color: AppColors.blue,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                if (isReturnedCheck) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.redAccent.withOpacity(
                                          0.4,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.report,
                                          color: Colors.redAccent,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'This check was returned. Review the bank and status details below.',
                                            style: const TextStyle(
                                              color: Colors.redAccent,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 16),
                                if (payment['check_details'] != null) ...[
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildCheckDetail(
                                          'Check ID',
                                          payment['check_details']['check_id']
                                                  ?.toString() ??
                                              'N/A',
                                        ),
                                      ),
                                      Expanded(
                                        child: _buildCheckDetail(
                                          'Bank',
                                          payment['check_details']['banks']?['bank_name'] ??
                                              'N/A',
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildCheckDetail(
                                          'Exchange Rate',
                                          payment['check_details']['exchange_rate']
                                                  ?.toString() ??
                                              'N/A',
                                        ),
                                      ),
                                      Expanded(
                                        child: _buildCheckDetail(
                                          'Exchange Date',
                                          _formatDate(
                                            payment['check_details']['exchange_date']
                                                ?.toString(),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildCheckDetail(
                                          'Status',
                                          payment['check_details']['status'] ??
                                              'N/A',
                                        ),
                                      ),
                                      Expanded(
                                        child: _buildCheckDetail(
                                          'Branch',
                                          payment['check_details']['branches']?['address'] ??
                                              'N/A',
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (hasEndorsement) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: AppColors.card,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppColors.blue.withOpacity(
                                            0.2,
                                          ),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: const [
                                              Icon(
                                                Icons.swap_horiz,
                                                color: AppColors.blue,
                                                size: 18,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                'Endorsement Details',
                                                style: TextStyle(
                                                  color: AppColors.blue,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          _buildCheckDetail(
                                            'Endorsed To',
                                            payment['check_details']['endorsed_to']
                                                    ?.toString() ??
                                                'N/A',
                                          ),
                                          const SizedBox(height: 8),
                                          _buildCheckDetail(
                                            'Notes',
                                            payment['check_details']['endorsed_description']
                                                    ?.toString() ??
                                                'N/A',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  if (payment['check_details']['check_image'] !=
                                      null) ...[
                                    Container(
                                      width: double.infinity,
                                      height: 200,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppColors.blue.withOpacity(
                                            0.2,
                                          ),
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          payment['check_details']['check_image'],
                                          fit: BoxFit.cover,
                                          loadingBuilder:
                                              (
                                                context,
                                                child,
                                                loadingProgress,
                                              ) {
                                                if (loadingProgress == null)
                                                  return child;
                                                return Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                        color: AppColors.blue,
                                                      ),
                                                );
                                              },
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                return Center(
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                        Icons.error,
                                                        color: AppColors.grey,
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        'Failed to load image',
                                                        style: TextStyle(
                                                          color: AppColors.grey,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                        ),
                                      ),
                                    ),
                                  ],
                                ] else ...[
                                  Center(
                                    child: Text(
                                      'Check details not available',
                                      style: TextStyle(
                                        color: AppColors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.blue.withOpacity(0.1), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.blue, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.grey,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      body: Row(
        children: [
          const Sidebar(activeIndex: 4),
          Expanded(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ================== Header & Tabs ==================
                    PaymentHeader(
                      currentPage: 'archive',
                      isIncoming: isIncoming,
                      onIncomingChanged: (value) {
                        setState(() => isIncoming = value);
                      },
                    ),

                    const SizedBox(height: 18),

                    // ================== Search + Filter ==================
                    Row(
                      children: [
                        Spacer(),
                        _SearchFilterBar(
                          controller: _searchController,
                          filterButtonKey: _filterButtonKey,
                          onFilterTap: _toggleFilterPopup,
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // ================== جدول الأرشيف ==================
                    Expanded(
                      child: _ArchiveTable(
                        isIncoming: isIncoming,
                        incomingPayments: filteredIncomingPayments,
                        outgoingPayments: filteredOutgoingPayments,
                        isLoading: isLoading,
                        onPaymentTap: _showPaymentDetailsDialog,
                        hoveredRow: hoveredRow,
                        onHoverChanged: (index) =>
                            setState(() => hoveredRow = index),
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

  /* ----------------------- FILTER POPUP ----------------------- */

  void _toggleFilterPopup() {
    if (_filterOverlay != null) {
      _closeFilterPopup();
    } else {
      _showFilterPopup();
    }
  }

  void _showFilterPopup() {
    final RenderBox? renderBox =
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
                      color: const Color(0xFF2D2D2D),
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
                        Text(
                          'Filter by Date Range',
                          style: TextStyle(
                            color: AppColors.blue,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Divider(color: Color(0xFF3D3D3D), height: 1),
                        const SizedBox(height: 16),

                        // From Date (text input with auto-format)
                        _DateInputField(
                          label: 'From Date',
                          controller: _fromDateController,
                          onDateChanged: (date) {
                            setState(() {
                              _fromDate = date;
                              _filterPayments();
                            });
                            setOverlayState(() {});
                          },
                          onClear: () {
                            _fromDateController.clear();
                            setState(() {
                              _fromDate = null;
                              _filterPayments();
                            });
                            setOverlayState(() {});
                          },
                        ),
                        const SizedBox(height: 16),

                        // To Date (text input with auto-format)
                        _DateInputField(
                          label: 'To Date',
                          controller: _toDateController,
                          onDateChanged: (date) {
                            setState(() {
                              _toDate = date;
                              _filterPayments();
                            });
                            setOverlayState(() {});
                          },
                          onClear: () {
                            _toDateController.clear();
                            setState(() {
                              _toDate = null;
                              _filterPayments();
                            });
                            setOverlayState(() {});
                          },
                        ),

                        const SizedBox(height: 16),
                        const Divider(color: Color(0xFF3D3D3D), height: 1),
                        const SizedBox(height: 12),

                        // Clear button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: () {
                                _fromDateController.clear();
                                _toDateController.clear();
                                setState(() {
                                  _fromDate = null;
                                  _toDate = null;
                                  _filterPayments();
                                });
                                setOverlayState(() {});
                              },
                              child: Text(
                                'Clear Filter',
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

  void _closeFilterPopup() {
    _filterOverlay?.remove();
    _filterOverlay = null;
  }
}

// ------------------------------------------------------------------
// الألوان (نفس payment page)
// ------------------------------------------------------------------
class AppColors {
  static const white = Color(0xFFFFFFFF);
  static const blue = Color(0xFF50B2E7);
  static const card = Color(0xFF2D2D2D);
  static const cardAlt = Color(0xFF262626);
  static const grey = Color(0xFF999999);
  static const dark = Color(0xFF202020);
  static const black = Color(0xFF000000);
}

// ------------------------------------------------------------------
// Search + Filter bar
// ------------------------------------------------------------------
class _SearchFilterBar extends StatelessWidget {
  final TextEditingController controller;
  final GlobalKey filterButtonKey;
  final VoidCallback onFilterTap;

  const _SearchFilterBar({
    required this.controller,
    required this.filterButtonKey,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
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
                Icons.person_search_rounded,
                color: AppColors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  style: const TextStyle(color: AppColors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Enter Name',
                    hintStyle: TextStyle(color: AppColors.grey, fontSize: 13),
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
        _RoundIconButton(
          key: filterButtonKey,
          icon: Icons.filter_alt_rounded,
          onTap: onFilterTap,
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------
// Round Icon Button
// ------------------------------------------------------------------
class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

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
        color: AppColors.card,
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

// ------------------------------------------------------------------
// جدول الأرشيف
// ------------------------------------------------------------------
class _ArchiveTable extends StatelessWidget {
  final bool isIncoming;
  final List<Map<String, dynamic>> incomingPayments;
  final List<Map<String, dynamic>> outgoingPayments;
  final bool isLoading;
  final Function(Map<String, dynamic>, bool) onPaymentTap;
  final int? hoveredRow;
  final Function(int?) onHoverChanged;

  const _ArchiveTable({
    required this.isIncoming,
    required this.incomingPayments,
    required this.outgoingPayments,
    required this.isLoading,
    required this.onPaymentTap,
    required this.hoveredRow,
    required this.onHoverChanged,
  });

  @override
  Widget build(BuildContext context) {
    final rows = isIncoming ? incomingPayments : outgoingPayments;

    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.blue),
      );
    }

    if (rows.isEmpty) {
      return Center(
        child: Text(
          'No payments found',
          style: TextStyle(color: AppColors.grey, fontSize: 16),
        ),
      );
    }

    const headerStyle = TextStyle(
      color: AppColors.white,
      fontSize: 14,
      fontWeight: FontWeight.w700,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // رأس الجدول
        Row(
          children: [
            Expanded(
              flex: 4,
              child: Text(
                isIncoming ? 'Customer Name' : 'Supplier Name',
                style: headerStyle,
              ),
            ),
            const Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.center,
                child: Text('Payment Method', style: headerStyle),
              ),
            ),
            const Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text('Price', style: headerStyle),
              ),
            ),
            const Expanded(
              flex: 3,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Pay Date',
                  style: TextStyle(
                    color: AppColors.blue,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),
        // line under header (like payment_page _TableHeaderBar)
        Container(
          height: 1,
          width: double.infinity,
          color: Colors.white.withOpacity(0.4),
        ),

        const SizedBox(height: 10),

        // الصفوف (zebra rows) — enlarged
        Expanded(
          child: ListView.builder(
            itemCount: rows.length,
            padding: const EdgeInsets.only(top: 6),
            itemBuilder: (context, index) {
              final row = rows[index];
              final paymentMethodLabel = (row['payment_method'] ?? 'cash')
                  .toString()
                  .replaceAll('_', ' ')
                  .toUpperCase();
              final bool isEven = index.isEven;
              final Color rowColor = isEven
                  ? AppColors.cardAlt
                  : AppColors.card;
              final isHovered = hoveredRow == index;

              return MouseRegion(
                onEnter: (_) => onHoverChanged(index),
                onExit: (_) => onHoverChanged(null),
                child: GestureDetector(
                  onTap: () => onPaymentTap(row, isIncoming),
                  child: Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: rowColor,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                        color: isHovered ? AppColors.blue : Colors.transparent,
                        width: 1.5,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Text(
                            isIncoming
                                ? (row['payer'] ?? '')
                                : (row['payee'] ?? ''),
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Align(
                            alignment: Alignment.center,
                            child: Text(
                              paymentMethodLabel,
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              row['price'] ?? '',
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              row['date'] ?? '',
                              style: const TextStyle(
                                color: AppColors.blue,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------
// Date Input Field with Auto-Formatting (DD/MM/YYYY)
// ------------------------------------------------------------------
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

    // Auto-format: add slashes automatically
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

    // Validate and parse date
    if (text.length == 10) {
      final date = _parseDate(text);
      if (date != null) {
        setState(() => _errorText = null);
        widget.onDateChanged(date);
      } else {
        setState(() => _errorText = 'Invalid date format');
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

  DateTime? _parseDate(String text) {
    try {
      final parts = text.split('/');
      if (parts.length != 3) return null;

      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);

      if (day < 1 || day > 31) return null;
      if (month < 1 || month > 12) return null;
      if (year < 1900 || year > 2100) return null;

      final date = DateTime(year, month, day);

      // Validate that the date is actually valid (e.g., not Feb 30)
      if (date.day != day || date.month != month || date.year != year) {
        return null;
      }

      return date;
    } catch (e) {
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
                    errorText: null, // Don't show error in field
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
