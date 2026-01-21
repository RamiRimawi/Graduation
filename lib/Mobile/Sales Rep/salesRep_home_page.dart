import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../supabase_config.dart';
import '../bottom_navbar.dart';
import '../account_page.dart';
import 'salesRep_cart_page.dart';
import 'salesRep_archive_page.dart';
import 'salesRep_customers_page.dart';

class SalesRepHomePage extends StatefulWidget {
  const SalesRepHomePage({super.key});

  @override
  State<SalesRepHomePage> createState() => _SalesRepHomePageState();
}

class _SalesRepHomePageState extends State<SalesRepHomePage> {
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
          .map(
            (product) => {
              'id': product['product_id'],
              'name': product['name'] ?? '',
              'brand': (product['brand'] as Map?)?['name'] ?? 'Unknown brand',
              'category':
                  (product['category'] as Map?)?['name'] ?? 'Unknown category',
              'selling_price': product['selling_price'],
              'image': product['product_image'] as String?,
              'inventory': product['total_quantity'] ?? 0,
            },
          )
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
        MaterialPageRoute(builder: (_) => const SalesRepHomePage()),
      );
    } else if (i == 1) {
      // Cart
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SalesRepCartPage()),
      );
    } else if (i == 2) {
      // Archive
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SalesRepArchivePage()),
      );
    } else if (i == 3) {
      // Customers
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SalesRepCustomersPage()),
      );
    } else if (i == 4) {
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
                child: CircularProgressIndicator(color: Color(0xFFB7A447)),
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
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              // Calculate number of columns based on width
                              int crossAxisCount;
                              double childAspectRatio;

                              if (constraints.maxWidth >= 650) {
                                crossAxisCount = 3;
                                childAspectRatio = 0.65;
                              } else if (constraints.maxWidth >= 450) {
                                crossAxisCount = 2;
                                childAspectRatio = 0.60;
                              } else if (constraints.maxWidth >= 350) {
                                crossAxisCount = 2;
                                childAspectRatio = 0.58;
                              } else {
                                crossAxisCount = 1;
                                childAspectRatio = 0.75;
                              }

                              return GridView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  16,
                                  16,
                                  8,
                                ),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossAxisCount,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 14,
                                      childAspectRatio: childAspectRatio,
                                    ),
                                itemCount: visibleProducts.length,
                                itemBuilder: (context, index) {
                                  final product = visibleProducts[index];
                                  return _buildCard(product);
                                },
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
    final alreadyInCart =
        productId != null && _cartProductIds.contains(productId);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Scale down elements on very small screens
        final screenWidth = MediaQuery.of(context).size.width;
        final isVerySmall = screenWidth < 350;
        final isSingleColumn = screenWidth < 350;
        final cardPadding = isVerySmall ? 8.0 : 10.0;
        final imageRadius = isVerySmall ? 10.0 : 14.0;
        final imageAspectRatio = isSingleColumn ? 1.2 : 1.0;
        final nameFontSize = isVerySmall ? 11.0 : 13.0;
        final brandFontSize = isVerySmall ? 10.0 : 12.0;
        final buttonPadding = isVerySmall ? 4.0 : 6.0;
        final buttonFontSize = isVerySmall ? 11.0 : 13.0;
        final spacing = isVerySmall ? 4.0 : 6.0;

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
              padding: EdgeInsets.all(cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: _buildProductImage(
                      imageUrl,
                      imageRadius,
                      imageAspectRatio,
                    ),
                  ),
                  SizedBox(height: spacing),
                  Text(
                    product['name'] ?? '',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: nameFontSize,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    brandName,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: brandFontSize,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: spacing),
                  _buildAddToCartButton(
                    product,
                    disabled: alreadyInCart,
                    buttonPadding: buttonPadding,
                    buttonFontSize: buttonFontSize,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductImage(
    String? imageUrl, [
    double radius = 14.0,
    double aspectRatio = 1.0,
  ]) {
    final placeholder = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF262626),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Icon(
          Icons.image_outlined,
          color: const Color(0xFFB7A447),
          size: radius * 2.8,
        ),
      ),
    );

    if (imageUrl == null || imageUrl.isEmpty) {
      return placeholder;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: AspectRatio(
        aspectRatio: aspectRatio,
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

  Widget _buildAddToCartButton(
    Map<String, dynamic> product, {
    bool disabled = false,
    double buttonPadding = 6.0,
    double buttonFontSize = 13.0,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: disabled
              ? Colors.grey.shade600
              : const Color(0xFFB7A447),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: buttonPadding),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        onPressed: disabled
            ? null
            : () async {
                await _addToCart(product);
              },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              disabled ? 'Added' : 'Add',
              style: TextStyle(
                fontSize: buttonFontSize,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              disabled
                  ? Icons.check_circle
                  : Icons.shopping_cart_checkout_outlined,
              size: buttonFontSize + 3,
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding to cart: $e')));
      }
    }
  }

  void _showProductSheet(Map<String, dynamic> product) {
    final imageUrl = (product['image'] as String?)?.trim();
    final brandName = product['brand'] as String? ?? 'Unknown brand';
    final categoryName = product['category'] as String? ?? 'Unknown category';
    final sellingPrice = product['selling_price'];
    final productId = product['id'] as int?;
    final alreadyInCart =
        productId != null && _cartProductIds.contains(productId);

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Dialog(
            backgroundColor: const Color(0xFF2D2D2D),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 200,
                      child: Center(child: _buildProductImage(imageUrl)),
                    ),
                    const SizedBox(height: 16),
                    _infoRow('Name', product['name'] ?? ''),
                    const SizedBox(height: 8),
                    _infoRow('Category', categoryName),
                    const SizedBox(height: 8),
                    _infoRow('Brand', brandName),
                    const SizedBox(height: 8),
                    _infoRow(
                      'Selling Price',
                      sellingPrice != null ? sellingPrice.toString() : '—',
                    ),
                    const SizedBox(height: 16),
                    _buildAddToCartButton(product, disabled: alreadyInCart),
                  ],
                ),
              ),
            ),
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
