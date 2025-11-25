import 'package:flutter/material.dart';
import 'Bar.dart';
import 'order_item.dart';


class PreparingOrderDetailsPage extends StatelessWidget {
  final String customerName;
  final List<OrderItem> items;
  final String preparedByName;
  final String preparedByImage;

  const PreparingOrderDetailsPage({
    super.key,
    required this.customerName,
    required this.items,
    required this.preparedByName,
    required this.preparedByImage,
  });

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
              // Back + Title
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

              // Table Headers
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

              // Items
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
                          Expanded(
                            flex: 2,
                            child: Text(
                              "${item.qty} ${item.unit}",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.gold,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
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

              // ===== Preparing By Section =====
              // ===== Preparing By Section =====
              Row(
                children: [
                  const Text(
                    "Preparing By:",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,            // 🔥 أكبر من قبل
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // 🔥 صورة أكبر
                  CircleAvatar(
                    radius: 28,                // كان 20 → الآن أكبر
                    backgroundImage: AssetImage(preparedByImage),
                  ),

                  const SizedBox(width: 14),

                  // 🔥 اسم أكبر وأوضح
                  Text(
                    preparedByName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,             // كان 15 → الآن أكبر
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),


              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
