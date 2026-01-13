import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../supabase_config.dart';
import '../bottom_navbar.dart';
import 'customer_home_page.dart';
import 'customer_cart_page.dart';
import '../account_page.dart';

class CustomerArchivePage extends StatefulWidget {
  const CustomerArchivePage({super.key});

  @override
  State<CustomerArchivePage> createState() => _CustomerArchivePageState();
}

class _CustomerArchivePageState extends State<CustomerArchivePage> {
  final Color _bg = const Color(0xFF1A1A1A);
  final Color _card = const Color(0xFF2D2D2D);
  final Color _accent = const Color(0xFFF9D949);
  final Color _muted = Colors.white70;
  int _currentIndex = 2;
  bool _isLoading = true;
  List<Map<String, dynamic>> _preparingOrders = [];
  List<Map<String, dynamic>> _deliveredOrders = [];
  List<Map<String, dynamic>> _deliveredOrdersAll = [];
  DateTime? _fromDate;
  DateTime? _toDate;

  void _onNavTap(int i) {
    setState(() => _currentIndex = i);
    if (i == 0) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const CustomerHomePage()));
    } else if (i == 1) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const CustomerCartPage()));
    } else if (i == 2) {
      // stay
    } else if (i == 3) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AccountPage()));
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
      _preparingOrders = [];
      _deliveredOrders = [];
      _deliveredOrdersAll = [];
      _fromDate = null;
      _toDate = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userIdStr = prefs.getString('current_user_id');
      final customerId = userIdStr != null ? int.tryParse(userIdStr) : null;
      if (customerId == null) {
        setState(() => _isLoading = false);
        return;
      }

        const progressStatuses = ['Preparing', 'Prepared', 'Delivery', 'Pinned', 'Received', 'Updated to Customer'];
        final statusListLiteral = '(${progressStatuses.map((s) => '"$s"').join(',')})';

        final preparing = await supabase
          .from('customer_order')
          .select('customer_order_id, order_date, order_status')
          .eq('customer_id', customerId)
          .filter('order_status', 'in', statusListLiteral)
          .order('order_date', ascending: false);
      final prepList = (preparing as List<dynamic>).cast<Map<String, dynamic>>();
      final prepIds = prepList.map<int>((e) => (e['customer_order_id'] as int)).toList();
      Map<int, int> prepCounts = {};
      Map<int, DateTime?> updateTimes = {};
      if (prepIds.isNotEmpty) {
        final prepDesc = await supabase
          .from('customer_order_description')
          .select('customer_order_id, product_id')
          .filter('customer_order_id', 'in', '(${prepIds.join(',')})');
        final descList = (prepDesc as List<dynamic>).cast<Map<String, dynamic>>();
        final Map<int, Set<int>> perOrderProducts = {};
        for (final row in descList) {
          final oid = row['customer_order_id'] as int;
          final pid = row['product_id'] as int;
          perOrderProducts.putIfAbsent(oid, () => <int>{}).add(pid);
        }
        perOrderProducts.forEach((k, v) => prepCounts[k] = v.length);

        final updateDesc = await supabase
            .from('customer_order_description')
            .select('customer_order_id, last_action_time')
            .filter('customer_order_id', 'in', '(${prepIds.join(',')})');
        final updateList = (updateDesc as List<dynamic>).cast<Map<String, dynamic>>();
        for (final row in updateList) {
          final oid = row['customer_order_id'] as int;
          final tsStr = row['last_action_time'] as String?;
          final ts = tsStr != null ? DateTime.tryParse(tsStr) : null;
          if (ts != null) {
            final current = updateTimes[oid];
            if (current == null || ts.isAfter(current)) {
              updateTimes[oid] = ts;
            }
          }
        }
      }
      _preparingOrders = prepList.map<Map<String, dynamic>>((e) {
        final dtStr = e['order_date'] as String?;
        final rawStatus = (e['order_status'] as String?) ?? '';
        DateTime? dt;
        if (rawStatus == 'Updated to Customer') {
          dt = updateTimes[e['customer_order_id']];
        } else {
          dt = dtStr != null ? DateTime.tryParse(dtStr) : null;
        }
        return {
          'id': e['customer_order_id'] as int,
          'count': prepCounts[e['customer_order_id']] ?? 0,
          'dateTime': dt,
          'dateLabel': dt != null ? _formatDate(dt) : '—',
          'statusRaw': rawStatus,
          'statusLabel': _progressStatusLabel(rawStatus),
        };
      }).toList();

      final delivered = await supabase
          .from('customer_order')
          .select('customer_order_id, last_action_time, order_status')
          .eq('customer_id', customerId)
          .eq('order_status', 'Delivered')
          .order('last_action_time', ascending: false);
      final delList = (delivered as List<dynamic>).cast<Map<String, dynamic>>();
      final delIds = delList.map<int>((e) => (e['customer_order_id'] as int)).toList();
      Map<int, int> delCounts = {};
      if (delIds.isNotEmpty) {
        final delDesc = await supabase
          .from('customer_order_description')
          .select('customer_order_id, product_id')
          .filter('customer_order_id', 'in', '(${delIds.join(',')})');
        final descList = (delDesc as List<dynamic>).cast<Map<String, dynamic>>();
        final Map<int, Set<int>> perOrderProducts = {};
        for (final row in descList) {
          final oid = row['customer_order_id'] as int;
          final pid = row['product_id'] as int;
          perOrderProducts.putIfAbsent(oid, () => <int>{}).add(pid);
        }
        perOrderProducts.forEach((k, v) => delCounts[k] = v.length);
      }
      _deliveredOrdersAll = delList.map<Map<String, dynamic>>((e) {
        final dtStr = e['last_action_time'] as String?;
        final dt = dtStr != null ? DateTime.tryParse(dtStr) : null;
        final rawStatus = (e['order_status'] as String?) ?? 'Delivered';
        return {
          'id': e['customer_order_id'] as int,
          'count': delCounts[e['customer_order_id']] ?? 0,
          'dateTime': dt,
          'dateLabel': dt != null ? _formatDate(dt) : '—',
          'statusRaw': rawStatus,
          'statusLabel': rawStatus,
        };
      }).toList();

      final filteredDelivered = _filterDeliveredByDateRange(_fromDate, _toDate, _deliveredOrdersAll);

      setState(() {
        _deliveredOrders = filteredDelivered;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching orders: $e');
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _formatTime(DateTime dt) {
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  String _progressStatusLabel(String? rawStatus) {
    if (rawStatus != null && rawStatus == 'Updated to Customer') {
      return 'Update';
    }
    return 'In progress';
  }

  List<Map<String, dynamic>> _filterDeliveredByDateRange(DateTime? fromDate, DateTime? toDate, List<Map<String, dynamic>> source) {
    if (fromDate == null && toDate == null) {
      return List<Map<String, dynamic>>.from(source);
    }
    
    return source.where((order) {
      final dt = order['dateTime'] as DateTime?;
      if (dt == null) return false;
      final orderDay = DateTime(dt.year, dt.month, dt.day);
      
      if (fromDate != null && toDate != null) {
        final fromDay = DateTime(fromDate.year, fromDate.month, fromDate.day);
        final toDay = DateTime(toDate.year, toDate.month, toDate.day);
        return !orderDay.isBefore(fromDay) && !orderDay.isAfter(toDay);
      } else if (fromDate != null) {
        final fromDay = DateTime(fromDate.year, fromDate.month, fromDate.day);
        return !orderDay.isBefore(fromDay);
      } else if (toDate != null) {
        final toDay = DateTime(toDate.year, toDate.month, toDate.day);
        return !orderDay.isAfter(toDay);
      }
      return true;
    }).toList();
  }

  Future<void> _pickFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: _toDate ?? DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _fromDate = picked;
        _deliveredOrders = _filterDeliveredByDateRange(_fromDate, _toDate, _deliveredOrdersAll);
      });
    }
  }

  Future<void> _pickToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? DateTime.now(),
      firstDate: _fromDate ?? DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _toDate = picked;
        _deliveredOrders = _filterDeliveredByDateRange(_fromDate, _toDate, _deliveredOrdersAll);
      });
    }
  }

  void _clearDateFilter() {
    if (_fromDate == null && _toDate == null) return;
    setState(() {
      _fromDate = null;
      _toDate = null;
      _deliveredOrders = List<Map<String, dynamic>>.from(_deliveredOrdersAll);
    });
  }

  void _showOrderDetails(Map<String, dynamic> order, {required bool isDelivered}) async {
    final id = order['id'] as int;
    final rawStatus = (order['statusRaw'] as String?) ?? (isDelivered ? 'Delivered' : '');
    final isUpdate = rawStatus == 'Updated to Customer';
    final dateTime = order['dateTime'] as DateTime?;
    final dateLabel = order['dateLabel'] as String? ?? '—';
    final formattedDate = dateTime != null ? '${_formatDate(dateTime)} ${_formatTime(dateTime)}' : dateLabel;

    String updateDescription = '';
    List<Map<String, dynamic>> productDetails = [];
    double totalOrderPrice = 0.0;

    try {
      if (isUpdate) {
        final header = await supabase
            .from('customer_order')
            .select('update_description')
            .eq('customer_order_id', id)
            .maybeSingle();
        updateDescription = (header?['update_description'] as String?) ?? '';

        final orderDescResp = await supabase
            .from('customer_order_description')
            .select(
                'product_id, quantity, updated_quantity, total_price, product:product_id(name, brand:brand_id(name), selling_price)')
            .eq('customer_order_id', id);
        final descList = (orderDescResp as List<dynamic>).cast<Map<String, dynamic>>();

        for (final desc in descList) {
          final productMap = desc['product'] as Map<String, dynamic>?;
          final brandMap = productMap?['brand'] as Map<String, dynamic>?;
          final oldQty = (desc['quantity'] as num?)?.toInt() ?? 0;
          final newQty = (desc['updated_quantity'] as num?)?.toInt() ?? oldQty;
          final totalPrice = (desc['total_price'] as num?)?.toDouble() ?? 0.0;
          final sellingPrice = (productMap?['selling_price'] as num?)?.toDouble() ?? 0.0;
          final unitPrice = oldQty > 0 ? totalPrice / oldQty : sellingPrice;
          final lineTotal = unitPrice * newQty;
          totalOrderPrice += lineTotal;

          productDetails.add({
            'id': desc['product_id'] as int,
            'name': productMap?['name'] as String? ?? 'Unknown',
            'brand': brandMap?['name'] as String? ?? '',
            'oldQty': oldQty,
            'newQty': newQty,
            'unitPrice': unitPrice,
            'lineTotal': lineTotal,
          });
        }
      } else {
        final orderDescResp = await supabase
            .from('customer_order_description')
            .select('product_id, quantity, total_price, product:product_id(name, brand:brand_id(name))')
            .eq('customer_order_id', id);
        final descList = (orderDescResp as List<dynamic>).cast<Map<String, dynamic>>();

        for (final desc in descList) {
          final productMap = desc['product'] as Map<String, dynamic>?;
          final brandMap = productMap?['brand'] as Map<String, dynamic>?;
          final quantity = (desc['quantity'] as num?)?.toInt() ?? 0;
          final totalPrice = (desc['total_price'] as num?)?.toDouble() ?? 0.0;
          totalOrderPrice += totalPrice;

          productDetails.add({
            'name': productMap?['name'] as String? ?? 'Unknown',
            'brand': brandMap?['name'] as String? ?? '',
            'quantity': quantity,
            'totalPrice': totalPrice,
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching product details: $e');
    }

    if (!mounted) return;

    Future<void> _handleUpdateDecision({required bool accept}) async {
      if (!isUpdate) return;
      try {
        final prefs = await SharedPreferences.getInstance();
        final userName = prefs.getString('current_user_name')?.trim();
        final customerName = (userName != null && userName.isNotEmpty) ? userName : 'Customer';
        final now = DateTime.now().toIso8601String();

        if (accept) {
          double newTotal = 0.0;
          for (final product in productDetails) {
            final newQty = product['newQty'] as int;
            final lineTotal = (product['unitPrice'] as double) * newQty;
            newTotal += lineTotal;

            await supabase
                .from('customer_order_description')
                .update({
                  'quantity': newQty,
                  'updated_quantity': null,
                  'total_price': lineTotal,
                  'last_action_by': customerName,
                  'last_action_time': now,
                })
                .eq('customer_order_id', id)
                .eq('product_id', product['id'] as int);
          }

          await supabase
              .from('customer_order')
              .update({
                'order_status': 'Pinned',
                'update_action': 'accepted by $customerName',
                'last_action_by': customerName,
                'last_action_time': now,
                'total_balance': newTotal,
              })
              .eq('customer_order_id', id);
        } else {
          await supabase
              .from('customer_order')
              .update({
                'order_status': 'Canceled',
                'update_action': 'rejected by $customerName',
                'last_action_by': customerName,
                'last_action_time': DateTime.now().toIso8601String(),
              })
              .eq('customer_order_id', id);
        }

        await _fetchOrders();
        if (!mounted) return;
        Navigator.pop(context);
      } catch (e) {
        debugPrint('Error handling update decision: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to process update: $e')),
        );
      }
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Dialog(
            backgroundColor: _card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 520, maxHeight: 640),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Order #$id',
                    style: TextStyle(color: _accent, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isDelivered ? 'Delivered: $formattedDate' : formattedDate,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  if (isUpdate && updateDescription.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Update Description', style: TextStyle(color: _accent, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        updateDescription,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            'Product',
                            style: TextStyle(color: _accent, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            isUpdate ? 'Old Qty' : 'Quantity',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: _accent, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            isUpdate ? 'New Qty' : 'Total Price',
                            textAlign: TextAlign.right,
                            style: TextStyle(color: _accent, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Flexible(
                    child: productDetails.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Text(
                              'No products',
                              style: TextStyle(color: Colors.white70),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: productDetails.length,
                            itemBuilder: (context, idx) {
                              final product = productDetails[idx];
                              return Container(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A1A1A),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product['name'],
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                          if ((product['brand'] as String).isNotEmpty)
                                            Text(
                                              product['brand'],
                                              style: const TextStyle(
                                                color: Colors.white54,
                                                fontSize: 11,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        isUpdate ? '${product['oldQty']}' : '${product['quantity']}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        isUpdate
                                            ? '${product['newQty']}'
                                            : (product['totalPrice'] as double).toStringAsFixed(2),
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isUpdate ? 'New Total Price:' : 'Total Price:',
                          style: TextStyle(
                            color: _accent,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          totalOrderPrice.toStringAsFixed(2),
                          style: TextStyle(
                            color: _accent,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isUpdate) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _handleUpdateDecision(accept: true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Accept'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _handleUpdateDecision(accept: false),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Reject'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFF9D949)))
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sended Orders', style: TextStyle(color: _accent, fontSize: 34, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    if (_preparingOrders.isEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16)),
                        child: const Text('No preparing orders', style: TextStyle(color: Colors.white70)),
                      )
                    else
                      ListView.builder(
                        itemCount: _preparingOrders.length,
                        padding: const EdgeInsets.only(bottom: 6),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, idx) {
                          final item = _preparingOrders[idx];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: GestureDetector(
                              onTap: () => _showOrderDetails(item, isDelivered: false),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: _card,
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.25),
                                          blurRadius: 1,
                                          spreadRadius: 1,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                                      child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: const [
                                          Text('ID #', style: TextStyle(color: Color(0xFFF9D949), fontSize: 14, fontWeight: FontWeight.w600)),
                                          SizedBox(width: 34),
                                          Text('Status', style: TextStyle(color: Color(0xFFF9D949), fontSize: 14, fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Text('${item['id']}',
                                              style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.bold)),
                                          const SizedBox(width: 28),
                                          Expanded(
                                            child: Text(item['statusLabel'] as String,
                                                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
                                          ),
                                          const SizedBox(width: 16),
                                          Container(
                                            width: 84,
                                            height: 64,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF262626),
                                              borderRadius: BorderRadius.circular(18),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.only(bottom: 4),
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text('${item['count']}',
                                                      style: const TextStyle(color: Color(0xFFFFEFFF), fontSize: 25, fontWeight: FontWeight.bold)),
                                                  const SizedBox(height: 3),
                                                  const Text('products',
                                                      style: TextStyle(color: Color(0xFFF9D949), fontSize: 14, fontWeight: FontWeight.w500)),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (item['statusRaw'] == 'Updated to Customer')
                                Positioned(
                                  top: -4,
                                  right: -4,
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: _accent,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: _accent.withOpacity(0.5),
                                          blurRadius: 4,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 22),
                    Text('Archive', style: TextStyle(color: _accent, fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _pickFromDate,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(12)),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _fromDate == null ? 'From date' : _formatDate(_fromDate!),
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(Icons.calendar_today, color: _accent, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: _pickToDate,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(12)),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _toDate == null ? 'To date' : _formatDate(_toDate!),
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(Icons.calendar_today, color: _accent, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (_fromDate != null || _toDate != null) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _clearDateFilter,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(12)),
                              child: Icon(Icons.close, color: _accent, size: 18),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text('Order ID#', style: TextStyle(color: _muted, fontWeight: FontWeight.w700)),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text('# of product', style: TextStyle(color: _muted, fontWeight: FontWeight.w700)),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text('Date', style: TextStyle(color: _accent, fontWeight: FontWeight.w800), textAlign: TextAlign.right),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(color: Colors.white24, thickness: 1),
                    const SizedBox(height: 8),
                    ListView.builder(
                      itemCount: _deliveredOrders.length,
                      padding: const EdgeInsets.only(bottom: 12),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, idx) {
                        final item = _deliveredOrders[idx];
                        return GestureDetector(
                          onTap: () => _showOrderDetails(item, isDelivered: true),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text('${item['id']}',
                                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text('${item['count']}',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(item['dateLabel'] as String,
                                      textAlign: TextAlign.right,
                                      style: TextStyle(color: _accent, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: _currentIndex, onTap: _onNavTap),
    );
  }
}