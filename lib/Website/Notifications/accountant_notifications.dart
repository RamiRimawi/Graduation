import 'package:supabase_flutter/supabase_flutter.dart';
import '../../supabase_config.dart';
import 'notification_service.dart';

/// خدمة إشعارات المحاسب - تراقب التغييرات في قاعدة البيانات
class AccountantNotifications {
  static final AccountantNotifications _instance =
      AccountantNotifications._internal();
  factory AccountantNotifications() => _instance;
  AccountantNotifications._internal();

  final NotificationService _notificationService = NotificationService();
  final List<RealtimeChannel> _subscriptions = [];
  bool _isInitialized = false;
  bool _realtimeEnabled = false; // للتحقق من تفعيل Realtime

  /// تفعيل المراقبة لجميع الإشعارات
  Future<void> initialize() async {
    if (_isInitialized) {
      print('⚠️ Notifications already initialized');
      return;
    }

    print('🔄 Starting notification system initialization...');

    try {
      await _notificationService.initialize();
      print('✅ NotificationService initialized');

      // التحقق من إمكانية الاتصال بـ Realtime
      print('🔄 Checking Realtime availability...');
      _realtimeEnabled = await _checkRealtimeAvailability();
      
      if (!_realtimeEnabled) {
        print('⚠️ Realtime is not enabled in Supabase');
        print('💡 Notifications will not work until you enable Realtime');
        print('💡 Enable tables in: Supabase Dashboard → Database → Replication');
        _isInitialized = true;
        return;
      }
      print('✅ Realtime is available');

      // تشغيل كل listener مع معالجة أخطاء منفصلة
      await _initializeListeners();

      _isInitialized = true;
      print('✅ Notification system initialized successfully');
      print('💡 System is now monitoring for real-time updates');
    } catch (e, stackTrace) {
      print('❌ NOTIFICATION SYSTEM ERROR:');
      print('Error: $e');
      print('Stack trace:');
      print(stackTrace);
      _isInitialized = true; // تعيين كـ initialized حتى لا يحاول مرة أخرى
      // رمي الخطأ مرة أخرى ليتم التقاطه في login_page
      rethrow;
    }
  }

  /// تهيئة جميع الـ listeners بشكل آمن
  Future<void> _initializeListeners() async {
    try {
      // 1. مراقبة الطلبيات الجديدة من الزبائن
      print('🔄 Setting up customer orders listener...');
      await Future.delayed(const Duration(milliseconds: 50));
      _listenToCustomerOrders();

      // 2. مراقبة طلبيات الموردين
      print('🔄 Setting up supplier orders listener...');
      await Future.delayed(const Duration(milliseconds: 50));
      _listenToSupplierOrders();

      // 3. مراقبة الشيكات
      print('🔄 Setting up checks listeners...');
      await Future.delayed(const Duration(milliseconds: 50));
      _listenToCustomerChecks();
      await Future.delayed(const Duration(milliseconds: 50));
      _listenToSupplierChecks();

      // 4. مراقبة تعديلات الطلبيات
      print('🔄 Setting up order updates listener...');
      await Future.delayed(const Duration(milliseconds: 50));
      _listenToOrderUpdates();

      // 5. مراقبة المخزون
      print('🔄 Setting up low stock listener...');
      await Future.delayed(const Duration(milliseconds: 50));
      _listenToLowStock();
    } catch (e, stackTrace) {
      print('❌ Error during listeners initialization:');
      print('Error: $e');
      print('Stack trace: $stackTrace');
    }
  }

  /// التحقق من توفر Realtime
  Future<bool> _checkRealtimeAvailability() async {
    try {
      print('🔄 Creating test channel...');
      // محاولة إنشاء channel بسيط للتحقق
      final testChannel = supabase.channel('test_connection');
      await Future.delayed(const Duration(milliseconds: 100));
      supabase.removeChannel(testChannel);
      print('✅ Test channel created successfully');
      return true;
    } catch (e, stackTrace) {
      print('❌ Realtime availability check failed:');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  /// إيقاف جميع الاشتراكات
  void dispose() {
    try {
      for (var subscription in _subscriptions) {
        supabase.removeChannel(subscription);
      }
      _subscriptions.clear();
      _isInitialized = false;
      print('✅ Notification system disposed');
    } catch (e) {
      print('⚠️ Error disposing notification system: $e');
    }
  }

  // ============== 1. طلبيات جديدة من الزبائن ==============
  void _listenToCustomerOrders() {
    try {
      print('🔄 Subscribing to customer_order table...');
      
      try {
        final channel = supabase
            .channel('customer_orders_channel')
            .onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'customer_order',
              callback: (payload) async {
                try {
                  print('📦 New customer order received: ${payload.newRecord}');
                  final order = payload.newRecord;
                  final customerId = order['customer_id'];
                  final orderId = order['customer_order_id'];
                  final totalCost = order['total_cost'];

                  // جلب اسم الزبون
                  String customerName = 'Customer #$customerId';
                  try {
                    final customerData = await supabase
                        .from('customer')
                        .select('name')
                        .eq('customer_id', customerId)
                        .single();
                    customerName = customerData['name'] ?? customerName;
                  } catch (e) {
                    print('⚠️ Could not fetch customer name: $e');
                  }

                  await _notificationService.addNotification(
                    title: 'New order',
                    message:
                        'Order #$orderId from $customerName with total \$${totalCost?.toStringAsFixed(2) ?? "0"}',
                    type: 'order',
                  );
                  print('✅ Customer order notification added');
                } catch (e, stackTrace) {
                  print('❌ Error processing customer order notification:');
                  print('Error: $e');
                  print('Stack trace: $stackTrace');
                }
              },
            )
            .subscribe();

        _subscriptions.add(channel);
        print('✅ Customer orders listener subscribed');
      } catch (subscribeError, stackTrace) {
        print('❌ SUBSCRIBE ERROR for customer_order:');
        print('Error: $subscribeError');
        print('Stack trace: $stackTrace');
      }
    } catch (e, stackTrace) {
      print('❌ Cannot setup customer orders listener:');
      print('Error: $e');
      print('Stack trace: $stackTrace');
    }
  }

  // ============== 2. طلبيات الموردين ==============
  void _listenToSupplierOrders() {
    try {
      print('🔄 Subscribing to supplier_order table...');
      final channel = supabase
          .channel('supplier_orders_channel')
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'supplier_order',
            callback: (payload) async {
              try {
                final oldRecord = payload.oldRecord;
                final newRecord = payload.newRecord;

                final oldStatus = oldRecord['order_status'];
                final newStatus = newRecord['order_status'];

            // فقط عند تغيير الحالة
            if (oldStatus != newStatus) {
              final orderId = newRecord['order_id'];
              final supplierId = newRecord['supplier_id'];

              // جلب اسم المورد
              String supplierName = 'Supplier #$supplierId';
              try {
                final supplierData = await supabase
                    .from('supplier')
                    .select('name')
                    .eq('supplier_id', supplierId)
                    .single();
                supplierName = supplierData['name'] ?? supplierName;
              } catch (e) {
                // ignore
              }

              String statusText = '';
              if (newStatus == 'accepted') {
                statusText = 'has been accepted';
              } else if (newStatus == 'rejected') {
                statusText = 'has been rejected';
              } else if (newStatus == 'pending') {
                statusText = 'is pending';
              } else if (newStatus == 'completed') {
                statusText = 'has been completed';
              }

                await _notificationService.addNotification(
                  title: 'Supplier order update',
                  message: 'Order #$orderId from $supplierName $statusText',
                  type: 'order',
                );
              }
            } catch (e, stackTrace) {
              print('❌ Error processing supplier order notification:');
              print('Error: $e');
              print('Stack trace: $stackTrace');
            }
          },
        )
        .subscribe();

      _subscriptions.add(channel);
      print('✅ Supplier orders listener subscribed');

      // مراقبة التعديلات على طلبيات الموردين
      print('🔄 Subscribing to supplier_order_description table...');
      final updateChannel = supabase
          .channel('supplier_orders_description_channel')
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'supplier_order_description',
            callback: (payload) async {
              try {
                final orderId = payload.newRecord['order_id'];

                await _notificationService.addNotification(
                  title: 'Supplier update',
                  message: 'Supplier edited order #$orderId',
                  type: 'order',
                );
              } catch (e, stackTrace) {
                print('❌ Error processing supplier order description:');
                print('Error: $e');
                print('Stack trace: $stackTrace');
              }
            },
          )
          .subscribe();

      _subscriptions.add(updateChannel);
      print('✅ Supplier order description listener subscribed');
    } catch (e, stackTrace) {
      print('❌ Cannot listen to supplier orders:');
      print('Error: $e');
      print('Stack trace: $stackTrace');
    }
  }

  // ============== 3. شيكات الزبائن ==============
  void _listenToCustomerChecks() {
    print('🔄 Setting up customer checks monitoring...');
    // مراقبة الشيكات التي باقي 3 أيام
    _checkUpcomingChecks();
    print('✅ Customer checks monitoring setup complete');

    // إعادة الفحص كل يوم
    Future.delayed(const Duration(hours: 24), () {
      if (_isInitialized) {
        _listenToCustomerChecks();
      }
    });
  }

  Future<void> _checkUpcomingChecks() async {
    try {
      final today = DateTime.now();
      final threeDaysLater = today.add(const Duration(days: 3));

      // شيكات الزبائن
      final customerChecks = await supabase
          .from('customer_checks')
          .select('check_id, customer_id, exchange_rate, exchange_date')
          .eq('status', 'pending')
          .gte('exchange_date', today.toIso8601String().split('T')[0])
          .lte('exchange_date', threeDaysLater.toIso8601String().split('T')[0]);

      for (var check in customerChecks) {
        final exchangeDate = DateTime.parse(check['exchange_date']);
        final daysRemaining = exchangeDate.difference(today).inDays;

        if (daysRemaining == 0) {
          // شيك اليوم
          await _notificationService.addNotification(
            title: 'Check due today',
            message:
                'Check #${check['check_id']} for \$${check['exchange_rate']} must be cashed today',
            type: 'payment',
          );
        } else if (daysRemaining <= 3) {
          // شيك باقي 3 أيام أو أقل
          await _notificationService.addNotification(
            title: 'Check cash reminder',
            message:
                'Check #${check['check_id']} for \$${check['exchange_rate']} is due in $daysRemaining day(s)',
            type: 'payment',
          );
        }
      }

      // شيكات الموردين
      final supplierChecks = await supabase
          .from('supplier_checks')
          .select('check_id, supplier_id, exchange_rate, exchange_date')
          .eq('status', 'pending')
          .gte('exchange_date', today.toIso8601String().split('T')[0])
          .lte('exchange_date', threeDaysLater.toIso8601String().split('T')[0]);

      for (var check in supplierChecks) {
        final exchangeDate = DateTime.parse(check['exchange_date']);
        final daysRemaining = exchangeDate.difference(today).inDays;

        if (daysRemaining == 0) {
          await _notificationService.addNotification(
            title: 'Supplier check due today',
            message:
                'Check #${check['check_id']} for \$${check['exchange_rate']} must be cashed today',
            type: 'payment',
          );
        } else if (daysRemaining <= 3) {
          await _notificationService.addNotification(
            title: 'Supplier check cash reminder',
            message:
                'Check #${check['check_id']} for \$${check['exchange_rate']} is due in $daysRemaining day(s)',
            type: 'payment',
          );
        }
      }
    } catch (e) {
      // ignore error
    }
  }

  void _listenToSupplierChecks() {
    try {
      print('🔄 Subscribing to supplier_checks table...');
      final channel = supabase
          .channel('supplier_checks_channel')
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'supplier_checks',
            callback: (payload) async {
              try {
            final oldStatus = payload.oldRecord['status'];
            final newStatus = payload.newRecord['status'];

            if (oldStatus != newStatus && newStatus == 'cashed') {
              final checkId = payload.newRecord['check_id'];
              final amount = payload.newRecord['exchange_rate'];

                await _notificationService.addNotification(
                  title: 'Check cashed',
                  message: 'Check #$checkId for \$${amount ?? "0"} has been cashed',
                  type: 'payment',
                );
              }
            } catch (e, stackTrace) {
              print('❌ Error processing supplier check notification:');
              print('Error: $e');
              print('Stack trace: $stackTrace');
            }
          },
        )
        .subscribe();

      _subscriptions.add(channel);
      print('✅ Supplier checks listener subscribed');
    } catch (e, stackTrace) {
      print('❌ Cannot listen to supplier checks:');
      print('Error: $e');
      print('Stack trace: $stackTrace');
    }
  }

  // ============== 4. تعديلات الطلبيات ==============
  void _listenToOrderUpdates() {
    try {
      print('🔄 Subscribing to customer_order updates...');
      final channel = supabase
          .channel('customer_order_updates_channel')
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'customer_order',
            callback: (payload) async {
              try {
            final oldRecord = payload.oldRecord;
            final newRecord = payload.newRecord;

            // التحقق من التعديلات
            final updateAction = newRecord['update_action'];
            final updateDescription = newRecord['update_description'];

            if (updateAction != null && updateAction.toString().isNotEmpty) {
              final orderId = newRecord['customer_order_id'];
              final managedBy = newRecord['managed_by_id'];

              String message = 'Order #$orderId was updated';
              if (updateDescription != null &&
                  updateDescription.toString().isNotEmpty) {
                message += ': $updateDescription';
              }

              await _notificationService.addNotification(
                title: 'Manager order update',
                message: message,
                type: 'order',
              );
            }

            // التحقق من تغيير حالة الطلبية (قبول أو رفض من الزبون)
            final oldStatus = oldRecord['order_status'];
            final newStatus = newRecord['order_status'];

            if (oldStatus != newStatus) {
              final orderId = newRecord['customer_order_id'];

              String statusText = '';
              if (newStatus == 'accepted') {
                statusText = 'accepted';
              } else if (newStatus == 'rejected') {
                statusText = 'rejected';
              } else if (newStatus == 'cancelled') {
                statusText = 'cancelled';
              }

              if (statusText.isNotEmpty) {
                await _notificationService.addNotification(
                  title: 'Order status update',
                  message: 'Order #$orderId was $statusText by the customer',
                  type: 'order',
                  );
                }
              }
            } catch (e, stackTrace) {
              print('❌ Error processing order update notification:');
              print('Error: $e');
              print('Stack trace: $stackTrace');
            }
          },
        )
        .subscribe();

      _subscriptions.add(channel);
      print('✅ Order updates listener subscribed');
    } catch (e, stackTrace) {
      print('❌ Cannot listen to order updates:');
      print('Error: $e');
      print('Stack trace: $stackTrace');
    }
  }

  // ============== 5. مراقبة المخزون المنخفض ==============
  void _listenToLowStock() {
    try {
      print('🔄 Subscribing to product table for low stock alerts...');
      final channel = supabase
          .channel('product_stock_channel')
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'product',
            callback: (payload) async {
              try {
            final newRecord = payload.newRecord;
            final totalQuantity = newRecord['total_quantity'] as int?;
            final minimumStock = newRecord['minimum_stock'] as int?;
            final productName = newRecord['name'];
            final productId = newRecord['product_id'];

            if (totalQuantity != null &&
                minimumStock != null &&
                totalQuantity <= minimumStock) {
              await _notificationService.addNotification(
                title: 'Low stock alert',
                message:
                    'Product "$productName" (#$productId) reached the minimum: $totalQuantity of $minimumStock',
                  type: 'system',
                );
              }
            } catch (e, stackTrace) {
              print('❌ Error processing low stock notification:');
              print('Error: $e');
              print('Stack trace: $stackTrace');
            }
          },
        )
        .subscribe();

      _subscriptions.add(channel);
      print('✅ Low stock listener subscribed');
    } catch (e, stackTrace) {
      print('❌ Cannot listen to low stock:');
      print('Error: $e');
      print('Stack trace: $stackTrace');
    }
  }

  // ============== دوال مساعدة لإرسال إشعارات يدوية ==============

  /// إرسال إشعار عند إضافة طلبية جديدة
  Future<void> notifyNewCustomerOrder(
    int orderId,
    String customerName,
    double totalCost,
  ) async {
    await _notificationService.addNotification(
      title: 'New order',
      message:
          'Order #$orderId from $customerName with total \$${totalCost.toStringAsFixed(2)}',
      type: 'order',
    );
  }

  /// إرسال إشعار عند تغيير حالة طلبية مورد
  Future<void> notifySupplierOrderStatusChange(
    int orderId,
    String supplierName,
    String status,
  ) async {
    String statusText = '';
    if (status == 'accepted') {
      statusText = 'has been accepted';
    } else if (status == 'rejected') {
      statusText = 'has been rejected';
    }

    await _notificationService.addNotification(
      title: 'Supplier order update',
      message: 'Order #$orderId from $supplierName $statusText',
      type: 'order',
    );
  }

  /// إرسال إشعار عند اقتراب موعد صرف شيك
  Future<void> notifyCheckDueDate(
    int checkId,
    double amount,
    int daysRemaining,
    bool isCustomerCheck,
  ) async {
    final checkType = isCustomerCheck ? '' : '(supplier)';

    if (daysRemaining == 0) {
      await _notificationService.addNotification(
        title: 'Check due today $checkType',
        message: 'Check #$checkId for \$${amount.toStringAsFixed(2)} must be cashed today',
        type: 'payment',
      );
    } else {
      await _notificationService.addNotification(
        title: 'Check cash reminder $checkType',
        message:
            'Check #$checkId for \$${amount.toStringAsFixed(2)} is due in $daysRemaining day(s)',
        type: 'payment',
      );
    }
  }

  /// إرسال إشعار عند انخفاض المخزون
  Future<void> notifyLowStock(
    int productId,
    String productName,
    int currentQuantity,
    int minimumQuantity,
  ) async {
    await _notificationService.addNotification(
      title: 'Low stock alert',
      message:
          'Product "$productName" (#$productId) reached the minimum: $currentQuantity of $minimumQuantity',
      type: 'system',
    );
  }

  /// إرسال إشعار عند تعديل طلبية من Manager
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
