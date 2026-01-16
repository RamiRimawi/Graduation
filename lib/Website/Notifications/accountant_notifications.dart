import 'package:supabase_flutter/supabase_flutter.dart';
import '../../supabase_config.dart';
import 'notification_service.dart';

/// Safe conversion helpers to avoid "null" string parsing errors
int? _safeInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  final str = v.toString();
  if (str.isEmpty || str == 'null') return null;
  return int.tryParse(str);
}

double? _safeDouble(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  final str = v.toString();
  if (str.isEmpty || str == 'null') return null;
  return double.tryParse(str);
}

String _safeStr(dynamic v) {
  if (v == null) return '';
  final str = v.toString();
  return (str == 'null') ? '' : str;
}

/// Log null fields for debugging
void _logNullFields(String tag, Map<String, dynamic> rec) {
  final nullKeys = <String>[];
  rec.forEach((k, v) {
    if (v == null || v.toString() == 'null') nullKeys.add(k);
  });
  if (nullKeys.isNotEmpty) {
    print('⚠️ $tag null fields: $nullKeys');
  }
}

class AccountantNotifications {
  static final AccountantNotifications _instance =
      AccountantNotifications._internal();
  factory AccountantNotifications() => _instance;
  AccountantNotifications._internal();

  final NotificationService _notificationService = NotificationService();
  final List<RealtimeChannel> _subscriptions = [];

  bool _isInitialized = false;
  bool _realtimeEnabled = false;

  Future<void> initialize() async {
    if (_isInitialized) {
      print('⚠️ Notifications already initialized');
      return;
    }

    print('🔄 Starting notification system initialization...');

    try {
      await _notificationService.initialize();
      print('✅ NotificationService initialized');

      print('🔄 Checking Realtime availability...');
      _realtimeEnabled = await _checkRealtimeAvailability();

      if (!_realtimeEnabled) {
        print('⚠️ Realtime is not enabled in Supabase');
        print('💡 Enable tables in: Supabase Dashboard → Database → Replication');
        _isInitialized = true;
        return;
      }
      print('✅ Realtime is available');

      await _initializeListeners();

      _isInitialized = true;
      print('✅ Notification system initialized successfully');
    } catch (e, stackTrace) {
      print('❌ NOTIFICATION SYSTEM ERROR: $e');
      print(stackTrace);
      _isInitialized = true; // Mark as initialized to prevent retry loops
      // Don't rethrow - let the app continue without notifications
    }
  }

  Future<void> _initializeListeners() async {
    // Add delays between subscriptions to avoid overwhelming the connection
    const delay = Duration(milliseconds: 100);

    try {
      print('🔄 Setting up customer orders listener...');
      await Future.delayed(delay);
      _listenToCustomerOrders();

      print('🔄 Setting up supplier orders listener...');
      await Future.delayed(delay);
      _listenToSupplierOrders();

      print('🔄 Setting up checks listeners...');
      await Future.delayed(delay);
      _listenToCustomerChecks();
      
      await Future.delayed(delay);
      _listenToSupplierChecks();

      print('🔄 Setting up order updates listener...');
      await Future.delayed(delay);
      _listenToOrderUpdates();

      print('🔄 Setting up low stock listener...');
      await Future.delayed(delay);
      _listenToLowStock();

      print('✅ All listeners initialized');
    } catch (e, stackTrace) {
      print('❌ Error during listeners initialization: $e');
      print(stackTrace);
    }
  }

  Future<bool> _checkRealtimeAvailability() async {
    try {
      final testChannel = supabase.channel('test_connection_${DateTime.now().millisecondsSinceEpoch}');
      await Future.delayed(const Duration(milliseconds: 200));
      supabase.removeChannel(testChannel);
      return true;
    } catch (e) {
      print('❌ Realtime availability check failed: $e');
      return false;
    }
  }

  void dispose() {
    try {
      for (final ch in _subscriptions) {
        try {
          supabase.removeChannel(ch);
        } catch (_) {}
      }
      _subscriptions.clear();
      _isInitialized = false;
      print('✅ Notification system disposed');
    } catch (e) {
      print('⚠️ Error disposing notification system: $e');
    }
  }

  // ===================== 1) Customer Orders (INSERT) =====================
  void _listenToCustomerOrders() {
    try {
      final channelName = 'customer_orders_${DateTime.now().millisecondsSinceEpoch}';
      
      final channel = supabase
          .channel(channelName)
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'customer_order',
            callback: (payload) {
              // Wrap everything in Future.microtask to avoid blocking
              Future.microtask(() async {
                try {
                  final order = payload.newRecord;
                  _logNullFields('customer_order(new)', order);

                  final customerId = _safeInt(order['customer_id']);
                  final orderId = _safeInt(order['customer_order_id']);
                  final totalCost = _safeDouble(order['total_cost']);

                  if (orderId == null) {
                    print('⚠️ customer_order: orderId is null, skipping');
                    return;
                  }

                  String customerName = 'Customer #$customerId';
                  if (customerId != null) {
                    try {
                      final customerData = await supabase
                          .from('customer')
                          .select('name')
                          .eq('customer_id', customerId)
                          .maybeSingle();
                      if (customerData != null) {
                        customerName = _safeStr(customerData['name']);
                        if (customerName.isEmpty) customerName = 'Customer #$customerId';
                      }
                    } catch (e) {
                      print('⚠️ Could not fetch customer name: $e');
                    }
                  }

                  final totalText = totalCost?.toStringAsFixed(2) ?? '0.00';

                  await _notificationService.addNotification(
                    title: 'New order',
                    message: 'Order #$orderId from $customerName with total \$$totalText',
                    type: 'order',
                  );
                  print('✅ Customer order notification added for #$orderId');
                } catch (e, stackTrace) {
                  print('❌ Error processing customer order notification: $e');
                  print(stackTrace);
                }
              });
            },
          )
          .subscribe((status, error) {
            if (error != null) {
              print('❌ customer_order subscription error: $error');
            } else {
              print('✅ customer_order subscription status: $status');
            }
          });

      _subscriptions.add(channel);
      print('✅ customer_order INSERT subscribed');
    } catch (e, stackTrace) {
      print('❌ Cannot setup customer orders listener: $e');
      print(stackTrace);
    }
  }

  // ===================== 2) Supplier Orders (UPDATE) =====================
  void _listenToSupplierOrders() {
    try {
      final channelName = 'supplier_orders_${DateTime.now().millisecondsSinceEpoch}';
      
      final channel = supabase
          .channel(channelName)
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'supplier_order',
            callback: (payload) {
              Future.microtask(() async {
                try {
                  final newRecord = payload.newRecord;
                  final oldRecord = payload.oldRecord;

                  final newStatus = _safeStr(newRecord['order_status']);
                  final oldStatus = _safeStr(oldRecord['order_status']);

                  // Only notify on status change
                  if (newStatus.isEmpty || oldStatus == newStatus) return;

                  final orderId = _safeInt(newRecord['order_id']);
                  final supplierId = _safeInt(newRecord['supplier_id']);

                  if (orderId == null) return;

                  String supplierName = 'Supplier #$supplierId';
                  if (supplierId != null) {
                    try {
                      final supplierData = await supabase
                          .from('supplier')
                          .select('name')
                          .eq('supplier_id', supplierId)
                          .maybeSingle();
                      if (supplierData != null) {
                        final name = _safeStr(supplierData['name']);
                        if (name.isNotEmpty) supplierName = name;
                      }
                    } catch (_) {}
                  }

                  final statusTextMap = {
                    'Accepted': 'has been accepted',
                    'Rejected': 'has been rejected',
                    'Pending': 'is pending',
                    'Delivered': 'has been delivered',
                    'Hold': 'is on hold',
                    'Sent': 'has been sent',
                    'Updated': 'has been updated',
                  };

                  final statusText = statusTextMap[newStatus];
                  if (statusText == null) return;

                  await _notificationService.addNotification(
                    title: 'Supplier order update',
                    message: 'Order #$orderId from $supplierName $statusText',
                    type: 'order',
                  );
                } catch (e, stackTrace) {
                  print('❌ Error processing supplier order notification: $e');
                  print(stackTrace);
                }
              });
            },
          )
          .subscribe();

      _subscriptions.add(channel);
      print('✅ supplier_order UPDATE subscribed');
    } catch (e, stackTrace) {
      print('❌ Cannot listen to supplier orders: $e');
      print(stackTrace);
    }
  }

  // ===================== 3) Customer Checks (scheduled check) =====================
  void _listenToCustomerChecks() {
    print('🔄 Setting up customer checks monitoring...');
    _checkUpcomingChecks();
    print('✅ Customer checks monitoring setup complete');

    // Re-check daily
    Future.delayed(const Duration(hours: 24), () {
      if (_isInitialized) _listenToCustomerChecks();
    });
  }

  Future<void> _checkUpcomingChecks() async {
    try {
      final today = DateTime.now();
      final threeDaysLater = today.add(const Duration(days: 3));
      final todayStr = today.toIso8601String().split('T')[0];
      final futureStr = threeDaysLater.toIso8601String().split('T')[0];

      // Customer checks
      try {
        final customerChecks = await supabase
            .from('customer_checks')
            .select('check_id, customer_id, exchange_rate, exchange_date, status')
            .neq('status', 'Cashed')
            .gte('exchange_date', todayStr)
            .lte('exchange_date', futureStr);

        if (customerChecks is List) {
          for (final check in customerChecks) {
            try {
              final dateStr = _safeStr(check['exchange_date']);
              if (dateStr.isEmpty) continue;
              
              final exchangeDate = DateTime.tryParse(dateStr);
              if (exchangeDate == null) continue;
              
              final daysRemaining = exchangeDate.difference(today).inDays;
              final amount = _safeDouble(check['exchange_rate']) ?? 0.0;
              final checkId = _safeInt(check['check_id']) ?? 0;

              if (daysRemaining == 0) {
                await _notificationService.addNotification(
                  title: 'Check due today',
                  message: 'Check #$checkId for \$${amount.toStringAsFixed(2)} must be cashed today',
                  type: 'payment',
                );
              } else if (daysRemaining <= 3 && daysRemaining > 0) {
                await _notificationService.addNotification(
                  title: 'Check cash reminder',
                  message: 'Check #$checkId for \$${amount.toStringAsFixed(2)} is due in $daysRemaining day(s)',
                  type: 'payment',
                );
              }
            } catch (_) {}
          }
        }
      } catch (e) {
        print('⚠️ Error fetching customer checks: $e');
      }

      // Supplier checks
      try {
        final supplierChecks = await supabase
            .from('supplier_checks')
            .select('check_id, supplier_id, exchange_rate, exchange_date, status')
            .eq('status', 'Pending')
            .gte('exchange_date', todayStr)
            .lte('exchange_date', futureStr);

        if (supplierChecks is List) {
          for (final check in supplierChecks) {
            try {
              final dateStr = _safeStr(check['exchange_date']);
              if (dateStr.isEmpty) continue;
              
              final exchangeDate = DateTime.tryParse(dateStr);
              if (exchangeDate == null) continue;
              
              final daysRemaining = exchangeDate.difference(today).inDays;
              final amount = _safeDouble(check['exchange_rate']) ?? 0.0;
              final checkId = _safeInt(check['check_id']) ?? 0;

              if (daysRemaining == 0) {
                await _notificationService.addNotification(
                  title: 'Supplier check due today',
                  message: 'Check #$checkId for \$${amount.toStringAsFixed(2)} must be cashed today',
                  type: 'payment',
                );
              } else if (daysRemaining <= 3 && daysRemaining > 0) {
                await _notificationService.addNotification(
                  title: 'Supplier check cash reminder',
                  message: 'Check #$checkId for \$${amount.toStringAsFixed(2)} is due in $daysRemaining day(s)',
                  type: 'payment',
                );
              }
            } catch (_) {}
          }
        }
      } catch (e) {
        print('⚠️ Error fetching supplier checks: $e');
      }
    } catch (e) {
      print('⚠️ Error in _checkUpcomingChecks: $e');
    }
  }

  // ===================== 4) Supplier Checks (UPDATE) =====================
  void _listenToSupplierChecks() {
    try {
      final channelName = 'supplier_checks_${DateTime.now().millisecondsSinceEpoch}';
      
      final channel = supabase
          .channel(channelName)
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'supplier_checks',
            callback: (payload) {
              Future.microtask(() async {
                try {
                  final newStatus = _safeStr(payload.newRecord['status']);
                  final oldStatus = _safeStr(payload.oldRecord['status']);

                  if (oldStatus != newStatus && newStatus == 'Cashed') {
                    final checkId = _safeInt(payload.newRecord['check_id']) ?? 0;
                    final amount = _safeDouble(payload.newRecord['exchange_rate']) ?? 0.0;

                    await _notificationService.addNotification(
                      title: 'Check cashed',
                      message: 'Check #$checkId for \$${amount.toStringAsFixed(2)} has been cashed',
                      type: 'payment',
                    );
                  }
                } catch (e) {
                  print('❌ Error processing supplier check notification: $e');
                }
              });
            },
          )
          .subscribe();

      _subscriptions.add(channel);
      print('✅ supplier_checks UPDATE subscribed');
    } catch (e, stackTrace) {
      print('❌ Cannot listen to supplier checks: $e');
      print(stackTrace);
    }
  }

  // ===================== 5) Order Updates =====================
  void _listenToOrderUpdates() {
    try {
      final channelName = 'customer_order_updates_${DateTime.now().millisecondsSinceEpoch}';
      
      final channel = supabase
          .channel(channelName)
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'customer_order',
            callback: (payload) {
              Future.microtask(() async {
                try {
                  final oldRecord = payload.oldRecord;
                  final newRecord = payload.newRecord;

                  final orderId = _safeInt(newRecord['customer_order_id']);
                  if (orderId == null) return;

                  // Check for manager updates
                  final updateAction = _safeStr(newRecord['update_action']);
                  final updateDescription = _safeStr(newRecord['update_description']);

                  if (updateAction.isNotEmpty) {
                    String message = 'Order #$orderId was updated';
                    if (updateDescription.isNotEmpty) {
                      message += ': $updateDescription';
                    }

                    await _notificationService.addNotification(
                      title: 'Manager order update',
                      message: message,
                      type: 'order',
                    );
                    return; // Don't double-notify
                  }

                  // Check for status changes
                  final oldStatus = _safeStr(oldRecord['order_status']);
                  final newStatus = _safeStr(newRecord['order_status']);

                  if (oldStatus != newStatus && newStatus.isNotEmpty) {
                    final statusTextMap = {
                      'Received': 'received',
                      'Pinned': 'pinned',
                      'Prepared': 'prepared',
                      'Delivery': 'out for delivery',
                      'Delivered': 'delivered',
                      'Canceled': 'cancelled',
                      'Hold': 'put on hold',
                    };

                    final statusText = statusTextMap[newStatus];
                    if (statusText != null) {
                      await _notificationService.addNotification(
                        title: 'Order status update',
                        message: 'Order #$orderId was $statusText',
                        type: 'order',
                      );
                    }
                  }
                } catch (e) {
                  print('❌ Error processing order update notification: $e');
                }
              });
            },
          )
          .subscribe();

      _subscriptions.add(channel);
      print('✅ Order updates listener subscribed');
    } catch (e, stackTrace) {
      print('❌ Cannot listen to order updates: $e');
      print(stackTrace);
    }
  }

  // ===================== 6) Low Stock =====================
  void _listenToLowStock() {
    try {
      final channelName = 'product_stock_${DateTime.now().millisecondsSinceEpoch}';
      
      final channel = supabase
          .channel(channelName)
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'product',
            callback: (payload) {
              Future.microtask(() async {
                try {
                  final newRecord = payload.newRecord;

                  final totalQuantity = _safeInt(newRecord['total_quantity']);
                  final minimumStock = _safeInt(newRecord['minimum_stock']);
                  final productName = _safeStr(newRecord['name']);
                  final productId = _safeInt(newRecord['product_id']);

                  if (totalQuantity != null &&
                      minimumStock != null &&
                      totalQuantity <= minimumStock) {
                    await _notificationService.addNotification(
                      title: 'Low stock alert',
                      message: 'Product "$productName" (#$productId) reached minimum: $totalQuantity of $minimumStock',
                      type: 'system',
                    );
                  }
                } catch (e) {
                  print('❌ Error processing low stock notification: $e');
                }
              });
            },
          )
          .subscribe();

      _subscriptions.add(channel);
      print('✅ product low stock listener subscribed');
    } catch (e, stackTrace) {
      print('❌ Cannot listen to low stock: $e');
      print(stackTrace);
    }
  }

  // ============== Helper methods for manual notifications ==============

  Future<void> notifyNewCustomerOrder(
    int orderId,
    String customerName,
    double totalCost,
  ) async {
    await _notificationService.addNotification(
      title: 'New order',
      message: 'Order #$orderId from $customerName with total \$${totalCost.toStringAsFixed(2)}',
      type: 'order',
    );
  }

  Future<void> notifySupplierOrderStatusChange(
    int orderId,
    String supplierName,
    String status,
  ) async {
    final statusTextMap = {
      'Accepted': 'has been accepted',
      'Rejected': 'has been rejected',
      'Pending': 'is pending',
      'Delivered': 'has been delivered',
      'Hold': 'is on hold',
    };

    final statusText = statusTextMap[status] ?? 'status changed to $status';

    await _notificationService.addNotification(
      title: 'Supplier order update',
      message: 'Order #$orderId from $supplierName $statusText',
      type: 'order',
    );
  }

  Future<void> notifyCheckDueDate(
    int checkId,
    double amount,
    int daysRemaining,
    bool isCustomerCheck,
  ) async {
    final checkType = isCustomerCheck ? '' : ' (supplier)';

    if (daysRemaining == 0) {
      await _notificationService.addNotification(
        title: 'Check due today$checkType',
        message: 'Check #$checkId for \$${amount.toStringAsFixed(2)} must be cashed today',
        type: 'payment',
      );
    } else {
      await _notificationService.addNotification(
        title: 'Check cash reminder$checkType',
        message: 'Check #$checkId for \$${amount.toStringAsFixed(2)} is due in $daysRemaining day(s)',
        type: 'payment',
      );
    }
  }

  Future<void> notifyLowStock(
    int productId,
    String productName,
    int currentQuantity,
    int minimumQuantity,
  ) async {
    await _notificationService.addNotification(
      title: 'Low stock alert',
      message: 'Product "$productName" (#$productId) reached minimum: $currentQuantity of $minimumQuantity',
      type: 'system',
    );
  }

  Future<void> notifyOrderUpdateByManager(
    int orderId,
    String updateDescription,
  ) async {
    await _notificationService.addNotification(
      title: 'Manager order update',
      message: 'Order #$orderId was updated: $updateDescription',
      type: 'order',
    );
  }
}