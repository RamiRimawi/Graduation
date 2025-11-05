import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/sidebar.dart'; // ← نفس الشريط الجانبي

class DeliveryPage extends StatelessWidget {
  const DeliveryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final activeDeliveries = [
      {"name": "Ayman Rimawi", "img": "assets/images/ayman.jpg"},
      {"name": "Rami Rimawi", "img": "assets/images/rami.jpg"},
      {"name": "Ramadan abu syam", "img": "assets/images/ramadan.jpg"},
    ];

    final idleDeliveries = [
      {"name": "Eyas Barghouthi", "img": "assets/images/eyas.jpg"},
      {"name": "Ahmad Naser", "img": "assets/images/ahmad.jpg"},
      {"name": "Salah Amar", "img": "assets/images/salah.jpg"},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF202020),
      body: Row(
        children: [
          const Sidebar(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // العنوان الرئيسي
                  Text(
                    "Delivery",
                    style: GoogleFonts.roboto(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 35),

                  // القسم الأول
                  Text(
                    "Active Deliveries",
                    style: GoogleFonts.roboto(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 15),

                  Wrap(
                    spacing: 20,
                    runSpacing: 15,
                    children: activeDeliveries
                        .map((d) => _DeliveryCard(
                              name: d["name"]!,
                              imgPath: d["img"]!,
                            ))
                        .toList(),
                  ),

                  const SizedBox(height: 40),

                  // القسم الثاني
                  Text(
                    "Idle Deliveries",
                    style: GoogleFonts.roboto(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 15),

                  Wrap(
                    spacing: 20,
                    runSpacing: 15,
                    children: idleDeliveries
                        .map((d) => _DeliveryCard(
                              name: d["name"]!,
                              imgPath: d["img"]!,
                              isIdle: true,
                            ))
                        .toList(),
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

class _DeliveryCard extends StatelessWidget {
  final String name;
  final String imgPath;
  final bool isIdle;

  const _DeliveryCard({
    required this.name,
    required this.imgPath,
    this.isIdle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 3))
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: AssetImage(imgPath),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              style: GoogleFonts.roboto(
                color: isIdle ? Colors.white70 : Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
