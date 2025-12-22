import 'package:flutter/material.dart';
import 'manager_theme.dart';
import 'SelectStaffSheet.dart';
import 'order_item.dart';

class OrderDetailsPage extends StatefulWidget {
  final String customerName;
  final List<OrderItem> items;

  const OrderDetailsPage({
    super.key,
    required this.customerName,
    required this.items,
  });

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  void _openStaffSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SelectStaffSheet(
        onSelected: (staffName) {
          Navigator.pop(context);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Sent to $staffName")));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.customerName,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              const Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Text(
                      "Product Name",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      "Brand",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      "Quantity",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),
              Container(height: 1, color: Colors.white24),
              const SizedBox(height: 12),

              Expanded(
                child: ListView.builder(
                  itemCount: widget.items.length,
                  itemBuilder: (_, i) {
                    final item = widget.items[i];

                    final controller = TextEditingController(
                      text: item.qty.toString(),
                    );

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: Text(
                              item.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              item.brand,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ),

                          // ===== QUANTITY BOX =====
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // الصندوق الذهبي
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFB7A447),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  alignment: Alignment.center,
                                  child: TextField(
                                    controller: controller,
                                    onChanged: (v) {
                                      if (v.isNotEmpty) {
                                        setState(
                                          () => item.qty =
                                              int.tryParse(v) ?? item.qty,
                                        );
                                      }
                                    },
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                    ),
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      isCollapsed: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 8),

                                Text(
                                  item.unit,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),

              // SEND BUTTON
              CustomSendButton(text: "s  e  n  d", onTap: _openStaffSelector),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomSendButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const CustomSendButton({super.key, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: AppColors.gold,
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // ===== النص على اليسار =====
            Text(
              text,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 8,
              ),
            ),

            // ===== الأيقونة على اليمين =====
            Transform.rotate(
              angle: -0.8,
              child: const Icon(
                Icons.send_rounded,
                color: AppColors.white,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
