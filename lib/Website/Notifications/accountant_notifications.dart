import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../supabase_config.dart';
import 'notification_service.dart';

/// Hybrid notification system - Realtime with fallback to Polling
/// يحاول استخدام Realtime أولاً، وإذا فشل يستخدم Polling
class AccountantNotifications {
  static final AccountantNotifications _instance =
      AccountantNotifications._internal();
  factory AccountantNotifications() => _instance;
  AccountantNotifications._internal();

  final NotificationService _notificationService = NotificationService();
  final List<RealtimeChannel> _subscriptions = [];

  bool _isInitialized = false;
  bool _usePolling = false;
  Timer? _pollingTimer;

  // لتتبع الحالات
  int? _lastCustomerOrderId;
  final Set<int> _processedCustomerOrders = {};
  final Map<int, String> _lastSupplierOrderStatus = {};
  final Map<int, String> _lastCustomerOrderStatus = {};
  final Set<int> _notifiedLowStockProducts = {};

  // ===================== Safe Conversion Helpers =====================
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

  /// تفعيل نظام الإشعارات
  Future<void> initialize() async {
    if (_isInitialized) {
      print('⚠️ Notifications already initialized');
      return;
    }

    print('🔄 Starting notification system initialization...');

    try {
      await _notificationService.initialize();
      print('✅ NotificationService initialized');

      await _initializeLastIds();

      // محاولة Realtime مع حماية من الأخطاء
      print('🔄 Attempting to setup Realtime listeners...');
      
      bool realtimeSuccess = await _trySetupRealtime();
      
      if (!realtimeSuccess) {
        print('⚠️ Realtime failed, switching to Polling mode');
        _usePolling = true;
        _startPolling();
      }

      await _checkUpcomingChecks();

      _isInitialized = true;
      print('✅ Notification system initialized (${_usePolling ? "Polling" : "Realtime"} mode)');
    } catch (e, stackTrace) {
      print('❌ NOTIFICATION SYSTEM ERROR: $e');
      print(stackTrace);
      
      _usePolling = true;
      _startPolling();
      _isInitialized = true;
    }
  }

  Future<void> _initializeLastIds() async {
    try {
      final lastOrder = await supabase
          .from('customer_order')
          .select('customer_order_id')
          .order('customer_order_id', ascending: false)
          .limit(1)
          .maybeSingle();

      if (lastOrder != null) {
        _lastCustomerOrderId = _safeInt(lastOrder['customer_order_id']);
        print('📌 Last customer order ID: $_lastCustomerOrderId');
      }

      final supplierOrders = await supabase
          .from('supplier_order')
          .select('order_id, order_status')
          .limit(100);

      if (supplierOrders is List) {
        for (final order in supplierOrders) {
          final orderId = _safeInt(order['order_id']);
          final status = _safeStr(order['order_status']);
          if (orderId != null) {
            _lastSupplierOrderStatus[orderId] = status;
          }
        }
      }

      final customerOrders = await supabase
          .from('customer_order')
          .select('customer_order_id, order_status')
          .limit(200);

      if (customerOrders is List) {
        for (final order in customerOrders) {
          final orderId = _safeInt(order['customer_order_id']);
          final status = _safeStr(order['order_status']);
          if (orderId != null) {
            _lastCustomerOrderStatus[orderId] = status;
          }
        }
      }
    } catch (e) {
      print('⚠️ Error initializing last IDs: $e');
    }
  }

  Future<bool> _trySetupRealtime() async {
    try {
      int successCount = 0;
      int failCount = 0;

      // 1. Customer Orders INSERT
      try {
        await _setupCustomerOrdersRealtime();
        successCount++;
      } catch (e) {
        print('⚠️ Customer orders realtime failed: $e');
        failCount++;
      }

      await Future.delayed(const Duration(milliseconds: 100));

      // 2. Supplier Orders UPDATE
      try {
        await _setupSupplierOrdersRealtime();
        successCount++;
      } catch (e) {
        print('⚠️ Supplier orders realtime failed: $e');
        failCount++;
      }

      await Future.delayed(const Duration(milliseconds: 100));

      // 3. Customer Order Status UPDATE
      try {
        await _setupCustomerOrderStatusRealtime();
        successCount++;
      } catch (e) {
        print('⚠️ Customer order status realtime failed: $e');
        failCount++;
      }

      await Future.delayed(const Duration(milliseconds: 100));

      // 4. Low Stock
      try {
        await _setupLowStockRealtime();
        successCount++;
      } catch (e) {
        print('⚠️ Low stock realtime failed: $e');
        failCount++;
      }

      await Future.delayed(const Duration(milliseconds: 100));

      // 5. Supplier Checks
      try {
        await _setupSupplierChecksRealtime();
        successCount++;
      } catch (e) {
        print('⚠️ Supplier checks realtime failed: $e');
        failCount++;
      }

      print('📊 Realtime setup: $successCount success, $failCount failed');

      if (failCount > successCount) {
        _disposeRealtimeChannels();
        return false;
      }

      await Future.delayed(const Duration(seconds: 1));
      return true;
    } catch (e) {
      print('❌ Realtime setup failed completely: $e');
      return false;
    }
  }

  void _disposeRealtimeChannels() {
    for (final ch in _subscriptions) {
      try {
        supabase.removeChannel(ch);
      } catch (_) {}
    }
    _subscriptions.clear();
  }

  // ===================== REALTIME LISTENERS =====================

  Future<void> _setupCustomerOrdersRealtime() async {
    final channelName = 'co_insert_${DateTime.now().millisecondsSinceEpoch}';
    final channel = supabase.channel(channelName);
    
    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'customer_order',
      callback: (payload) => _safeHandle(() => _handleCustomerOrderInsert(payload)),
    );
    
    await channel.subscribe((status, error) {
      if (error != null) {
        print('❌ customer_order subscription error: $error');
      } else {
        print('✅ customer_order subscription: $status');
      }
    });

    _subscriptions.add(channel);
  }

  Future<void> _handleCustomerOrderInsert(PostgresChangePayload payload) async {
    final order = payload.newRecord;
    
    final orderId = _safeInt(order['customer_order_id']);
    if (orderId == null) return;
    
    if (_processedCustomerOrders.contains(orderId)) return;
    _processedCustomerOrders.add(orderId);

    final customerId = _safeInt(order['customer_id']);
    String customerName = 'Customer #$customerId';

    if (customerId != null) {
      try {
        final data = await supabase
            .from('customer')
            .select('name')
            .eq('customer_id', customerId)
            .maybeSingle();
        if (data != null) {
          final name = _safeStr(data['name']);
          if (name.isNotEmpty) customerName = name;
        }
      } catch (_) {}
    }

    final totalCost = _safeDouble(order['total_cost']);
    final totalText = totalCost?.toStringAsFixed(2) ?? '0.00';

    await _notificationService.addNotification(
      title: 'New order',
      message: 'Order #$orderId from $customerName with total \$$totalText',
      type: 'order',
    );
    print('🔔 [Realtime] New customer order: #$orderId');
  }

  Future<void> _setupSupplierOrdersRealtime() async {
    final channelName = 'so_update_${DateTime.now().millisecondsSinceEpoch}';
    final channel = supabase.channel(channelName);
    
    channel.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'supplier_order',
      callback: (payload) => _safeHandle(() => _handleSupplierOrderUpdate(payload)),
    );
    
    await channel.subscribe();
    _subscriptions.add(channel);
    print('✅ supplier_order UPDATE subscribed');
  }

  Future<void> _handleSupplierOrderUpdate(PostgresChangePayload payload) async {
    final newRecord = payload.newRecord;
    final oldRecord = payload.oldRecord;

    final newStatus = _safeStr(newRecord['order_status']);
    final oldStatus = _safeStr(oldRecord['order_status']);

    if (newStatus.isEmpty || oldStatus == newStatus) return;

    final orderId = _safeInt(newRecord['order_id']);
    if (orderId == null) return;

    final supplierId = _safeInt(newRecord['supplier_id']);
    String supplierName = 'Supplier #$supplierId';

    if (supplierId != null) {
      try {
        final data = await supabase
            .from('supplier')
            .select('name')
            .eq('supplier_id', supplierId)
            .maybeSingle();
        if (data != null) {
          final name = _safeStr(data['name']);
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
    };

    final statusText = statusTextMap[newStatus];
    if (statusText == null) return;

    await _notificationService.addNotification(
      title: 'Supplier order update',
      message: 'Order #$orderId from $supplierName $statusText',
      type: 'order',
    );
    print('🔔 [Realtime] Supplier order update: #$orderId -> $newStatus');
  }

  Future<void> _setupCustomerOrderStatusRealtime() async {
    final channelName = 'co_status_${DateTime.now().millisecondsSinceEpoch}';
    final channel = supabase.channel(channelName);
    
    channel.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'customer_order',
      callback: (payload) => _safeHandle(() => _handleCustomerOrderStatusUpdate(payload)),
    );
    
    await channel.subscribe();
    _subscriptions.add(channel);
    print('✅ customer_order status UPDATE subscribed');
  }

  Future<void> _handleCustomerOrderStatusUpdate(PostgresChangePayload payload) async {
    final newRecord = payload.newRecord;
    final oldRecord = payload.oldRecord;

    final orderId = _safeInt(newRecord['customer_order_id']);
    if (orderId == null) return;

    // Check for manager updates
    final updateAction = _safeStr(newRecord['update_action']);
    if (updateAction.isNotEmpty) {
      final updateDescription = _safeStr(newRecord['update_description']);
      String message = 'Order #$orderId was updated';
      if (updateDescription.isNotEmpty) message += ': $updateDescription';

      await _notificationService.addNotification(
        title: 'Manager order update',
        message: message,
        type: 'order',
      );
      return;
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
        print('🔔 [Realtime] Order status: #$orderId -> $newStatus');
      }
    }
  }

  Future<void> _setupLowStockRealtime() async {
    final channelName = 'product_stock_${DateTime.now().millisecondsSinceEpoch}';
    final channel = supabase.channel(channelName);
    
    channel.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'product',
      callback: (payload) => _safeHandle(() => _handleLowStock(payload)),
    );
    
    await channel.subscribe();
    _subscriptions.add(channel);
    print('✅ product low stock subscribed');
  }

  Future<void> _handleLowStock(PostgresChangePayload payload) async {
    final newRecord = payload.newRecord;

    final productId = _safeInt(newRecord['product_id']);
    if (productId == null) return;

    final totalQuantity = _safeInt(newRecord['total_quantity']);
    final minimumStock = _safeInt(newRecord['minimum_stock']);
    final productName = _safeStr(newRecord['name']);

    if (totalQuantity == null || minimumStock == null) return;

    if (totalQuantity <= minimumStock) {
      if (_notifiedLowStockProducts.contains(productId)) return;
      _notifiedLowStockProducts.add(productId);

      await _notificationService.addNotification(
        title: 'Low stock alert',
        message: 'Product "$productName" (#$productId) reached minimum: $totalQuantity of $minimumStock',
        type: 'system',
      );
      print('🔔 [Realtime] Low stock: $productName');
    } else {
      _notifiedLowStockProducts.remove(productId);
    }
  }

  Future<void> _setupSupplierChecksRealtime() async {
    final channelName = 'supplier_checks_${DateTime.now().millisecondsSinceEpoch}';
    final channel = supabase.channel(channelName);
    
    channel.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'supplier_checks',
      callback: (payload) => _safeHandle(() => _handleSupplierCheckUpdate(payload)),
    );
    
    await channel.subscribe();
    _subscriptions.add(channel);
    print('✅ supplier_checks subscribed');
  }

  Future<void> _handleSupplierCheckUpdate(PostgresChangePayload payload) async {
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
  }

  /// Safe handler wrapper - يلتقط الأخطاء ويحولها لـ polling إذا تكررت
  void _safeHandle(Future<void> Function() handler) {
    runZonedGuarded(() async {
      try {
        await handler();
      } catch (e) {
        print('❌ Handler error: $e');
        _switchToPolling();
      }
    }, (error, stack) {
      print('❌ Uncaught error in handler: $error');
      _switchToPolling();
    });
  }

  // ===================== POLLING FALLBACK =====================

  void _switchToPolling() {
    if (_usePolling) return;
    
    print('🔄 Switching to Polling mode due to Realtime errors...');
    _usePolling = true;
    _disposeRealtimeChannels();
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _pollForChanges();
    });
    print('✅ Polling started (every 5 seconds)');
  }

  Future<void> _pollForChanges() async {
    if (!_isInitialized) return;

    try {
      await _checkNewCustomerOrders();
      await _checkSupplierOrderChanges();
      await _checkCustomerOrderStatusChanges();
      await _checkLowStockPolling();
    } catch (e) {
      print('⚠️ Polling error: $e');
    }
  }

  Future<void> _checkNewCustomerOrders() async {
    try {
      final orders = await supabase
          .from('customer_order')
          .select('customer_order_id, customer_id, total_cost')
          .order('customer_order_id', ascending: false)
          .limit(10);

      if (orders is! List || orders.isEmpty) return;

      for (final order in orders) {
        final orderId = _safeInt(order['customer_order_id']);
        if (orderId == null) continue;

        if (_lastCustomerOrderId != null && orderId <= _lastCustomerOrderId!) continue;
        if (_processedCustomerOrders.contains(orderId)) continue;

        _processedCustomerOrders.add(orderId);

        final customerId = _safeInt(order['customer_id']);
        String customerName = 'Customer #$customerId';

        if (customerId != null) {
          try {
            final data = await supabase
                .from('customer')
                .select('name')
                .eq('customer_id', customerId)
                .maybeSingle();
            if (data != null) {
              final name = _safeStr(data['name']);
              if (name.isNotEmpty) customerName = name;
            }
          } catch (_) {}
        }

        final totalCost = _safeDouble(order['total_cost']);
        final totalText = totalCost?.toStringAsFixed(2) ?? '0.00';

        await _notificationService.addNotification(
          title: 'New order',
          message: 'Order #$orderId from $customerName with total \$$totalText',
          type: 'order',
        );

        if (_lastCustomerOrderId == null || orderId > _lastCustomerOrderId!) {
          _lastCustomerOrderId = orderId;
        }
      }
    } catch (e) {
      print('⚠️ Error checking new customer orders: $e');
    }
  }

  Future<void> _checkSupplierOrderChanges() async {
    try {
      final orders = await supabase
          .from('supplier_order')
          .select('order_id, supplier_id, order_status')
          .limit(50);

      if (orders is! List) return;

      for (final order in orders) {
        final orderId = _safeInt(order['order_id']);
        if (orderId == null) continue;

        final newStatus = _safeStr(order['order_status']);
        final oldStatus = _lastSupplierOrderStatus[orderId] ?? '';

        if (newStatus.isEmpty || newStatus == oldStatus) {
          _lastSupplierOrderStatus[orderId] = newStatus;
          continue;
        }

        _lastSupplierOrderStatus[orderId] = newStatus;

        final supplierId = _safeInt(order['supplier_id']);
        String supplierName = 'Supplier #$supplierId';

        if (supplierId != null) {
          try {
            final data = await supabase
                .from('supplier')
                .select('name')
                .eq('supplier_id', supplierId)
                .maybeSingle();
            if (data != null) {
              final name = _safeStr(data['name']);
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
        };

        final statusText = statusTextMap[newStatus];
        if (statusText == null) continue;

        await _notificationService.addNotification(
          title: 'Supplier order update',
          message: 'Order #$orderId from $supplierName $statusText',
          type: 'order',
        );
      }
    } catch (e) {
      print('⚠️ Error checking supplier order changes: $e');
    }
  }

  Future<void> _checkCustomerOrderStatusChanges() async {
    try {
      final orders = await supabase
          .from('customer_order')
          .select('customer_order_id, order_status')
          .order('customer_order_id', ascending: false)
          .limit(100);

      if (orders is! List) return;

      for (final order in orders) {
        final orderId = _safeInt(order['customer_order_id']);
        if (orderId == null) continue;

        final newStatus = _safeStr(order['order_status']);
        if (newStatus.isEmpty) continue;

        if (!_lastCustomerOrderStatus.containsKey(orderId)) {
          _lastCustomerOrderStatus[orderId] = newStatus;
          continue;
        }

        final oldStatus = _lastCustomerOrderStatus[orderId] ?? '';
        if (newStatus == oldStatus) continue;

        _lastCustomerOrderStatus[orderId] = newStatus;

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
        if (statusText == null) continue;

        await _notificationService.addNotification(
          title: 'Order status update',
          message: 'Order #$orderId status: $statusText',
          type: 'order',
        );
      }
    } catch (e) {
      print('⚠️ Error checking customer order status: $e');
    }
  }

  Future<void> _checkLowStockPolling() async {
    try {
      final products = await supabase
          .from('product')
          .select('product_id, name, total_quantity, minimum_stock')
          .limit(200);

      if (products is! List) return;

      for (final product in products) {
        final productId = _safeInt(product['product_id']);
        if (productId == null) continue;

        final totalQuantity = _safeInt(product['total_quantity']);
        final minimumStock = _safeInt(product['minimum_stock']);
        final productName = _safeStr(product['name']);

        if (totalQuantity == null || minimumStock == null) continue;

        if (totalQuantity <= minimumStock) {
          if (_notifiedLowStockProducts.contains(productId)) continue;
          _notifiedLowStockProducts.add(productId);

          await _notificationService.addNotification(
            title: 'Low stock alert',
            message: 'Product "$productName" (#$productId) reached minimum: $totalQuantity of $minimumStock',
            type: 'system',
          );
        } else {
          _notifiedLowStockProducts.remove(productId);
        }
      }
    } catch (e) {
      print('⚠️ Error checking low stock: $e');
    }
  }

  // ===================== CHECKS (Scheduled) =====================

  Future<void> _checkUpcomingChecks() async {
    print('🔄 Checking upcoming checks...');
    try {
      final today = DateTime.now();
      final threeDaysLater = today.add(const Duration(days: 3));
      final todayStr = today.toIso8601String().split('T')[0];
      final futureStr = threeDaysLater.toIso8601String().split('T')[0];

      try {
        final customerChecks = await supabase
            .from('customer_checks')
            .select('check_id, exchange_rate, exchange_date, status')
            .neq('status', 'Cashed')
            .gte('exchange_date', todayStr)
            .lte('exchange_date', futureStr);

        if (customerChecks is List) {
          for (final check in customerChecks) {
            await _processCheck(check, today, false);
          }
        }
      } catch (e) {
        print('⚠️ Error fetching customer checks: $e');
      }

      try {
        final supplierChecks = await supabase
            .from('supplier_checks')
            .select('check_id, exchange_rate, exchange_date, status')
            .eq('status', 'Pending')
            .gte('exchange_date', todayStr)
            .lte('exchange_date', futureStr);

        if (supplierChecks is List) {
          for (final check in supplierChecks) {
            await _processCheck(check, today, true);
          }
        }
      } catch (e) {
        print('⚠️ Error fetching supplier checks: $e');
      }

      print('✅ Checks verification complete');
    } catch (e) {
      print('⚠️ Error in _checkUpcomingChecks: $e');
    }

    Future.delayed(const Duration(hours: 12), () {
      if (_isInitialized) _checkUpcomingChecks();
    });
  }

  Future<void> _processCheck(Map<String, dynamic> check, DateTime today, bool isSupplier) async {
    try {
      final dateStr = _safeStr(check['exchange_date']);
      if (dateStr.isEmpty) return;

      final exchangeDate = DateTime.tryParse(dateStr);
      if (exchangeDate == null) return;

      final daysRemaining = exchangeDate.difference(today).inDays;
      final amount = _safeDouble(check['exchange_rate']) ?? 0.0;
      final checkId = _safeInt(check['check_id']) ?? 0;
      final prefix = isSupplier ? 'Supplier ' : '';

      if (daysRemaining == 0) {
        await _notificationService.addNotification(
          title: '${prefix}Check due today',
          message: 'Check #$checkId for \$${amount.toStringAsFixed(2)} must be cashed today',
          type: 'payment',
        );
      } else if (daysRemaining > 0 && daysRemaining <= 3) {
        await _notificationService.addNotification(
          title: '${prefix}Check cash reminder',
          message: 'Check #$checkId for \$${amount.toStringAsFixed(2)} is due in $daysRemaining day(s)',
          type: 'payment',
        );
      }
    } catch (_) {}
  }

  /// إيقاف نظام الإشعارات
  void dispose() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _disposeRealtimeChannels();
    _processedCustomerOrders.clear();
    _lastSupplierOrderStatus.clear();
    _lastCustomerOrderStatus.clear();
    _notifiedLowStockProducts.clear();
    _lastCustomerOrderId = null;
    _isInitialized = false;
    _usePolling = false;
    print('✅ Notification system disposed');
  }

  // ============== Manual notification helpers ==============

  Future<void> notifyNewCustomerOrder(int orderId, String customerName, double totalCost) async {
    await _notificationService.addNotification(
      title: 'New order',
      message: 'Order #$orderId from $customerName with total \$${totalCost.toStringAsFixed(2)}',
      type: 'order',
    );
  }

  Future<void> notifySupplierOrderStatusChange(int orderId, String supplierName, String status) async {
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

  Future<void> notifyCheckDueDate(int checkId, double amount, int daysRemaining, bool isCustomerCheck) async {
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

  Future<void> notifyLowStock(int productId, String productName, int currentQuantity, int minimumQuantity) async {
    await _notificationService.addNotification(
      title: 'Low stock alert',
      message: 'Product "$productName" (#$productId) reached minimum: $currentQuantity of $minimumQuantity',
      type: 'system',
    );
  }

  Future<void> notifyOrderUpdateByManager(int orderId, String updateDescription) async {
    await _notificationService.addNotification(
      title: 'Manager order update',
      message: 'Order #$orderId was updated: $updateDescription',
      type: 'order',
    );
  }
}