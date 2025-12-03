import 'package:flutter/material.dart';
import 'supplier_bottom_nav.dart';
import 'supplier_home_page.dart';

class OrderDetailsPage extends StatelessWidget {
  final String customerName;
  final List<Map<String, dynamic>> products;

  const OrderDetailsPage({
    super.key,
    required this.customerName,
    required this.products,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),

      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Back button + Name
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D2D2D),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Icon(Icons.arrow_back, color: Color(0xFFF9D949)),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  customerName,
                  style: const TextStyle(
                    color: Color(0xFFF9D949),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            // Table Headers
            Row(
              children: const [
                Expanded(
                  flex: 4,
                  child: Text("Product Name",
                      style: TextStyle(color: Colors.white60, fontSize: 16)),
                ),
                Expanded(
                  flex: 2,
                  child: Text("Brand",
                      style: TextStyle(color: Colors.white60, fontSize: 16)),
                ),
                Expanded(
                  flex: 2,
                  child: Text("Quantity",
                      style: TextStyle(color: Colors.white60, fontSize: 16)),
                ),
              ],
            ),

            const SizedBox(height: 10),
            Container(height: 1, color: Colors.white12),
            const SizedBox(height: 10),

            // Product rows
            Expanded(
              child: ListView.builder(
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final p = products[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Text(
                            p['name'],
                            style:
                                const TextStyle(color: Colors.white, fontSize: 17),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            p['brand'],
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 16),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2D2D2D),
                              borderRadius: BorderRadius.circular(10),
                              border:
                                  Border.all(color: Color(0xFFF9D949), width: 1),
                            ),
                            child: Text(
                              "${p['quantity']}",
                              style: const TextStyle(
                                  color: Color(0xFFF9D949),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
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

            // Done button
            GestureDetector(
              onTap: () {},
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9D949),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "D   o   n   e",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    SizedBox(width: 12),
                    Icon(Icons.send, color: Color(0xFF1A1A1A)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),

      bottomNavigationBar: SupplierBottomNav(
        currentIndex: 0,
        onTap: (i) {
          if (i == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AccountPage()),
            );
          }
        },
      ),
    );
  }
}
