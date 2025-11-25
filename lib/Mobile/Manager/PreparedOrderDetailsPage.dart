import 'package:flutter/material.dart';
import 'Bar.dart';
import 'order_item.dart';
import 'package:dolphin/Mobile/Manager/CustomSendButton.dart';
import 'SelectDeliveryDriverSheet.dart'; // ✨ البوتوم شيت الجديد للدرايفرز

class PreparedOrderDetailsPage extends StatelessWidget {
  final String customerName;
  final List<OrderItem> items;
  final String preparedByName;
  final String preparedByImage;

  const PreparedOrderDetailsPage({
    super.key,
    required this.customerName,
    required this.items,
    required this.preparedByName,
    required this.preparedByImage,
  });

  void _openDriverSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SelectDeliveryDriverSheet(
        onSelected: (driverName) {
          Navigator.pop(context);

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Sent to $driverName")));
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
              // ===================== Back + Name =====================
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    customerName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ===================== TABLE HEADER =====================
              const Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Text(
                      "Product Name",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
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
                        fontWeight: FontWeight.bold,
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
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),
              Container(height: 1, color: Colors.white24),
              const SizedBox(height: 10),

              // ===================== ITEMS LIST =====================
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final item = items[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          // NAME
                          Expanded(
                            flex: 5,
                            child: Text(
                              item.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          // BRAND
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

                          // ===================== QUANTITY (NOT EDITABLE) =====================
                          Expanded(
                            flex: 2,

                            child: Center(
                              child: Text(
                                "${item.qty} ${item.unit}",
                                style: const TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
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

              const SizedBox(height: 20),

              // ===================== PREPARED BY =====================
              Row(
                children: [
                  const Text(
                    "Prepared By:",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 10),

                  CircleAvatar(
                    radius: 26, // 🔥 أكبر
                    backgroundImage: AssetImage(preparedByImage),
                  ),

                  const SizedBox(width: 10),

                  Text(
                    preparedByName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17, // 🔥 أكبر
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 26),

              // ===================== SEND BUTTON =====================
              CustomSendButton(
                text: "s   e   n   d",
                onTap: () => _openDriverSelector(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
