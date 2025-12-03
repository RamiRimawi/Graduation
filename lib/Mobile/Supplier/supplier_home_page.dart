import 'package:flutter/material.dart';
import '../account_page.dart';
import 'supplier_bottom_nav.dart';
import 'order_details_page.dart';   // ⬅ مهم جداً

class SupplierHomePage extends StatefulWidget {
  const SupplierHomePage({super.key});

  @override
  State<SupplierHomePage> createState() => _SupplierHomePageState();
}

class _SupplierHomePageState extends State<SupplierHomePage> {
  int navIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),

      body: Padding(
        padding: const EdgeInsets.fromLTRB(15, 60, 15, 20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildCard(
                id: "8",
                name: "Rami Rimawi",
                products: "5",
                productsList: demoProducts,
              ),
              _buildCard(
                id: "22",
                name: "Nizar Ahamd",
                products: "13",
                productsList: demoProducts,
              ),
              _buildCard(
                id: "63",
                name: "Akef Al Asmar",
                products: "9",
                productsList: demoProducts,
              ),
              _buildCard(
                id: "5",
                name: "Eyas Barghouthi",
                products: "11",
                productsList: demoProducts,
              ),
            ],
          ),
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

  /// -----------------------------------------------------------------
  /// كارت واحد يمثل Order واحد
  /// -----------------------------------------------------------------
  Widget _buildCard({
    required String id,
    required String name,
    required String products,
    required List<Map<String, dynamic>> productsList,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderDetailsPage(
              customerName: name,
              products: productsList,
            ),
          ),
        );
      },

      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D2D),
          borderRadius: BorderRadius.circular(16),
        ),

        child: Row(
          children: [
            // ID
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("ID #", style: TextStyle(color: Color(0xFFF9D949))),
                Text(id,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
              ],
            ),

            const SizedBox(width: 20),

            // Customer name
            Expanded(
              child: Column(
                children: [
                  const Text("Customer Name",
                      style: TextStyle(color: Color(0xFFF9D949))),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            ),

            // Product count box
            Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFFF9D949), width: 1),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(products,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  const Text("Product",
                      style:
                          TextStyle(color: Color(0xFFF9D949), fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


/// -------------------------------------------------------------------------
/// داتا مؤقتة (Demo) لصفحة Details
/// -------------------------------------------------------------------------
List<Map<String, dynamic>> demoProducts = [
  {"name": "Hand Shower", "brand": "GROHE", "quantity": 1},
  {"name": "Freestanding Bathtub", "brand": "Royal", "quantity": 1},
  {"name": "Wall-Hung Toilet", "brand": "GROHE", "quantity": 1},
  {"name": "Kitchen Sink", "brand": "Royal", "quantity": 1},
  {"name": "Towel Ring", "brand": "Royal", "quantity": 1},
];
