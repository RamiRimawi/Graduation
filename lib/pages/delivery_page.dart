import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/sidebar.dart'; // نفس الشريط الجانبي

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
          const Sidebar(activeIndex: 3),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // العنوان + أيقونة الجرس
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Delivery",
                        style: GoogleFonts.roboto(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D2D2D),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.notifications_none_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 35),

                  // القسم الأول: Active Deliveries
                  Text(
                    "Active Deliveries",
                    style: GoogleFonts.roboto(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Wrap(
                    spacing: 24,
                    runSpacing: 20,
                    children: activeDeliveries
                        .map(
                          (d) => _DeliveryCard(
                            name: d["name"]!,
                            imgPath: d["img"]!,
                            isIdle: false,
                          ),
                        )
                        .toList(),
                  ),

                  const SizedBox(height: 40),

                  // القسم الثاني: Idle Deliveries
                  Text(
                    "Idle Deliveries",
                    style: GoogleFonts.roboto(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Wrap(
                    spacing: 24,
                    runSpacing: 20,
                    children: idleDeliveries
                        .map(
                          (d) => _DeliveryCard(
                            name: d["name"]!,
                            imgPath: d["img"]!,
                            isIdle: true,
                          ),
                        )
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
      width: 190,
      height: 210,
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(radius: 49, backgroundImage: AssetImage(imgPath)),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              name,
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                color: isIdle ? Colors.white70 : Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
