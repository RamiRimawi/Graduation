import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../supabase_config.dart';
import '../sidebar.dart';
import 'delivery_live_popup.dart';
import '../Notifications/notification_bell_widget.dart';

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
      // Fetch all delivery drivers with profile images from accounts table
      final driversRes =
          await supabase
                  .from('delivery_driver')
                  .select(
                    'delivery_driver_id, name, accounts!delivery_driver_delivery_driver_id_fkey(profile_image)',
                  )
                  .order('name', ascending: true)
              as List<dynamic>;

      List<Map<String, dynamic>> active = [];
      List<Map<String, dynamic>> idle = [];

      for (final driver in driversRes) {
        final driverId = driver['delivery_driver_id'] as int;
        final driverName = driver['name'] as String;

        // Extract profile image from accounts
        String? profileImage;
        final account = driver['accounts'];
        if (account is List && account.isNotEmpty) {
          profileImage = account.first['profile_image'] as String?;
        } else if (account is Map<String, dynamic>) {
          profileImage = account['profile_image'] as String?;
        }

        // Check if driver has active orders with status 'Delivery'
        final ordersRes =
            await supabase
                    .from('customer_order')
                    .select('customer_order_id')
                    .eq('delivered_by_id', driverId)
                    .eq('order_status', 'Delivery')
                    .limit(1)
                as List<dynamic>;

        if (ordersRes.isNotEmpty) {
          // Driver is active (has orders in Delivery status)
          active.add({
            'name': driverName,
            'profile_image': profileImage,
            'delivery_driver_id': driverId,
          });
        } else {
          // Driver is idle (no active deliveries)
          idle.add({
            'name': driverName,
            'profile_image': profileImage,
            'delivery_driver_id': driverId,
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
                      const NotificationBellWidget(),
                    ],
                  ),

                  const SizedBox(height: 35),

                  if (_loading)
                    const Expanded(
                      child: Center(child: CircularProgressIndicator()),
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
                                            onTap: () {
                                              showDialog(
                                                context: context,
                                                barrierDismissible: true,
                                                builder: (ctx) => DeliveryLivePopup(
                                                  driverId:
                                                      d["delivery_driver_id"] ??
                                                      0,
                                                  driverName: d["name"]!,
                                                  profileImage:
                                                      d["profile_image"],
                                                ),
                                              );
                                            },
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
                                            onTap: () {
                                              showDialog(
                                                context: context,
                                                barrierDismissible: true,
                                                builder: (ctx) => DeliveryLivePopup(
                                                  driverId:
                                                      d["delivery_driver_id"] ??
                                                      0,
                                                  driverName: d["name"]!,
                                                  profileImage:
                                                      d["profile_image"],
                                                ),
                                              );
                                            },
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

class _DeliveryCard extends StatefulWidget {
  final String name;
  final String? profileImage;
  final bool isIdle;
  final VoidCallback? onTap;

  const _DeliveryCard({
    required this.name,
    this.profileImage,
    this.isIdle = false,
    this.onTap,
  });

  @override
  State<_DeliveryCard> createState() => _DeliveryCardState();
}

class _DeliveryCardState extends State<_DeliveryCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final hoverEnabled = widget.onTap != null;
    final scale = hoverEnabled && _hovered ? 1.05 : 1.0;
    final avatarScale = hoverEnabled && _hovered ? 1.08 : 1.0;

    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : MouseCursor.defer,
      onEnter: hoverEnabled ? (_) => setState(() => _hovered = true) : null,
      onExit: hoverEnabled ? (_) => setState(() => _hovered = false) : null,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: Container(
            width: 190,
            height: 210,
            decoration: BoxDecoration(
              color: const Color(0xFF2D2D2D),
              borderRadius: BorderRadius.circular(16),
              border: hoverEnabled && _hovered
                  ? Border.all(
                      color: const Color(0xFFDADADA).withOpacity(0.8),
                      width: 2,
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black38.withOpacity(
                    _hovered && hoverEnabled ? 0.6 : 0.45,
                  ),
                  blurRadius: _hovered && hoverEnabled ? 14 : 8,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AnimatedScale(
                      scale: avatarScale,
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: hoverEnabled && _hovered
                                  ? const Color(0xFFDADADA).withOpacity(0.7)
                                  : Colors.transparent,
                              blurRadius: hoverEnabled && _hovered ? 28 : 0,
                              spreadRadius: hoverEnabled && _hovered ? 4 : 0,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 55,
                          backgroundImage:
                              widget.profileImage != null &&
                                  widget.profileImage!.isNotEmpty
                              ? NetworkImage(widget.profileImage!)
                              : null,
                          backgroundColor: widget.isIdle
                              ? Colors.grey
                              : const Color(0xFF67CD67),
                          child:
                              widget.profileImage == null ||
                                  widget.profileImage!.isEmpty
                              ? Text(
                                  widget.name[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        widget.name,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.roboto(
                          color: widget.isIdle ? Colors.white70 : Colors.white,
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
                if (!widget.isIdle)
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
          ),
        ),
      ),
    );
  }
}
