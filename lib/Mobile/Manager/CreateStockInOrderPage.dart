import 'package:flutter/material.dart';
import '../manager_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../supabase_config.dart';

// ======================= MODEL =======================
class Product {
  final int productId;
  final String name;
  final String brand;
  final int availableQty;
  final String unit;
  final double wholesalePrice;

  Product(
    this.productId,
    this.name,
    this.brand,
    this.availableQty,
    this.unit,
    this.wholesalePrice,
  );
}

// ======================= PAGE =======================
class CreateStockInOrderPage extends StatefulWidget {
  const CreateStockInOrderPage({super.key});

  @override
  State<CreateStockInOrderPage> createState() => _CreateStockInOrderPageState();
}

class _CreateStockInOrderPageState extends State<CreateStockInOrderPage> {
  String? selectedSupplier;
  int? selectedSupplierId;
  String dialogSearch = "";
  String supplierSearch = "";
  List<Map<String, dynamic>> suppliers = [];
  bool isLoadingSuppliers = false;

  @override
  void initState() {
    super.initState();
    _fetchSuppliers();
  }

  Future<void> _fetchSuppliers() async {
    setState(() => isLoadingSuppliers = true);
    try {
      final response = await Supabase.instance.client
          .from('supplier')
          .select('supplier_id, name')
          .order('name');
      setState(() {
        suppliers = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading suppliers: $e')));
      }
    } finally {
      setState(() => isLoadingSuppliers = false);
    }
  }

  // المنتجات المختارة في الصفحة الرئيسية
  List<Map<String, dynamic>> selectedProducts = [];

  // جميع المنتجات الخاصة بالمورد
  List<Product> supplierProducts = [];
  bool isLoadingProducts = false;

  List<Product> selectedInDialog = [];

  Future<void> _loadProductsForSupplier(int supplierId) async {
    setState(() => isLoadingProducts = true);
    try {
      // تحميل المنتجات الخاصة بالـ supplier عبر جدول batch
      final response = await supabase
          .from('batch')
          .select('''
            product:product_id (
              product_id,
              name,
              brand:brand_id(name),
              unit:unit_id(unit_name),
              wholesale_price,
              total_quantity,
              is_active
            )
          ''')
          .eq('supplier_id', supplierId);

      // استخراج المنتجات الفريدة (قد يكون نفس المنتج في أكثر من batch)
      final Map<int, Product> uniqueProducts = {};

      for (var item in (response as List)) {
        if (item['product'] != null) {
          final product = item['product'] as Map<String, dynamic>;
          if (product['is_active'] == true) {
            final productId = product['product_id'] as int;
            if (!uniqueProducts.containsKey(productId)) {
              uniqueProducts[productId] = Product(
                productId,
                product['name'] ?? 'Unknown',
                product['brand']?['name'] ?? '-',
                product['total_quantity'] ?? 0,
                product['unit']?['unit_name'] ?? 'pcs',
                (product['wholesale_price'] as num?)?.toDouble() ?? 0.0,
              );
            }
          }
        }
      }

      setState(() {
        supplierProducts = uniqueProducts.values.toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading products: $e')));
      }
      print('Error loading products for supplier: $e');
    } finally {
      setState(() => isLoadingProducts = false);
    }
  }

  // فتح البوب أب الخاص بإضافة المنتجات
  void _openAddProductsDialog() {
    selectedInDialog = [];
    dialogSearch = "";

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            final filtered = supplierProducts.where((p) {
              return p.name.toLowerCase().contains(dialogSearch.toLowerCase());
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: AppColors.bgDark,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // ===== HEADER =====
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Select Products",
                          style: TextStyle(
                            color: AppColors.gold,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  // ===== SEARCH FIELD =====
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cardAlt,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextField(
                        style: const TextStyle(color: Colors.white),
                        onChanged: (v) {
                          setStateSheet(() => dialogSearch = v);
                        },
                        decoration: const InputDecoration(
                          hintText: "Search product...",
                          hintStyle: TextStyle(color: Colors.white54),
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.search, color: AppColors.gold),
                        ),
                      ),
                    ),
                  ),

                  // ===== COLUMN HEADERS =====
                  if (!isLoadingProducts && supplierProducts.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: Text(
                                "Product",
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 24),
                              child: Text(
                                "Current Qty",
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ===== PRODUCT LIST =====
                  Expanded(
                    child: isLoadingProducts
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.gold,
                            ),
                          )
                        : supplierProducts.isEmpty
                        ? const Center(
                            child: Text(
                              "No products available for this supplier",
                              style: TextStyle(color: Colors.white54),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final p = filtered[i];
                              final isSelected = selectedInDialog.contains(p);

                              return GestureDetector(
                                onTap: () {
                                  setStateSheet(() {
                                    isSelected
                                        ? selectedInDialog.remove(p)
                                        : selectedInDialog.add(p);
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
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
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              p.brand,
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        "${p.availableQty}",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        p.unit,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      if (isSelected)
                                        const Icon(
                                          Icons.check_circle,
                                          color: AppColors.gold,
                                          size: 24,
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  // ===== ADD BUTTON =====
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.gold,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: selectedInDialog.isEmpty
                              ? null
                              : () {
                                  setState(() {
                                    for (var p in selectedInDialog) {
                                      selectedProducts.insert(0, {
                                        "product_id": p.productId,
                                        "name": p.name,
                                        "brand": p.brand,
                                        "qty": 1,
                                        "unit": p.unit,
                                        "wholesale_price": p.wholesalePrice,
                                      });
                                    }
                                  });
                                  Navigator.pop(context);
                                },
                          child: Text(
                            selectedInDialog.isEmpty
                                ? "SELECT PRODUCTS"
                                : "ADD ${selectedInDialog.length} PRODUCT${selectedInDialog.length > 1 ? 'S' : ''}",
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _removeProduct(int index) {
    setState(() => selectedProducts.removeAt(index));
  }

  Future<void> _sendOrder() async {
    // Validate that supplier and products are selected
    if (selectedSupplierId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a supplier'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one product'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
      );

      // Get manager info from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final managerIdStr = prefs.getString('current_user_id');
      final managerName = prefs.getString('current_user_name');

      if (managerIdStr == null || managerName == null) {
        if (mounted) Navigator.pop(context); // Close loading
        throw Exception('Manager information not found');
      }

      final managerId = int.parse(managerIdStr);

      // Calculate total cost (sum of qty * wholesale_price for all products)
      double totalCost = 0;
      for (var product in selectedProducts) {
        final qty = product['qty'] as int;
        final wholesalePrice = product['wholesale_price'] as double;
        totalCost += qty * wholesalePrice;
      }

      const taxPercent = 16;
      final totalBalance = totalCost * (1 + taxPercent / 100);

      // Insert into supplier_order
      final orderInsertResponse = await supabase
          .from('supplier_order')
          .insert({
            'supplier_id': selectedSupplierId,
            'total_cost': totalCost,
            'tax_percent': taxPercent,
            'total_balance': totalBalance,
            'order_date': DateTime.now().toIso8601String(),
            'order_status': 'Pending',
            'created_by_id': managerId,
            'last_tracing_by': managerName,
            'last_tracing_time': DateTime.now().toIso8601String(),
          })
          .select('order_id')
          .single();

      final orderId = orderInsertResponse['order_id'] as int;

      // Insert into supplier_order_description for each product
      final descriptionInserts = selectedProducts.map((product) {
        return {
          'order_id': orderId,
          'product_id': product['product_id'] as int,
          'quantity': product['qty'] as int,
          'price_per_product': product['wholesale_price'] as double,
          'last_tracing_by': managerName,
          'last_tracing_time': DateTime.now().toIso8601String(),
        };
      }).toList();

      await supabase
          .from('supplier_order_description')
          .insert(descriptionInserts);

      // Close loading and show success
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order #$orderId sent successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Clear form
        setState(() {
          selectedProducts.clear();
          selectedSupplier = null;
          selectedSupplierId = null;
        });
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openSupplierSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            final filtered = suppliers.where((s) {
              final name = s['name']?.toString().toLowerCase() ?? '';
              return name.contains(supplierSearch.toLowerCase());
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: AppColors.bgDark,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // ===== HEADER =====
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Select Supplier",
                          style: TextStyle(
                            color: AppColors.gold,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  // ===== SEARCH FIELD =====
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cardAlt,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextField(
                        style: const TextStyle(color: Colors.white),
                        onChanged: (v) {
                          setStateSheet(() => supplierSearch = v);
                        },
                        decoration: const InputDecoration(
                          hintText: "Search supplier...",
                          hintStyle: TextStyle(color: Colors.white54),
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.search, color: AppColors.gold),
                        ),
                      ),
                    ),
                  ),

                  // ===== SUPPLIER LIST =====
                  Expanded(
                    child: suppliers.isEmpty
                        ? const Center(
                            child: Text(
                              "No suppliers available",
                              style: TextStyle(color: Colors.white54),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final supplier = filtered[i];
                              final supplierId = supplier['supplier_id'];
                              final supplierName = supplier['name'] ?? '';
                              final isSelected =
                                  selectedSupplierId == supplierId;

                              return GestureDetector(
                                onTap: () async {
                                  setState(() {
                                    selectedSupplierId = supplierId;
                                    selectedSupplier = supplierName;
                                  });
                                  Navigator.pop(context);
                                  // تحميل منتجات الـ supplier المحدد
                                  await _loadProductsForSupplier(supplierId);
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
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
                                        child: Text(
                                          supplierName,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      if (isSelected)
                                        const Icon(
                                          Icons.check_circle,
                                          color: AppColors.gold,
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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
              // ===== BACK BUTTON + TITLE =====
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Create Stock-in Order",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ===== SUPPLIER SELECT =====
              GestureDetector(
                onTap: isLoadingSuppliers ? null : _openSupplierSelector,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.gold, width: 1.4),
                    borderRadius: BorderRadius.circular(14),
                    color: AppColors.card,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        selectedSupplier ?? "Select Supplier",
                        style: TextStyle(
                          color: selectedSupplier == null
                              ? Colors.white54
                              : Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      Icon(Icons.arrow_drop_down, color: AppColors.gold),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ===== HEADER =====
              const Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      "Product Name",
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      "Brand",
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: EdgeInsets.only(right: 30),
                      child: Text(
                        "Quantity",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),
              Container(height: 1, color: Colors.white24),
              const SizedBox(height: 12),

              // ===== PRODUCT LIST =====
              Expanded(
                child: selectedProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 80,
                              color: Colors.white24,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "No Products Added",
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Tap the + button to add products",
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: selectedProducts.length,
                        itemBuilder: (_, i) {
                          final p = selectedProducts[i];
                          final controller = TextEditingController(
                            text: p["qty"].toString(),
                          );

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
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),

                                // BRAND
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    p["brand"],
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
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
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: TextField(
                                            controller: controller,
                                            onChanged: (v) {
                                              if (v.isNotEmpty) {
                                                setState(
                                                  () => p["qty"] =
                                                      int.tryParse(v) ??
                                                      p["qty"],
                                                );
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
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                          ),
                                        ),

                                        const SizedBox(width: 6),

                                        Text(
                                          p["unit"],
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontWeight: FontWeight.w600,
                                          ),
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
                      onTap: _sendOrder,
                      child: Container(
                        height: 54,
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "s  e  n  d",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 8,
                              ),
                            ),
                            Transform.rotate(
                              angle: -0.8,
                              child: const Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ],
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
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 28,
                      ),
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
