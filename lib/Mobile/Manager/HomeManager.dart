import 'package:flutter/material.dart';
// ignore: unused_import
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../supabase_config.dart';
import '../manager_theme.dart';

const double kGap = 16;
const double kStatHeight = 144;

class StorageStaff {
  final String name;
  final int inventory;
  final bool online;
  StorageStaff(this.name, this.inventory, {this.online = true});
}

class LowStockItem {
  final String productName;
  final String brand;
  final String inventoryName;
  final int qty;
  LowStockItem(this.productName, this.brand, this.inventoryName, this.qty);
}

class HomeManagerPage extends StatefulWidget {
  final void Function(int)? onSwitchTab;
  const HomeManagerPage({super.key, this.onSwitchTab});

  @override
  State<HomeManagerPage> createState() => _HomeManagerPageState();
}

class _HomeManagerPageState extends State<HomeManagerPage> {
  int pinnedOrdersCount = 0;
  int ordersUpdated = 5;

  List<StorageStaff> staff = [];
  List<LowStockItem> lowStock = [];
  bool _loadingLowStock = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    staff = [
      StorageStaff('Ayman', 2),
      StorageStaff('Ramadan', 1),
      StorageStaff('Rami', 2),
      StorageStaff('Ibraheem', 1),
      StorageStaff('Ammar', 1),
    ];
    setState(() {});
    _fetchPinnedOrdersCount();
    _fetchLowStockProducts();
  }

  Future<void> _fetchPinnedOrdersCount() async {
    try {
      final response = await supabase
          .from('customer_order')
          .select('customer_order_id')
          .eq('order_status', 'Pinned');

      if (mounted) {
        setState(() {
          pinnedOrdersCount = response.length;
        });
      }
    } catch (e) {
      debugPrint('Error fetching pinned orders count: $e');
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _fetchLowStockProducts() async {
    try {
      // Fetch all products with their brand, total_quantity and minimum_stock
      final productsResponse = await supabase
          .from('product')
          .select(
            'product_id, name, brand:brand_id(name), total_quantity, minimum_stock',
          )
          .not('minimum_stock', 'is', null);

      List<LowStockItem> items = [];

      for (var product in productsResponse) {
        final totalQty = product['total_quantity'] as int? ?? 0;
        final minStock = product['minimum_stock'] as int?;

        // Filter where total_quantity <= minimum_stock
        if (minStock != null && totalQty <= minStock) {
          final productId = product['product_id'] as int;
          final productName = product['name'] as String? ?? 'Unknown';
          final brandName = product['brand']?['name'] as String? ?? 'N/A';

          // Fetch batch inventory details for this product
          final batchesResponse = await supabase
              .from('batch')
              .select('inventory:inventory_id(inventory_name), quantity')
              .eq('product_id', productId);

          // Group by inventory and sum quantities
          Map<String, int> inventoryQtyMap = {};
          for (var batch in batchesResponse) {
            final inventoryName =
                batch['inventory']?['inventory_name'] as String? ?? 'Unknown';
            final qty = batch['quantity'] as int? ?? 0;
            inventoryQtyMap[inventoryName] =
                (inventoryQtyMap[inventoryName] ?? 0) + qty;
          }

          // Add each inventory location as a separate row
          if (inventoryQtyMap.isEmpty) {
            // If no batches, show the product with total quantity
            items.add(LowStockItem(productName, brandName, 'N/A', totalQty));
          } else {
            for (var entry in inventoryQtyMap.entries) {
              items.add(
                LowStockItem(productName, brandName, entry.key, entry.value),
              );
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          lowStock = items;
          _loadingLowStock = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching low stock products: $e');
      if (mounted) {
        setState(() => _loadingLowStock = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double staffCardHeight = kStatHeight * 2 + kGap;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 120,
                    child: Column(
                      children: [
                        StatCardFancy(
                          icon: Icons.forward_to_inbox_rounded,
                          count: '$pinnedOrdersCount',
                          bottomWord: 'Receives',
                          onTap: () {
                            widget.onSwitchTab?.call(
                              1,
                            ); // Switch to StockOutPage tab
                          },
                        ),
                        const SizedBox(height: kGap),
                        StatCardFancy(
                          icon: Icons.inventory_2_rounded,
                          count: '$ordersUpdated',
                          bottomWord: 'Updated',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: kGap),
                  Expanded(
                    child: StaffCard(data: staff, fixedHeight: staffCardHeight),
                  ),
                ],
              ),
              const SizedBox(height: kGap),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: LowStockCard(
                    data: lowStock,
                    isLoading: _loadingLowStock,
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

class StatCardFancy extends StatelessWidget {
  final IconData icon;
  final String count;
  final String bottomWord;
  final VoidCallback? onTap;
  const StatCardFancy({
    super.key,
    required this.icon,
    required this.count,
    required this.bottomWord,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      height: kStatHeight,
      decoration: _cardDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.bgDark.withOpacity(.6),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: AppColors.yellow),
              ),
              const SizedBox(height: 6),
              Text(
                count,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Order',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                bottomWord,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.gold,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: card);
    }
    return card;
  }
}

class StaffCard extends StatelessWidget {
  final List<StorageStaff> data;
  final double fixedHeight;
  const StaffCard({super.key, required this.data, required this.fixedHeight});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: fixedHeight,
      child: Container(
        decoration: _cardDecoration(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Text(
                    'Storage Staff',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Spacer(),
                  Text(
                    'Inventory',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  physics: const BouncingScrollPhysics(),
                  itemCount: data.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _StaffRow(
                    name: data[i].name,
                    inv: data[i].inventory,
                    online: data[i].online,
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

class _StaffRow extends StatelessWidget {
  final String name;
  final int inv;
  final bool online;
  const _StaffRow({required this.name, required this.inv, this.online = true});

  @override
  Widget build(BuildContext context) {
    final String initial = name.isNotEmpty
        ? name.substring(0, 1).toUpperCase()
        : '?';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgDark.withOpacity(.25),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.card,
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (online)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            '$inv',
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class LowStockCard extends StatelessWidget {
  final List<LowStockItem> data;
  final bool isLoading;
  const LowStockCard({super.key, required this.data, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDecoration(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'Low Stock Products',
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .4,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Column(
              children: [
                Row(
                  children: const [
                    Expanded(
                      flex: 5,
                      child: Text(
                        'Product Name',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: EdgeInsets.only(left: 12),
                        child: Text(
                          'Brand',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Inventory',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Quantity',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: AppColors.gold,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(height: 1, color: Colors.white24),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.yellow),
                    )
                  : data.isEmpty
                  ? const Center(
                      child: Text(
                        'No low stock products',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: data.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _LowStockRow(item: data[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LowStockRow extends StatelessWidget {
  final LowStockItem item;
  const _LowStockRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card.withOpacity(.85),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              item.productName,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                item.brand,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 3,
            child: Text(
              item.inventoryName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${item.qty}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.yellow,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: AppColors.card,
    borderRadius: BorderRadius.circular(18),
    boxShadow: const [
      BoxShadow(color: AppColors.shadow, blurRadius: 10, offset: Offset(0, 4)),
    ],
  );
}
