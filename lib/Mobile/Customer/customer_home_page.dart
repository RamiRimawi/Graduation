import 'package:flutter/material.dart';
import '../bottom_navbar.dart';
import '../account_page.dart';
import 'customer_cart_page.dart';
import 'customer_archive_page.dart';

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({Key? key}) : super(key: key);

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  final List<Map<String, dynamic>> products = List.generate(
    8,
    (i) => {
      'id': i + 1,
      'name': 'Hand Shower',
      'brand': 'GROHE',
      'inventory': (i % 3) + 1,
    },
  );

  int _currentNavIndex = 0;

  void _onNavTap(int i) {
    setState(() => _currentNavIndex = i);

    // Navigate similarly to supplier_home_page.dart behavior:
    if (i == 0) {
      // Home - replace with this page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CustomerHomePage()),
      );
    } else if (i == 1) {
      // Cart
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CustomerCartPage()),
      );
    } else if (i == 2) {
      // Archive
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CustomerArchivePage()),
      );
    } else if (i == 3) {
      // Account (shared)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AccountPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF202020),
      body: SafeArea(
        child: products.isEmpty
            ? const Center(
                child: Text(
                  'No products available',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildCard(product),
                  );
                },
              ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentNavIndex,
        onTap: _onNavTap,
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CustomerCartPage(),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D2D),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 1,
              spreadRadius: 1,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Text(
                    'ID #',
                    style: TextStyle(
                      color: Color(0xFFB7A447),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 34),
                  Text(
                    'Product Name',
                    style: TextStyle(
                      color: Color(0xFFB7A447),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 2),

              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '${product['id']}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 28),

                  Expanded(
                    child: Text(
                      '${product['name']} — ${product['brand']}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const SizedBox(width: 16),

                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: const Color(0xFF262626),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${product['inventory']}',
                          style: const TextStyle(
                            color: Color(0xFFFFEFFF),
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'inventory #',
                          style: TextStyle(
                            color: Color(0xFFB7A447),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
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
      ),
    );
  }
}