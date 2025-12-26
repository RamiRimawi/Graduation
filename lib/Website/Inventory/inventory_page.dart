import 'package:flutter/material.dart';
import '../sidebar.dart';
import 'Inventory_add_product_popup.dart';
import 'Inventory_add_pop.dart';
import 'Inventory_product_details_popup.dart';
import '../../supabase_config.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  int selectedTab = 0; // 0: Total, 1: Inventory #1, 2: Inventory #2
  bool showAddProductPopup = false;
  bool showAddInventoryPopup = false;
  int? selectedProductIndex;

  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> allProducts = [];
  List<Map<String, dynamic>> inventories = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      // Load inventories
      final inventoriesResponse = await supabase
          .from('inventory')
          .select('inventory_id, inventory_name')
          .order('inventory_id');

      inventories = List<Map<String, dynamic>>.from(inventoriesResponse);

      // Load all products
      final productsResponse = await supabase
          .from('product')
          .select('''
            product_id,
            name,
            brand:brand_id(brand_id, name),
            product_category:category_id(product_category_id, name),
            selling_price,
            wholesale_price,
            minimum_profit_percent,
            total_quantity
          ''')
          .eq('is_active', true)
          .order('product_id');

      allProducts = List<Map<String, dynamic>>.from(productsResponse);

      // Load products with batch quantities per inventory
      await _loadProductsByInventory();

      if (!mounted) return;
      setState(() => isLoading = false);
    } catch (e) {
      print('Error loading data: $e');
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadProductsByInventory() async {
    if (selectedTab == 0) {
      // Total - show ALL products with total_quantity from product table
      setState(() {
        products = allProducts;
      });
    } else {
      // Specific inventory - map tab index to inventory from list
      // selectedTab 1 -> first inventory, 2 -> second inventory, etc.
      final inventoryIndex = selectedTab - 1;

      if (inventoryIndex < 0 || inventoryIndex >= inventories.length) {
        print('Invalid inventory tab index');
        setState(() {
          products = [];
        });
        return;
      }

      final inventoryId = inventories[inventoryIndex]['inventory_id'] as int;

      try {
        final batchResponse = await supabase
            .from('batch')
            .select('''
              product_id,
              quantity,
              inventory_id
            ''')
            .eq('inventory_id', inventoryId);

        final batches = List<Map<String, dynamic>>.from(batchResponse);

        // Group batches by product_id and sum quantities
        Map<int, int> productQuantities = {};
        for (var batch in batches) {
          final productId = batch['product_id'] as int;
          final quantity = batch['quantity'] as int? ?? 0;
          productQuantities[productId] =
              (productQuantities[productId] ?? 0) + quantity;
        }

        // Show only products that exist in this inventory (quantity > 0)
        setState(() {
          products = allProducts
              .where(
                (product) =>
                    productQuantities.containsKey(product['product_id']),
              )
              .map((product) {
                final productId = product['product_id'] as int;
                final qty = productQuantities[productId] ?? 0;
                return {...product, 'inventory_quantity': qty};
              })
              .toList();
        });
      } catch (e) {
        print('Error loading inventory products: $e');
        setState(() {
          products = [];
        });
      }
    }
  }

  void _filterProducts(String query) {
    setState(() {
      searchQuery = query;
    });
  }

  List<Map<String, dynamic>> get filteredProducts {
    if (searchQuery.isEmpty) return products;

    return products.where((product) {
      final name = (product['name'] ?? '').toString().toLowerCase();
      final brand = ((product['brand'] as Map?)?['name'] ?? '')
          .toString()
          .toLowerCase();
      final query = searchQuery.toLowerCase();
      return name.startsWith(query) || brand.startsWith(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Row(
            children: [
              const Sidebar(activeIndex: 2),
              Expanded(
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 35,
                      vertical: 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🔹 Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Inventory',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            Row(
                              children: [
                                _AddProductButton(
                                  onPressed: () {
                                    setState(() {
                                      showAddProductPopup = true;
                                    });
                                  },
                                ),
                                const SizedBox(width: 12),
                                _AddInventoryButton(
                                  onPressed: () {
                                    setState(() {
                                      showAddInventoryPopup = true;
                                    });
                                  },
                                ),
                                const SizedBox(width: 12),
                                const Icon(
                                  Icons.notifications_none_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // 🔹 Inventory Tabs
                        _InventoryTabs(
                          selectedTab: selectedTab,
                          inventories: inventories,
                          onTabChanged: (index) {
                            selectedTab = index;
                            _loadProductsByInventory();
                          },
                        ),
                        const SizedBox(height: 20),

                        // 🔹 Search & Filter
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            SizedBox(
                              width: 230,
                              child: _SearchField(
                                hint: 'Product Name',
                                onChanged: _filterProducts,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // 🔹 Table Header
                        _TableHeader(),
                        const SizedBox(height: 6),

                        // 🔹 Table Rows
                        Expanded(
                          child: isLoading
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF50B2E7),
                                  ),
                                )
                              : filteredProducts.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No products found',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: filteredProducts.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (context, i) {
                                    final p = filteredProducts[i];
                                    final bg = i.isEven
                                        ? const Color(0xFF2D2D2D)
                                        : const Color(0xFF262626);
                                    return Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            selectedProductIndex = i;
                                          });
                                        },
                                        borderRadius: BorderRadius.circular(14),
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          decoration: BoxDecoration(
                                            color: bg,
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 14,
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                flex: 2,
                                                child: Center(
                                                  child: Text(
                                                    p['product_id'].toString(),
                                                    style: _cellStyle(),
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                flex: 4,
                                                child: Center(
                                                  child: Text(
                                                    p['name'] ?? '',
                                                    style: _cellStyle(),
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                flex: 3,
                                                child: Center(
                                                  child: Text(
                                                    (p['brand'] as Map?)?['name']
                                                            ?.toString() ??
                                                        '',
                                                    style: _cellStyle(),
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                flex: 3,
                                                child: Center(
                                                  child: Text(
                                                    (p['product_category']
                                                                as Map?)?['name']
                                                            ?.toString() ??
                                                        '',
                                                    style: _cellStyle(),
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                flex: 3,
                                                child: Center(
                                                  child: Text(
                                                    '\$${(p['selling_price'] ?? 0).toStringAsFixed(0)}',
                                                    style: _cellStyle(),
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                flex: 2,
                                                child: Center(
                                                  child: Text(
                                                    selectedTab == 0
                                                        ? (p['total_quantity'] ??
                                                                  0)
                                                              .toString()
                                                        : (p['inventory_quantity'] ??
                                                                  0)
                                                              .toString(),
                                                    style: _cellStyle()
                                                        .copyWith(
                                                          color: const Color(
                                                            0xFFB7A447,
                                                          ),
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
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
          // Add Product Popup
          if (showAddProductPopup)
            AddProductPopup(
              selectedInventoryId: selectedTab == 0
                  ? null
                  : (selectedTab - 1 >= 0 &&
                        selectedTab - 1 < inventories.length)
                  ? inventories[selectedTab - 1]['inventory_id'] as int
                  : null,
              onClose: () {
                setState(() {
                  showAddProductPopup = false;
                });
              },
              onProductAdded: () {
                _loadData(); // Reload data to show new product
              },
            ),
          // Add Inventory Popup
          if (showAddInventoryPopup)
            AddInventoryPopup(
              onClose: () {
                setState(() {
                  showAddInventoryPopup = false;
                });
              },
              onInventoryAdded: () {
                _loadData(); // Reload data to show new inventory in tabs
              },
            ),
          // Product Details Popup
          if (selectedProductIndex != null) ...[
            Builder(
              builder: (context) {
                final product = filteredProducts[selectedProductIndex!];
                final invFilter = selectedTab == 0
                    ? null
                    : (inventories.isNotEmpty &&
                          selectedTab - 1 >= 0 &&
                          selectedTab - 1 < inventories.length)
                    ? inventories[selectedTab - 1]['inventory_id'] as int
                    : null;
                return ProductDetailsPopup(
                  productId: product['product_id'].toString(),
                  productName: product['name'] ?? '',
                  brandName:
                      (product['brand'] as Map?)?['name']?.toString() ?? '',
                  category:
                      (product['product_category'] as Map?)?['name']
                          ?.toString() ??
                      '',
                  wholesalePrice:
                      '\$${(product['wholesale_price'] ?? 0).toStringAsFixed(0)}',
                  sellingPrice:
                      '\$${(product['selling_price'] ?? 0).toStringAsFixed(0)}',
                  minProfit:
                      '${(product['minimum_profit_percent'] ?? 0).toStringAsFixed(0)}%',
                  brandId: (product['brand'] as Map?)?['brand_id'] as int?,
                  categoryId:
                      (product['product_category']
                              as Map?)?['product_category_id']
                          as int?,
                  inventoryIdFilter: invFilter,
                  onClose: () {
                    setState(() {
                      selectedProductIndex = null;
                    });
                  },
                  onDataChanged: () {
                    _loadData(); // Reload data after edit
                  },
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  TextStyle _cellStyle() => const TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.w600,
    fontSize: 17,
  );
}

// 🔹 Table Header
class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: const [
            _HeaderCell(text: 'Product ID #', flex: 2),
            _HeaderCell(text: 'Product Name', flex: 4),
            _HeaderCell(text: 'Brand', flex: 3),
            _HeaderCell(text: 'Category', flex: 3),
            _HeaderCell(text: 'Selling Price', flex: 3),
            _HeaderCell(text: 'Quantity', flex: 2, color: Color(0xFFB7A447)),
          ],
        ),
        const SizedBox(height: 8),
        Container(height: 1, color: Colors.white24),
      ],
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final int flex;
  final Color? color;
  const _HeaderCell({required this.text, this.flex = 1, this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: color ?? Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// 🔹 Add Product Button
class _AddProductButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _AddProductButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const ShapeDecoration(
        shape: StadiumBorder(),
        color: Color(0xFFFFE14D),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onPressed,
          customBorder: const StadiumBorder(),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.add_box_rounded, color: Colors.black87),
                SizedBox(width: 8),
                Text(
                  'Add Product',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 🔹 Add Inventory Button
class _AddInventoryButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _AddInventoryButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const ShapeDecoration(
        shape: StadiumBorder(),
        color: Color(0xFF50B2E7),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onPressed,
          customBorder: const StadiumBorder(),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.home_rounded, color: Colors.black87),
                SizedBox(width: 8),
                Text(
                  'Add Inventory',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 🔹 Inventory Tabs
class _InventoryTabs extends StatelessWidget {
  final int selectedTab;
  final List<Map<String, dynamic>> inventories;
  final ValueChanged<int> onTabChanged;
  const _InventoryTabs({
    required this.selectedTab,
    required this.inventories,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Total Tab
        _TabButton(
          label: 'Total',
          isSelected: selectedTab == 0,
          onTap: () => onTabChanged(0),
        ),
        const SizedBox(width: 12),

        // Dynamic Inventory Tabs
        ...inventories.asMap().entries.map((entry) {
          final index = entry.key + 1; // +1 because 0 is Total
          final inventory = entry.value;
          final inventoryId = inventory['inventory_id'];
          final location =
              inventory['inventory_name'] ?? 'Inventory #$inventoryId';

          return Row(
            children: [
              _TabButton(
                label: location,
                isSelected: selectedTab == index,
                onTap: () => onTabChanged(index),
              ),
              const SizedBox(width: 12),
            ],
          );
        }).toList(),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? const Color(0xFFFFFFFF) // #FFFFFF - White for active
                        : const Color(
                            0xFFFFFFFF,
                          ).withOpacity(0.6), // White with opacity for inactive
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
              ),
              if (isSelected)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Container(
                    height: 2,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFF50B2E7), // #50B2E7 - Blue underline
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// 🔹 Search Field
class _SearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String>? onChanged;
  const _SearchField({required this.hint, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.inventory_rounded, size: 18),
        filled: true,
        fillColor: const Color(0xFF2D2D2D),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: Color(0xFFB7A447), width: 1.2),
        ),
      ),
    );
  }
}
