import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OrderDetailPopup {
  static void show(
    BuildContext context, {
    required String orderType, // "in" أو "out"
    required String status, // "NEW" أو "UPDATE"
    required List<Map<String, dynamic>> products,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      builder: (_) => Stack(
        children: [
          // ---------- خلفية مغبشة ----------
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(color: Colors.black.withOpacity(0.3)),
          ),

          // ---------- محتوى الـ Popup ----------
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 1000,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D2D),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ------------------------- العنوان -------------------------
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Order Detail',
                              style: GoogleFonts.roboto(
                                color: const Color(0xFFB7A447),
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: status == "NEW"
                                    ? Colors.yellow.shade600
                                    : Colors.orangeAccent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                status,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // -------------------- بيانات العميل / المورد --------------------
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            orderType == "in"
                                ? "Supplier Name: Saed Rimawi"
                                : "Customer: Saed Rimawi",
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Center(
                            child: Text(
                              "Date: 18-8-2026",
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              "Time: 11:00 AM",
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    if (orderType == "out")
                      const Text(
                        "Location: Ramallah, Beit Rema | Quarter: Maaser",
                        style: TextStyle(fontSize: 15),
                      ),

                    const SizedBox(height: 14),

                    // ------------------------- الجدول -------------------------
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Row(
                            children: const [
                              Expanded(
                                flex: 1,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text("Product ID"),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Center(child: Text("Product Name")),
                              ),
                              Expanded(
                                flex: 2,
                                child: Center(child: Text("Brand")),
                              ),
                              Expanded(
                                flex: 2,
                                child: Center(child: Text("Price per product")),
                              ),
                              Expanded(
                                flex: 2,
                                child: Center(child: Text("Quantity")),
                              ),
                              Expanded(
                                flex: 2,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Text("Total Price"),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(color: Colors.white24, height: 0),

                        // الصفوف
                        for (final product in products)
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF252525),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      product["id"].toString(),
                                      style: const TextStyle(
                                        color: Colors.amberAccent,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Center(
                                    child: Text(
                                      product["name"],
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Center(
                                    child: Text(
                                      product["brand"],
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Center(
                                    child: Text(
                                      product["price"],
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Center(
                                    child: Text(
                                      product["quantity"].toString(),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      product["total"].toString(),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ------------------------- الإجمالي -------------------------
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: const [
                        Text(
                          "Total Price : ",
                          style: TextStyle(
                            color: Color(0xFFB7A447),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "12,566\$",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ------------------------- الأزرار -------------------------
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _OrderButton(
                          label: "Later",
                          color: Colors.grey.shade600,
                          icon: Icons.access_time,
                        ),
                        const SizedBox(width: 14),
                        _OrderButton(
                          label: status == "UPDATE"
                              ? "Reject Update"
                              : "Reject Order",
                          color: Colors.red.shade700,
                          icon: Icons.cancel_outlined,
                        ),
                        const SizedBox(width: 14),
                        _OrderButton(
                          label: status == "UPDATE"
                              ? "Accept Update"
                              : "Send Order",
                          color: Colors.yellow.shade600,
                          icon: Icons.send_rounded,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------ زر داخل الـ popup ------------------------
class _OrderButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _OrderButton({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      onPressed: () => Navigator.pop(context),
      icon: Icon(icon, color: Colors.black),
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
