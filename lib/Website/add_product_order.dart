import 'package:flutter/material.dart';
import '../supabase_config.dart';

class AddProductPopup extends StatefulWidget {
  final VoidCallback onClose;
  final Function(List<Map<String, dynamic>>)? onDone;
  final List<Map<String, dynamic>> existingProducts;
  final List<Map<String, dynamic>>? availableProducts;
  const AddProductPopup({
    super.key, 
    required this.onClose, 
    this.onDone,
    this.existingProducts = const [],
    this.availableProducts,
  });

  @override
  State<AddProductPopup> createState() => _AddProductPopupState();
}

class _AddProductPopupState extends State<AddProductPopup> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  List<Map<String, dynamic>> _selectedProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchController.addListener(_filterProducts);
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      List<Map<String, dynamic>> allProductsFromDB;
      
      // إذا تم توفير availableProducts، استخدمها بدلاً من تحميل جميع المنتجات
      if (widget.availableProducts != null) {
        allProductsFromDB = widget.availableProducts!;
      } else {
        final response = await supabase
            .from('product')
            .select('''
              product_id,
              name,
              brand:brand(name),
              total_quantity,
              selling_price,
              wholesale_price,
              unit:unit(unit_name)
            ''')
            .eq('is_active', true)
            .order('name');
        
        allProductsFromDB = List<Map<String, dynamic>>.from(response);
      }
      
      // فلتر المنتجات: إظهار فقط المنتجات غير الموجودة في الجدول
      final availableProducts = allProductsFromDB.where((product) {
        return !widget.existingProducts.any((p) => p['product_id'] == product['product_id']);
      }).toList();
      
      setState(() {
        _allProducts = availableProducts;
        _filteredProducts = _allProducts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load products: $e')),
        );
      }
    }
  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = _allProducts;
      } else {
        _filteredProducts = _allProducts.where((p) {
          final name = (p['name'] ?? '').toString().toLowerCase();
          final brand = ((p['brand'] as Map?)?['name'] ?? '').toString().toLowerCase();
          return name.contains(query) || brand.contains(query);
        }).toList();
      }
    });
  }

  void _toggleProductSelection(Map<String, dynamic> product) {
    setState(() {
      final index = _selectedProducts.indexWhere(
        (p) => p['product_id'] == product['product_id']
      );
      if (index >= 0) {
        // المنتج موجود - زيادة الكمية تلقائياً
        _selectedProducts[index]['quantity'] = (_selectedProducts[index]['quantity'] ?? 0) + 1;
      } else {
        // منتج جديد - إضافة بكمية 1
        _selectedProducts.add({
          'product_id': product['product_id'],
          'name': product['name'],
          'brand': product['brand'],
          'total_quantity': product['total_quantity'],
          'selling_price': product['selling_price'],
          'wholesale_price': product['wholesale_price'],
          'unit': product['unit'],
          'quantity': 1,
        });
      }
    });
  }

  void _done() {
    if (widget.onDone != null) {
      widget.onDone!(_selectedProducts);
    }
    widget.onClose();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 310, vertical: 40),
      child: Material(
        borderRadius: BorderRadius.circular(20),
        color: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Scaffold(
            backgroundColor: const Color(0xFF2D2D2D),
            body: Container(
              width: 900,
              constraints: const BoxConstraints(maxHeight: 650),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Add Products to Order',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFFFE14D),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: widget.onClose,
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white24, height: 1),
                  // Search
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search Product...',
                        hintStyle: const TextStyle(color: Colors.white54),
                        prefixIcon: const Icon(Icons.search, color: Color(0xFFFFE14D)),
                        filled: true,
                        fillColor: const Color(0xFF3D3D3D),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  // Product List
                  Expanded(
                    flex: 2,
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFFFE14D),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _filteredProducts.length,
                            itemBuilder: (ctx, index) {
                              final product = _filteredProducts[index];
                              final isSelected = _selectedProducts.any(
                                (p) => p['product_id'] == product['product_id']
                              );
                              final totalQty = product['total_quantity'] ?? 0;
                              return Card(
                                color: isSelected ? const Color(0xFF4D4D2D) : const Color(0xFF3D3D3D),
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: Icon(
                                    isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                                    color: const Color(0xFFFFE14D),
                                  ),
                                  title: Text(
                                    product['name'] ?? '',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: Text(
                                    'Brand: ${(product['brand'] as Map?)?['name'] ?? 'N/A'}',
                                    style: const TextStyle(color: Colors.white70),
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4D4D4D),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Qty: $totalQty',
                                      style: const TextStyle(
                                        color: Color(0xFFFFE14D),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  onTap: () => _toggleProductSelection(product),
                                ),
                              );
                            },
                          ),
                  ),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 20),
                  // Done Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _selectedProducts.isEmpty ? null : _done,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFE14D),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, color: Colors.black87, size: 22),
                            SizedBox(width: 10),
                            Text(
                              'Done',
                              style: TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

}
