import 'package:flutter/material.dart';
import 'sidebar.dart';
import 'Payment_checks_page.dart';
import 'Payment_archive_page.dart';
import 'Payment_choose_payment.dart';
import '../supabase_config.dart';

/// صفحة الـ Payment Dashboard
class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  // 0 = Statistics , 1 = Checks , 2 = Archive
  int activeTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      body: Row(
        children: [
          const Sidebar(activeIndex: 4),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ================== الهيدر العلوي ==================
                  Row(
                    children: [
                      const Text(
                        'Payment',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: () => showSelectTransactionDialog(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.blue,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          elevation: 4,
                        ),
                        icon: const Icon(
                          Icons.add,
                          color: AppColors.black,
                          size: 18,
                        ),
                        label: const Text(
                          'Add Payment',
                          style: TextStyle(
                            color: AppColors.black,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(
                          color: AppColors.card,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.notifications_none_rounded,
                          color: AppColors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ================== Tabs: Statistics / Checks / Archive ==================
                  Row(
                    children: [
                      _TopTab(
                        label: 'Statistics',
                        isActive: activeTab == 0,
                        onTap: () => setState(() => activeTab = 0),
                      ),
                      const SizedBox(width: 24),
                      _TopTab(
                        label: 'Checks',
                        isActive: activeTab == 1,
                        onTap: () {
                          setState(() => activeTab = 1);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CheckPage(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 24),
                      _TopTab(
                        label: 'Archive',
                        isActive: activeTab == 2,
                        onTap: () {
                          setState(() => activeTab = 2);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ArchivePaymentPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // ================== المحتوى مع Scroll ==================
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // ================== الصف العلوي ==================
                          SizedBox(
                            height: 280,
                            child: const Row(
                              children: [
                                Expanded(flex: 3, child: _UpcomingChecksCard()),
                                SizedBox(width: 18),
                                Expanded(flex: 2, child: _TopStatsCards()),
                              ],
                            ),
                          ),

                          const SizedBox(height: 18),

                          // ================== الصف السفلي ==================
                          SizedBox(
                            height: 440,
                            child: const Row(
                              children: [
                                Expanded(flex: 2, child: _MostDebtorsCard()),
                                SizedBox(width: 18),
                                Expanded(flex: 5, child: _TotalProfitCard()),
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
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------
// الألوان (حسب الصورة)
// ------------------------------------------------------------------
class AppColors {
  static const white = Color(0xFFFFFFFF);
  static const blue = Color(0xFF50B2E7);
  static const card = Color(0xFF2D2D2D);
  static const cardAlt = Color(0xFF262626);
  static const grey = Color(0xFF999999);
  static const dark = Color(0xFF202020);
  static const black = Color(0xFF000000);
  // black must be opaque so text/icons are visible (was transparent which hid the label)
}

// ------------------------------------------------------------------
// Tabs فوق (Statistics / Checks / Archive)
// ------------------------------------------------------------------
class _TopTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  const _TopTab({required this.label, this.isActive = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? AppColors.blue : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? AppColors.white : AppColors.grey,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

// Card: Upcoming Checks  (zebra + scroll + check status أزرق)
// ------------------------------------------------------------------
class _UpcomingChecksCard extends StatefulWidget {
  const _UpcomingChecksCard();

  @override
  State<_UpcomingChecksCard> createState() => _UpcomingChecksCardState();
}

class _UpcomingChecksCardState extends State<_UpcomingChecksCard> {
  List<Map<String, dynamic>> upcomingChecks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUpcomingChecks();
  }

  Future<void> _fetchUpcomingChecks() async {
    try {
      if (!mounted) return;
      setState(() => isLoading = true);

      // Calculate date range - next 7 days
      final now = DateTime.now();
      final oneWeekFromNow = now.add(const Duration(days: 7));

      // Format dates for SQL query
      final startDate = now.toIso8601String().split('T')[0];
      final endDate = oneWeekFromNow.toIso8601String().split('T')[0];

      // Fetch customer checks with status "Company Box" or "Endorsed"
      final customerChecksResponse = await supabase
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
          .gte('exchange_date', startDate)
          .lte('exchange_date', endDate)
          .inFilter('status', ['Company Box', 'Endorsed']);

      // Fetch supplier checks with status "pending"
      final supplierChecksResponse = await supabase
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
          .gte('exchange_date', startDate)
          .lte('exchange_date', endDate)
          .eq('status', 'Pending');

      // Combine both lists
      final List<Map<String, dynamic>> combinedChecks = [];

      // Add customer checks
      for (var check in customerChecksResponse) {
        combinedChecks.add({
          'owner': check['customer']?['name'] ?? 'Unknown',
          'price': '\$${check['exchange_rate']?.toString() ?? '0'}',
          'date': _formatDate(check['exchange_date']),
          'status': _capitalizeStatus(check['status']),
          'type': 'customer',
        });
      }

      // Add supplier checks
      for (var check in supplierChecksResponse) {
        combinedChecks.add({
          'owner': check['supplier']?['name'] ?? 'Unknown',
          'price': '\$${check['exchange_rate']?.toString() ?? '0'}',
          'date': _formatDate(check['exchange_date']),
          'status': _capitalizeStatus(check['status']),
          'type': 'supplier',
        });
      }

      // Sort by date
      combinedChecks.sort((a, b) {
        final dateA = DateTime.tryParse(a['date'] ?? '') ?? DateTime.now();
        final dateB = DateTime.tryParse(b['date'] ?? '') ?? DateTime.now();
        return dateA.compareTo(dateB);
      });

      if (!mounted) return;
      setState(() {
        upcomingChecks = combinedChecks;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching upcoming checks: $e');
      if (!mounted) return;
      setState(() => isLoading = false);
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

  String _capitalizeStatus(String? status) {
    if (status == null) return '';
    return status
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upcoming Checks',
            style: TextStyle(
              color: AppColors.blue,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),

          // الهيدر
          const _TableHeaderBar(
            titles: [
              'Check owner',
              'Price',
              'Caching Date',
              'Type',
              'Check Status',
            ],
            blueIndex: 3,
            flexes: [3, 1, 1, 1, 2],
          ),
          const SizedBox(height: 6),

          // 🔹 Scroll داخلي لتفادي overflow
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.blue),
                  )
                : upcomingChecks.isEmpty
                ? const Center(
                    child: Text(
                      'No upcoming checks',
                      style: TextStyle(color: AppColors.grey, fontSize: 14),
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: upcomingChecks.asMap().entries.map((entry) {
                        final index = entry.key;
                        final check = entry.value;
                        final owner = check['owner'] ?? '';
                        final price = check['price'] ?? '';
                        final date = check['date'] ?? '';
                        final status = check['status'] ?? '';
                        final type = check['type'] ?? '';

                        final bool isEven = index.isEven;
                        final Color rowColor = isEven
                            ? AppColors.dark
                            : AppColors.cardAlt;

                        return Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: rowColor,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  owner,
                                  style: const TextStyle(
                                    color: AppColors.white,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    price,
                                    style: const TextStyle(
                                      color: AppColors.white,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    date,
                                    style: const TextStyle(
                                      color: AppColors.white,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    type == 'customer'
                                        ? 'Customer'
                                        : 'Supplier',
                                    style: const TextStyle(
                                      color: AppColors.blue,
                                      fontSize: 13,
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
                                    status,
                                    style: const TextStyle(
                                      color: AppColors.blue, // 🔹 الكل أزرق
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------
// الكروت الصغيرة Endorsed / Returned
// ------------------------------------------------------------------
class _TopStatsCards extends StatefulWidget {
  const _TopStatsCards();

  @override
  State<_TopStatsCards> createState() => _TopStatsCardsState();
}

class _TopStatsCardsState extends State<_TopStatsCards> {
  int endorsedCount = 0;
  int returnedCount = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCheckStats();
  }

  Future<void> _fetchCheckStats() async {
    try {
      if (mounted) setState(() => isLoading = true);

      // Fetch endorsed checks count (customer checks only)
      final endorsedResponse = await supabase
          .from('customer_checks')
          .select('check_id')
          .eq('status', 'Endorsed');

      // Calculate this month's date range
      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

      final startDate = firstDayOfMonth.toIso8601String().split('T')[0];
      final endDate = lastDayOfMonth.toIso8601String().split('T')[0];

      // Fetch returned checks count for this month (customer checks)
      final returnedResponse = await supabase
          .from('customer_checks')
          .select('check_id')
          .eq('status', 'Returned')
          .gte('exchange_date', startDate)
          .lte('exchange_date', endDate);

      if (mounted) {
        setState(() {
          endorsedCount = endorsedResponse.length;
          returnedCount = returnedResponse.length;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching check stats: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SingleStatCard(
            icon: Image.asset(
              'assets/icons/doller.png',
              width: 40,
              height: 40,
              fit: BoxFit.contain,
              errorBuilder: (c, e, s) => const Icon(
                Icons.autorenew_rounded,
                color: AppColors.blue,
                size: 28,
              ),
            ),
            number: isLoading ? '-' : endorsedCount.toString(),
            label: 'Check',
            bottomMain: 'Endorsed',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _SingleStatCard(
            icon: Image.asset(
              'assets/icons/dontcheck.png',
              width: 36,
              height: 36,
              fit: BoxFit.contain,
              errorBuilder: (c, e, s) => const Icon(
                Icons.block_rounded,
                color: AppColors.blue,
                size: 28,
              ),
            ),
            number: isLoading ? '-' : returnedCount.toString(),
            label: 'Check',
            bottomMain: 'Returned',
            bottomSmall: 'this month',
          ),
        ),
      ],
    );
  }
}

class _SingleStatCard extends StatelessWidget {
  final Widget icon;
  final String number;
  final String label; // النص الصغير تحت الرقم (Check)
  final String bottomMain; // الكلمة الكبيرة باللون الأزرق (Endorsed / Returned)
  final String? bottomSmall; // النص الأزرق الصغير (this month)

  const _SingleStatCard({
    required this.icon,
    required this.number,
    required this.label,
    required this.bottomMain,
    this.bottomSmall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 🔹 الأيقونة الزرقاء في الأعلى
          SizedBox(width: 44, height: 44, child: Center(child: icon)),
          const SizedBox(height: 4),

          // 🔹 الرقم الكبير
          Text(
            number,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 42,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),

          // 🔹 النص الصغير "Check"
          Text(
            label,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),

          // 🔹 النص الأزرق في الأسفل
          Column(
            children: [
              Text(
                bottomMain,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.blue,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (bottomSmall != null)
                Text(
                  bottomSmall!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.blue,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------
// هيدر تابل عام مع flex مطابق للصفوف + alignment مضبوط
// ------------------------------------------------------------------
class _TableHeaderBar extends StatelessWidget {
  final List<String> titles;
  final int blueIndex; // أي عمود يكون عنوانه أزرق
  final List<int>? flexes; // نفس flex تبع الصفوف

  const _TableHeaderBar({
    required this.titles,
    required this.blueIndex,
    this.flexes,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      // نفس الـ padding اللي مستخدم في صفوف الجدول
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: titles.asMap().entries.map((entry) {
              final index = entry.key;
              final title = entry.value;

              // لو flexes موجودة نستخدمها، غير هيك 1
              final flex = flexes != null && index < flexes!.length
                  ? flexes![index]
                  : 1;

              // أول عمود يسار، باقي الأعمدة يمين (مثل الصفوف بالضبط)
              final Alignment alignment = index == 0
                  ? Alignment.centerLeft
                  : Alignment.centerRight;

              return Expanded(
                flex: flex,
                child: Align(
                  alignment: alignment,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: alignment,
                    child: Text(
                      title,
                      style: TextStyle(
                        color: index == blueIndex
                            ? AppColors.blue
                            : AppColors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 4),
          Container(
            height: 1,
            width: double.infinity,
            color: Colors.white.withOpacity(0.4),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------
// Card: Most Debtors
// ------------------------------------------------------------------
class _MostDebtorsCard extends StatefulWidget {
  const _MostDebtorsCard();

  @override
  State<_MostDebtorsCard> createState() => _MostDebtorsCardState();
}

class _MostDebtorsCardState extends State<_MostDebtorsCard> {
  List<Map<String, dynamic>> topSuppliers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTopSuppliers();
  }

  Future<void> _fetchTopSuppliers() async {
    try {
      if (!mounted) return;
      setState(() => isLoading = true);

      // Fetch top 5 suppliers ordered by creditor_balance (highest first)
      final response = await supabase
          .from('supplier')
          .select('name, creditor_balance')
          .not('creditor_balance', 'is', null)
          .order('creditor_balance', ascending: false)
          .limit(5);

      if (!mounted) return;
      setState(() {
        topSuppliers = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching top suppliers: $e');
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Most Debtors',
            style: TextStyle(
              color: AppColors.blue,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),

          const _TableHeaderBar(
            titles: ['Supplier Name', 'Creditor Balance'],
            blueIndex: 1,
            flexes: [3, 1],
          ),
          const SizedBox(height: 6),
          // الصفوف مع Scroll داخلي لتجنّب overflow
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.blue),
                  )
                : topSuppliers.isEmpty
                ? const Center(
                    child: Text(
                      'No suppliers found',
                      style: TextStyle(color: AppColors.grey, fontSize: 14),
                    ),
                  )
                : ListView.builder(
                    itemCount: topSuppliers.length,
                    padding: const EdgeInsets.only(top: 2),
                    itemBuilder: (context, index) {
                      final supplier = topSuppliers[index];
                      final name = supplier['name'] ?? 'Unknown';
                      final balance = supplier['creditor_balance'] ?? 0;
                      final bool isEven = index.isEven;

                      final Color rowColor = isEven
                          ? AppColors.dark
                          : AppColors.cardAlt;

                      return Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: rowColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                name,
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  '\$${balance.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: AppColors.blue,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
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
      ),
    );
  }
}

// ------------------------------------------------------------------
// Card: Total profit + الرسم البياني
// ------------------------------------------------------------------
class _TotalProfitCard extends StatelessWidget {
  const _TotalProfitCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Expanded(child: _ProfitChart())],
      ),
    );
  }
}

// ===================== Total Profit Chart =====================
class _ProfitChart extends StatefulWidget {
  const _ProfitChart();

  @override
  State<_ProfitChart> createState() => _ProfitChartState();
}

class _ProfitChartState extends State<_ProfitChart>
    with SingleTickerProviderStateMixin {
  String selectedYear = '2026';

  List<double> profitData = List.filled(12, 0.0);
  final List<String> months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static const double _barMaxHeight = 230;
  static const int _tickCount = 5;

  int? _hoveredIndex;

  late final AnimationController _controller;
  late final Animation<double> _animation;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _fetchProfitData();
    _controller.forward();
  }

  Future<void> _fetchProfitData() async {
    setState(() {
      isLoading = true;
    });
    try {
      // Get all customer orders for the selected year
      final response = await supabase
          .from('customer_order')
          .select('''
            customer_order_id,
            order_date,
            tax_percent,
            customer_order_description!customer_order_description_customer_order_id_fkey (
              product_id,
              quantity,
              total_price,
              product:product_id (
                wholesale_price
              )
            )
          ''')
          .gte('order_date', '${selectedYear}-01-01')
          .lte('order_date', '${selectedYear}-12-31');

      // Prepare monthly profit array
      List<double> monthlyProfit = List.filled(12, 0.0);

      for (var order in response) {
        final orderDate = DateTime.tryParse(order['order_date'] ?? '');
        if (orderDate == null) continue;
        final monthIndex = orderDate.month - 1;
        final taxPercent = (order['tax_percent'] ?? 0).toDouble();
        final descriptions =
            order['customer_order_description'] as List<dynamic>? ?? [];

        double orderProfit = 0.0;
        for (var desc in descriptions) {
          final totalPrice = (desc['total_price'] ?? 0).toDouble();
          final quantity = (desc['quantity'] ?? 0).toDouble();
          final wholesalePrice = (desc['product']?['wholesale_price'] ?? 0)
              .toDouble();
          // Profit for this product in the order
          final productProfit =
              (totalPrice - (wholesalePrice * quantity)) *
              (1 - (taxPercent / 100));
          orderProfit += productProfit;
        }
        monthlyProfit[monthIndex] += orderProfit;
      }

      setState(() {
        profitData = monthlyProfit;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching profit data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final anim = _animation.value;
        final maxProfit = (profitData.reduce((a, b) => a > b ? a : b)).abs();
        final chartMaxY = maxProfit > 0 ? maxProfit * 1.2 : 20;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // العنوان + السنة
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total profit',
                  style: TextStyle(
                    color: AppColors.blue,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cardAlt,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(1, 2),
                      ),
                    ],
                  ),
                  child: DropdownButton<String>(
                    value: selectedYear,
                    dropdownColor: AppColors.card,
                    underline: const SizedBox(),
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: AppColors.white,
                      size: 16,
                    ),
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    items: const ['2024', '2025', '2026']
                        .map(
                          (year) =>
                              DropdownMenuItem(value: year, child: Text(year)),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedYear = value);
                        _fetchProfitData();
                        _controller.forward(from: 0);
                      }
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // الرسم البياني يأخذ المساحة المتبقية (بدون overflow)
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.blue),
                    )
                  : Stack(
                      children: [
                        // GRID
                        Positioned.fill(
                          child: Column(
                            children: List.generate(_tickCount, (index) {
                              return Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border(
                                      top: BorderSide(
                                        color: Colors.white.withOpacity(0.08),
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // محور Y
                            SizedBox(
                              width: 40,
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: List.generate(_tickCount, (index) {
                                  final step = chartMaxY / (_tickCount - 1);
                                  final value = index * step;
                                  return Text(
                                    value == 0
                                        ? '0'
                                        : '${value.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      color: AppColors.grey,
                                      fontSize: 10,
                                    ),
                                  );
                                }).reversed.toList(),
                              ),
                            ),

                            const SizedBox(width: 8),

                            // الأعمدة
                            Expanded(
                              child: Column(
                                children: [
                                  Expanded(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: List.generate(months.length, (
                                        index,
                                      ) {
                                        final v = profitData[index];
                                        final targetHeight = chartMaxY > 0
                                            ? (v / chartMaxY) * _barMaxHeight
                                            : 0.0;
                                        final baseHeight =
                                            targetHeight * anim.clamp(0, 1);

                                        final isHovered =
                                            _hoveredIndex == index;
                                        final barHeight = isHovered
                                            ? baseHeight + 12
                                            : baseHeight;
                                        final barWidth = isHovered
                                            ? 38.0
                                            : 32.0;
                                        final opacity = isHovered ? 1.0 : 0.85;

                                        return MouseRegion(
                                          onEnter: (_) => setState(
                                            () => _hoveredIndex = index,
                                          ),
                                          onExit: (_) => setState(
                                            () => _hoveredIndex = null,
                                          ),
                                          child: Tooltip(
                                            message:
                                                '${profitData[index].toStringAsFixed(2)} - ${months[index]}',
                                            waitDuration: const Duration(
                                              milliseconds: 150,
                                            ),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                // Profit label ABOVE the bar
                                                Opacity(
                                                  opacity: anim,
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          bottom: 6,
                                                        ),
                                                    child: Text(
                                                      '\$ ${profitData[index].toInt()} ',
                                                      style: TextStyle(
                                                        color: isHovered
                                                            ? AppColors.white
                                                            : AppColors.white
                                                                  .withOpacity(
                                                                    0.9,
                                                                  ),
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                // The bar itself
                                                AnimatedContainer(
                                                  duration: const Duration(
                                                    milliseconds: 250,
                                                  ),
                                                  curve: Curves.easeOutCubic,
                                                  width: barWidth,
                                                  height: barHeight,
                                                  decoration: BoxDecoration(
                                                    color: AppColors.blue
                                                        .withOpacity(opacity),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          5,
                                                        ),
                                                    boxShadow:
                                                        isHovered &&
                                                            barHeight > 0
                                                        ? [
                                                            BoxShadow(
                                                              color: AppColors
                                                                  .blue
                                                                  .withOpacity(
                                                                    0.4,
                                                                  ),
                                                              blurRadius: 10,
                                                              spreadRadius: 1,
                                                              offset:
                                                                  const Offset(
                                                                    0,
                                                                    2,
                                                                  ),
                                                            ),
                                                          ]
                                                        : [],
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                // Month label under the bar
                                                Text(
                                                  months[index],
                                                  style: const TextStyle(
                                                    color: AppColors.grey,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}

// ------------------------------------------------------------------
// Popup: Select Transaction Type (Add Payment)
// ------------------------------------------------------------------
void showSelectTransactionDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.cardAlt,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 6),
                      Text(
                        'Select Transaction Type',
                        style: TextStyle(
                          color: AppColors.blue,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 18),

                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.of(ctx).pop();
                                showChoosePaymentMethodDialog(ctx, 'incoming');
                              },
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: AppColors.card,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Image.asset(
                                      'assets/icons/incoming_payment.png',
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Incoming Payment',
                                    style: TextStyle(
                                      color: AppColors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          Container(
                            width: 1,
                            height: 180,
                            margin: const EdgeInsets.symmetric(horizontal: 18),
                            color: Colors.white.withOpacity(0.12),
                          ),

                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.of(ctx).pop();
                                showChoosePaymentMethodDialog(ctx, 'outgoing');
                              },
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: AppColors.card,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Image.asset(
                                      'assets/icons/outgoing_payment.png',
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Outgoing Payment',
                                    style: TextStyle(
                                      color: AppColors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),

                  Positioned(
                    top: 6,
                    right: 6,
                    child: InkWell(
                      onTap: () => Navigator.of(ctx).pop(),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white70,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
