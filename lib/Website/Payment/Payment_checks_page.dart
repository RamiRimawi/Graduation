import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../sidebar.dart';
import 'payment_header.dart';
import '../../supabase_config.dart';

/// صفحة الـ Checks (Incoming) مثل الصورة
class CheckPage extends StatefulWidget {
  const CheckPage({super.key});

  @override
  State<CheckPage> createState() => _CheckPageState();
}

class _CheckPageState extends State<CheckPage> {
  bool isIncoming = true;
  List<Map<String, dynamic>> incomingChecks = [];
  List<Map<String, dynamic>> outgoingChecks = [];
  List<Map<String, dynamic>> filteredIncomingChecks = [];
  List<Map<String, dynamic>> filteredOutgoingChecks = [];
  bool isLoading = false;
  final TextEditingController _searchController = TextEditingController();

  // Filter state
  final Set<String> _selectedStatuses = {};
  final GlobalKey _filterButtonKey = GlobalKey();
  OverlayEntry? _filterOverlay;

  // Hover state tracking
  int? hoveredRow;

  // Suppliers for endorsement
  List<Map<String, dynamic>> suppliers = [];
  bool isLoadingSuppliers = false;

  @override
  void initState() {
    super.initState();
    _fetchChecks();
    _fetchSuppliers();
    _searchController.addListener(_filterChecks);
  }

  @override
  void dispose() {
    _filterOverlay?.remove();
    _filterOverlay = null;
    _searchController.dispose();
    super.dispose();
  }

  void _filterChecks() {
    final query = _searchController.text.toLowerCase();

    // Apply search filter for outgoing (no status filter)
    if (query.isEmpty) {
      filteredOutgoingChecks = outgoingChecks;
    } else {
      filteredOutgoingChecks = outgoingChecks
          .where(
            (check) =>
                check['owner'].toString().toLowerCase().startsWith(query),
          )
          .toList();
    }

    // Apply both search and status filter for incoming
    List<Map<String, dynamic>> tempIncoming = incomingChecks;

    // First apply status filter
    if (_selectedStatuses.isNotEmpty) {
      tempIncoming = tempIncoming
          .where((check) => _selectedStatuses.contains(check['status']))
          .toList();
    }

    // Then apply search filter
    if (query.isNotEmpty) {
      tempIncoming = tempIncoming
          .where(
            (check) =>
                check['owner'].toString().toLowerCase().startsWith(query),
          )
          .toList();
    }

    setState(() {
      filteredIncomingChecks = tempIncoming;
    });
  }

  Future<void> _fetchChecks() async {
    setState(() => isLoading = true);
    await Future.wait([_fetchIncomingChecks(), _fetchOutgoingChecks()]);
    setState(() => isLoading = false);
  }

  Future<void> _fetchSuppliers() async {
    try {
      setState(() => isLoadingSuppliers = true);
      final response = await supabase
          .from('supplier')
          .select('supplier_id, name')
          .order('name', ascending: true);
      setState(() {
        suppliers = List<Map<String, dynamic>>.from(response);
        isLoadingSuppliers = false;
      });
    } catch (e) {
      setState(() => isLoadingSuppliers = false);
      print('Error fetching suppliers: $e');
    }
  }

  Future<String> _getLoggedInAccountantName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accountantId = prefs.getInt('accountant_id');

      if (accountantId == null) return 'System';

      final response = await supabase
          .from('accountant')
          .select('name')
          .eq('accountant_id', accountantId)
          .maybeSingle();

      return response?['name']?.toString() ?? 'System';
    } catch (e) {
      print('Error getting accountant name: $e');
      return 'System';
    }
  }

  Future<void> _fetchIncomingChecks() async {
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
            customer_id,
            endorsed_to,
            customer:customer_id ( name ),
            banks!bank_id ( bank_name ),
            branches!bank_branch ( address )
          ''')
          .inFilter('status', ['Company Box', 'Endorsed'])
          .order('exchange_date', ascending: true);

      // Collect endorsed_to supplier IDs to resolve names in one query
      final endorsedIds = <int>{};
      for (final check in response) {
        final endorsedTo = check['endorsed_to'];
        if (endorsedTo is int) {
          endorsedIds.add(endorsedTo);
        }
      }

      final Map<int, String> supplierNames = {};
      if (endorsedIds.isNotEmpty) {
        try {
          final supplierResponse = await supabase
              .from('supplier')
              .select('supplier_id, name')
              .inFilter('supplier_id', endorsedIds.toList());

          for (final supplier in supplierResponse) {
            final id = supplier['supplier_id'];
            if (id is int) {
              supplierNames[id] = supplier['name']?.toString() ?? '';
            }
          }
        } catch (e) {
          print('Error fetching endorsed supplier names: $e');
        }
      }

      final List<Map<String, dynamic>> checks = [];
      for (var check in response) {
        final endorsedTo = check['endorsed_to'];
        checks.add({
          'owner': check['customer']?['name'] ?? 'Unknown',
          'price': '\$${check['exchange_rate']?.toString() ?? '0'}',
          'date': _formatDate(check['exchange_date']),
          'status': check['status'] ?? 'Unknown',
          'check_id': check['check_id'],
          'check_details': {
            'check_id': check['check_id'],
            'exchange_rate': check['exchange_rate'],
            'exchange_date': check['exchange_date'],
            'status': check['status'],
            'description': check['description'],
            'endorsed_description': check['endorsed_description'],
            'check_image': check['check_image'],
            'banks': check['banks'],
            'branches': check['branches'],
            'customer_id': check['customer_id'],
            'endorsed_to': endorsedTo,
            'endorsed_supplier': endorsedTo is int
                ? {'name': supplierNames[endorsedTo]}
                : null,
          },
        });
      }
      setState(() {
        incomingChecks = checks;
        filteredIncomingChecks = checks;
      });
    } catch (e) {
      print('Error fetching incoming checks: $e');
    }
  }

  Future<void> _fetchOutgoingChecks() async {
    try {
      final response = await supabase
          .from('supplier_checks')
          .select('''
            check_id,
            bank_id,
            bank_branch,
            check_image,
            exchange_rate,
            exchange_date,
            status,
            description,
            supplier_id,
            supplier:supplier_id ( name ),
            banks!bank_id ( bank_name ),
            branches!bank_branch ( address )
          ''')
          .inFilter('status', ['Pending'])
          .order('exchange_date', ascending: true);

      final List<Map<String, dynamic>> checks = [];
      for (var check in response) {
        checks.add({
          'owner': check['supplier']?['name'] ?? 'Unknown',
          'price': '\$${check['exchange_rate']?.toString() ?? '0'}',
          'date': _formatDate(check['exchange_date']),
          'status': check['status'] ?? 'Pending',
          'check_id': check['check_id'],
          'check_details': {
            'check_id': check['check_id'],
            'exchange_rate': check['exchange_rate'],
            'exchange_date': check['exchange_date'],
            'status': check['status'],
            'description': check['description'],
            'check_image': check['check_image'],
            'banks': check['banks'],
            'branches': check['branches'],
            'supplier_id': check['supplier_id'],
          },
        });
      }
      setState(() {
        outgoingChecks = checks;
        filteredOutgoingChecks = checks;
      });
    } catch (e) {
      print('Error fetching outgoing checks: $e');
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

  Future<void> _updateCheckStatus(
    int checkId,
    bool isIncoming,
    String newStatus,
  ) async {
    try {
      final accountantName = await _getLoggedInAccountantName();
      final table = isIncoming ? 'customer_checks' : 'supplier_checks';
      await supabase
          .from(table)
          .update({
            'status': newStatus,
            'last_action_time': DateTime.now().toIso8601String(),
            'last_action_by': accountantName,
          })
          .eq('check_id', checkId);
      await _fetchChecks();
      _filterChecks();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Status updated to $newStatus')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update status: $e')));
      }
    }
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  Future<void> _createPaymentFromCheck(
    Map<String, dynamic> details,
    bool isIncoming,
    int checkId,
  ) async {
    final amount = _toDouble(details['exchange_rate']);
    final description = (details['description'] ?? '') as String?;
    final nowIso = DateTime.now().toIso8601String();
    final status = details['status'] as String?;
    final endorsedTo = details['endorsed_to'] as int?;
    final accountantName = await _getLoggedInAccountantName();

    // Handle endorsed checks
    if (status == 'Endorsed') {
      final customerId = details['customer_id'] as int?;

      if (endorsedTo != null) {
        // Endorsed to supplier - create outgoing payment and update supplier balance
        // Note: check_id is null because the physical check is a customer check,
        // not a supplier check, so it can't reference supplier_checks table
        final enhancedDescription =
            'Endorsed customer check #$checkId\n${description ?? ''}';

        await supabase.from('outgoing_payment').insert({
          'amount': amount,
          'date_time': nowIso,
          'description': enhancedDescription,
          'payment_method': 'endorsed check',
          'check_id': null,
          'supplier_id': endorsedTo,
          'last_action_by': accountantName,
          'last_action_time': nowIso,
        });

        // Update supplier creditor_balance = creditor_balance - amount
        final sup = await supabase
            .from('supplier')
            .select('creditor_balance')
            .eq('supplier_id', endorsedTo)
            .maybeSingle();
        final current = _toDouble(sup?['creditor_balance']);
        final newBalance = current - amount;
        await supabase
            .from('supplier')
            .update({
              'creditor_balance': newBalance,
              'last_action_by': accountantName,
              'last_action_time': nowIso,
            })
            .eq('supplier_id', endorsedTo);
      }

      // Always reduce the originating customer's balance when the endorsed check is cashed
      if (customerId != null) {
        final cust = await supabase
            .from('customer')
            .select('balance_debit')
            .eq('customer_id', customerId)
            .maybeSingle();
        final currentCustBal = _toDouble(cust?['balance_debit']);
        final newCustBal = currentCustBal - amount;
        await supabase
            .from('customer')
            .update({
              'balance_debit': newCustBal,
              'last_action_by': accountantName,
              'last_action_time': nowIso,
            })
            .eq('customer_id', customerId);
      }

      // If endorsed_to is null (Dolphin Company), no outgoing payment; just customer balance is adjusted above
      return;
    }

    // Handle regular incoming/outgoing checks
    if (isIncoming) {
      final customerId = details['customer_id'] as int?;
      if (customerId == null) {
        throw Exception('Missing customer_id for incoming check');
      }
      // Insert payment
      await supabase.from('incoming_payment').insert({
        'amount': amount,
        'date_time': nowIso,
        'description': description,
        'payment_method': 'check',
        'check_id': checkId,
        'customer_id': customerId,
      });
      // Update customer balance_debit = balance_debit - amount
      final cust = await supabase
          .from('customer')
          .select('balance_debit')
          .eq('customer_id', customerId)
          .maybeSingle();
      final current = _toDouble(cust?['balance_debit']);
      final newBalance = current - amount;
      await supabase
          .from('customer')
          .update({
            'balance_debit': newBalance,
            'last_action_by': accountantName,
            'last_action_time': nowIso,
          })
          .eq('customer_id', customerId);
    } else {
      final supplierId = details['supplier_id'] as int?;
      if (supplierId == null) {
        throw Exception('Missing supplier_id for outgoing check');
      }
      // Insert payment
      await supabase.from('outgoing_payment').insert({
        'amount': amount,
        'date_time': nowIso,
        'description': description,
        'payment_method': 'check',
        'check_id': checkId,
        'supplier_id': supplierId,
      });
      // Update supplier creditor_balance = creditor_balance - amount
      final sup = await supabase
          .from('supplier')
          .select('creditor_balance')
          .eq('supplier_id', supplierId)
          .maybeSingle();
      final current = _toDouble(sup?['creditor_balance']);
      final newBalance = current - amount;
      await supabase
          .from('supplier')
          .update({
            'creditor_balance': newBalance,
            'last_action_by': accountantName,
            'last_action_time': nowIso,
          })
          .eq('supplier_id', supplierId);
    }
  }

  void _showCheckDetailsDialog(Map<String, dynamic> row, bool isIncoming) {
    final details = row['check_details'] as Map<String, dynamic>?;
    final status = row['status']?.toString() ?? 'Unknown';
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.92,
            constraints: const BoxConstraints(maxWidth: 1200, maxHeight: 750),
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
                // Header
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
                          isIncoming ? Icons.call_received : Icons.call_made,
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
                              '${isIncoming ? 'Incoming' : 'Outgoing'} Check',
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (details != null)
                              Text(
                                'Check ID: ${details['check_id']}',
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
                        // Main row: Details on left, Image on right
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left column: Details
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 20),
                                  // Top grid: Three fields - Owner / Status / Date
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: _buildDetailCard(
                                          icon: isIncoming
                                              ? Icons.person
                                              : Icons.business,
                                          title: isIncoming
                                              ? 'Customer Name'
                                              : 'Supplier Name',
                                          value: row['owner'] ?? 'Unknown',
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildDetailCard(
                                          icon: Icons.verified,
                                          title: 'Status',
                                          value: status,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildDetailCard(
                                          icon: Icons.calendar_today,
                                          title: 'Exchange Date',
                                          value: _formatDate(
                                            details?['exchange_date'],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 24),

                                  // Check info grid: Three fields - Exchange Rate / Bank / Branch
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildDetailCard(
                                          icon: Icons.attach_money,
                                          title: 'Exchange Rate',
                                          value:
                                              (details?['exchange_rate']
                                                  ?.toString() ??
                                              '0'),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildDetailCard(
                                          icon: Icons.account_balance,
                                          title: 'Bank',
                                          value:
                                              details?['banks']?['bank_name'] ??
                                              'N/A',
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildDetailCard(
                                          icon: Icons.location_on,
                                          title: 'Branch',
                                          value:
                                              details?['branches']?['address'] ??
                                              'N/A',
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Endorsed field - shown only if status is 'Endorsed'
                                  if (status == 'Endorsed') ...[
                                    const SizedBox(height: 24),
                                    _buildDetailCard(
                                      icon: Icons.card_giftcard,
                                      title: 'Endorsed To',
                                      value: _getEndorsedToName(details),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            const SizedBox(width: 24),

                            // Right column: Image centered
                            if ((details?['check_image'] ?? '') != '')
                              Expanded(
                                flex: 2,
                                child: Center(
                                  child: Container(
                                    width: double.infinity,
                                    height: 300,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.blue.withOpacity(0.2),
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        details!['check_image'],
                                        fit: BoxFit.contain,
                                        loadingBuilder:
                                            (context, child, progress) {
                                              if (progress == null) {
                                                return child;
                                              }
                                              return const Center(
                                                child:
                                                    CircularProgressIndicator(
                                                      color: AppColors.blue,
                                                    ),
                                              );
                                            },
                                        errorBuilder: (context, error, stack) {
                                          return Center(
                                            child: Text(
                                              'Failed to load image',
                                              style: TextStyle(
                                                color: AppColors.grey,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Description section at bottom - larger
                        if (status == 'Endorsed') ...[
                          // Split description and endorsed description for Endorsed status
                          if ((details?['description'] ?? '')
                              .toString()
                              .isNotEmpty) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppColors.blue.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.blue.withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.description,
                                              color: AppColors.blue,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Original Description',
                                              style: TextStyle(
                                                color: AppColors.grey,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          details?['description'] ?? '',
                                          style: const TextStyle(
                                            color: AppColors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            height: 1.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppColors.blue.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.blue.withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.card_giftcard,
                                              color: AppColors.blue,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Endorsement Notes',
                                              style: TextStyle(
                                                color: AppColors.grey,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          details?['endorsed_description'] ??
                                              '',
                                          style: const TextStyle(
                                            color: AppColors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            height: 1.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ] else if ((details?['description'] ?? '')
                            .toString()
                            .isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.blue.withOpacity(0.05),
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
                                    Icon(
                                      Icons.description,
                                      color: AppColors.blue,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Description',
                                      style: TextStyle(
                                        color: AppColors.grey,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  details?['description'] ?? '',
                                  style: const TextStyle(
                                    color: AppColors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        const SizedBox(height: 16),

                        // Centered action buttons
                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: _buildActionButtons(
                              row,
                              isIncoming,
                              status,
                            ),
                          ),
                        ),
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

  List<Widget> _buildActionButtons(
    Map<String, dynamic> row,
    bool isIncoming,
    String status,
  ) {
    final checkId =
        (row['check_id'] ?? row['check_details']?['check_id']) as int?;
    if (checkId == null) return [];
    List<Widget> buttons = [];

    void addButton(String label, Color color) {
      buttons.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: ElevatedButton(
            onPressed: () async {
              // Show confirmation for Returned; otherwise update immediately
              if (label == 'Returned') {
                showDialog(
                  context: context,
                  builder: (ctx) => Dialog(
                    backgroundColor: Colors.transparent,
                    child: Container(
                      width: 380,
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.blue.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Confirm Return',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Are you sure you want to mark this check as Returned?',
                            style: TextStyle(
                              color: AppColors.grey,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: const Text(
                                  'No',
                                  style: TextStyle(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () async {
                                  await _updateCheckStatus(
                                    checkId,
                                    isIncoming,
                                    'Returned',
                                  );
                                  if (mounted) {
                                    Navigator.of(ctx).pop(); // close confirm
                                    Navigator.of(
                                      context,
                                    ).pop(); // close details
                                  }
                                },
                                child: const Text(
                                  'Yes',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              } else {
                if (label == 'Cashed') {
                  // Confirm cashing and then create payment + update statuses/balances
                  showDialog(
                    context: context,
                    builder: (ctx) => Dialog(
                      backgroundColor: Colors.transparent,
                      child: Container(
                        width: 420,
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.blue.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Confirm Cashing',
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'This will create an ${isIncoming ? 'incoming' : 'outgoing'} payment and update balances. Proceed?',
                              style: TextStyle(
                                color: AppColors.grey,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  child: const Text(
                                    'No',
                                    style: TextStyle(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: () async {
                                    try {
                                      final details =
                                          (row['check_details'] ?? {})
                                              as Map<String, dynamic>;
                                      await _createPaymentFromCheck(
                                        details,
                                        isIncoming,
                                        checkId,
                                      );
                                      await _updateCheckStatus(
                                        checkId,
                                        isIncoming,
                                        'Cashed',
                                      );
                                      if (mounted) {
                                        Navigator.of(
                                          ctx,
                                        ).pop(); // close confirm
                                        Navigator.of(
                                          context,
                                        ).pop(); // close details
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        Navigator.of(ctx).pop();
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Failed to cash check: $e',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  child: const Text(
                                    'Yes',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                } else if (label == 'Endorsed') {
                  // Show endorsement selection popup
                  _showEndorsementPopup(checkId, row);
                } else {
                  await _updateCheckStatus(checkId, isIncoming, label);
                  if (mounted) Navigator.of(context).pop();
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 2,
            ),
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
        ),
      );
    }

    if (isIncoming) {
      if (status == 'Company Box') {
        addButton('Cashed', Colors.green);
        addButton('Endorsed', AppColors.blue);
        addButton('Returned', Colors.red);
      } else if (status == 'Endorsed') {
        addButton('Cashed', Colors.green);
        addButton('Returned', Colors.red);
      }
    } else {
      addButton('Cashed', Colors.green);
      addButton('Returned', Colors.red);
    }

    return buttons;
  }

  void _showEndorsementPopup(int checkId, Map<String, dynamic> row) {
    final details = row['check_details'] as Map<String, dynamic>?;
    String? selectedSupplier; // null = Dolphin Company, else supplier_id
    final descriptionController = TextEditingController();
    final supplierSearchController = TextEditingController();
    List<Map<String, dynamic>> filteredSuppliers = [];

    final supplierLayerLink = LayerLink();
    OverlayEntry? supplierOverlayEntry;

    void hideSupplierOverlay() {
      supplierOverlayEntry?.remove();
      supplierOverlayEntry = null;
    }

    void showSupplierOverlay(StateSetter setDialogState) {
      hideSupplierOverlay();

      supplierOverlayEntry = OverlayEntry(
        builder: (context) => Stack(
          children: [
            GestureDetector(
              onTap: hideSupplierOverlay,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.transparent,
              ),
            ),
            Positioned(
              width: 452, // Match container width minus padding
              child: CompositedTransformFollower(
                link: supplierLayerLink,
                showWhenUnlinked: false,
                offset: const Offset(0, 60),
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.cardBorder, width: 1),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: filteredSuppliers.length,
                      itemBuilder: (context, index) {
                        final item = filteredSuppliers[index];
                        final name = item['name'] ?? 'Unknown';
                        final supplierId = item['supplier_id'];
                        return InkWell(
                          onTap: () {
                            setDialogState(() {
                              selectedSupplier = supplierId?.toString();
                              supplierSearchController.text = name;
                              filteredSuppliers = [];
                            });
                            hideSupplierOverlay();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            child: Text(
                              name,
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

      Overlay.of(context).insert(supplierOverlayEntry!);
    }

    void filterSuppliers(String query, StateSetter setDialogState) {
      setDialogState(() {
        if (query.isEmpty) {
          filteredSuppliers = [
            {'supplier_id': null, 'name': 'Dolphin Company'},
            ...suppliers,
          ];
        } else {
          final q = query.toLowerCase();
          filteredSuppliers = [
            if ('dolphin company'.startsWith(q))
              {'supplier_id': null, 'name': 'Dolphin Company'},
            ...suppliers.where(
              (s) => s['name'].toString().toLowerCase().startsWith(q),
            ),
          ];
        }
      });
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              width: 500,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.blue.withOpacity(0.2),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Endorse Check',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Searchable Dropdown
                  const Text(
                    'Endorse To',
                    style: TextStyle(
                      color: AppColors.blue,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CompositedTransformTarget(
                    link: supplierLayerLink,
                    child: TextFormField(
                      controller: supplierSearchController,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.cardAlt,
                        hintText: 'Search or select supplier...',
                        hintStyle: TextStyle(
                          color: AppColors.grey.withOpacity(0.6),
                          fontSize: 15,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(
                            color: AppColors.cardBorder,
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(
                            color: AppColors.cardBorder,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(
                            color: AppColors.blue,
                            width: 1.5,
                          ),
                        ),
                        suffixIcon: Icon(
                          Icons.arrow_drop_down,
                          color: AppColors.blue,
                          size: 28,
                        ),
                      ),
                      onTap: () {
                        if (filteredSuppliers.isEmpty) {
                          filterSuppliers(
                            supplierSearchController.text,
                            setDialogState,
                          );
                        }
                        showSupplierOverlay(setDialogState);
                      },
                      onChanged: (value) {
                        filterSuppliers(value, setDialogState);
                        if (filteredSuppliers.isNotEmpty) {
                          showSupplierOverlay(setDialogState);
                        } else {
                          hideSupplierOverlay();
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(
                      color: AppColors.blue,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: descriptionController,
                    maxLines: 3,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Additional notes...',
                      hintStyle: TextStyle(color: AppColors.grey, fontSize: 14),
                      filled: true,
                      fillColor: AppColors.cardAlt,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: AppColors.blue.withOpacity(0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: AppColors.blue.withOpacity(0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.blue),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          hideSupplierOverlay();
                          Navigator.of(ctx).pop();
                          descriptionController.dispose();
                          supplierSearchController.dispose();
                        },
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          // Show confirmation
                          final desc = descriptionController.text.trim();
                          final supplierName = supplierSearchController.text
                              .trim();
                          hideSupplierOverlay();
                          Navigator.of(ctx).pop();
                          _showEndorsementConfirmation(
                            checkId,
                            selectedSupplier,
                            supplierName,
                            desc,
                            details,
                          );
                          descriptionController.dispose();
                          supplierSearchController.dispose();
                        },
                        child: const Text(
                          'Done',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showEndorsementConfirmation(
    int checkId,
    String? supplierId,
    String supplierName,
    String description,
    Map<String, dynamic>? details,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 380,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.blue.withOpacity(0.2),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Confirm Endorsement',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Endorse check to $supplierName?',
                style: TextStyle(
                  color: AppColors.grey,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text(
                      'No',
                      style: TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      try {
                        await _processEndorsement(
                          checkId,
                          supplierId,
                          supplierName,
                          description,
                          details,
                        );
                        if (mounted) {
                          Navigator.of(ctx).pop(); // close confirm
                          Navigator.of(context).pop(); // close details
                        }
                      } catch (e) {
                        if (mounted) {
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to endorse: $e')),
                          );
                        }
                      }
                    },
                    child: const Text(
                      'Yes',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processEndorsement(
    int checkId,
    String? supplierId,
    String supplierName,
    String description,
    Map<String, dynamic>? details,
  ) async {
    final nowIso = DateTime.now().toIso8601String();
    final accountantName = await _getLoggedInAccountantName();

    // Build endorsed description with endorsement info and user's notes
    // If endorsed to Dolphin Company, prefix the note; if to a supplier, keep the note as-is.
    String endorsedDescription;
    if (supplierId == null) {
      endorsedDescription = 'Endorsed to Dolphin Company\n\n$description';
    } else {
      endorsedDescription = description;
    }

    // Update check - keep original description, store endorsement info separately
    final updateData = {
      'status': 'Endorsed',
      'last_action_time': nowIso,
      'last_action_by': accountantName,
      'endorsed_description': endorsedDescription,
    };

    if (supplierId != null) {
      updateData['endorsed_to'] = supplierId;
    }

    await supabase
        .from('customer_checks')
        .update(updateData)
        .eq('check_id', checkId);

    // Refresh checks
    await _fetchChecks();
    _filterChecks();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check endorsed successfully')),
      );
    }
  }

  String _getEndorsedToName(Map<String, dynamic>? details) {
    if (details == null) return 'N/A';

    final endorsedTo = details['endorsed_to'];

    // If endorsed_to is null, it means Dolphin Company
    if (endorsedTo == null) {
      return 'Dolphin Company';
    }

    // If endorsed_to is a number, it's a supplier ID
    final endorsedSupplier = details['endorsed_supplier'];
    final endorsedName = endorsedSupplier?['name']?.toString();

    if (endorsedName != null && endorsedName.isNotEmpty) {
      return endorsedName;
    }

    return 'Supplier ID: $endorsedTo';
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
                      currentPage: 'checks',
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
                          isIncoming: isIncoming,
                          onFilterTap: _toggleFilterPopup,
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // ================== تابل الشيكات ==================
                    Expanded(
                      child: _ChecksTable(
                        isIncoming: isIncoming,
                        incomingChecks: filteredIncomingChecks,
                        outgoingChecks: filteredOutgoingChecks,
                        isLoading: isLoading,
                        onRowTap: (row, incoming) =>
                            _showCheckDetailsDialog(row, incoming),
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
          // Invisible background to detect clicks outside
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeFilterPopup,
              child: Container(color: Colors.transparent),
            ),
          ),
          // The actual filter popup
          Positioned(
            left: offset.dx - 200 + size.width,
            top: offset.dy + size.height + 8,
            child: Material(
              color: Colors.transparent,
              child: StatefulBuilder(
                builder: (context, setOverlayState) => GestureDetector(
                  onTap: () {}, // Prevent clicks from closing
                  child: Container(
                    width: 220,
                    padding: const EdgeInsets.all(12),
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
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 8),
                          child: Text(
                            'Filter by Status',
                            style: TextStyle(
                              color: AppColors.blue,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Divider(color: Color(0xFF3D3D3D), height: 1),
                        const SizedBox(height: 8),
                        ..._buildStatusCheckboxes(setOverlayState),
                        const SizedBox(height: 8),
                        const Divider(color: Color(0xFF3D3D3D), height: 1),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _selectedStatuses.clear();
                                  _filterChecks();
                                });
                                setOverlayState(() {});
                              },
                              child: Text(
                                'Clear All',
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

  List<Widget> _buildStatusCheckboxes(StateSetter setOverlayState) {
    final statuses = ['Company Box', 'Endorsed'];
    return statuses.map((status) {
      final isSelected = _selectedStatuses.contains(status);
      return InkWell(
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedStatuses.remove(status);
            } else {
              _selectedStatuses.add(status);
            }
            _filterChecks();
          });
          setOverlayState(() {});
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Row(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.blue : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? AppColors.blue : Colors.white54,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: isSelected
                    ? const Center(
                        child: Icon(Icons.check, size: 14, color: Colors.black),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  status,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontSize: 13,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  void _closeFilterPopup() {
    _filterOverlay?.remove();
    _filterOverlay = null;
  }
}

// ------------------------------------------------------------------
// الألوان
// ------------------------------------------------------------------
class AppColors {
  static const white = Color(0xFFFFFFFF);
  static const blue = Color(0xFF50B2E7);
  static const card = Color(0xFF2D2D2D);
  static const cardAlt = Color(0xFF262626);
  static const grey = Color(0xFF9E9E9E);
  static const dark = Color(0xFF202020);
  static const black = Color(0xFF000000);
  static const cardBorder = Color(0xFF3D3D3D);
}

// ------------------------------------------------------------------
// Search + Filter bar (Enter Name + أيقونة فلتر)
// ------------------------------------------------------------------
class _SearchFilterBar extends StatelessWidget {
  final TextEditingController controller;
  final GlobalKey filterButtonKey;
  final bool isIncoming;
  final VoidCallback onFilterTap;

  const _SearchFilterBar({
    required this.controller,
    required this.filterButtonKey,
    required this.isIncoming,
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
        // Filter button - only active for incoming
        if (isIncoming)
          _RoundIconButton(
            key: filterButtonKey,
            icon: Icons.filter_alt_rounded,
            onTap: onFilterTap,
          )
        else
          // Invisible placeholder to maintain layout
          const SizedBox(width: 32, height: 32),
      ],
    );
  }
}

// ------------------------------------------------------------------
// Round Icon Button (like mobile_accounts_page.dart)
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
// جدول الشيكات (الرأس + الصفوف)
// ------------------------------------------------------------------
class _ChecksTable extends StatelessWidget {
  final bool isIncoming;
  final List<Map<String, dynamic>> incomingChecks;
  final List<Map<String, dynamic>> outgoingChecks;
  final bool isLoading;
  final Function(Map<String, dynamic>, bool)? onRowTap;
  final int? hoveredRow;
  final Function(int?)? onHoverChanged;

  const _ChecksTable({
    required this.isIncoming,
    required this.incomingChecks,
    required this.outgoingChecks,
    required this.isLoading,
    this.onRowTap,
    this.hoveredRow,
    this.onHoverChanged,
  });

  @override
  Widget build(BuildContext context) {
    // اختر البيانات بناءً على isIncoming
    final rows = isIncoming ? incomingChecks : outgoingChecks;

    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.blue),
      );
    }

    if (rows.isEmpty) {
      return Center(
        child: Text(
          'No checks found',
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
        if (isIncoming)
          Row(
            children: [
              Expanded(flex: 4, child: Text('Check owner', style: headerStyle)),
              const Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text('Price', style: headerStyle),
                ),
              ),
              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text('Caching Date', style: headerStyle),
                ),
              ),
              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Check Status',
                    style: TextStyle(
                      color: AppColors.blue,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          )
        else
          Row(
            children: [
              const Expanded(
                flex: 4,
                child: Text('Check payee', style: headerStyle),
              ),
              const Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text('Price', style: headerStyle),
                ),
              ),
              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text('Caching Date', style: headerStyle),
                ),
              ),
              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Check Status',
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

        // الصفوف (zebra rows مع radius) — enlarged rows (more padding / spacing)
        Expanded(
          child: ListView.builder(
            itemCount: rows.length,
            padding: const EdgeInsets.only(top: 6),
            itemBuilder: (context, index) {
              final row = rows[index];
              final bool isEven = index.isEven;
              final Color rowColor = isEven
                  ? AppColors.cardAlt
                  : AppColors.card;

              if (isIncoming) {
                // Incoming: 4 columns
                final isHovered = hoveredRow == index;
                return MouseRegion(
                  onEnter: (_) => onHoverChanged?.call(index),
                  onExit: (_) => onHoverChanged?.call(null),
                  child: GestureDetector(
                    onTap: onRowTap != null ? () => onRowTap!(row, true) : null,
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
                          color: isHovered
                              ? AppColors.blue
                              : Colors.transparent,
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
                              row['owner'] ?? '',
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
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
                                  color: AppColors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                row['status'] ?? '',
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
              } else {
                // Outgoing: 4 columns (same as incoming)
                final isHovered = hoveredRow == index;
                return MouseRegion(
                  onEnter: (_) => onHoverChanged?.call(index),
                  onExit: (_) => onHoverChanged?.call(null),
                  child: GestureDetector(
                    onTap: onRowTap != null
                        ? () => onRowTap!(row, false)
                        : null,
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
                          color: isHovered
                              ? AppColors.blue
                              : Colors.transparent,
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
                              row['owner'] ?? '',
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
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
                                  color: AppColors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                row['status'] ?? '',
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
              }
            },
          ),
        ),
      ],
    );
  }
}
