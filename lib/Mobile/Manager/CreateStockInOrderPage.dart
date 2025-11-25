import 'package:flutter/material.dart';
import 'Bar.dart';

// ======================= MODEL =======================
class Product {
  final String name;
  final String brand;
  final int availableQty;
  final String unit;

  Product(this.name, this.brand, this.availableQty, this.unit);
}

// ======================= PAGE =======================
class CreateStockInOrderPage extends StatefulWidget {
  const CreateStockInOrderPage({super.key});

  @override
  State<CreateStockInOrderPage> createState() =>
      _CreateStockInOrderPageState();
}

class _CreateStockInOrderPageState extends State<CreateStockInOrderPage> {
  String? selectedSupplier;
  String dialogSearch = "";

  // المنتجات المختارة في الصفحة الرئيسية
  List<Map<String, dynamic>> selectedProducts = [
    {"name": "Hand Shower", "brand": "GROHE", "qty": 1, "unit": "cm"},
    {"name": "Freestanding Bathtub", "brand": "Royal", "qty": 1, "unit": "cm"},
    {"name": "Wall-Hung Toilet", "brand": "GROHE", "qty": 1, "unit": "cm"},
    {"name": "Kitchen Sink", "brand": "Royal", "qty": 1, "unit": "cm"},
  ];

  // جميع المنتجات الخاصة بالمورد
  final List<Product> supplierProducts = [
    Product("Hand Shower", "GROHE", 33, "cm"),
    Product("Freestanding Bathtub", "Royal", 12, "pcs"),
    Product("Wall-Hung Toilet", "GROHE", 8, "cm"),
    Product("Kitchen Sink", "Royal", 55, "cm"),
    Product("Towel Ring", "Royal", 27, "cm"),
  ];

  List<Product> selectedInDialog = [];

  // فتح البوب أب الخاص بإضافة المنتجات
  void _openAddProductsDialog() {
    selectedInDialog = [];
    dialogSearch = "";

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final filtered = supplierProducts.where((p) {
              return p.name.toLowerCase().contains(dialogSearch.toLowerCase());
            }).toList();

            return AlertDialog(
              backgroundColor: AppColors.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                "Select Products",
                style: TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w900,
                    fontSize: 18),
              ),

              content: SizedBox(
                width: double.maxFinite,
                height: 420,
                child: Column(
                  children: [
                    // ===== SEARCH FIELD =====
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.cardAlt,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextField(
                        style: const TextStyle(color: Colors.white),
                        onChanged: (v) {
                          setStateDialog(() => dialogSearch = v);
                        },
                        decoration: const InputDecoration(
                          hintText: "Search product...",
                          hintStyle: TextStyle(color: Colors.white54),
                          border: InputBorder.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ===== PRODUCT LIST =====
                    Expanded(
                      child: ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final p = filtered[i];
                          final isSelected = selectedInDialog.contains(p);

                          return GestureDetector(
                            onTap: () {
                              setStateDialog(() {
                                isSelected
                                    ? selectedInDialog.remove(p)
                                    : selectedInDialog.add(p);
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.cardAlt,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.gold
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          p.brand,
                                          style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),

                                  Text("${p.availableQty}",
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800)),
                                  const SizedBox(width: 6),
                                  Text(p.unit,
                                      style: const TextStyle(
                                          color: Colors.white70)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // ========== ADD BUTTON ==========
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      for (var p in selectedInDialog) {
                        selectedProducts.insert(0, {
                          "name": p.name,
                          "brand": p.brand,
                          "qty": 1,
                          "unit": p.unit,
                        });
                      }
                    });

                    Navigator.pop(context);
                  },
                  child: const Text(
                    "ADD",
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _removeProduct(int index) {
    setState(() => selectedProducts.removeAt(index));
  }

  // ======================= UI =======================
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
              // ===== TITLE =====
              const Text(
                "Create Stock-in Order",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 20),

              // ===== SUPPLIER SELECT =====
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.gold, width: 1.4),
                  borderRadius: BorderRadius.circular(14),
                  color: AppColors.card,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    dropdownColor: AppColors.card,
                    value: selectedSupplier,
                    hint: const Text(
                      "Select Supplier",
                      style: TextStyle(color: Colors.white54),
                    ),
                    icon: const Icon(Icons.arrow_drop_down,
                        color: AppColors.gold),
                    items: [
                      "Ahmad Nizar",
                      "Saed Rimawi",
                      "Akef Al Asmar"
                    ].map((s) {
                      return DropdownMenuItem(
                        value: s,
                        child: Text(
                          s,
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }).toList(),
                    onChanged: (v) {
                      setState(() => selectedSupplier = v);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ===== HEADER =====
              const Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text("Product Name",
                        style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text("Brand",
                        style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text("Quantity",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ],
              ),

              const SizedBox(height: 6),
              Container(height: 1, color: Colors.white24),
              const SizedBox(height: 12),

              // ===== PRODUCT LIST =====
              Expanded(
                child: ListView.builder(
                  itemCount: selectedProducts.length,
                  itemBuilder: (_, i) {
                    final p = selectedProducts[i];
                    final controller =
                        TextEditingController(text: p["qty"].toString());

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          // NAME
                          Expanded(
                            flex: 4,
                            child: Text(
                              p["name"],
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),

                          // BRAND
                          Expanded(
                            flex: 3,
                            child: Text(
                              p["brand"],
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),

                          // === FIXED & RESPONSIVE QUANTITY FIELD ===
                          Expanded(
                            flex: 3,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Row(
                                children: [
                                  // GOLD BOX
                                  Container(
                                    width: 50,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: AppColors.gold,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    alignment: Alignment.center,
                                    child: TextField(
                                      controller: controller,
                                      onChanged: (v) {
                                        if (v.isNotEmpty) {
                                          setState(() => p["qty"] =
                                              int.tryParse(v) ?? p["qty"]);
                                        }
                                      },
                                      textAlign: TextAlign.center,
                                      keyboardType: TextInputType.number,
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                      ),
                                      decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          isCollapsed: true,
                                          contentPadding: EdgeInsets.zero),
                                    ),
                                  ),

                                  const SizedBox(width: 6),

                                  Text(
                                    p["unit"],
                                    style: const TextStyle(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w600),
                                  ),

                                  const SizedBox(width: 8),

                                  // DELETE BUTTON
                                  GestureDetector(
                                    onTap: () => _removeProduct(i),
                                    child: const Icon(
                                      Icons.cancel_rounded,
                                      color: Colors.redAccent,
                                      size: 28,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 14),

              // ===== BOTTOM BUTTONS =====
              Row(
                children: [
                  // SEND ORDER
                  Expanded(
                    child: GestureDetector(
                      onTap: () {},
                      child: Container(
                        height: 55,
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          "Send Order   >",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // ADD (+)
                  GestureDetector(
                    onTap: selectedSupplier == null
                        ? null
                        : _openAddProductsDialog,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: selectedSupplier == null
                            ? Colors.grey
                            : AppColors.gold,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add,
                          color: Colors.black, size: 28),
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
