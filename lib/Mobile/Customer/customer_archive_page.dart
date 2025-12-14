import 'package:flutter/material.dart';
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
  int _currentIndex = 2; // Archive / Orders tab index for customer layout

  // demo data
  final List<Map<String, String>> _orders = [
    {'id': '5', 'count': '5', 'date': '8/6/2025'},
    {'id': '6', 'count': '13', 'date': '8/6/2025'},
    {'id': '26', 'count': '2', 'date': '8/6/2025'},
    {'id': '32', 'count': '4', 'date': '8/6/2025'},
    {'id': '50', 'count': '6', 'date': '8/6/2025'},
  ];

  void _onNavTap(int i) {
    setState(() => _currentIndex = i);
    if (i == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CustomerHomePage()),
      );
    } else if (i == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CustomerCartPage()),
      );
    } else if (i == 2) {
      // already on Archive
    } else if (i == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AccountPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== Sended Orders header + card =====
              Text(
                'Sended Orders',
                style: TextStyle(
                  color: _accent,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Container(
                margin: const EdgeInsets.only(bottom: 15),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    // ID
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('ID #', style: TextStyle(color: Color(0xFFF9D949))),
                        Text('8',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),

                    const SizedBox(width: 20),

                    // Status
                    Expanded(
                      child: Column(
                        children: const [
                          Text('Status',
                              style: TextStyle(color: Color(0xFFF9D949))),
                          Text(
                            'IN Progress',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                        ],
                      ),
                    ),

                    // Product count box
                    Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Color(0xFFF9D949), width: 1),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text('5',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold)),
                          Text('Product',
                              style: TextStyle(
                                  color: Color(0xFFF9D949), fontSize: 10)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // ===== Archive header + date selector =====
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Archive',
                      style: TextStyle(
                        color: _accent,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // date dropdown-like pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _card,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: const [
                        Text('8/6/2025', style: TextStyle(color: Colors.white)),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_drop_down, color: Colors.white70),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // table header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Order ID#',
                        style: TextStyle(color: _muted, fontWeight: FontWeight.w700),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '# of product',
                        style: TextStyle(color: _muted, fontWeight: FontWeight.w700),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Date',
                        style: TextStyle(color: _accent, fontWeight: FontWeight.w800),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),
              const Divider(color: Colors.white24, thickness: 1),
              const SizedBox(height: 8),

              // ===== Archive list =====
              ListView.builder(
                itemCount: _orders.length,
                padding: const EdgeInsets.only(bottom: 12),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, idx) {
                  final item = _orders[idx];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: _card,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            item['id']!,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            item['count']!,
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            item['date']!,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: _accent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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

      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }
}