import 'package:flutter/material.dart';
import 'sidebar.dart'; // الملف فيه class SideBar

class CreateStockInPage extends StatefulWidget {
  const CreateStockInPage({super.key});

  @override
  State<CreateStockInPage> createState() => _CreateStockInPageState();
}

class _CreateStockInPageState extends State<CreateStockInPage> {
  String? selectedSupplier;
  int? hoveredIndex; // ✅ لتتبع الصف الذي عليه الماوس

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF202020),
      body: SafeArea(
        child: Row(
          children: [
            const Sidebar(activeIndex: 1),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 35,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ===== HEADER =====
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // زر الرجوع + Supplier + Date & Time
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // زر الرجوع
                            Container(
                              decoration: const BoxDecoration(
                                color: Color(0xFF2D2D2D),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                ),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                            const SizedBox(height: 40),
                            // Supplier + Date & Time
                            Row(
                              children: [
                                // Supplier
                                const Text(
                                  "Supplier :",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  height: 38,
                                  width: 200,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: const Color(0xFFB7A447),
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                    color: const Color(0xFF2D2D2D),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      dropdownColor: const Color(0xFF2D2D2D),
                                      value: selectedSupplier,
                                      hint: const Text(
                                        "Select Supplier",
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                      items: const [
                                        DropdownMenuItem(
                                          value: "Al-Nassar",
                                          child: Text(
                                            "Al-Nassar",
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: "Royal Supply",
                                          child: Text(
                                            "Royal Supply",
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: "Beit Al-Tayeb",
                                          child: Text(
                                            "Beit Al-Tayeb",
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                      onChanged: (value) {},
                                      icon: const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 140),
                                // Date & Time بجانب supplier
                                const Text(
                                  "Date : 18-8-2026",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                const Text(
                                  "Time : 11:00 AM",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Icon(
                          Icons.notifications_none_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ],
                    ),

                    const SizedBox(height: 25),

                    // ===== LINE =====
                    const Divider(color: Colors.white30, thickness: 1),
                    const SizedBox(height: 6),

                    // ===== TABLE SECTION =====
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // TABLE
                          // TABLE
                          Expanded(
                            flex: 10,
                            child: ListView.builder(
                              itemCount: demoData.length + 1,
                              itemBuilder: (context, index) {
                                if (index == 0) {
                                  return Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 10,
                                        ),
                                        child: Row(
                                          children: const [
                                            _HeaderCell(
                                              text: 'Product ID #',
                                              flex: 2,
                                            ),
                                            _HeaderCell(
                                              text: 'Product Name',
                                              flex: 4,
                                            ),
                                            _HeaderCell(text: 'Brand', flex: 3),
                                            _HeaderCell(
                                              text: 'Price per product',
                                              flex: 3,
                                            ),
                                            _HeaderCell(
                                              text: 'Quantity',
                                              flex: 2,
                                            ),
                                            _HeaderCell(
                                              text: 'Total Price',
                                              flex: 3,
                                            ),
                                          ],
                                        ),
                                      ),
                                      // 🔹 خط تحت عناوين الجدول
                                      Container(
                                        height: 1.5,
                                        color: Colors.white24,
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 4,
                                        ),
                                      ),
                                    ],
                                  );
                                }

                                final row = demoData[index - 1];
                                final bgColor = (index % 2 == 0)
                                    ? const Color(0xFF2D2D2D)
                                    : const Color(0xFF262626);

                                // ✅ Hover + الصفوف
                                return MouseRegion(
                                  onEnter: (_) =>
                                      setState(() => hoveredIndex = index),
                                  onExit: (_) =>
                                      setState(() => hoveredIndex = null),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      color: bgColor,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: hoveredIndex == index
                                            ? const Color(0xFF50B2E7)
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: Center(
                                            child: Text(
                                              "${row['id']}",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 4,
                                          child: Center(
                                            child: Text(
                                              row['name'],
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 3,
                                          child: Center(
                                            child: Text(
                                              row['brand'],
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 3,
                                          child: Center(
                                            child: Text(
                                              "${row['price']}\$",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                        // 🔹 عمود الكمية مع المربع الذهبي
                                        Expanded(
                                          flex: 2,
                                          child: Center(
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFB7A447),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    "${row['qty']}",
                                                    style: const TextStyle(
                                                      color: Colors.black,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    "cm",
                                                    style: TextStyle(
                                                      color: Colors.white
                                                          .withOpacity(0.9),
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 3,
                                          child: Center(
                                            child: Text(
                                              "${row['total']}\$",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(width: 40),

                          // BUTTONS
                          Expanded(
                            flex: 3,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const SizedBox(height: 45),
                                _ActionButton(
                                  color: const Color(0xFFB7A447),
                                  icon: Icons.add_box_rounded,
                                  label: 'Add Product',
                                  textColor: Colors.black,
                                  width: 200,
                                ),
                                const SizedBox(height: 25),
                                _ActionButton(
                                  color: const Color(0xFFC34239),
                                  icon: Icons.delete_forever_rounded,
                                  label: 'Remove Product',
                                  textColor: Colors.white,
                                  width: 200,
                                ),
                                const SizedBox(height: 25),
                                _ActionButton(
                                  color: const Color(0xFF4287AD),
                                  icon: Icons.send_rounded,
                                  label: 'Send Order',
                                  textColor: Colors.black,
                                  width: 200,
                                ),
                                const SizedBox(height: 25),
                                _ActionButton(
                                  color: const Color(0xFF6F6F6F),
                                  icon: Icons.pause_circle_filled_rounded,
                                  label: 'Hold',
                                  textColor: Colors.white,
                                  width: 200,
                                ),
                                const SizedBox(height: 40),
                                const Divider(color: Colors.white30),
                                const SizedBox(height: 10),
                                const Text(
                                  'Total Price : 12,566\$',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===== HEADER CELL =====
class _HeaderCell extends StatelessWidget {
  final String text;
  final int flex;
  const _HeaderCell({required this.text, required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ===== ACTION BUTTON =====
class _ActionButton extends StatelessWidget {
  final Color color;
  final Color textColor;
  final IconData icon;
  final String label;
  final double width;

  const _ActionButton({
    required this.color,
    required this.icon,
    required this.label,
    required this.textColor,
    this.width = 220,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(40),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ===== DEMO DATA =====
final List<Map<String, dynamic>> demoData = [
  {
    'id': 26,
    'name': 'Ahmad Nizar',
    'brand': 'GROHE',
    'price': 26,
    'qty': 26,
    'total': 26,
  },
  {
    'id': 27,
    'name': 'Saed Rimawi',
    'brand': 'Royal',
    'price': 150,
    'qty': 310,
    'total': 150,
  },
  {
    'id': 30,
    'name': 'Akef Al Asmar',
    'brand': 'GROHE',
    'price': 200,
    'qty': 30,
    'total': 200,
  },
  {
    'id': 29,
    'name': 'Nizar Fares',
    'brand': 'Royal',
    'price': 25,
    'qty': 324,
    'total': 25,
  },
  {
    'id': 31,
    'name': 'Sameer Haj',
    'brand': 'Royal',
    'price': 10,
    'qty': 31,
    'total': 10,
  },
  {
    'id': 28,
    'name': 'Eyas Barghouthi',
    'brand': 'GROHE',
    'price': 30,
    'qty': 218,
    'total': 30,
  },
  {
    'id': 20,
    'name': 'Sami Jaber',
    'brand': 'GROHE',
    'price': 43,
    'qty': 230,
    'total': 43,
  },
];
