import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../supabase_config.dart';
import 'sidebar.dart'; // نفس الشريط الجانبي

class DeliveryPage extends StatefulWidget {
  const DeliveryPage({super.key});

  @override
  State<DeliveryPage> createState() => _DeliveryPageState();
}

class _DeliveryPageState extends State<DeliveryPage> {
  List<Map<String, dynamic>> activeDeliveries = [];
  List<Map<String, dynamic>> idleDeliveries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchDeliveryDrivers();
  }

  Future<void> _fetchDeliveryDrivers() async {
    setState(() {
      _loading = true;
    });
    try {
      // Fetch all delivery drivers with profile image
      final driversRes = await supabase
          .from('delivery_driver')
          .select('delivery_driver_id, name, profile_image')
          .order('name', ascending: true) as List<dynamic>;

      List<Map<String, dynamic>> active = [];
      List<Map<String, dynamic>> idle = [];

      for (final driver in driversRes) {
        final driverId = driver['delivery_driver_id'] as int;
        final driverName = driver['name'] as String;

        // Check if driver has active orders with status 'Delivery'
        final ordersRes = await supabase
            .from('customer_order')
            .select('customer_order_id')
            .eq('delivered_by_id', driverId)
            .eq('order_status', 'Delivery')
            .limit(1) as List<dynamic>;

        if (ordersRes.isNotEmpty) {
          // Driver is active (has orders in Delivery status)
          active.add({
            'name': driverName,
            'profile_image': driver['profile_image'],
          });
        } else {
          // Driver is idle (no active deliveries)
          idle.add({
            'name': driverName,
            'profile_image': driver['profile_image'],
          });
        }
      }

      if (mounted) {
        setState(() {
          activeDeliveries = active;
          idleDeliveries = idle;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching delivery drivers: $e');
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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

                  if (_loading)
                    const Expanded(
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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

                            activeDeliveries.isEmpty
                                ? Text(
                                    'No active deliveries',
                                    style: GoogleFonts.roboto(
                                      color: Colors.white60,
                                      fontSize: 14,
                                    ),
                                  )
                                : Wrap(
                                    spacing: 24,
                                    runSpacing: 20,
                                    children: activeDeliveries
                                        .map(
                                          (d) => _DeliveryCard(
                                            name: d["name"]!,
                                            profileImage: d["profile_image"],
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

                            idleDeliveries.isEmpty
                                ? Text(
                                    'No idle deliveries',
                                    style: GoogleFonts.roboto(
                                      color: Colors.white60,
                                      fontSize: 14,
                                    ),
                                  )
                                : Wrap(
                                    spacing: 24,
                                    runSpacing: 20,
                                    children: idleDeliveries
                                        .map(
                                          (d) => _DeliveryCard(
                                            name: d["name"]!,
                                            profileImage: d["profile_image"],
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
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  final String name;
  final String? profileImage;
  final bool isIdle;

  const _DeliveryCard({
    required this.name,
    this.profileImage,
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
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 55,
                backgroundImage: profileImage != null && profileImage!.isNotEmpty
                    ? NetworkImage(profileImage!)
                    : null,
                backgroundColor: isIdle ? Colors.grey : const Color(0xFF67CD67),
                child: profileImage == null || profileImage!.isEmpty
                    ? Text(
                        name[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 12),
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
          // نقطة خضراء للـ active
          if (!isIdle)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Color(0xFF67CD67),
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
