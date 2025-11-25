import 'package:flutter/material.dart';
import 'Bar.dart';
import 'CreateStockInOrderPage.dart';

class StockInPage extends StatefulWidget {
  const StockInPage({super.key});

  @override
  State<StockInPage> createState() => _StockInPageState();
}

class _StockInPageState extends State<StockInPage> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> recommendedOrders = [
    {"id": 26, "supplier": "Ahmad Nizar", "inventory": 1},
    {"id": 27, "supplier": "Saed Rimawi", "inventory": 1},
    {"id": 30, "supplier": "Akef Al Asmar", "inventory": 2},
    {"id": 28, "supplier": "Nizar Fares", "inventory": 2},
    {"id": 20, "supplier": "Eyas Barghouthi", "inventory": 1},
  ];

  List<Map<String, dynamic>> filteredOrders = [];

  @override
  void initState() {
    super.initState();
    filteredOrders = List.from(recommendedOrders);

    _searchController.addListener(() {
      final query = _searchController.text.toLowerCase();

      setState(() {
        filteredOrders = recommendedOrders.where((order) {
          final supplier = order["supplier"].toLowerCase();

          // 🔍 يبدأ بالحرف المكتوب (بحث أدق)
          return supplier.startsWith(query);
        }).toList();
      });
    });
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
              // ===================== TITLE =====================
              const Text(
                "Recommended orders",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),

              // ===================== SEARCH FIELD =====================
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 0,
                ),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: AppColors.gold, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        decoration: const InputDecoration(
                          hintText: "Supplier Name",
                          hintStyle: TextStyle(
                            color: Colors.white54,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ===================== TABLE HEADER =====================
              const Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      "Order ID #",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: Text(
                      "Supplier Name",
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
                      "Inventory #",
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
              const SizedBox(height: 14),

              // ===================== ORDERS LIST =====================
              Expanded(
                child: ListView.builder(
                  itemCount: filteredOrders.length,
                  itemBuilder: (_, i) {
                    final o = filteredOrders[i];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          // Order ID
                          Expanded(
                            flex: 3,
                            child: Text(
                              "${o["id"]}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),

                          // Supplier Name
                          Expanded(
                            flex: 5,
                            child: Text(
                              o["supplier"],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),

                          // Inventory #
                          Expanded(
                            flex: 3,
                            child: Text(
                              "${o["inventory"]}",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
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

              const SizedBox(height: 10),

              // ===================== Create Order BUTTON =====================
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CreateStockInOrderPage(),
                      ),
                    );
                  },

                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_box_rounded,
                          color: Colors.black,
                          size: 22,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Create Order",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
