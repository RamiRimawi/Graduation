import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../supabase_config.dart';

class DeliveryLivePopup extends StatefulWidget {
  final int driverId;
  final String driverName;
  final String? profileImage;

  const DeliveryLivePopup({
    super.key,
    required this.driverId,
    required this.driverName,
    this.profileImage,
  });

  @override
  State<DeliveryLivePopup> createState() => _DeliveryLivePopupState();
}

class _DeliveryLivePopupState extends State<DeliveryLivePopup> {
  final MapController _mapController = MapController();

  LatLng _driverLocation = const LatLng(31.9522, 35.2332); // Default: Ramallah
  LatLng? _customerLocation;
  String? _customerName;
  int? _orderId;
  List<Map<String, dynamic>> _otherOrders = [];
  List<LatLng> _routePoints = const [];
  bool _isRouting = false;
  RealtimeChannel? _driverChannel;

  // Helper: حساب الزوم المناسب حسب المسافة (بـ كم)
  double _getZoomForDistance(double distanceMeters) {
    // تقريبية: كلما زادت المسافة قل الزوم
    if (distanceMeters < 500) return 16;
    if (distanceMeters < 1500) return 15;
    if (distanceMeters < 3000) return 14;
    if (distanceMeters < 6000) return 13;
    if (distanceMeters < 12000) return 12;
    if (distanceMeters < 25000) return 11;
    if (distanceMeters < 50000) return 10;
    if (distanceMeters < 100000) return 9;
    return 8;
  }

  @override
  void initState() {
    super.initState();
    _fetchLocations();
    // اشتراك realtime على جدول السائق
    _driverChannel = supabase.channel('driver_location_${widget.driverId}')
      .onPostgresChanges(
        event: PostgresChangeEvent.update,
        table: 'delivery_driver',
        callback: (payload) {
          // عند تحديث الموقع في قاعدة البيانات
          _fetchLocations(updateOnly: true);
        },
      )
      ..subscribe();
  }

  @override
  void dispose() {
    if (_driverChannel != null) {
      supabase.removeChannel(_driverChannel!);
    }
    super.dispose();
  }

  Future<void> _fetchLocations({bool updateOnly = false}) async {
    try {
      // Fetch driver location
      final response = await supabase
          .from('delivery_driver')
          .select('latitude_location, longitude_location')
          .eq('delivery_driver_id', widget.driverId)
          .single();

      final lat = response['latitude_location'] as num?;
      final lng = response['longitude_location'] as num?;

      if (mounted && lat != null && lng != null) {
        final newDriverLoc = LatLng(lat.toDouble(), lng.toDouble());
        setState(() {
          _driverLocation = newDriverLoc;
        });
        // إذا كان لدينا موقع العميل، احسب المسافة واضبط الزوم
        if (_customerLocation != null) {
          final dist = Distance().as(LengthUnit.Meter, newDriverLoc, _customerLocation!);
          final center = LatLng(
            (newDriverLoc.latitude + _customerLocation!.latitude) / 2,
            (newDriverLoc.longitude + _customerLocation!.longitude) / 2,
          );
          // استخدم زوم ثابت
          _mapController.move(center, 14);
        } else {
          _mapController.move(newDriverLoc, 14);
        }
      } else if (!updateOnly) {
      }

      // If customer not yet loaded, fetch active deliveries for this driver
      if (_customerLocation == null) {
        final orders = await supabase
            .from('customer_order')
            .select('customer_order_id, order_date, customer:customer_id(customer_id, name, latitude_location, longitude_location)')
            .eq('delivered_by_id', widget.driverId)
            .eq('order_status', 'Delivery')
            .order('order_date', ascending: false) as List<dynamic>;

        if (orders.isNotEmpty) {
          final primary = orders.first as Map<String, dynamic>;
          final customer = primary['customer'] as Map<String, dynamic>?;
          final custLat = customer?['latitude_location'] as num?;
          final custLng = customer?['longitude_location'] as num?;
          final custName = customer?['name'] as String?;
          final orderId = primary['customer_order_id'] as int?;

          if (custLat != null && custLng != null && mounted) {
            final newCustomerLoc = LatLng(custLat.toDouble(), custLng.toDouble());
            setState(() {
              _customerLocation = newCustomerLoc;
              _customerName = custName;
              _orderId = orderId;
              _otherOrders = orders
                  .skip(1)
                  .map((o) {
                    final c = (o as Map<String, dynamic>)['customer'] as Map<String, dynamic>?;
                    return {
                      'order_id': o['customer_order_id'],
                      'name': c?['name'],
                    };
                  })
                  .toList();
            });
            // إذا كان لدينا موقع السائق، احسب المسافة واضبط الزوم
            // ignore: unnecessary_null_comparison
            if (_driverLocation != null) {
              final dist = Distance().as(LengthUnit.Meter, _driverLocation, newCustomerLoc);
              final center = LatLng(
                (_driverLocation.latitude + newCustomerLoc.latitude) / 2,
                (_driverLocation.longitude + newCustomerLoc.longitude) / 2,
              );
              final zoom = _getZoomForDistance(dist);
              _mapController.move(center, zoom);
            }
          }
        }
      }

      // Fetch driving route when both points are available
      if (_customerLocation != null && mounted) {
        _fetchRoute();
      }
    } catch (e) {
      debugPrint('Error fetching locations: $e');
    }
  }

  Future<void> _fetchRoute() async {
    if (_customerLocation == null || _isRouting) return;
    _isRouting = true;
    try {
      final start = _driverLocation;
      final end = _customerLocation!;
      final url =
          'https://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson';
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final coords = data['routes'][0]['geometry']['coordinates'] as List;
          final polyline = coords
              .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
              .toList();
          if (mounted) {
            setState(() {
              _routePoints = polyline;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching route: $e');
    } finally {
      _isRouting = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          return Container(
            width: width,
            height: height * 0.9,
            decoration: BoxDecoration(
              color: const Color(0xFF1F1F1F),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                // Info side panel
                SizedBox(
                  width: width * 0.28,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundImage: (widget.profileImage != null && widget.profileImage!.isNotEmpty)
                                  ? NetworkImage(widget.profileImage!)
                                  : null,
                              backgroundColor: const Color(0xFF67CD67),
                              child: (widget.profileImage == null || widget.profileImage!.isEmpty)
                                  ? Text(
                                      widget.driverName.isNotEmpty ? widget.driverName[0].toUpperCase() : '?',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.driverName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close, color: Colors.white70),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const SizedBox(height: 8),
                        Text(
                          'Now delivering to',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: const [
                            Expanded(
                              child: Text(
                                'Order ID #',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Customer Name',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2D2D2D),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 6,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _orderId != null ? _orderId.toString() : '-',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  _customerName ?? '-',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_otherOrders.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          const Text(
                            'Other orders',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._otherOrders.map(
                            (o) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2D2D2D),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 6,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        o['order_id']?.toString() ?? '-',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        o['name'] ?? '-',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
                // Map area
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    child: Stack(
                      children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            center: _driverLocation,
                            zoom: 14,
                            maxZoom: 18,
                          ),
                          children: [
                            TileLayer(
                              // Use a provider with an API key to avoid OSM blocking.
                              // Replace YOUR_KEY below with a valid key (e.g., MapTiler or Mapbox).
                              urlTemplate:
                                  'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=dkYOU5miikUvzB2wvCgJ',
                              userAgentPackageName: 'com.example.app',
                              tileProvider: NetworkTileProvider(),
                            ),
                            if (_routePoints.isNotEmpty)
                              PolylineLayer(
                                polylines: [
                                  Polyline(
                                    points: _routePoints,
                                    strokeWidth: 4,
                                    color: Colors.blueAccent,
                                  ),
                                ],
                              ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: _driverLocation,
                                  width: 50,
                                  height: 50,
                                  child: _DriverMarker(),
                                ),
                                if (_customerLocation != null)
                                  Marker(
                                    point: _customerLocation!,
                                    width: 46,
                                    height: 46,
                                    child: _CustomerMarker(),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        Positioned(
                          top: 16,
                          right: 16,
                          child: Column(
                            children: [
                              _MapIconButton(
                                icon: Icons.my_location,
                                onTap: () => _mapController.move(_driverLocation, 16),
                              ),
                              const SizedBox(height: 8),
                              _MapIconButton(
                                icon: Icons.zoom_in,
                                onTap: () => _mapController.move(_mapController.center, _mapController.zoom + 1),
                              ),
                              const SizedBox(height: 8),
                              _MapIconButton(
                                icon: Icons.zoom_out,
                                onTap: () => _mapController.move(_mapController.center, _mapController.zoom - 1),
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
          );
        },
      ),
    );
  }

}

class _MapIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _MapIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.6),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _DriverMarker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFF67CD67),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Icon(Icons.local_shipping, color: Colors.black87, size: 20),
    );
  }
}

class _CustomerMarker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.blueAccent, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Icon(Icons.location_on, color: Colors.redAccent, size: 20),
    );
  }
}
