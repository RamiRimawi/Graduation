import 'package:flutter/material.dart';
import '../bottom_navbar.dart';
import 'customer_home_page.dart';
import 'customer_archive_page.dart';
import '../account_page.dart';

class CustomerCartPage extends StatefulWidget {
  const CustomerCartPage({Key? key}) : super(key: key);

  @override
  State<CustomerCartPage> createState() => _CustomerCartPageState();
}

class _CustomerCartPageState extends State<CustomerCartPage> {
  // sample in-memory cart data (replace with your real data)
  final List<Map<String, dynamic>> _items = [
    {'name': 'Hand Shower', 'brand': 'GROHE', 'price': 200.0, 'qty': 1},
    {'name': 'Hand Shower', 'brand': 'GROHE', 'price': 200.0, 'qty': 1},
    {'name': 'Hand Shower', 'brand': 'GROHE', 'price': 200.0, 'qty': 1},
    {'name': 'Hand Shower', 'brand': 'GROHE', 'price': 200.0, 'qty': 1},
    {'name': 'Hand Shower', 'brand': 'GROHE', 'price': 200.0, 'qty': 1},
  ];

  int _currentIndex = 1; // Cart tab index

  Color get _bg => const Color(0xFF1A1A1A);
  Color get _card => const Color(0xFF2D2D2D);
  Color get _accent => const Color(0xFFB7A447); // yellow pill
  Color get _muted => Colors.white70;

  double get _total {
    return _items.fold(0.0, (s, i) => s + (i['price'] as double) * (i['qty'] as int));
  }

  void _increaseQty(int index) {
    setState(() {
      _items[index]['qty'] = (_items[index]['qty'] as int) + 1;
    });
  }

  void _decreaseQty(int index) {
    setState(() {
      final current = _items[index]['qty'] as int;
      if (current > 1) _items[index]['qty'] = current - 1;
    });
  }

  void _sendOrder() {
    // implement sending order logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Order sent (demo)')),
    );
  }

  // ========== Edit quantity dialog (similar to OrderDetailsPage) ==========
  void _editQuantity(int index) {
    final controller = TextEditingController(text: '${_items[index]['qty']}');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2D2D2D),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            "Edit Quantity",
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: "Enter quantity",
              hintStyle: TextStyle(color: Colors.white70),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFB7A447))),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () {
                final val = int.tryParse(controller.text);
                if (val != null && val > 0) {
                  setState(() {
                    _items[index]['qty'] = val;
                  });
                }
                Navigator.pop(context);
              },
              child: const Text("Save", style: TextStyle(color: Color(0xFFB7A447))),
            ),
          ],
        );
      },
    );
  }

  // ===== navigation handler for bottom bar (Customer layout indices) =====
  void _onNavTap(int i) {
    setState(() => _currentIndex = i);

    if (i == 0) {
      // Home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CustomerHomePage()),
      );
    } else if (i == 1) {
      // Cart (this page) - replace to refresh / keep behavior consistent
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CustomerCartPage()),
      );
    } else if (i == 2) {
      // Archive
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CustomerArchivePage()),
      );
    } else if (i == 3) {
      // Account (shared)
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
        child: Column(
          children: [
            const SizedBox(height: 12),

            // Header labels row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  Row(
                    children: const [
                      Expanded(flex: 3, child: Text('Name', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
                      Expanded(flex: 2, child: Text('Brand', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
                      Expanded(flex: 2, child: Text('Price', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
                      SizedBox(width: 86, child: Text('Quantity', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFF9D949), fontWeight: FontWeight.w700))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(color: Colors.white24, thickness: 1),
                ],
              ),
            ),

            // Product list
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: ListView.separated(
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final item = _items[i];
                    return Container(
                      decoration: BoxDecoration(
                        color: _card,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          // Name (two lines)
                          Expanded(
                            flex: 3,
                            child: Text(
                              item['name'] as String,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                            ),
                          ),

                          // Brand
                          Expanded(
                            flex: 2,
                            child: Text(
                              item['brand'] as String,
                              style: TextStyle(color: _muted, fontWeight: FontWeight.w700),
                              textAlign: TextAlign.left,
                            ),
                          ),

                          // Price
                          Expanded(
                            flex: 2,
                            child: Text(
                              '${(item['price'] as double).toStringAsFixed(0)}\$',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                              textAlign: TextAlign.left,
                            ),
                          ),

                          // Quantity pill + unit (tappable)
                          SizedBox(
                            width: 86,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap: () => _editQuantity(i),
                                  child: Container(
                                    width: 44,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: _accent,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '${item['qty']}',
                                      style: const TextStyle(
                                        color: Color(0xFF202020),
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text('cm', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            // Spacer to visually match screenshot
            const SizedBox(height: 18),

            // Total price
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Tolat Price : ${_formatNumber(_total)}\$',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Send Order button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0),
              child: SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _sendOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      SizedBox(width: 12),
                      Text(
                        'S e n d   O r d e r',
                        style: TextStyle(color: Color(0xFF202020), fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 2),
                      ),
                      SizedBox(width: 12),
                      Icon(Icons.send, color: Color(0xFF202020)),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),

      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }

  String _formatNumber(double v) {
    // simple thousands separator
    final parts = v.toInt().toString().split('').reversed.toList();
    final out = <String>[];
    for (var i = 0; i < parts.length; i++) {
      if (i != 0 && i % 3 == 0) out.add(',');
      out.add(parts[i]);
    }
    return out.reversed.join();
  }
}