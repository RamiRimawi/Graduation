import 'package:flutter/material.dart';
import 'sidebar.dart';
import 'Payment_header.dart';
import '../supabase_config.dart';

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
  Set<String> _selectedStatuses = {};
  final GlobalKey _filterButtonKey = GlobalKey();
  OverlayEntry? _filterOverlay;

  @override
  void initState() {
    super.initState();
    _fetchChecks();
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

  Future<void> _fetchIncomingChecks() async {
    try {
      final response = await supabase
          .from('customer_checks')
          .select('''
            check_id,
            exchange_rate,
            exchange_date,
            status,
            customer_id,
            customer:customer_id (
              name
            )
          ''')
          .inFilter('status', ['Company Box', 'Endorsed'])
          .order('exchange_date', ascending: true);

      if (response is List) {
        final List<Map<String, dynamic>> checks = [];
        for (var check in response) {
          checks.add({
            'owner': check['customer']?['name'] ?? 'Unknown',
            'price': '\$${check['exchange_rate']?.toString() ?? '0'}',
            'date': _formatDate(check['exchange_date']),
            'status': check['status'] ?? 'Unknown',
          });
        }
        setState(() {
          incomingChecks = checks;
          filteredIncomingChecks = checks;
        });
      }
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
            exchange_rate,
            exchange_date,
            status,
            supplier_id,
            supplier:supplier_id (
              name
            )
          ''')
          .inFilter('status', ['Pending'])
          .order('exchange_date', ascending: true);

      if (response is List) {
        final List<Map<String, dynamic>> checks = [];
        for (var check in response) {
          checks.add({
            'owner': check['supplier']?['name'] ?? 'Unknown',
            'price': '\$${check['exchange_rate']?.toString() ?? '0'}',
            'date': _formatDate(check['exchange_date']),
            'status': _formatDate(
              check['exchange_date'],
            ), // For outgoing, status shows the cashing date
          });
        }
        setState(() {
          outgoingChecks = checks;
          filteredOutgoingChecks = checks;
        });
      }
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

  const _ChecksTable({
    required this.isIncoming,
    required this.incomingChecks,
    required this.outgoingChecks,
    required this.isLoading,
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
                  child: Text(
                    'Caching Date',
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
                );
              } else {
                // Outgoing: 3 columns only
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
              }
            },
          ),
        ),
      ],
    );
  }
}
