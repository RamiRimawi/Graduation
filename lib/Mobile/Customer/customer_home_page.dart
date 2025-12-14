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
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, String>> products = List.generate(
    8,
    (i) => {
      'name': 'Hand Shower',
      'brand': 'GROHE',
      'image':
          'https://via.placeholder.com/200.png?text=Product', // simple placeholder
    },
  );

  int _currentNavIndex = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
    final bg = const Color(0xFF1A1A1A);
    final cardBg = const Color(0xFF2D2D2D);
    final muted = Colors.white70;
    final accent = const Color(0xFFF9D949);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // small top spacing (matches screenshot)
                const SizedBox(height: 12),

                // grid of products
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: GridView.builder(
                      padding: const EdgeInsets.only(bottom: 120, top: 4),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.68,
                          ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final p = products[index];
                        return _productCard(p, cardBg, accent, muted);
                      },
                    ),
                  ),
                ),
              ],
            ),

            // bottom search overlay (floating above grid, above bottom nav)
            Positioned(
              left: 16,
              right: 16,
              bottom: 10, // adjust this value if you want the bar lower/higher
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Entre Product Name',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      Container(
                        width: 44,
                        height: 44,
                        margin: const EdgeInsets.only(left: 8),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.inventory_2_outlined,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            // optional: navigate to cart/archive
                            // Example: go to cart
                            _onNavTap(1);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // use your existing BottomNavBar (matches earlier usage in repo)
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentNavIndex,
        onTap: _onNavTap,
      ),
    );
  }

  Widget _productCard(
    Map<String, String> p,
    Color cardBg,
    Color accent,
    Color muted,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // image area
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                p['image']!,
                fit: BoxFit.cover,
                errorBuilder: (context, _, __) => Container(
                  color: Colors.grey.shade800,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.image,
                    color: Colors.white70,
                    size: 40,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // name & brand (two lines)
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Name : ${p['name']}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Brand : ${p['brand']}',
              style: TextStyle(
                color: muted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const Spacer(),

          // Add to cart button row
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'Add to cart',
                        style: TextStyle(
                          color: Color(0xFF202020),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.shopping_cart_outlined,
                        color: Color(0xFF202020),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}