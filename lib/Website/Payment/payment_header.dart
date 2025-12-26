import 'package:flutter/material.dart';
import '../Payment_page.dart';
import 'Payment_checks_page.dart';
import 'Payment_archive_page.dart';

/// Reusable header for payment pages
class PaymentHeader extends StatelessWidget {
  final String currentPage; // 'statistics', 'checks', or 'archive'
  final bool? isIncoming; // For checks and archive pages (null for statistics)
  final ValueChanged<bool>? onIncomingChanged; // Callback when switch changes

  const PaymentHeader({
    super.key,
    required this.currentPage,
    this.isIncoming,
    this.onIncomingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ================== Header Section ==================
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
              icon: const Icon(Icons.add, color: AppColors.black, size: 18),
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

        // ================== Tab Navigation ==================
        Row(
          children: [
            _TopTextTab(
              label: 'Statistics',
              isActive: currentPage == 'statistics',
              onTap: currentPage != 'statistics'
                  ? () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const PaymentPage()),
                      );
                    }
                  : null,
            ),
            const SizedBox(width: 24),
            _TopTextTab(
              label: 'Checks',
              isActive: currentPage == 'checks',
              onTap: currentPage != 'checks'
                  ? () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const CheckPage()),
                      );
                    }
                  : null,
            ),
            const SizedBox(width: 24),
            _TopTextTab(
              label: 'Archive',
              isActive: currentPage == 'archive',
              onTap: currentPage != 'archive'
                  ? () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ArchivePaymentPage(),
                        ),
                      );
                    }
                  : null,
            ),
            // Show Incoming/Outgoing switch only for checks and archive pages
            if (isIncoming != null && onIncomingChanged != null) ...[
              const SizedBox(width: 32),
              _IncomingOutgoingSwitch(
                isIncoming: isIncoming!,
                onIncoming: () => onIncomingChanged!(true),
                onOutgoing: () => onIncomingChanged!(false),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------
// Incoming/Outgoing Switch
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
// Top Text Tab Widget
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
// Colors
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
