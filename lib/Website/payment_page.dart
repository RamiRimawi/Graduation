import 'package:flutter/material.dart';
import 'sidebar.dart';
import 'checks_page.dart';
import 'archive_payment_page.dart';
import 'choose_payment.dart';

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
          const Sidebar(activeIndex: 4), // السايدبار
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
                        onTap: () {
                          setState(() => activeTab = 0);
                          // إنت أصلاً في الصفحة نفسها، ما في تنقّل
                        },
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
                            height: 260,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: const [
                                Expanded(flex: 3, child: _UpcomingChecksCard()),
                                SizedBox(width: 18),
                                Expanded(flex: 2, child: _TopStatsCards()),
                              ],
                            ),
                          ),

                          const SizedBox(height: 18),

                          // ================== الصف السفلي ==================
                          SizedBox(
                            height: 330,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: const [
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

// ------------------------------------------------------------------
// Card: Upcoming Checks  (zebra + scroll + check status أزرق)
// ------------------------------------------------------------------
class _UpcomingChecksCard extends StatelessWidget {
  const _UpcomingChecksCard();

  @override
  Widget build(BuildContext context) {
    final rows = <List<String>>[
      ['Kareem Manasra', '1000\$', '19/10/2025', 'Company Box'],
      ['Ammar Shobaki', '2000\$', '22/8/2025', 'Company Box'],
      ['Ata Musleh', '500\$', '22/8/2025', 'Endorsed'],
      ['Ameer Yasin', '3000\$', '23/9/2025', 'Endorsed'],
      ['Ahmad Nizar', '7000\$', '25/8/2025', 'Company Box'],
    ];

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
            titles: ['Check owner', 'Price', 'Caching Date', 'Check Status'],
            blueIndex: 3,
            flexes: [3, 1, 1, 2],
          ),
          const SizedBox(height: 6),

          // 🔹 Scroll داخلي لتفادي overflow
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: rows.asMap().entries.map((entry) {
                  final index = entry.key;
                  final row = entry.value;
                  final owner = row[0];
                  final price = row[1];
                  final date = row[2];
                  final status = row[3];

                  final bool isEven = index.isEven;
                  final Color rowColor = isEven
                      ? AppColors.dark
                      : AppColors.cardAlt;

                  return Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
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
class _TopStatsCards extends StatelessWidget {
  const _TopStatsCards();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SingleStatCard(
            icon: Image.asset(
              'assets/icon/doller.png',
              width: 60,
              height: 60,
              fit: BoxFit.contain,
              errorBuilder: (c, e, s) => const Icon(
                Icons.autorenew_rounded,
                color: AppColors.blue,
                size: 40,
              ),
            ),
            number: '9',
            label: 'Check',
            bottomMain: 'Endorsed',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _SingleStatCard(
            icon: Image.asset(
              'assets/icon/dontcheck.png',
              width: 50,
              height: 50,
              fit: BoxFit.contain,
              errorBuilder: (c, e, s) => const Icon(
                Icons.block_rounded,
                color: AppColors.blue,
                size: 40,
              ),
            ),
            number: '5',
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
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 🔹 الأيقونة الزرقاء في الأعلى
          SizedBox(width: 60, height: 60, child: Center(child: icon)),
          const SizedBox(height: 5),

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
          const SizedBox(height: 5),

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
class _MostDebtorsCard extends StatelessWidget {
  const _MostDebtorsCard();

  @override
  Widget build(BuildContext context) {
    final rows = <List<String>>[
      ['Kareem Manasra', '1000\$'],
      ['Ammar Shobaki', '2000\$'],
      ['Ata Musleh', '500\$'],
      ['Ameer Yasin', '3000\$'],
      ['Ahmad Nizar', '7000\$'],
    ];

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
            titles: ['Check owner', 'Debit Balance'],
            blueIndex: 1,
            flexes: [3, 1],
          ),
          const SizedBox(height: 6),
          // الصفوف مع Scroll داخلي لتجنّب overflow
          Expanded(
            child: ListView.builder(
              itemCount: rows.length,
              padding: const EdgeInsets.only(top: 2),
              itemBuilder: (context, index) {
                final owner = rows[index][0];
                final balance = rows[index][1];
                final bool isEven = index.isEven;

                final Color rowColor = isEven
                    ? AppColors.dark
                    : AppColors.cardAlt;

                return Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
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
                          owner,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            balance,
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

  final List<int> profitData = [13, 14, 14, 15, 16, 16, 17, 17, 16, 18, 18, 20];
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

  static const double _maxY = 20;
  static const double _barMaxHeight = 180;
  static const int _tickCount = 5;

  int? _hoveredIndex;

  late final AnimationController _controller;
  late final Animation<double> _animation;

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
    _controller.forward();
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
              child: Stack(
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(_tickCount, (index) {
                            final step = _maxY / (_tickCount - 1);
                            final value = index * step;
                            return Text(
                              value == 0 ? '0' : '${value.toInt()}K',
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
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: List.generate(months.length, (index) {
                                  final v = profitData[index].toDouble();
                                  final targetHeight =
                                      (v / _maxY) * _barMaxHeight;
                                  final baseHeight =
                                      targetHeight * anim.clamp(0, 1);

                                  final isHovered = _hoveredIndex == index;
                                  final barHeight = isHovered
                                      ? baseHeight + 12
                                      : baseHeight;
                                  final barWidth = isHovered ? 30.0 : 26.0;
                                  final opacity = isHovered ? 1.0 : 0.85;

                                  return MouseRegion(
                                    onEnter: (_) =>
                                        setState(() => _hoveredIndex = index),
                                    onExit: (_) =>
                                        setState(() => _hoveredIndex = null),
                                    child: Tooltip(
                                      message:
                                          '${profitData[index]}K - ${months[index]}',
                                      waitDuration: const Duration(
                                        milliseconds: 150,
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 250,
                                            ),
                                            curve: Curves.easeOutCubic,
                                            width: barWidth,
                                            height: barHeight,
                                            decoration: BoxDecoration(
                                              color: AppColors.blue.withOpacity(
                                                opacity,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                              boxShadow:
                                                  isHovered && barHeight > 0
                                                  ? [
                                                      BoxShadow(
                                                        color: AppColors.blue
                                                            .withOpacity(0.4),
                                                        blurRadius: 10,
                                                        spreadRadius: 1,
                                                        offset: const Offset(
                                                          0,
                                                          2,
                                                        ),
                                                      ),
                                                    ]
                                                  : [],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Opacity(
                                            opacity: anim,
                                            child: Text(
                                              '${profitData[index]}K',
                                              style: TextStyle(
                                                color: isHovered
                                                    ? AppColors.white
                                                    : AppColors.white
                                                          .withOpacity(0.9),
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
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
                                      'assets/icon/incoming_payment.png',
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
                                      'assets/icon/outgoing_payment.png',
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
