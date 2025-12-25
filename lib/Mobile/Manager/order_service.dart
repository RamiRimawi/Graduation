import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'order_item.dart';

class OrderService {
  static final supabase = Supabase.instance.client;

  /// Fetch order details with items from database
  static Future<OrderData?> fetchOrderDetails(int orderId) async {
    try {
      // Fetch order header
      final orderResponse = await supabase
          .from('customer_order')
          .select('*, customer(*)')
          .eq('customer_order_id', orderId)
          .single();

      // Fetch order items with product details
      final itemsResponse = await supabase
          .from('customer_order_description')
          .select('*, product(name, brand:brand_id(*), unit:unit_id(*))')
          .eq('customer_order_id', orderId);

      if (itemsResponse.isEmpty) {
        return null;
      }

      // Extract customer name
      final customerName =
          orderResponse['customer']['name'] as String? ?? 'Unknown';

      // Convert items to OrderItem list
      final items = <OrderItem>[];
      for (final itemData in itemsResponse) {
        final productData = itemData['product'] as Map<String, dynamic>;
        final brandData = productData['brand'] as Map<String, dynamic>?;
        final unitData = productData['unit'] as Map<String, dynamic>?;

        // Try to get unit name from different possible column names
        String unitName = 'Unit';
        if (unitData != null) {
          unitName =
              unitData['name'] as String? ??
              unitData['unit_name'] as String? ??
              unitData['description'] as String? ??
              'Unit';
        }

        final item = OrderItem(
          itemData['product_id'] as int? ?? 0,
          productData['name'] as String? ?? 'Unknown',
          brandData?['name'] as String? ?? 'Unknown',
          unitName,
          itemData['quantity'] as int? ?? 0,
        );
        items.add(item);
      }

      return OrderData(
        orderId: orderId,
        customerName: customerName,
        items: items,
      );
    } catch (e) {
      print('Error fetching order details: $e');
      return null;
    }
  }

  /// Fetch all pending orders for manager
  static Future<List<OrderSummary>> fetchPendingOrders() async {
    try {
      final response = await supabase
          .from('customer_order')
          .select(
            'customer_order_id, customer:customer_id(name), order_date, order_status',
          )
          .eq('order_status', 'pending')
          .order('order_date', ascending: false);

      final orders = <OrderSummary>[];
      for (final order in response) {
        orders.add(
          OrderSummary(
            orderId: order['customer_order_id'] as int,
            customerName: order['customer']['name'] as String? ?? 'Unknown',
            orderDate: order['order_date'] as String,
            status: order['order_status'] as String,
          ),
        );
      }
      return orders;
    } catch (e) {
      print('Error fetching pending orders: $e');
      return [];
    }
  }

  /// Save split order allocations to customer_order_inventory
  static Future<bool> saveSplitOrder({
    required int orderId,
    required List<Map<String, dynamic>> splits,
  }) async {
    try {
      // Get manager name and ID from SharedPreferences first (to use in inventory rows)
      final prefs = await SharedPreferences.getInstance();
      final managerIdStr = prefs.getString('current_user_id');
      final int? managerId = managerIdStr != null
          ? int.tryParse(managerIdStr)
          : null;
      String? managerName = prefs.getString('current_user_name');

      // If name is not stored, try to get it using manager_id
      if (managerName == null || managerName.isEmpty) {
        if (managerId != null) {
          try {
            final managerResponse = await supabase
                .from('storage_manager')
                .select('name')
                .eq('storage_manager_id', managerId)
                .single();
            managerName = managerResponse['name'] as String?;
          } catch (e) {
            print('Error fetching manager name: $e');
            managerName = 'Manager';
          }
        }
      }

      final now = DateTime.now().toIso8601String();

      // Build rows for customer_order_inventory
      final inventoryRows = <Map<String, dynamic>>[];

      for (final split in splits) {
        final staffId = split['staffId'] as int;
        final inventoryId = split['inventoryId'] as int;
        final items = split['items'] as Map<int, int>; // productId -> quantity
        final batches =
            split['batches'] as Map<int, int?>?; // productId -> batchId

        for (final entry in items.entries) {
          final productId = entry.key;
          final quantity = entry.value;
          final batchId = batches?[productId]; // Get batch for this product

          inventoryRows.add({
            'customer_order_id': orderId,
            'product_id': productId,
            'inventory_id': inventoryId,
            'quantity': quantity,
            'prepared_by': staffId,
            'batch_id': batchId,
            'last_action_by': managerName ?? 'Manager',
            'last_action_time': now,
          });
        }
      }

      // Insert all rows into customer_order_inventory
      await supabase.from('customer_order_inventory').insert(inventoryRows);

      // Update customer_order_description for all products in this order
      final allProductIds = <int>{};
      for (final split in splits) {
        final items = split['items'] as Map<int, int>;
        allProductIds.addAll(items.keys);
      }

      for (final productId in allProductIds) {
        await supabase
            .from('customer_order_description')
            .update({
              'last_action_by': managerName ?? 'Manager',
              'last_action_time': now,
            })
            .eq('customer_order_id', orderId)
            .eq('product_id', productId);
      }

      // Update order status, last action by, timestamp, and manager_by_id
      final Map<String, dynamic> updateData = {
        'order_status': 'Preparing',
        'last_action_by': managerName ?? 'Manager',
        'last_action_time': now,
      };

      // Add manager_by_id if manager ID is available
      if (managerId != null) {
        updateData['managed_by_id'] = managerId;
      }

      await supabase
          .from('customer_order')
          .update(updateData)
          .eq('customer_order_id', orderId);

      return true;
    } catch (e) {
      print('Error saving split order: $e');
      return false;
    }
  }

  /// Assign a delivery driver to an order and update status to Delivery
  static Future<bool> assignDeliveryDriver({
    required int orderId,
    required int driverId,
  }) async {
    try {
      // Get manager name and ID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final managerIdStr = prefs.getString('current_user_id');
      final int? managerId = managerIdStr != null
          ? int.tryParse(managerIdStr)
          : null;
      String? managerName = prefs.getString('current_user_name');

      if (managerName == null || managerName.isEmpty) {
        if (managerId != null) {
          try {
            final managerResponse = await supabase
                .from('storage_manager')
                .select('name')
                .eq('storage_manager_id', managerId)
                .single();
            managerName = managerResponse['name'] as String?;
          } catch (e) {
            print('Error fetching manager name: $e');
            managerName = 'Manager';
          }
        }
      }

      final now = DateTime.now().toIso8601String();

      // Fetch all inventory items for this order to update quantities
      final inventoryItems = await supabase
          .from('customer_order_inventory')
          .select('product_id, batch_id, prepared_quantity')
          .eq('customer_order_id', orderId);

      final productIds = <int>{};

      // Update batch and product quantities
      for (final item in inventoryItems) {
        final productId = item['product_id'] as int?;
        final batchId = item['batch_id'] as int?;
        final preparedQty = item['prepared_quantity'] as int? ?? 0;

        if (preparedQty <= 0 || productId == null) continue;

        productIds.add(productId);

        // Update batch quantity if batch_id exists
        if (batchId != null) {
          // Fetch current batch quantity
          final batchResponse = await supabase
              .from('batch')
              .select('quantity')
              .eq('batch_id', batchId)
              .eq('product_id', productId)
              .single();

          final currentBatchQty = batchResponse['quantity'] as int? ?? 0;
          final newBatchQty = currentBatchQty - preparedQty;

          // Update batch quantity
          await supabase
              .from('batch')
              .update({'quantity': newBatchQty})
              .eq('batch_id', batchId)
              .eq('product_id', productId);
        }

        // Update product total_quantity
        final productResponse = await supabase
            .from('product')
            .select('total_quantity')
            .eq('product_id', productId)
            .single();

        final currentTotalQty = productResponse['total_quantity'] as int? ?? 0;
        final newTotalQty = currentTotalQty - preparedQty;

        await supabase
            .from('product')
            .update({'total_quantity': newTotalQty})
            .eq('product_id', productId);
      }

      // Update customer_order_description for all products in this order
      for (final productId in productIds) {
        await supabase
            .from('customer_order_description')
            .update({
              'last_action_by': managerName ?? 'Manager',
              'last_action_time': now,
            })
            .eq('customer_order_id', orderId)
            .eq('product_id', productId);
      }

      // Update order status
      await supabase
          .from('customer_order')
          .update({
            'delivered_by_id': driverId,
            'order_status': 'Delivery',
            'last_action_by': managerName ?? 'Manager',
            'last_action_time': now,
          })
          .eq('customer_order_id', orderId);

      return true;
    } catch (e) {
      print('Error assigning delivery driver: $e');
      return false;
    }
  }
}

class OrderData {
  final int orderId;
  final String customerName;
  final List<OrderItem> items;

  OrderData({
    required this.orderId,
    required this.customerName,
    required this.items,
  });
}

class OrderSummary {
  final int orderId;
  final String customerName;
  final String orderDate;
  final String status;

  OrderSummary({
    required this.orderId,
    required this.customerName,
    required this.orderDate,
    required this.status,
  });
}
