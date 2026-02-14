import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../supabase_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'offline_database_helper.dart';

class StaffSyncManager {
  static final StaffSyncManager instance = StaffSyncManager._init();

  StaffSyncManager._init();

  final _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  bool _isOnline = true;
  bool _isSyncing = false;

  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;

  // Initialize and start monitoring connectivity
  Future<void> initialize() async {
    // Clean up old cache entries
    final db = OfflineDatabaseHelper.instance;
    await db.clearOldCache();

    // Check initial connectivity
    final result = await _connectivity.checkConnectivity();
    _isOnline = result != ConnectivityResult.none;

    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      result,
    ) {
      final wasOffline = !_isOnline;
      _isOnline = result != ConnectivityResult.none;

      // If we just came back online, sync pending actions
      if (wasOffline && _isOnline) {
        syncPendingActions();
      }
    });
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }

  // Process all pending actions in the queue
  Future<void> syncPendingActions() async {
    if (_isSyncing || !_isOnline) return;

    _isSyncing = true;
    try {
      final db = OfflineDatabaseHelper.instance;
      final actions = await db.getPendingActions();

      for (final action in actions) {
        try {
          final actionType = action['action_type'] as String;
          final customerId = action['customer_order_id'] as int;
          final payload =
              jsonDecode(action['payload'] as String) as Map<String, dynamic>;

          if (actionType == 'mark_order_prepared') {
            await _processMarkOrderPrepared(customerId, payload);
          }

          // Successfully processed, delete from queue
          await db.deletePendingAction(action['id'] as int);

          // Clear cached data for this order since it's now synced
          await db.clearCachedOrder(customerId);
        } catch (e) {
          // Failed to process, increment retry count
          final retryCount = action['retry_count'] as int;
          await db.incrementRetryCount(action['id'] as int);

          // If retried too many times (5+), delete to prevent infinite retries
          if (retryCount >= 5) {
            print(
              'Action ${action['id']} failed after 5 retries, removing from queue',
            );
            await db.deletePendingAction(action['id'] as int);
          }
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  // Process the "mark order as prepared" action
  Future<void> _processMarkOrderPrepared(
    int customerId,
    Map<String, dynamic> payload,
  ) async {
    final products = payload['products'] as List;
    final prefs = await SharedPreferences.getInstance();
    final staffId = int.tryParse(prefs.getString('current_user_id') ?? '');
    final staffName = prefs.getString('current_user_name') ?? 'Unknown';
    final now = DateTime.now();

    for (final product in products) {
      final pid = product['product_id'] as int;
      final allocations = product['allocations'] as List;

      // Remove previous allocations for this staff/product
      await supabase
          .from('customer_order_inventory')
          .delete()
          .eq('customer_order_id', customerId)
          .eq('product_id', pid)
          .eq('prepared_by', staffId ?? 0);

      // Insert new allocations
      for (final alloc in allocations) {
        final picked = alloc['prepared_qty'] as int? ?? 0;
        if (picked <= 0) continue;

        await supabase.from('customer_order_inventory').insert({
          'customer_order_id': customerId,
          'product_id': pid,
          'inventory_id': alloc['inventory_id'],
          'quantity': picked,
          'prepared_by': staffId,
          'batch_id': alloc['batch_id'],
          'prepared_quantity': picked,
          'last_action_by': staffName,
          'last_action_time': now.toIso8601String(),
        });
      }

      // Update customer_order_description
      await supabase
          .from('customer_order_description')
          .update({
            'last_action_by': staffName,
            'last_action_time': now.toIso8601String(),
          })
          .eq('customer_order_id', customerId)
          .eq('product_id', pid);
    }

    // Check if all items in this order are prepared
    final allInventoryItems = await supabase
        .from('customer_order_inventory')
        .select('prepared_quantity')
        .eq('customer_order_id', customerId);

    final allPrepared = allInventoryItems.every(
      (item) => item['prepared_quantity'] != null,
    );

    if (allPrepared) {
      await supabase
          .from('customer_order')
          .update({
            'order_status': 'Prepared',
            'last_action_by': staffName,
            'last_action_time': now.toIso8601String(),
          })
          .eq('customer_order_id', customerId);
    }
  }

  // Fetch orders with caching
  Future<List<Map<String, dynamic>>> fetchOrdersWithCache(int staffId) async {
    final db = OfflineDatabaseHelper.instance;

    if (_isOnline) {
      try {
        // Fetch from Supabase - only get items where prepared_quantity is null (not yet completed)
        final inventoryItems = await supabase
            .from('customer_order_inventory')
            .select('customer_order_id, product_id, prepared_quantity')
            .eq('prepared_by', staffId)
            .isFilter('prepared_quantity', null)
            .order('customer_order_id');

        if (inventoryItems.isEmpty) {
          return [];
        }

        final Set<int> orderIds = {};
        for (final item in inventoryItems) {
          final orderId = item['customer_order_id'] as int?;
          if (orderId != null) orderIds.add(orderId);
        }

        final orders = await supabase
            .from('customer_order')
            .select(
              'customer_order_id, order_status, customer:customer_id(name)',
            )
            .filter('customer_order_id', 'in', orderIds.toList())
            .eq('order_status', 'Preparing')
            .order('customer_order_id');

        Map<int, int> productCounts = {};
        for (final item in inventoryItems) {
          final id = item['customer_order_id'] as int?;
          if (id == null) continue;
          productCounts[id] = (productCounts[id] ?? 0) + 1;
        }

        final mapped = orders.map<Map<String, dynamic>>((o) {
          final id = o['customer_order_id'] as int? ?? 0;
          final customer =
              (o['customer'] as Map?)?['name']?.toString() ?? 'Unknown';
          final products = productCounts[id] ?? 0;
          return {'id': id, 'name': customer, 'products': products};
        }).toList();

        // Cache the results
        await db.cacheOrders(mapped);

        return mapped;
      } catch (e) {
        // Network error, fall back to cache
        return await db.getCachedOrders();
      }
    } else {
      // Offline, load from cache
      return await db.getCachedOrders();
    }
  }

  // Fetch products with caching
  Future<List<Map<String, dynamic>>> fetchProductsWithCache(
    int orderId,
    int staffId,
  ) async {
    final db = OfflineDatabaseHelper.instance;

    if (_isOnline) {
      try {
        // Fetch from Supabase
        final inventoryItems = await supabase
            .from('customer_order_inventory')
            .select(
              'product_id, quantity, prepared_quantity, batch_id, inventory_id',
            )
            .eq('customer_order_id', orderId)
            .eq('prepared_by', staffId)
            .order('product_id');

        if (inventoryItems.isEmpty) {
          return [];
        }

        final productIds = inventoryItems
            .map((row) => row['product_id'] as int?)
            .where((id) => id != null)
            .cast<int>()
            .toSet()
            .toList();

        final productsResponse = await supabase
            .from('product')
            .select(
              'product_id, name, brand:brand_id(name), unit:unit_id(unit_name)',
            )
            .inFilter('product_id', productIds);

        final productMap = {
          for (final p in productsResponse) p['product_id'] as int: p,
        };

        final batchIds = inventoryItems
            .map((row) => row['batch_id'] as int?)
            .where((id) => id != null)
            .cast<int>()
            .toSet()
            .toList();

        Map<int, Map<String, dynamic>> batchMap = {};
        if (batchIds.isNotEmpty) {
          final batchesResponse = await supabase
              .from('batch')
              .select(
                'batch_id, quantity, storage_location_descrption, inventory_id',
              )
              .inFilter('batch_id', batchIds);

          batchMap = {
            for (final b in batchesResponse)
              b['batch_id'] as int: Map<String, dynamic>.from(b),
          };
        }

        final Map<int, Map<String, dynamic>> grouped = {};

        for (final row in inventoryItems) {
          final int? productId = row['product_id'] as int?;
          if (productId == null) continue;

          final productDetails = productMap[productId];
          final brandMap = productDetails?['brand'] as Map?;
          final unitMap = productDetails?['unit'] as Map?;
          final batchId = row['batch_id'] as int?;
          final batch = batchId != null ? batchMap[batchId] : null;

          grouped.putIfAbsent(productId, () {
            return {
              'product_id': productId,
              'name': productDetails?['name']?.toString() ?? 'Unknown',
              'brand': brandMap?['name']?.toString() ?? 'Unknown',
              'unit': unitMap?['unit_name']?.toString() ?? 'Unit',
              'quantity': 0,
              'inventory_id': row['inventory_id'] as int?,
              'allocations': <Map<String, dynamic>>[],
            };
          });

          final requiredQty = (row['quantity'] as num?)?.toInt() ?? 0;
          final preparedQty =
              (row['prepared_quantity'] as num?)?.toInt() ?? requiredQty;

          grouped[productId]!['quantity'] =
              (grouped[productId]!['quantity'] as int? ?? 0) + requiredQty;

          (grouped[productId]!['allocations'] as List<Map<String, dynamic>>)
              .add({
                'batch_id': batchId,
                'inventory_id': row['inventory_id'] as int?,
                'storage_location':
                    batch?['storage_location_descrption']?.toString() ?? 'N/A',
                'available_qty': (batch?['quantity'] as num?)?.toInt() ?? 0,
                'prepared_qty': preparedQty,
              });
        }

        final products = grouped.values.toList();

        // Cache products and allocations
        await db.cacheProducts(orderId, products);
        for (final product in products) {
          await db.cacheAllocations(
            orderId,
            product['product_id'] as int,
            List<Map<String, dynamic>>.from(product['allocations']),
          );
        }

        return products;
      } catch (e) {
        // Network error, fall back to cache
        final products = await db.getCachedProducts(orderId);
        for (final product in products) {
          product['allocations'] = await db.getCachedAllocations(
            orderId,
            product['product_id'] as int,
          );
        }
        return products;
      }
    } else {
      // Offline, load from cache
      final products = await db.getCachedProducts(orderId);
      for (final product in products) {
        product['allocations'] = await db.getCachedAllocations(
          orderId,
          product['product_id'] as int,
        );
      }
      return products;
    }
  }

  // Fetch batches with caching
  Future<List<Map<String, dynamic>>> fetchBatchesWithCache({
    required int productId,
    int? inventoryId,
  }) async {
    final db = OfflineDatabaseHelper.instance;

    if (_isOnline) {
      try {
        var query = supabase
            .from('batch')
            .select(
              'batch_id, quantity, storage_location_descrption, inventory_id',
            )
            .eq('product_id', productId)
            .gt('quantity', 0);

        if (inventoryId != null) {
          query = query.eq('inventory_id', inventoryId);
        }

        final batches = await query.order('batch_id');
        final batchList = List<Map<String, dynamic>>.from(batches);

        // Cache the batches
        await db.cacheBatches(productId, batchList);

        return batchList;
      } catch (e) {
        // Network error, fall back to cache
        return await db.getCachedBatches(productId, inventoryId: inventoryId);
      }
    } else {
      // Offline, load from cache
      return await db.getCachedBatches(productId, inventoryId: inventoryId);
    }
  }

  // Queue action when saving order preparation
  Future<void> queueOrderPreparation({
    required int customerId,
    required List<Map<String, dynamic>> products,
  }) async {
    final db = OfflineDatabaseHelper.instance;

    final payload = jsonEncode({'products': products});

    await db.addPendingAction(
      actionType: 'mark_order_prepared',
      customerId: customerId,
      payload: payload,
    );

    // Try to sync immediately if online
    if (_isOnline) {
      await syncPendingActions();
    }
  }

  // Get count of pending actions
  Future<int> getPendingActionsCount() async {
    final db = OfflineDatabaseHelper.instance;
    final actions = await db.getPendingActions();
    return actions.length;
  }

  // Get list of customer order IDs that have pending actions
  Future<Set<int>> getPendingOrderIds() async {
    final db = OfflineDatabaseHelper.instance;
    final actions = await db.getPendingActions();
    return actions
        .map((action) => action['customer_order_id'] as int?)
        .where((id) => id != null)
        .cast<int>()
        .toSet();
  }

  // Check if a specific order has pending actions
  Future<bool> hasOrderPendingSync(int orderId) async {
    final pendingIds = await getPendingOrderIds();
    return pendingIds.contains(orderId);
  }
}
