import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/sidebar.dart'; // ← استيراد الشريط الجانبي الحقيقي

class MobileAccountsPage extends StatelessWidget {
  const MobileAccountsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, List<String>> accountGroups = {
      "Storage Manager": ["Mohammad Assi"],
      "Storage Staff": [
        "Moath Mouadi",
        "Ameer Yasin",
        "Abdullah Odwan",
        "Kareem Manasra",
        "Ramadan Abu Syam",
        "Ammar Shobaki",
        "Ibraheem Inaya",
      ],
      "Delivery Driver": [
        "Ata Musleh",
        "Ibraheem Inaya",
        "Abdullah Odwan",
        "Kareem Manasra",
        "Moath Mouadi",
      ],
      "Customer": [
        "Ramadan Abu Syam",
        "Ammar Shobaki",
        "Moath Mouadi",
        "Ameer Yasin",
        "Ata Musleh",
        "Ibraheem Inaya",
        "Rami Rimawi",
      ],
      "Sales Rep": [
        "Abdullah Odwan",
        "Kareem Manasra",
        "Ayman Rimawi",
        "Rami Rimawi",
        "Ramadan Abu Syam",
        "Moath Mouadi",
        "Ameer Yasin",
      ],
      "Supplier": [
        "Ayman Rimawi",
        "Rami Rimawi",
        "Abdullah Odwan",
        "Kareem Manasra",
      ],
    };

    return Scaffold(
      backgroundColor: const Color(0xFF202020),
      body: Row(
        children: [
          const Sidebar(), // ← الشريط الجانبي
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // -------------------- العنوان + الزر --------------------
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Mobile Account",
                        style: GoogleFonts.roboto(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF9D949),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        onPressed: () {},
                        icon: const Icon(Icons.person_add_alt_1,
                            color: Colors.black),
                        label: const Text(
                          "Add Account",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // -------------------- حقل البحث --------------------
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 250,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D2D2D),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.person_search_rounded,
                                color: Colors.white60, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                style: TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: "Account Name",
                                  hintStyle: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 14,
                                  ),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            SizedBox(width: 5),
                            Icon(Icons.filter_alt_rounded,
                                color: Colors.amberAccent),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  // -------------------- المحتوى (القوائم + الكروت) --------------------
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final entry in accountGroups.entries) ...[
                            Text(
                              entry.key,
                              style: GoogleFonts.roboto(
                                color: const Color(0xFFB7A447),
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                for (final name in entry.value)
                                  _AccountCard(name: name),
                              ],
                            ),
                            const SizedBox(height: 35),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------- الكرت الخاص بكل شخص -------------------
class _AccountCard extends StatelessWidget {
  final String name;

  const _AccountCard({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            offset: Offset(0, 3),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 15,
            backgroundColor: Colors.grey,
            child: Icon(Icons.person, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
