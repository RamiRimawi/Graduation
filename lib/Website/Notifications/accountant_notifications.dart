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

  /// تفعيل المراقبة لجميع الإشعارات
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _notificationService.initialize();

    // 1. مراقبة الطلبيات الجديدة من الزبائن
    _listenToCustomerOrders();

    // 2. مراقبة طلبيات الموردين
    _listenToSupplierOrders();

    // 3. مراقبة الشيكات
    _listenToCustomerChecks();
    _listenToSupplierChecks();

    // 4. مراقبة تعديلات الطلبيات
    _listenToOrderUpdates();

    // 5. مراقبة المخزون
    _listenToLowStock();

    _isInitialized = true;
  }

  /// إيقاف جميع الاشتراكات
  void dispose() {
    for (var subscription in _subscriptions) {
      supabase.removeChannel(subscription);
    }
    _subscriptions.clear();
    _isInitialized = false;
  }

  // ============== 1. طلبيات جديدة من الزبائن ==============
  void _listenToCustomerOrders() {
    final channel = supabase
        .channel('customer_orders_channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'customer_order',
          callback: (payload) async {
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
              // ignore
            }

            await _notificationService.addNotification(
              title: 'طلبية جديدة',
              message:
                  'طلبية رقم #$orderId من $customerName بقيمة \$${totalCost?.toStringAsFixed(2) ?? "0"}',
              type: 'order',
            );
          },
        )
        .subscribe();

    _subscriptions.add(channel);
  }

  // ============== 2. طلبيات الموردين ==============
  void _listenToSupplierOrders() {
    final channel = supabase
        .channel('supplier_orders_channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'supplier_order',
          callback: (payload) async {
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
                statusText = 'تم قبول';
              } else if (newStatus == 'rejected') {
                statusText = 'تم رفض';
              } else if (newStatus == 'pending') {
                statusText = 'قيد الانتظار';
              } else if (newStatus == 'completed') {
                statusText = 'تم إكمال';
              }

              await _notificationService.addNotification(
                title: 'تحديث طلبية مورد',
                message: '$statusText طلبية رقم #$orderId من $supplierName',
                type: 'order',
              );
            }
          },
        )
        .subscribe();

    _subscriptions.add(channel);

    // مراقبة التعديلات على طلبيات الموردين
    final updateChannel = supabase
        .channel('supplier_orders_description_channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'supplier_order_description',
          callback: (payload) async {
            final orderId = payload.newRecord['order_id'];

            await _notificationService.addNotification(
              title: 'تعديل من المورد',
              message: 'تم تعديل الطلبية رقم #$orderId من قبل المورد',
              type: 'order',
            );
          },
        )
        .subscribe();

    _subscriptions.add(updateChannel);
  }

  // ============== 3. شيكات الزبائن ==============
  void _listenToCustomerChecks() {
    // مراقبة الشيكات التي باقي 3 أيام
    _checkUpcomingChecks();

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
            title: 'شيك للصرف اليوم',
            message:
                'شيك رقم #${check['check_id']} بقيمة \$${check['exchange_rate']} يجب صرفه اليوم',
            type: 'payment',
          );
        } else if (daysRemaining <= 3) {
          // شيك باقي 3 أيام أو أقل
          await _notificationService.addNotification(
            title: 'تذكير بموعد صرف شيك',
            message:
                'شيك رقم #${check['check_id']} بقيمة \$${check['exchange_rate']} باقي $daysRemaining يوم لصرفه',
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
            title: 'شيك للصرف اليوم (مورد)',
            message:
                'شيك رقم #${check['check_id']} بقيمة \$${check['exchange_rate']} يجب صرفه اليوم',
            type: 'payment',
          );
        } else if (daysRemaining <= 3) {
          await _notificationService.addNotification(
            title: 'تذكير بموعد صرف شيك (مورد)',
            message:
                'شيك رقم #${check['check_id']} بقيمة \$${check['exchange_rate']} باقي $daysRemaining يوم لصرفه',
            type: 'payment',
          );
        }
      }
    } catch (e) {
      // ignore error
    }
  }

  void _listenToSupplierChecks() {
    final channel = supabase
        .channel('supplier_checks_channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'supplier_checks',
          callback: (payload) async {
            final oldStatus = payload.oldRecord['status'];
            final newStatus = payload.newRecord['status'];

            if (oldStatus != newStatus && newStatus == 'cashed') {
              final checkId = payload.newRecord['check_id'];
              final amount = payload.newRecord['exchange_rate'];

              await _notificationService.addNotification(
                title: 'تم صرف شيك',
                message: 'تم صرف الشيك رقم #$checkId بقيمة \$${amount ?? "0"}',
                type: 'payment',
              );
            }
          },
        )
        .subscribe();

    _subscriptions.add(channel);
  }

  // ============== 4. تعديلات الطلبيات ==============
  void _listenToOrderUpdates() {
    final channel = supabase
        .channel('customer_order_updates_channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'customer_order',
          callback: (payload) async {
            final oldRecord = payload.oldRecord;
            final newRecord = payload.newRecord;

            // التحقق من التعديلات
            final updateAction = newRecord['update_action'];
            final updateDescription = newRecord['update_description'];

            if (updateAction != null && updateAction.toString().isNotEmpty) {
              final orderId = newRecord['customer_order_id'];
              final managedBy = newRecord['managed_by_id'];

              String message = 'تم تعديل الطلبية رقم #$orderId';
              if (updateDescription != null &&
                  updateDescription.toString().isNotEmpty) {
                message += ': $updateDescription';
              }

              await _notificationService.addNotification(
                title: 'تعديل طلبية من Manager',
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
                statusText = 'قبول';
              } else if (newStatus == 'rejected') {
                statusText = 'رفض';
              } else if (newStatus == 'cancelled') {
                statusText = 'إلغاء';
              }

              if (statusText.isNotEmpty) {
                await _notificationService.addNotification(
                  title: 'تحديث حالة الطلبية',
                  message: 'تم $statusText الطلبية رقم #$orderId من قبل الزبون',
                  type: 'order',
                );
              }
            }
          },
        )
        .subscribe();

    _subscriptions.add(channel);
  }

  // ============== 5. مراقبة المخزون المنخفض ==============
  void _listenToLowStock() {
    final channel = supabase
        .channel('product_stock_channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'product',
          callback: (payload) async {
            final newRecord = payload.newRecord;
            final totalQuantity = newRecord['total_quantity'] as int?;
            final minimumStock = newRecord['minimum_stock'] as int?;
            final productName = newRecord['name'];
            final productId = newRecord['product_id'];

            if (totalQuantity != null &&
                minimumStock != null &&
                totalQuantity <= minimumStock) {
              await _notificationService.addNotification(
                title: 'تحذير: مخزون منخفض',
                message:
                    'المنتج "$productName" (رقم #$productId) وصل للحد الأدنى: $totalQuantity من $minimumStock',
                type: 'system',
              );
            }
          },
        )
        .subscribe();

    _subscriptions.add(channel);
  }

  // ============== دوال مساعدة لإرسال إشعارات يدوية ==============

  /// إرسال إشعار عند إضافة طلبية جديدة
  Future<void> notifyNewCustomerOrder(
    int orderId,
    String customerName,
    double totalCost,
  ) async {
    await _notificationService.addNotification(
      title: 'طلبية جديدة',
      message:
          'طلبية رقم #$orderId من $customerName بقيمة \$${totalCost.toStringAsFixed(2)}',
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
      statusText = 'تم قبول';
    } else if (status == 'rejected') {
      statusText = 'تم رفض';
    }

    await _notificationService.addNotification(
      title: 'تحديث طلبية مورد',
      message: '$statusText طلبية رقم #$orderId من $supplierName',
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
    final checkType = isCustomerCheck ? '' : '(مورد)';

    if (daysRemaining == 0) {
      await _notificationService.addNotification(
        title: 'شيك للصرف اليوم $checkType',
        message: 'شيك رقم #$checkId بقيمة \$${amount.toStringAsFixed(2)} يجب صرفه اليوم',
        type: 'payment',
      );
    } else {
      await _notificationService.addNotification(
        title: 'تذكير بموعد صرف شيك $checkType',
        message:
            'شيك رقم #$checkId بقيمة \$${amount.toStringAsFixed(2)} باقي $daysRemaining يوم لصرفه',
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
      title: 'تحذير: مخزون منخفض',
      message:
          'المنتج "$productName" (رقم #$productId) وصل للحد الأدنى: $currentQuantity من $minimumQuantity',
      type: 'system',
    );
  }

  /// إرسال إشعار عند تعديل طلبية من Manager
  Future<void> notifyOrderUpdateByManager(
    int orderId,
    String updateDescription,
  ) async {
    await _notificationService.addNotification(
      title: 'تعديل طلبية من Manager',
      message: 'تم تعديل الطلبية رقم #$orderId: $updateDescription',
      type: 'order',
    );
  }
}
