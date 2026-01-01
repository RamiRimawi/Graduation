import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../supabase_config.dart';
import '../bottom_navbar.dart';
import 'salesRep_home_page.dart';
import 'salesRep_cart_page.dart';
import 'salesRep_customers_page.dart';
import '../account_page.dart';

class SalesRepArchivePage extends StatefulWidget {
  const SalesRepArchivePage({super.key});

  @override
  State<SalesRepArchivePage> createState() => _SalesRepArchivePageState();
}

class _SalesRepArchivePageState extends State<SalesRepArchivePage> {
  final Color _bg = const Color(0xFF1A1A1A);
  final Color _card = const Color(0xFF2D2D2D);
  final Color _accent = const Color(0xFFF9D949);
  final Color _muted = Colors.white70;
  int _currentIndex = 2;
  bool _isLoading = true;
  List<Map<String, dynamic>> _preparingOrders = [];
  List<Map<String, dynamic>> _deliveredOrders = [];
  List<Map<String, dynamic>> _deliveredOrdersAll = [];
  DateTime? _selectedDate;

  void _onNavTap(int i) {
    setState(() => _currentIndex = i);
    if (i == 0) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SalesRepHomePage()));
    } else if (i == 1) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SalesRepCartPage()));
    } else if (i == 2) {
      // stay
    } else if (i == 3) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SalesRepCustomersPage()));
    } else if (i == 4) {
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
      _selectedDate = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userIdStr = prefs.getString('current_user_id');
      final salesRepId = userIdStr != null ? int.tryParse(userIdStr) : null;
      if (salesRepId == null) {
        setState(() => _isLoading = false);
        return;
      }

        const progressStatuses = ['Preparing', 'Prepared', 'Delivery', 'Pinned', 'Received'];
        final statusListLiteral = '(${progressStatuses.map((s) => '"$s"').join(',')})';

        final preparing = await supabase
          .from('customer_order')
          .select('customer_order_id, order_date, order_status')
          .eq('sales_rep_id', salesRepId)
          .filter('order_status', 'in', statusListLiteral)
          .order('order_date', ascending: false);
      final prepList = (preparing as List<dynamic>).cast<Map<String, dynamic>>();
      final prepIds = prepList.map<int>((e) => (e['customer_order_id'] as int)).toList();
      Map<int, int> prepCounts = {};
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
      }
      _preparingOrders = prepList.map<Map<String, dynamic>>((e) {
        final dtStr = e['order_date'] as String?;
        final dt = dtStr != null ? DateTime.tryParse(dtStr) : null;
        final rawStatus = (e['order_status'] as String?) ?? '';
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
          .eq('sales_rep_id', salesRepId)
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

      final filteredDelivered = _filterDeliveredByDate(_selectedDate, _deliveredOrdersAll);

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
    if (rawStatus == null) return 'In progress';
    final lower = rawStatus.toLowerCase();
    if (lower.startsWith('receiv')) return 'Sent';
    return 'In progress';
  }

  List<Map<String, dynamic>> _filterDeliveredByDate(DateTime? startDate, List<Map<String, dynamic>> source) {
    if (startDate == null) {
      return List<Map<String, dynamic>>.from(source);
    }
    final startDay = DateTime(startDate.year, startDate.month, startDate.day);
    return source.where((order) {
      final dt = order['dateTime'] as DateTime?;
      if (dt == null) return false;
      final orderDay = DateTime(dt.year, dt.month, dt.day);
      return !orderDay.isBefore(startDay);
    }).toList();
  }

  Future<void> _pickDateFilter() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _deliveredOrders = _filterDeliveredByDate(_selectedDate, _deliveredOrdersAll);
      });
    }
  }

  void _clearDateFilter() {
    if (_selectedDate == null) return;
    setState(() {
      _selectedDate = null;
      _deliveredOrders = List<Map<String, dynamic>>.from(_deliveredOrdersAll);
    });
  }

  void _showOrderDetails(Map<String, dynamic> order, {required bool isDelivered}) async {
    final id = order['id'] as int;
    final count = order['count'] ?? 0;
    final rawStatus = (order['statusRaw'] as String?) ?? (isDelivered ? 'Delivered' : '');
    final statusLabel = isDelivered ? (rawStatus.isNotEmpty ? rawStatus : 'Delivered') : (order['statusLabel'] as String? ?? 'In progress');
    final dateTime = order['dateTime'] as DateTime?;
    final dateLabel = order['dateLabel'] as String? ?? '—';
    final formattedDate = dateTime != null ? '${_formatDate(dateTime)} ${_formatTime(dateTime)}' : dateLabel;

    // Fetch product details for this order
    List<Map<String, dynamic>> productDetails = [];
    try {
      final orderDescResp = await supabase
          .from('customer_order_description')
          .select('product_id, quantity')
          .eq('customer_order_id', id);
      final descList = (orderDescResp as List<dynamic>).cast<Map<String, dynamic>>();
      
      for (final desc in descList) {
        final productId = desc['product_id'] as int;
        final quantity = desc['quantity'] as int?;
        final productResp = await supabase
            .from('product')
            .select('name')
            .eq('product_id', productId)
            .maybeSingle();
        
        if (productResp != null) {
          productDetails.add({
            'name': productResp['name'] as String? ?? 'Unknown',
            'quantity': quantity ?? 0,
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching product details: $e');
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    'Order #$id',
                    style: TextStyle(color: _accent, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 14),
                _detailRow('Status', statusLabel),
                const SizedBox(height: 10),
                if (productDetails.isNotEmpty) ...
                  [
                    const Text('Products:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    ...productDetails.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final product = entry.value;
                      return Column(
                        children: [
                          _detailRow('product${idx + 1}', product['name']),
                          const SizedBox(height: 4),
                          _detailRow('Quantity', '${product['quantity']}'),
                          const SizedBox(height: 10),
                        ],
                      );
                    }),
                  ]
                else
                  ...
                  [
                    const Text('No products', style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 10),
                  ],
                _detailRow('Date', formattedDate),
              ],
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
                              child: Container(
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
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                                            height: 84,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF262626),
                                              borderRadius: BorderRadius.circular(18),
                                            ),
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
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: Text('Archive', style: TextStyle(color: _accent, fontSize: 28, fontWeight: FontWeight.bold)),
                        ),
                        GestureDetector(
                          onTap: _pickDateFilter,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              children: [
                                Text(_selectedDate == null ? 'Select date' : _formatDate(_selectedDate!),
                                    style: const TextStyle(color: Colors.white)),
                                const SizedBox(width: 6),
                                Icon(Icons.calendar_today, color: _accent, size: 18),
                              ],
                            ),
                          ),
                        ),
                        if (_selectedDate != null) ...[
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
