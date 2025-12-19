import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../supabase_config.dart';
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
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  bool _isLoading = true;
  int _currentNavIndex = 0;
  final Set<int> _cartProductIds = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearch);
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleSearch);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _products = [];
      _filteredProducts = [];
    });

    try {
      final response = await supabase
          .from('product')
          .select('''
            product_id,
            name,
            product_image,
            brand:brand_id(name),
            category:category_id(name),
            selling_price,
            total_quantity
          ''')
          .eq('is_active', true)
          .order('product_id');

      final fetched = List<Map<String, dynamic>>.from(response);
      final normalized = fetched
          .map((product) => {
                'id': product['product_id'],
                'name': product['name'] ?? '',
                'brand': (product['brand'] as Map?)?['name'] ?? 'Unknown brand',
                'category': (product['category'] as Map?)?['name'] ?? 'Unknown category',
                'selling_price': product['selling_price'],
                'image': product['product_image'] as String?,
                'inventory': product['total_quantity'] ?? 0,
              })
          .toList();

      if (!mounted) return;

      setState(() {
        _products = normalized;
        _filteredProducts = _applySearch(_searchController.text, normalized);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading products: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleSearch() {
    setState(() {
      _filteredProducts = _applySearch(_searchController.text, _products);
    });
  }

  List<Map<String, dynamic>> _applySearch(
    String query,
    List<Map<String, dynamic>> source,
  ) {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return List<Map<String, dynamic>>.from(source);

    return source.where((product) {
      final name = (product['name'] ?? '').toString().toLowerCase();
      final brand = (product['brand'] ?? '').toString().toLowerCase();
      return name.contains(trimmed) || brand.contains(trimmed);
    }).toList();
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
    final List<Map<String, dynamic>> visibleProducts = _filteredProducts;

    return Scaffold(
      backgroundColor: const Color(0xFF202020),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFB7A447),
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: visibleProducts.isEmpty
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
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            itemCount: visibleProducts.length,
                            itemBuilder: (context, index) {
                              final product = visibleProducts[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: _buildCard(product),
                              );
                            },
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: _buildSearchField(),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentNavIndex,
        onTap: _onNavTap,
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.search, color: Color(0xFFB7A447), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Search by product or brand',
                hintStyle: TextStyle(color: Colors.white54, fontSize: 14),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> product) {
    final imageUrl = (product['image'] as String?)?.trim();
    final brandName = product['brand'] as String? ?? 'Unknown brand';
    final productId = product['id'] as int?;
    final alreadyInCart = productId != null && _cartProductIds.contains(productId);

    return GestureDetector(
      onTap: () => _showProductSheet(product),
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
            horizontal: 12,
            vertical: 14,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProductImage(imageUrl),
              const SizedBox(height: 12),
              Text(
                'Name : ${product['name'] ?? ''}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Brand : $brandName',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              _buildAddToCartButton(product, disabled: alreadyInCart),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage(String? imageUrl) {
    final placeholder = Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF262626),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(
        Icons.image_outlined,
        color: Color(0xFFB7A447),
        size: 48,
      ),
    );

    if (imageUrl == null || imageUrl.isEmpty) {
      return placeholder;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 150,
        width: double.infinity,
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => placeholder,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              color: const Color(0xFF262626),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFB7A447),
                  strokeWidth: 2,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAddToCartButton(Map<String, dynamic> product, {bool disabled = false}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: disabled ? Colors.grey.shade600 : const Color(0xFFB7A447),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
        onPressed: disabled ? null : () async {
          await _addToCart(product);
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              disabled ? 'Added' : 'Add to cart',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              disabled ? Icons.check_circle : Icons.shopping_cart_checkout_outlined,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addToCart(Map<String, dynamic> product) async {
    final productId = product['id'] as int?;
    if (productId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing cart items from local storage
      final cartJson = prefs.getString('cart_items') ?? '{}';
      final cartMap = jsonDecode(cartJson) as Map<String, dynamic>;
      
      debugPrint('Current cart items: $cartMap');
      
      // Add or update product in cart
      cartMap[productId.toString()] = {
        'product_id': product['id'],
        'name': product['name'],
        'brand': product['brand'],
        'price': product['selling_price'],
        'qty': (cartMap[productId.toString()]?['qty'] as int? ?? 0) + 1,
      };
      
      debugPrint('Updated cart items: $cartMap');
      
      // Save back to local storage
      await prefs.setString('cart_items', jsonEncode(cartMap));
      
      debugPrint('Saved cart items to local storage');
      
      setState(() {
        _cartProductIds.add(productId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Added to cart'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error adding to cart: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding to cart: $e')),
        );
      }
    }
  }

  void _showProductSheet(Map<String, dynamic> product) {
    final imageUrl = (product['image'] as String?)?.trim();
    final brandName = product['brand'] as String? ?? 'Unknown brand';
    final categoryName = product['category'] as String? ?? 'Unknown category';
    final sellingPrice = product['selling_price'];
    final productId = product['id'] as int?;
    final alreadyInCart = productId != null && _cartProductIds.contains(productId);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2D2D2D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: _buildProductImage(imageUrl)),
              const SizedBox(height: 16),
              _infoRow('Name', product['name'] ?? ''),
              const SizedBox(height: 8),
              _infoRow('Category', categoryName),
              const SizedBox(height: 8),
              _infoRow('Brand', brandName),
              const SizedBox(height: 8),
              _infoRow('Selling Price', sellingPrice != null ? sellingPrice.toString() : '—'),
              const SizedBox(height: 16),
              _buildAddToCartButton(product, disabled: alreadyInCart),
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}