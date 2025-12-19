import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../supabase_config.dart';
import '../bottom_navbar.dart';
import 'customer_home_page.dart';
import 'customer_cart_page.dart';
import '../account_page.dart';

class CustomerArchivePage extends StatefulWidget {
  const CustomerArchivePage({Key? key}) : super(key: key);

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
  bool _sortAscending = false;

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
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userIdStr = prefs.getString('current_user_id');
      final customerId = userIdStr != null ? int.tryParse(userIdStr) : null;
      if (customerId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final preparing = await supabase
          .from('customer_order')
          .select('customer_order_id, order_date')
          .eq('customer_id', customerId)
          .eq('order_status', 'Preparing')
          .order('order_date', ascending: false);
      final prepList = (preparing as List<dynamic>).cast<Map<String, dynamic>>();
      final prepIds = prepList.map<int>((e) => (e['customer_order_id'] as int)).toList();
      Map<int, int> prepCounts = {};
      if (prepIds.isNotEmpty) {
        final prepDesc = await supabase
          .from('customer_order_description')
          .select('customer_order_id, product_id')
          .filter('customer_order_id', 'in', prepIds);
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
        return {
          'id': e['customer_order_id'] as int,
          'count': prepCounts[e['customer_order_id']] ?? 0,
          'date': dt != null ? _formatDate(dt) : '—',
          'status': 'Preparing',
        };
      }).toList();

      final delivered = await supabase
          .from('customer_order')
          .select('customer_order_id, last_action_time')
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
          .filter('customer_order_id', 'in', delIds);
        final descList = (delDesc as List<dynamic>).cast<Map<String, dynamic>>();
        final Map<int, Set<int>> perOrderProducts = {};
        for (final row in descList) {
          final oid = row['customer_order_id'] as int;
          final pid = row['product_id'] as int;
          perOrderProducts.putIfAbsent(oid, () => <int>{}).add(pid);
        }
        perOrderProducts.forEach((k, v) => delCounts[k] = v.length);
      }
      _deliveredOrders = delList.map<Map<String, dynamic>>((e) {
        final dtStr = e['last_action_time'] as String?;
        final dt = dtStr != null ? DateTime.tryParse(dtStr) : null;
        return {
          'id': e['customer_order_id'] as int,
          'count': delCounts[e['customer_order_id']] ?? 0,
          'date': dt != null ? _formatDate(dt) : '—',
          'status': 'Delivered',
        };
      }).toList();

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error fetching orders: $e');
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  void _toggleDateSort() {
    setState(() {
      _sortAscending = !_sortAscending;
      _deliveredOrders.sort((a, b) {
        final dateA = a['date'] as String;
        final dateB = b['date'] as String;
        final comparison = dateA.compareTo(dateB);
        return _sortAscending ? comparison : -comparison;
      });
    });
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
                                          child: Text('Preparing',
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
                          onTap: _toggleDateSort,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              children: [
                                const Text('Date', style: TextStyle(color: Colors.white)),
                                const SizedBox(width: 6),
                                Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward, color: _accent, size: 18),
                              ],
                            ),
                          ),
                        ),
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
                        return Container(
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
                                child: Text(item['date'] as String,
                                    textAlign: TextAlign.right,
                                    style: TextStyle(color: _accent, fontWeight: FontWeight.bold)),
                              ),
                            ],
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