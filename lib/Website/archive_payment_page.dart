import 'package:flutter/material.dart';
import 'payment_page.dart';
import 'sidebar.dart';
import 'checks_page.dart';
import 'choose_payment.dart';
import 'payment_header.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_config.dart';

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
            customer_id,
            customer:customer_id (
              name
            )
          ''')
          .order('date_time', ascending: false);

      if (response is List) {
        final List<Map<String, dynamic>> payments = [];
        for (var payment in response) {
          payments.add({
            'payer': payment['customer']?['name'] ?? 'Unknown',
            'price': '\$${payment['amount']?.toString() ?? '0'}',
            'date': _formatDate(payment['date_time']),
            'description': payment['description'] ?? '',
          });
        }
        setState(() {
          incomingPayments = payments;
          filteredIncomingPayments = payments;
        });
      }
    } catch (e) {
      print('Error fetching incoming payments: $e');
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
            supplier_id,
            supplier:supplier_id (
              name
            )
          ''')
          .order('date_time', ascending: false);

      if (response is List) {
        final List<Map<String, dynamic>> payments = [];
        for (var payment in response) {
          payments.add({
            'payee': payment['supplier']?['name'] ?? 'Unknown',
            'price': '\$${payment['amount']?.toString() ?? '0'}',
            'date': _formatDate(payment['date_time']),
            'description': payment['description'] ?? '',
          });
        }
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
// Inline Calendar (embedded, not center dialog)
// ------------------------------------------------------------------
class _InlineCalendar extends StatelessWidget {
  final String label;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onChange;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const _InlineCalendar({
    required this.label,
    required this.selectedDate,
    required this.onChange,
    this.firstDate,
    this.lastDate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF232427),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.blue, width: 1),
          ),
          child: CalendarDatePicker(
            initialDate: selectedDate ?? DateTime.now(),
            firstDate: firstDate ?? DateTime(2020, 1, 1),
            lastDate: lastDate ?? DateTime(2030, 12, 31),
            onDateChanged: onChange,
          ),
        ),
      ],
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

  const _ArchiveTable({
    required this.isIncoming,
    required this.incomingPayments,
    required this.outgoingPayments,
    required this.isLoading,
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
                isIncoming ? 'Payer Name' : 'Payee Name',
                style: headerStyle,
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
              final bool isEven = index.isEven;
              final Color rowColor = isEven
                  ? AppColors.cardAlt
                  : AppColors.card;

              return Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: rowColor,
                  borderRadius: BorderRadius.circular(26),
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
