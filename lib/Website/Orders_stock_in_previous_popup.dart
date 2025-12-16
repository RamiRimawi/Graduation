import 'package:flutter/material.dart';
import '../supabase_config.dart';
import 'package:intl/intl.dart';

class AppColors {
  static const white = Color(0xFFFFFFFF);
  static const gold = Color(0xFFB7A447);
  static const bgDark = Color(0xFF202020);
  static const card = Color(0xFF2D2D2D);
  static const cardAlt = Color(0xFF262626);
  static const divider = Color(0xFF6F6F6F);
  static const blue = Color(0xFF50B2E7);
}

class OrdersStockInPreviousPopup extends StatefulWidget {
  final String orderId;
  const OrdersStockInPreviousPopup({Key? key, required this.orderId})
    : super(key: key);

  @override
  State<OrdersStockInPreviousPopup> createState() =>
      _OrdersStockInPreviousPopupState();
}

class _OrdersStockInPreviousPopupState
    extends State<OrdersStockInPreviousPopup> {
  Widget _buildInventoryRow(Map<String, dynamic> inv, String unitName) {
    final inventory = inv['inventory'] as Map?;
    final inventoryName = inventory?['inventory_name'] ?? 'Unknown Inventory';
    final batchId = inv['batch_id'] != null
        ? ' (Batch: ${inv['batch_id']})'
        : '';
    final quantity = inv['quantity'] ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(
            Icons.inventory,
            size: 16,
            color: AppColors.blue.withOpacity(0.7),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$inventoryName$batchId',
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            '$quantity $unitName',
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _orderData;
  List<Map<String, dynamic>> _products = [];

  @override
  void initState() {
    super.initState();
    _fetchOrderDetails();
  }

  Future<void> _fetchOrderDetails() async {
    try {
      final orderIdInt = int.tryParse(widget.orderId) ?? 0;
      // Fetch order main details with all related data
      final orderResponse = await supabase
          .from('supplier_order')
          .select('''
            order_id,
            order_date,
            order_status,
            receives_by_id,
            supplier:supplier_id(name),
            storage_staff:receives_by_id(name)
          ''')
          .eq('order_id', orderIdInt)
          .maybeSingle();

      // Fetch product details (simulate as in stock out popup)
      final descriptionData = await supabase
          .from('supplier_order_description')
          .select('''
            product_id,
            quantity,
            receipt_quantity,
            price_per_product,
            product:product_id(name, unit:unit_id(unit_name))
          ''')
          .eq('order_id', orderIdInt);

      // Fetch inventory breakdown from supplier_order_inventory
      final inventoryData = await supabase
          .from('supplier_order_inventory')
          .select('''
            product_id,
            inventory_id,
            batch_id,
            quantity,
            inventory:inventory_id(inventory_name)
          ''')
          .eq('supplier_order_id', orderIdInt);

      // Group inventory data by product_id
      final Map<int, List<Map<String, dynamic>>> inventoryByProduct = {};
      for (final invRow in inventoryData) {
        final productId = invRow['product_id'] as int;
        if (!inventoryByProduct.containsKey(productId)) {
          inventoryByProduct[productId] = [];
        }
        inventoryByProduct[productId]!.add({
          'inventory_id': invRow['inventory_id'],
          'batch_id': invRow['batch_id'],
          'quantity': invRow['quantity'],
          'inventory': invRow['inventory'],
        });
      }

      // Build final products list with all data combined
      final List<Map<String, dynamic>> productsList = [];
      for (final desc in descriptionData) {
        final productId = desc['product_id'] as int;
        final inventoriesForProduct = inventoryByProduct[productId] ?? [];
        final quantity = desc['quantity'] ?? 0;
        final receiptQuantity = desc['receipt_quantity'] ?? 0;
        final pricePerProduct = desc['price_per_product'] ?? 0;
        final totalPrice = (quantity is num && pricePerProduct is num)
            ? (quantity * pricePerProduct)
            : 0;
        productsList.add({
          'product_id': productId,
          'product': desc['product'],
          'quantity': quantity,
          'receipt_quantity': receiptQuantity,
          'price_per_product': pricePerProduct,
          'total_price': totalPrice,
          'inventories': inventoriesForProduct,
        });
      }
      setState(() {
        _orderData = orderResponse;
        _products = productsList;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.7,
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 700),
        decoration: BoxDecoration(
          color: AppColors.bgDark,
          borderRadius: BorderRadius.circular(20),
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              )
            : _buildOrderContent(),
      ),
    );
  }

  Widget _buildOrderContent() {
    if (_orderData == null) return const SizedBox();
    final supplier = _orderData!['supplier'] as Map?;
    final storageStaff = _orderData!['storage_staff'] as Map?;
    final orderDate = _orderData!['order_date'] != null
        ? DateTime.parse(_orderData!['order_date'])
        : null;
    final status = _orderData!['order_status'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.bgDark,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Details',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Order #${widget.orderId}',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.gold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
              ),
            ],
          ),
        ),
        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle('Supplier & Order Information'),
                            const SizedBox(height: 12),
                            _buildInfoGrid([
                              _InfoItem(
                                'Supplier Name',
                                supplier?['name'] ?? 'N/A',
                                icon: Icons.person,
                              ),
                              _InfoItem(
                                'Order Date',
                                orderDate != null
                                    ? DateFormat('dd/MM/yyyy').format(orderDate)
                                    : 'N/A',
                                icon: Icons.calendar_today,
                              ),
                              // Removed Delivered Date (column does not exist)
                              _InfoItem(
                                'Status',
                                status,
                                icon: Icons.info_outline,
                              ),
                            ]),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle('Staff Information'),
                            const SizedBox(height: 12),
                            _buildInfoGrid([
                              _InfoItem(
                                'Received By',
                                storageStaff?['name'] ?? 'N/A',
                                icon: Icons.inventory_2,
                              ),
                            ]),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('Products (${_products.length})'),
                const SizedBox(height: 12),
                ..._products.map((product) => _buildProductCard(product)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );
  }

  Widget _buildInfoGrid(List<_InfoItem> items) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: items.map((item) {
        return SizedBox(
          width: (MediaQuery.of(context).size.width * 0.7 - 72) / 2,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(item.icon, color: AppColors.blue, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.white.withOpacity(0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.value,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: item.valueColor ?? Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final productInfo = product['product'] as Map?;
    final unitInfo = productInfo?['unit'] as Map?;
    final inventories = product['inventories'] as List? ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  productInfo?['name'] ?? 'Unknown Product',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildProductDetail(
                'Ordered',
                '${product['quantity'] ?? 0} ${unitInfo?['unit_name'] ?? 'units'}',
                Icons.shopping_cart,
              ),
              const SizedBox(width: 16),
              _buildProductDetail(
                'Received',
                '${product['receipt_quantity'] ?? 0} ${unitInfo?['unit_name'] ?? 'units'}',
                Icons.check_circle_outline,
                valueColor: AppColors.gold,
              ),
              const SizedBox(width: 16),
              _buildProductDetail(
                'Total Price',
                '\$${product['total_price'] ?? 0}',
                Icons.attach_money,
                valueColor: AppColors.blue,
              ),
            ],
          ),
          if (inventories.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(color: AppColors.divider, height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.warehouse,
                  size: 16,
                  color: AppColors.gold.withOpacity(0.7),
                ),
                const SizedBox(width: 6),
                Text(
                  'Source Inventories:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...inventories.map(
              (inv) =>
                  _buildInventoryRow(inv, unitInfo?['unit_name'] ?? 'units'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductDetail(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.white.withOpacity(0.5)),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.white.withOpacity(0.5),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoItem {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;
  // ignore: unused_element_parameter
  _InfoItem(this.label, this.value, {required this.icon, this.valueColor});
}
