import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../supabase_config.dart';

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
  RealtimeChannel? _orderChannel;
  Timer? _pollingTimer;

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
  
  // ✅ الاستماع للتغييرات في جدول delivery_driver
  _driverChannel = supabase.channel('driver_location_${widget.driverId}')
    .onPostgresChanges(
      event: PostgresChangeEvent.update,
      table: 'delivery_driver',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'delivery_driver_id',
        value: widget.driverId,
      ),
      callback: (payload) {
        if (!mounted) return; // ✅ تحقق من mounted قبل المعالجة
        debugPrint('🔄 Driver data updated: ${payload.newRecord}');
        // عند تحديث current_order_id أو الموقع
        _fetchLocations(updateOnly: true);
      },
    )
    ..subscribe();

  // ✅ الاستماع للتغييرات في جدول customer_order (لاكتشاف عند تغيير الحالة إلى Delivered)
  _orderChannel = supabase.channel('order_status_${widget.driverId}')
    .onPostgresChanges(
      event: PostgresChangeEvent.update,
      table: 'customer_order',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'delivered_by_id',
        value: widget.driverId,
      ),
      callback: (payload) {
        if (!mounted) return; // ✅ تحقق من mounted قبل المعالجة
        
        final newRecord = payload.newRecord as Map<String, dynamic>;
        final status = newRecord['order_status'] as String?;
        final orderId = newRecord['customer_order_id'] as int?;
        debugPrint('🔄 Order status changed to: $status for order $orderId (driver ${widget.driverId})');
        
        // إذا تم تحديث الحالة إلى Delivered
        if (status == 'Delivered' && mounted) {
          debugPrint('⚡ Detected Delivered status for order $orderId - removing from UI');
          
          // إذا كانت هذه هي الأوردر الحالية
          if (_orderId == orderId && mounted) {
            debugPrint('🗑️ Clearing current order $orderId');
            setState(() {
              _customerLocation = null;
              _customerName = null;
              _orderId = null;
              _routePoints = [];
            });
          }
          
          // إزالة من قائمة الأوردرات الأخرى
          if (mounted) {
            setState(() {
              _otherOrders.removeWhere((order) => order['order_id'] == orderId);
              debugPrint('📋 Removed order $orderId from other orders list');
            });
          }
          
          // اجلب البيانات الكاملة والزوم حسب المسافة الجديدة
          if (mounted) {
            _fetchLocations(updateOnly: false);
          }
        }
      },
    )
    ..subscribe();

  // ✅ بدء polling لتحديث الأوردرات كل 5 ثوان (backup للـ realtime)
  _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
    if (mounted) {
      debugPrint('🔄 Polling for order status changes...');
      _fetchLocations(updateOnly: true);
    }
  });
}

  @override
  void dispose() {
    if (_driverChannel != null) {
      supabase.removeChannel(_driverChannel!);
    }
    if (_orderChannel != null) {
      supabase.removeChannel(_orderChannel!);
    }
    _pollingTimer?.cancel();
    super.dispose();
  }

 Future<void> _fetchLocations({bool updateOnly = false}) async {
  if (!mounted) return; // ✅ تحقق من mounted قبل البدء
  
  try {
    // ✅ جلب موقع السائق + الأوردر النشط
    final driverData = await supabase
        .from('delivery_driver')
        .select('delivery_driver_id, latitude_location, longitude_location, current_order_id')
        .eq('delivery_driver_id', widget.driverId)
        .maybeSingle(); // ✅ استخدم maybeSingle بدلاً من single

    if (driverData == null) {
      debugPrint('⚠️ Driver data not found');
      return;
    }

    final lat = driverData['latitude_location'] as num?;
    final lng = driverData['longitude_location'] as num?;
    final currentOrderId = driverData['current_order_id'] as int?;

    // تحديث موقع السائق
    if (mounted && lat != null && lng != null) {
      final newDriverLoc = LatLng(lat.toDouble(), lng.toDouble());
      if (mounted) {
        setState(() {
          _driverLocation = newDriverLoc;
        });
      }

      if (!updateOnly && mounted) {
        if (_customerLocation != null) {
          final center = LatLng(
            (newDriverLoc.latitude + _customerLocation!.latitude) / 2,
            (newDriverLoc.longitude + _customerLocation!.longitude) / 2,
          );
            _mapController.move(center, _mapController.camera.zoom);
        } else {
            _mapController.move(newDriverLoc, _mapController.camera.zoom);
        }
      }
    }

    // ✅ إذا كان في أوردر نشط، اجلب تفاصيله
    if (currentOrderId != null && mounted) {
      final orderData = await supabase
          .from('customer_order')
          .select('''
            customer_order_id,
            customer:customer_id(
              customer_id,
              name,
              latitude_location,
              longitude_location
            )
          ''')
          .eq('customer_order_id', currentOrderId)
          .maybeSingle(); // ✅ استخدم maybeSingle

      if (orderData == null || !mounted) {
        debugPrint('⚠️ Order data not found for ID: $currentOrderId');
        return;
      }

      final customer = orderData['customer'] as Map<String, dynamic>?;
      final custLat = customer?['latitude_location'] as num?;
      final custLng = customer?['longitude_location'] as num?;

      if (custLat != null && custLng != null && mounted) {
        final newCustomerLoc = LatLng(custLat.toDouble(), custLng.toDouble());
        
        if (mounted) {
          setState(() {
            _customerLocation = newCustomerLoc;
            _customerName = customer?['name'];
            _orderId = currentOrderId;
          });
        }

        // ضبط الخريطة
        final dist = Distance().as(LengthUnit.Meter, _driverLocation, newCustomerLoc);
        final center = LatLng(
          (_driverLocation.latitude + newCustomerLoc.latitude) / 2,
          (_driverLocation.longitude + newCustomerLoc.longitude) / 2,
        );
        final zoom = _getZoomForDistance(dist);
        if (mounted) {
          _mapController.move(center, zoom);
        }

        // جلب المسار
        if (mounted) {
          _fetchRoute();
        }
      }

      // ✅ جلب باقي الأوردرات (Other orders)
      if (mounted) {
        final otherOrders = await supabase
            .from('customer_order')
            .select('customer_order_id, customer:customer_id(name)')
            .eq('delivered_by_id', widget.driverId)
            .eq('order_status', 'Delivery')
            .neq('customer_order_id', currentOrderId)
            .order('order_date', ascending: false) as List<dynamic>;

        if (mounted) {
          setState(() {
            _otherOrders = otherOrders.map((o) {
              final c = (o as Map<String, dynamic>)['customer'] as Map<String, dynamic>?;
              return {
                'order_id': o['customer_order_id'],
                'name': c?['name'],
              };
            }).toList();
          });
        }
      }
    } else if (mounted) {
      // ✅ إذا current_order_id هو null، اجلب جميع الأوردرات واعرضها في Other orders
      final allOrders = await supabase
          .from('customer_order')
          .select('customer_order_id, customer:customer_id(name)')
          .eq('delivered_by_id', widget.driverId)
          .eq('order_status', 'Delivery')
          .order('order_date', ascending: false) as List<dynamic>;

      if (mounted) {
        setState(() {
          _customerLocation = null;
          _customerName = null;
          _orderId = null;
          _routePoints = [];
          _otherOrders = allOrders.map((o) {
            final c = (o as Map<String, dynamic>)['customer'] as Map<String, dynamic>?;
            return {
              'order_id': o['customer_order_id'],
              'name': c?['name'],
            };
          }).toList();
        });
        debugPrint('✅ current_order_id is null - showing ${_otherOrders.length} orders in Other orders list');
      }
    }
  } catch (e) {
    debugPrint('❌ Error fetching locations: $e');
    // ✅ لا تقم بعمل setState في حالة الخطأ إذا لم يكن mounted
    if (mounted) {
      // يمكنك عرض رسالة خطأ للمستخدم هنا إذا لزم الأمر
    }
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
                  color: Colors.black.withValues(alpha: 0.4),
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
                          _orderId != null 
                              ? 'Now delivering to'
                              : 'The delivery driver hasn\'t selected an order yet.',
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
                            initialCenter: _driverLocation,
                            initialZoom: 14,
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
                                onTap: () => _mapController.move(
                                  _mapController.camera.center,
                                  _mapController.camera.zoom + 1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _MapIconButton(
                                icon: Icons.zoom_out,
                                onTap: () => _mapController.move(
                                  _mapController.camera.center,
                                  _mapController.camera.zoom - 1,
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
      color: Colors.black.withValues(alpha: 0.6),
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
            color: Colors.black.withValues(alpha: 0.3),
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
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Icon(Icons.location_on, color: Colors.redAccent, size: 20),
    );
  }
}
