import 'package:flutter/material.dart';
import 'payment_page.dart';
import 'sidebar.dart';
import 'checks_page.dart';
import 'choose_payment.dart';

/// صفحة: Payment - Archive (Incoming / Outgoing)
class ArchivePaymentPage extends StatefulWidget {
  const ArchivePaymentPage({super.key});

  @override
  State<ArchivePaymentPage> createState() => _ArchivePaymentPageState();
}

class _ArchivePaymentPageState extends State<ArchivePaymentPage> {
  bool isIncoming = true;

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
                          onPressed: () => showChoosePaymentMethodDialog(
                            context,
                            isIncoming ? 'incoming' : 'outgoing',
                          ),
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
                              fontWeight: FontWeight.w700,
                              color: AppColors.black,
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

                    // ================== Tabs أعلى ==================
                    Row(
                      children: [
                        _TopTextTab(
                          label: 'Statistics',
                          isActive: false,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PaymentPage(),
                              ),
                            ); // يرجع لـ PaymentPage
                          },
                        ),
                        const SizedBox(width: 24),
                        _TopTextTab(
                          label: 'Checks',
                          isActive: false,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CheckPage(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 24),
                        const _TopTextTab(
                          label: 'Archive',
                          isActive: true, // هذه الصفحة
                        ),
                        const SizedBox(width: 32),

                        // Incoming / Outgoing switch
                        _IncomingOutgoingSwitch(
                          isIncoming: isIncoming,
                          onIncoming: () {
                            setState(() => isIncoming = true);
                          },
                          onOutgoing: () {
                            setState(() => isIncoming = false);
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // ================== Search + Filter ==================
                    const Row(children: [Spacer(), _SearchFilterBar()]),

                    const SizedBox(height: 8),

                    // ================== جدول الأرشيف ==================
                    Expanded(child: _ArchiveTable(isIncoming: isIncoming)),
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
// تابات النص العلوية
// ------------------------------------------------------------------
class _TopTextTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  const _TopTextTab({required this.label, this.isActive = false, this.onTap});

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
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------
// سويتش Incoming / Outgoing
// ------------------------------------------------------------------
class _IncomingOutgoingSwitch extends StatelessWidget {
  final bool isIncoming;
  final VoidCallback onIncoming;
  final VoidCallback onOutgoing;

  const _IncomingOutgoingSwitch({
    required this.isIncoming,
    required this.onIncoming,
    required this.onOutgoing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.cardAlt,
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Incoming
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onIncoming,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isIncoming
                      ? Colors.black.withOpacity(0.6)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  "Incoming",
                  style: TextStyle(
                    color: isIncoming ? AppColors.blue : AppColors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),

          // Outgoing
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onOutgoing,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: !isIncoming
                      ? Colors.black.withOpacity(0.6)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  "Outgoing",
                  style: TextStyle(
                    color: !isIncoming ? AppColors.blue : AppColors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------
// Search + Filter bar
// ------------------------------------------------------------------
class _SearchFilterBar extends StatelessWidget {
  const _SearchFilterBar();

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
            children: const [
              Icon(
                Icons.person_search_rounded,
                color: AppColors.white,
                size: 18,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Entre Name',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.grey, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: AppColors.blue,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.filter_list_rounded,
            color: AppColors.white,
            size: 18,
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

  const _ArchiveTable({required this.isIncoming});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> rows = [
      {'payer': 'Kareem Manasra', 'price': '1000\$', 'date': '19/8/2025'},
      {'payer': 'Ammar Shobaki', 'price': '2000\$', 'date': '22/8/2025'},
      {'payer': 'Ata Musleh', 'price': '500\$', 'date': '22/8/2025'},
      {'payer': 'Ameer Yasin', 'price': '3000\$', 'date': '23/8/2025'},
      {'payer': 'Ahmad Nizar', 'price': '7000\$', 'date': '25/8/2025'},
    ];

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
                        row['payer'] ?? '',
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
