import 'package:flutter/material.dart';
import 'add_incoming_cash.dart';
import 'add_outgoing_cash.dart';
import 'add_outgoing_check.dart';
import 'add_incoming_check.dart';

// ------------------------------------------------------------------
// Popup: Choose Payment Method (Cash / Check)
// ------------------------------------------------------------------

/// Color palette for the payment dialog
class _PaymentColors {
  static const white = Color(0xFFFFFFFF);
  static const blue = Color(0xFF50B2E7);
  static const card = Color(0xFF2D2D2D);
  static const cardAlt = Color(0xFF262626);
}

void showChoosePaymentMethodDialog(BuildContext context, String paymentType) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              decoration: BoxDecoration(
                color: _PaymentColors.cardAlt,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Stack(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 6),
                      Text(
                        'Choose Payment Method',
                        style: TextStyle(
                          color: _PaymentColors.blue,
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
                                if (paymentType == 'incoming') {
                                  Navigator.of(ctx).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const AddIncomingCashPage(),
                                    ),
                                  );
                                } else if (paymentType == 'outgoing') {
                                  Navigator.of(ctx).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const AddOutgoingCashPage(),
                                    ),
                                  );
                                }
                              },
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: _PaymentColors.card,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Image.asset(
                                      'assets/icon/cash.png',
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.contain,
                                      errorBuilder: (c, e, s) => const Icon(
                                        Icons.attach_money_rounded,
                                        color: _PaymentColors.white,
                                        size: 36,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Cash',
                                    style: TextStyle(
                                      color: _PaymentColors.white,
                                      fontSize: 20,
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
                                if (paymentType == 'incoming') {
                                  Navigator.of(ctx).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const AddIncomingCheckPage(),
                                    ),
                                  );
                                } else if (paymentType == 'outgoing') {
                                  Navigator.of(ctx).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const AddOutgoingCheckPage(),
                                    ),
                                  );
                                }
                              },
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: _PaymentColors.card,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Image.asset(
                                      'assets/icon/check.png',
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.contain,
                                      errorBuilder: (c, e, s) => const Icon(
                                        Icons.description_rounded,
                                        color: _PaymentColors.white,
                                        size: 36,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Check',
                                    style: TextStyle(
                                      color: _PaymentColors.white,
                                      fontSize: 20,
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
