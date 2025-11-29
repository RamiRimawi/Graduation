import 'package:flutter/material.dart';
import 'sidebar.dart';
import 'add_prodect_pop.dart';
import 'add_inventory_pop.dart';
import 'product_details_popup.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  int? selectedRow;
  int selectedTab = 0; // 0: Total, 1: Inventory #1, 2: Inventory #2
  bool showAddProductPopup = false;
  bool showAddInventoryPopup = false;
  int? selectedProductIndex;

  final products = const [
    ('1', 'Hand Shower', 'GROHE', 'shower', '26\$', '26'),
    ('2', 'Wall-Hung Toilet', 'Royal', 'Toilets', '150\$', '30'),
    ('3', 'Kitchen Sink', 'GROHE', 'Extensions', '200\$', '30'),
    ('4', 'Towel Ring', 'Royal', 'Extensions', '25\$', '29'),
    ('5', 'Freestanding Bathtub', 'Royal', 'Extensions', '10\$', '31'),
    ('6', 'Angle Valve', 'GROHE', 'Toilets', '30\$', '28'),
    ('7', 'Floor Drain', 'GROHE', 'Toilets', '43\$', '20'),
  ];

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
                          onTabChanged: (index) {
                            setState(() {
                              selectedTab = index;
                            });
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
                                onChanged: (v) {},
                              ),
                            ),
                            const SizedBox(width: 10),
                            _RoundIconButton(
                              icon: Icons.filter_alt_rounded,
                              onTap: () {},
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // 🔹 Table Header
                        _TableHeader(),
                        const SizedBox(height: 6),

                        // 🔹 Table Rows
                        Expanded(
                          child: ListView.separated(
                            itemCount: products.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, i) {
                              final p = products[i];
                              final bg = i.isEven
                                  ? const Color(0xFF2D2D2D)
                                  : const Color(0xFF262626);
                              return MouseRegion(
                                cursor: SystemMouseCursors.click,
                                onEnter: (_) => setState(() => selectedRow = i),
                                onExit: (_) =>
                                    setState(() => selectedRow = null),
                                child: Material(
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
                                        borderRadius: BorderRadius.circular(14),
                                        border: selectedRow == i
                                            ? Border.all(
                                                color: const Color(0xFF50B2E7),
                                                width: 2,
                                              )
                                            : null,
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
                                                p.$1,
                                                style: _cellStyle(),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 4,
                                            child: Center(
                                              child: Text(
                                                p.$2,
                                                style: _cellStyle(),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 3,
                                            child: Center(
                                              child: Text(
                                                p.$3,
                                                style: _cellStyle(),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 3,
                                            child: Center(
                                              child: Text(
                                                p.$4,
                                                style: _cellStyle(),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 3,
                                            child: Center(
                                              child: Text(
                                                p.$5,
                                                style: _cellStyle(),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Center(
                                              child: Text(
                                                '${p.$6} cm',
                                                style: _cellStyle().copyWith(
                                                  color: const Color(
                                                    0xFFB7A447,
                                                  ),
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
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
              onClose: () {
                setState(() {
                  showAddProductPopup = false;
                });
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
            ),
          // Product Details Popup
          if (selectedProductIndex != null) ...[
            Builder(
              builder: (context) {
                final product = products[selectedProductIndex!];
                return ProductDetailsPopup(
                  productId: product.$1,
                  productName: product.$2,
                  brandName: product.$3,
                  category: product.$4,
                  wholesalePrice: '30\$',
                  sellingPrice: product.$5,
                  minProfit: '20%',
                  onClose: () {
                    setState(() {
                      selectedProductIndex = null;
                    });
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
  final ValueChanged<int> onTabChanged;
  const _InventoryTabs({required this.selectedTab, required this.onTabChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _TabButton(
          label: 'Total',
          isSelected: selectedTab == 0,
          onTap: () => onTabChanged(0),
        ),
        const SizedBox(width: 12),
        _TabButton(
          label: 'Inventory #1',
          isSelected: selectedTab == 1,
          onTap: () => onTabChanged(1),
        ),
        const SizedBox(width: 12),
        _TabButton(
          label: 'Inventory #2',
          isSelected: selectedTab == 2,
          onTap: () => onTabChanged(2),
        ),
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

// 🔹 Filter Button
class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF2D2D2D), width: 3),
      ),
      child: Material(
        color: const Color(0xFF2D2D2D),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 20, color: const Color(0xFFB7A447)),
          ),
        ),
      ),
    );
  }
}
