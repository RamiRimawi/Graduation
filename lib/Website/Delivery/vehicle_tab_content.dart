import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../supabase_config.dart';
import 'vehicle_popup.dart';

class VehicleTabContent extends StatefulWidget {
  const VehicleTabContent({super.key});

  @override
  State<VehicleTabContent> createState() => _VehicleTabContentState();
}

class _VehicleTabContentState extends State<VehicleTabContent> {
  List<Map<String, dynamic>> vehicles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchVehicles();
  }

  Future<void> _fetchVehicles() async {
    setState(() {
      _loading = true;
    });
    try {
      final vehiclesRes =
          await supabase
                  .from('vehicle')
                  .select('*')
                  .order('plate_id', ascending: true)
              as List<dynamic>;

      if (mounted) {
        setState(() {
          vehicles = vehiclesRes.cast<Map<String, dynamic>>();
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching vehicles: $e');
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vehicles.isEmpty) {
      return Center(
        child: Text(
          'No vehicles available',
          style: GoogleFonts.roboto(color: Colors.white60, fontSize: 14),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "All Vehicles",
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
            children: vehicles
                .map(
                  (v) => VehicleCard(
                    plateId: v['plate_id']?.toString() ?? '',
                    brand: v['brand'] ?? 'Unknown',
                    model: v['model'] ?? 'Unknown',
                    vehicleImage: v['vehicle_image'],
                    isActive: v['is_active'] ?? false,
                    onTap: () {
                      showDialog(
                        context: context,
                        barrierDismissible: true,
                        builder: (ctx) => VehiclePopup(
                          plateId: v['plate_id'],
                          brand: v['brand'] ?? 'Unknown',
                          model: v['model'] ?? 'Unknown',
                          vehicleImage: v['vehicle_image'],
                          isActive: v['is_active'] ?? false,
                        ),
                      );
                    },
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class VehicleCard extends StatefulWidget {
  final String plateId;
  final String brand;
  final String model;
  final String? vehicleImage;
  final bool isActive;
  final VoidCallback? onTap;

  const VehicleCard({
    super.key,
    required this.plateId,
    required this.brand,
    required this.model,
    this.vehicleImage,
    this.isActive = false,
    this.onTap,
  });

  @override
  State<VehicleCard> createState() => _VehicleCardState();
}

class _VehicleCardState extends State<VehicleCard> {
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
                              widget.vehicleImage != null &&
                                  widget.vehicleImage!.isNotEmpty
                              ? NetworkImage(widget.vehicleImage!)
                              : null,
                          backgroundColor: widget.isActive
                              ? const Color(0xFF50B2E7)
                              : Colors.grey,
                          child:
                              widget.vehicleImage == null ||
                                  widget.vehicleImage!.isEmpty
                              ? Icon(
                                  Icons.local_shipping,
                                  color: Colors.white,
                                  size: 40,
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        '${widget.brand} ${widget.model}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.roboto(
                          color: widget.isActive
                              ? Colors.white
                              : Colors.white70,
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                // Green dot for active
                if (widget.isActive)
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
