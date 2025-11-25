import 'package:flutter/material.dart';
import 'sidebar.dart'; // الملف عندك فيه class SideBar

class CreateStockOutPage extends StatefulWidget {
  const CreateStockOutPage({super.key});

  @override
  State<CreateStockOutPage> createState() => _CreateStockOutPageState();
}

class _CreateStockOutPageState extends State<CreateStockOutPage> {
  String? selectedCustomer;
  final TextEditingController discountController = TextEditingController();
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
                    // ===== HEADER SECTION =====
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                            // Customer + Drop list
                            Row(
                              children: [
                                const Text(
                                  "Customer :",
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
                                      value: selectedCustomer,
                                      hint: const Text(
                                        "Select Customer",
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                      items: const [
                                        DropdownMenuItem(
                                          value: "Ahmad Nizar",
                                          child: Text(
                                            "Ahmad Nizar",
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: "Saed Rimawi",
                                          child: Text(
                                            "Saed Rimawi",
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: "Nizar Fares",
                                          child: Text(
                                            "Nizar Fares",
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

                    const SizedBox(height: 20),

                    // ===== LOCATION / DATE / TAX =====
                    Padding(
                      padding: const EdgeInsets.only(right: 30.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: const [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Location : Ramallah , Beit Rema",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                "Quarter : maaser",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(width: 220),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Date : 18-8-2026",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                "Time : 11:00 AM",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(width: 220),
                          Text(
                            "Tax percent : 18%",
                            style: TextStyle(color: Colors.white, fontSize: 15),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 15),
                    const Divider(color: Colors.white24, thickness: 1),
                    const SizedBox(height: 6),

                    // ===== TABLE SECTION =====
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ===== TABLE =====
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
                                      // 🔹 خط تحت العناوين
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

                                // ✅ hover effect فقط
                                return MouseRegion(
                                  onEnter: (_) =>
                                      setState(() => hoveredIndex = index),
                                  onExit: (_) =>
                                      setState(() => hoveredIndex = null),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
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
                                        // ✅ Quantity مع المربع الذهبي
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

                          const SizedBox(width: 40),

                          // ===== BUTTONS COLUMN =====
                          Expanded(
                            flex: 3,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                _ActionButton(
                                  color: const Color(0xFFB7A447),
                                  icon: Icons.add_box_rounded,
                                  label: 'Add Product',
                                  textColor: Colors.black,
                                  width: 220,
                                ),
                                const SizedBox(height: 20),
                                _ActionButton(
                                  color: const Color(0xFFC34239),
                                  icon: Icons.delete_forever_rounded,
                                  label: 'Remove Product',
                                  textColor: Colors.white,
                                  width: 220,
                                ),
                                const SizedBox(height: 20),
                                _ActionButton(
                                  color: const Color(0xFF4287AD),
                                  icon: Icons.send_rounded,
                                  label: 'Send Order',
                                  textColor: Colors.black,
                                  width: 220,
                                ),
                                const SizedBox(height: 20),
                                _ActionButton(
                                  color: const Color(0xFF6F6F6F),
                                  icon: Icons.pause_circle_filled_rounded,
                                  label: 'Hold',
                                  textColor: Colors.white,
                                  width: 220,
                                ),
                                const SizedBox(height: 30),
                                const Divider(color: Colors.white24),
                                const SizedBox(height: 18),
                                // ✅ Discount + TextField
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      "Discount:",
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    SizedBox(
                                      width: 80,
                                      height: 32,
                                      child: TextField(
                                        controller: discountController,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: "%",
                                          hintStyle: const TextStyle(
                                            color: Colors.white54,
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 0,
                                              ),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: Color(0xFFB7A447),
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: Color(0xFFB7A447),
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
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
    this.width = 260,
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

// ====== DEMO DATA ======
final List<Map<String, dynamic>> demoData = [
  {
    'id': 26,
    'name': 'Ahmad Nizar',
    'brand': 'GROHE',
    'price': 26,
    'qty': 234,
    'total': 26,
  },
  {
    'id': 27,
    'name': 'Saed Rimawi',
    'brand': 'Royal',
    'price': 150,
    'qty': 30,
    'total': 150,
  },
  {
    'id': 30,
    'name': 'Akef Al Asmar',
    'brand': 'GROHE',
    'price': 200,
    'qty': 100,
    'total': 200,
  },
  {
    'id': 29,
    'name': 'Nizar Fares',
    'brand': 'Royal',
    'price': 25,
    'qty': 29,
    'total': 25,
  },
  {
    'id': 31,
    'name': 'Sameer Haj',
    'brand': 'Royal',
    'price': 10,
    'qty': 32,
    'total': 10,
  },
  {
    'id': 28,
    'name': 'Eyas Barghouthi',
    'brand': 'GROHE',
    'price': 30,
    'qty': 28,
    'total': 30,
  },
  {
    'id': 20,
    'name': 'Sami Jaber',
    'brand': 'GROHE',
    'price': 43,
    'qty': 67,
    'total': 43,
  },
];
