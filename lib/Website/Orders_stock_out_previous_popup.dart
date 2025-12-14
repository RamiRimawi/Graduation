import 'package:flutter/material.dart';
import '../supabase_config.dart';

class AppColors {
  static const white = Color(0xFFFFFFFF);
  static const gold = Color(0xFFB7A447);
  static const bgDark = Color(0xFF202020);
  static const card = Color(0xFF2D2D2D);
  static const cardAlt = Color(0xFF262626);
  static const divider = Color(0xFF6F6F6F);
  static const blue = Color(0xFF50B2E7);
}

class OrderDetailsPopup extends StatefulWidget {
  final String orderId;

  const OrderDetailsPopup({super.key, required this.orderId});

  @override
  State<OrderDetailsPopup> createState() => _OrderDetailsPopupState();
}

class _OrderDetailsPopupState extends State<OrderDetailsPopup> {
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
          .from('customer_order')
          .select('''
            customer_order_id,
            order_date,
            delivered_date,
            total_cost,
            tax_percent,
            total_balance,
            order_status,
            customer:customer_id(name, mobile_number, address),
            sales_rep:sales_rep_id(name),
            delivery_driver:delivered_by_id(name, mobile_number),
            storage_staff:prepared_by_id(name),
            storage_manager:managed_by_id(name),
            accountant:accountant_id(name)
          ''')
          .eq('customer_order_id', orderIdInt)
          .single();

      // Fetch order description for quantities and prices
      final descriptionData = await supabase
          .from('customer_order_description')
          .select('''
            product_id,
            quantity,
            delivered_quantity,
            total_price,
            product:product_id(name, selling_price, unit:unit_id(unit_name))
          ''')
          .eq('customer_order_id', orderIdInt);

      // Fetch inventory breakdown from customer_order_inventory
      final inventoryData = await supabase
          .from('customer_order_inventory')
          .select('''
            product_id,
            inventory_id,
            batch_id,
            quantity,
            inventory:inventory_id(inventory_name)
          ''')
          .eq('customer_order_id', orderIdInt);

      // If no inventory data, try fetching without the relationship
      List<Map<String, dynamic>> inventoryDataFinal = inventoryData;
      if (inventoryData.isEmpty) {
        final rawInventoryData = await supabase
            .from('customer_order_inventory')
            .select('product_id, inventory_id, batch_id, quantity')
            .eq('customer_order_id', orderIdInt);

        // If we got data, fetch inventory locations separately
        if (rawInventoryData.isNotEmpty) {
          final inventoryIds = <int>{};
          for (final row in rawInventoryData) {
            inventoryIds.add(row['inventory_id'] as int);
          }

          if (inventoryIds.isNotEmpty) {
            final inventoryLocations = await supabase
                .from('inventory')
                .select('inventory_id, inventory_name')
                .inFilter('inventory_id', inventoryIds.toList());

            final locationsMap = <int, String>{};
            for (final loc in inventoryLocations) {
              locationsMap[loc['inventory_id'] as int] =
                  loc['inventory_name'] as String;
            }

            // Add inventory_location to each record
            inventoryDataFinal = rawInventoryData.map((row) {
              return {
                ...row,
                'inventory': {
                  'inventory_name': locationsMap[row['inventory_id']],
                },
              };
            }).toList();
          }
        }
      }

      // Group inventory data by product_id
      final Map<int, List<Map<String, dynamic>>> inventoryByProduct = {};

      for (final invRow in inventoryDataFinal) {
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

        productsList.add({
          'product_id': productId,
          'product': desc['product'],
          'quantity': desc['quantity'],
          'delivered_quantity': desc['delivered_quantity'],
          'total_price': desc['total_price'],
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

    final customer = _orderData!['customer'] as Map?;
    final salesRep = _orderData!['sales_rep'] as Map?;
    final deliveryDriver = _orderData!['delivery_driver'] as Map?;
    final preparedBy = _orderData!['storage_staff'] as Map?;
    final managedBy = _orderData!['storage_manager'] as Map?;

    final orderDate = _orderData!['order_date'] != null
        ? DateTime.parse(_orderData!['order_date'])
        : null;
    final deliveredDate = _orderData!['delivered_date'] != null
        ? DateTime.parse(_orderData!['delivered_date'])
        : null;

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
                // Customer & Order + Staff side-by-side cards
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
                            _buildSectionTitle('Customer & Order Information'),
                            const SizedBox(height: 12),
                            _buildInfoGrid([
                              _InfoItem(
                                'Customer Name',
                                customer?['name'] ?? 'N/A',
                                icon: Icons.person,
                              ),
                              _InfoItem(
                                'Mobile',
                                customer?['mobile_number'] ?? 'N/A',
                                icon: Icons.phone,
                              ),
                              _InfoItem(
                                'Order Date',
                                orderDate != null
                                    ? '${orderDate.day}/${orderDate.month}/${orderDate.year}'
                                    : 'N/A',
                                icon: Icons.calendar_today,
                              ),
                              _InfoItem(
                                'Delivered Date',
                                deliveredDate != null
                                    ? '${deliveredDate.day}/${deliveredDate.month}/${deliveredDate.year}'
                                    : 'N/A',
                                icon: Icons.check_circle,
                              ),
                            ]),
                            if (customer?['address'] != null) ...[
                              const SizedBox(height: 12),
                              _buildInfoCard(
                                'Address',
                                customer!['address'],
                                icon: Icons.location_on,
                              ),
                            ],
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
                                'Sales Representative',
                                salesRep?['name'] ?? 'N/A',
                                icon: Icons.badge,
                              ),
                              _InfoItem(
                                'Delivery Driver',
                                deliveryDriver?['name'] ?? 'N/A',
                                icon: Icons.local_shipping,
                              ),
                              _InfoItem(
                                'Prepared By',
                                preparedBy?['name'] ?? 'N/A',
                                icon: Icons.inventory_2,
                              ),
                              _InfoItem(
                                'Managed By',
                                managedBy?['name'] ?? 'N/A',
                                icon: Icons.supervised_user_circle,
                              ),
                            ]),
                            if (deliveryDriver?['mobile_number'] != null) ...[
                              const SizedBox(height: 12),
                              _buildInfoCard(
                                'Driver Mobile',
                                deliveryDriver!['mobile_number'],
                                icon: Icons.phone_android,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Financial Section
                _buildSectionTitle('Financial Details'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildFinancialRow(
                        'Total Cost',
                        _orderData!['total_cost']?.toString() ?? '0',
                      ),
                      const SizedBox(height: 8),
                      _buildFinancialRow(
                        'Tax (${_orderData!['tax_percent'] ?? 0}%)',
                        _calculateTax().toString(),
                        color: AppColors.white.withOpacity(0.7),
                      ),
                      const Divider(color: AppColors.divider, height: 24),
                      _buildFinancialRow(
                        'Total Balance',
                        _orderData!['total_balance']?.toString() ?? '0',
                        isBold: true,
                        color: AppColors.gold,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Products Section
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

  Widget _buildInfoCard(String label, String value, {required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.blue, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.white.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: color ?? Colors.white,
          ),
        ),
        Text(
          '\$$value',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: color ?? Colors.white,
          ),
        ),
      ],
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
                'Delivered',
                '${product['delivered_quantity'] ?? 0} ${unitInfo?['unit_name'] ?? 'units'}',
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

          // Inventory breakdown section
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

  Widget _buildInventoryRow(
    Map<String, dynamic> inventoryData,
    String unitName,
  ) {
    final inventory = inventoryData['inventory'] as Map?;
    final inventoryLocation = inventory?['inventory_name'] ?? 'Unknown';
    final quantity = inventoryData['quantity'] ?? 0;
    final batchId = inventoryData['batch_id'];

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bgDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.gold,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  inventoryLocation,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (batchId != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.divider.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Batch: $batchId',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.white.withOpacity(0.6),
                    ),
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.blue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$quantity $unitName',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.blue,
                  ),
                ),
              ),
            ],
          ),
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

  double _calculateTax() {
    final totalCost = _orderData!['total_cost'] ?? 0;
    final taxPercent = _orderData!['tax_percent'] ?? 0;
    return (totalCost * taxPercent / 100);
  }
}

class _InfoItem {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  _InfoItem(this.label, this.value, {required this.icon, this.valueColor});
}
