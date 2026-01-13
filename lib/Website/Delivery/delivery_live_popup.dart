import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
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
  int? _previousOrderId; // تتبع الأوردار السابق للكشف عن التغيير
  List<Map<String, dynamic>> _otherOrders = [];
  List<Map<String, dynamic>> _deliveredOrders = [];
  List<LatLng> _routePoints = const [];
  bool _isRouting = false;
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
    // Initial fetch with map positioning
    _fetchLocations().then((_) {
      // Ensure map is positioned after initial data is loaded
      if (mounted) {
        _positionMapView();
      }
    });

    // ✅ استخدام polling فقط لتجنب مشاكل postgres_changes مع null values
    // Polling أكثر موثوقية ولا يسبب FormatException

    // بدء polling لتحديث الأوردرات كل 2 ثانية (أسرع للحصول على تحديثات فورية)
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) {
        _fetchLocations(updateOnly: true);
      }
    });
  }

  // Helper method to position the map view based on current locations
  void _positionMapView() {
    if (_customerLocation != null) {
      // Center between driver and customer
      final dist = Distance().as(
        LengthUnit.Meter,
        _driverLocation,
        _customerLocation!,
      );
      final center = LatLng(
        (_driverLocation.latitude + _customerLocation!.latitude) / 2,
        (_driverLocation.longitude + _customerLocation!.longitude) / 2,
      );
      final zoom = _getZoomForDistance(dist);
      _mapController.move(center, zoom);
    } else {
      // No active delivery, just center on driver
      _mapController.move(_driverLocation, 14);
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchLocations({bool updateOnly = false}) async {
    if (!mounted) return; // ✅ تحقق من mounted قبل البدء

    try {
      // ✅ جلب موقع السائق + الأوردر النشط
      final driverData = await supabase
          .from('delivery_driver')
          .select(
            'delivery_driver_id, latitude_location, longitude_location, current_order_id',
          )
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

        // ✅ فقط تحديث الكاميرا في التحميل الأولي (وليس عند التحديثات)
        // لا تقم بتحريك الكاميرا أثناء التحديثات لتجنب إزعاج المستخدم أثناء التكبير/التصغير
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
              // إخفاء الأوردر المختار فوراً من قائمة Other orders بدون انتظار جلب الشبكة
              _otherOrders = _otherOrders
                  .where((o) => o['order_id'] != currentOrderId)
                  .toList();
            });
          }

          // جلب المسار والخريطة - فقط عند اختيار أوردار جديد
          if (mounted && _previousOrderId != currentOrderId) {
            _fetchRoute();
            _previousOrderId = currentOrderId;
          }
        }

        // ✅ جلب باقي الأوردرات (Other orders)
        if (mounted) {
          final otherOrders =
              await supabase
                      .from('customer_order')
                      .select('customer_order_id, customer:customer_id(name)')
                      .eq('delivered_by_id', widget.driverId)
                      .eq('order_status', 'Delivery')
                      .neq('customer_order_id', currentOrderId)
                      .order('order_date', ascending: false)
                  as List<dynamic>;

          // ✅ جلب الأوردرات المسلمة (Delivered orders) - فقط اليوم
          final deliveredOrdersRaw =
              await supabase
                      .from('customer_order')
                      .select('customer_order_id, customer:customer_id(name), customer_order_description(delivered_date)')
                      .eq('delivered_by_id', widget.driverId)
                      .eq('order_status', 'Delivered')
                      .limit(50)
                  as List<dynamic>;

          // ترتيب الأوردرات حسب delivered_date من الأحدث إلى الأقدم وتصفية لليوم فقط
          final today = DateTime.now();
          final todayStart = DateTime(today.year, today.month, today.day);
          final todayEnd = todayStart.add(const Duration(days: 1));

          final deliveredOrders = deliveredOrdersRaw
              .where((o) {
                final descriptions = (o as Map<String, dynamic>)['customer_order_description'] as List<dynamic>?;
                if (descriptions == null || descriptions.isEmpty || descriptions.first['delivered_date'] == null) {
                  return false;
                }
                final deliveredDate = DateTime.parse(descriptions.first['delivered_date'] as String);
                return deliveredDate.isAfter(todayStart) && deliveredDate.isBefore(todayEnd);
              })
              .toList()
            ..sort((a, b) {
              final aDate = ((a as Map<String, dynamic>)['customer_order_description'] as List<dynamic>).first['delivered_date'] as String;
              final bDate = ((b as Map<String, dynamic>)['customer_order_description'] as List<dynamic>).first['delivered_date'] as String;
              return DateTime.parse(bDate).compareTo(DateTime.parse(aDate));
            });
          final limitedDeliveredOrders = deliveredOrders.take(10).toList();

          if (mounted) {
            setState(() {
              _otherOrders = otherOrders.map((o) {
                final c =
                    (o as Map<String, dynamic>)['customer']
                        as Map<String, dynamic>?;
                return {'order_id': o['customer_order_id'], 'name': c?['name']};
              }).toList();
              _deliveredOrders = limitedDeliveredOrders.map((o) {
                final c =
                    (o as Map<String, dynamic>)['customer']
                        as Map<String, dynamic>?;
                return {'order_id': o['customer_order_id'], 'name': c?['name']};
              }).toList();
            });
          }
        }
      } else if (mounted) {
        // ✅ إذا current_order_id هو null - الأوردار انتهى
        // تحديث الخريطة فقط عند انتهاء الأوردار (التغيير من أوردار لا أوردار)
        final orderEnded = _previousOrderId != null && currentOrderId == null;
        
        if (orderEnded && mounted) {
          // حفظ بيانات الأوردر المنتهي لإضافتها فوراً إلى Other orders
          final endedOrderId = _previousOrderId;
          final endedCustomerName = _customerName;

          // تحريك الخريطة للموقع الحالي للسائق
          _mapController.move(_driverLocation, 14);

          // تحديث الواجهة فوراً: إعادة الأوردر إلى Other orders
          setState(() {
            if (endedOrderId != null) {
              _otherOrders = [
                {'order_id': endedOrderId, 'name': endedCustomerName},
                ..._otherOrders.where((o) => o['order_id'] != endedOrderId)
              ];
            }
            _customerLocation = null;
            _customerName = null;
            _orderId = null;
            _routePoints = [];
          });

          _previousOrderId = null;
        }

        // ✅ إذا current_order_id هو null، اجلب جميع الأوردرات واعرضها في Other orders
        final allOrders =
            await supabase
                    .from('customer_order')
                    .select('customer_order_id, customer:customer_id(name)')
                    .eq('delivered_by_id', widget.driverId)
                    .eq('order_status', 'Delivery')
                    .order('order_date', ascending: false)
                as List<dynamic>;

        // ✅ جلب الأوردرات المسلمة (Delivered orders) - فقط اليوم
        final deliveredOrdersRaw =
            await supabase
                    .from('customer_order')
                    .select('customer_order_id, customer:customer_id(name), customer_order_description(delivered_date)')
                    .eq('delivered_by_id', widget.driverId)
                    .eq('order_status', 'Delivered')
                    .limit(50)
                as List<dynamic>;

        // ترتيب الأوردرات حسب delivered_date من الأحدث إلى الأقدم وتصفية لليوم فقط
        final today = DateTime.now();
        final todayStart = DateTime(today.year, today.month, today.day);
        final todayEnd = todayStart.add(const Duration(days: 1));

        final deliveredOrders = deliveredOrdersRaw
            .where((o) {
              final descriptions = (o as Map<String, dynamic>)['customer_order_description'] as List<dynamic>?;
              if (descriptions == null || descriptions.isEmpty || descriptions.first['delivered_date'] == null) {
                return false;
              }
              final deliveredDate = DateTime.parse(descriptions.first['delivered_date'] as String);
              return deliveredDate.isAfter(todayStart) && deliveredDate.isBefore(todayEnd);
            })
            .toList()
          ..sort((a, b) {
            final aDate = ((a as Map<String, dynamic>)['customer_order_description'] as List<dynamic>).first['delivered_date'] as String;
            final bDate = ((b as Map<String, dynamic>)['customer_order_description'] as List<dynamic>).first['delivered_date'] as String;
            return DateTime.parse(bDate).compareTo(DateTime.parse(aDate));
          });
        final limitedDeliveredOrders = deliveredOrders.take(10).toList();

        if (mounted) {
          setState(() {
            _customerLocation = null;
            _customerName = null;
            _orderId = null;
            _routePoints = [];
            _otherOrders = allOrders.map((o) {
              final c =
                  (o as Map<String, dynamic>)['customer']
                      as Map<String, dynamic>?;
              return {'order_id': o['customer_order_id'], 'name': c?['name']};
            }).toList();
            _deliveredOrders = limitedDeliveredOrders.map((o) {
              final c =
                  (o as Map<String, dynamic>)['customer']
                      as Map<String, dynamic>?;
              return {'order_id': o['customer_order_id'], 'name': c?['name']};
            }).toList();
          });
          debugPrint(
            '✅ current_order_id is null - showing ${_otherOrders.length} orders in Other orders list',
          );
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
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final coords = data['routes'][0]['geometry']['coordinates'] as List;
          final polyline = coords
              .map(
                (c) =>
                    LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()),
              )
              .toList();
          if (mounted) {
            setState(() {
              _routePoints = polyline;
            });
            // تحديث الخريطة لعرض الطريق كاملة
            if (mounted && _routePoints.isNotEmpty) {
              _fitMapToRoute();
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching route: $e');
    } finally {
      _isRouting = false;
    }
  }

  // حساب الحدود والزوم المناسب لعرض الطريق كاملة مع زوم أكثر
  void _fitMapToRoute() {
    if (_routePoints.isEmpty) return;

    double minLat = _routePoints.first.latitude;
    double maxLat = _routePoints.first.latitude;
    double minLng = _routePoints.first.longitude;
    double maxLng = _routePoints.first.longitude;

    // حساب الحدود الدنيا والعليا لجميع نقاط الطريق
    for (final point in _routePoints) {
      minLat = minLat > point.latitude ? point.latitude : minLat;
      maxLat = maxLat < point.latitude ? point.latitude : maxLat;
      minLng = minLng > point.longitude ? point.longitude : minLng;
      maxLng = maxLng < point.longitude ? point.longitude : maxLng;
    }

    // إضافة padding صغير جداً حول الطريق (0.2% فقط من النطاق)
    final latPadding = (maxLat - minLat) * 0.002;
    final lngPadding = (maxLng - minLng) * 0.002;

    // حساب الحدود مع الـ padding الصغير
    final paddedMinLat = minLat - latPadding;
    final paddedMaxLat = maxLat + latPadding;
    final paddedMinLng = minLng - lngPadding;
    final paddedMaxLng = maxLng + lngPadding;

    // حساب المركز
    final centerLat = (paddedMinLat + paddedMaxLat) / 2;
    final centerLng = (paddedMinLng + paddedMaxLng) / 2;
    final center = LatLng(centerLat, centerLng);

    // حساب نطاق الطول والعرض بالدرجات بعد إضافة الـ padding
    final latDelta = (paddedMaxLat - paddedMinLat).abs();
    final lngDelta = (paddedMaxLng - paddedMinLng).abs();

    // حساب الزوم بناءً على النطاق الجغرافي - مع زوم أعلى
    double zoomLevel = 10.0;

    if (latDelta > 0 && lngDelta > 0) {
      // استخدام أكبر نطاق (الذي يتطلب زوم أقل)
      final maxDelta = latDelta > lngDelta ? latDelta : lngDelta;
      
      // صيغة حساب الزوم بدقة أعلى: زيادة طفيفة للاقتراب أكثر للطريق
      // zoom = log2(360 / maxDelta) + 0.25
      zoomLevel = (log(360 / maxDelta) / log(2)) + 0.60;
    
      
      // قيود الزوم
      if (zoomLevel > 19.5) zoomLevel = 19.5;
      if (zoomLevel < 4) zoomLevel = 4;
    }

    // تحريك الخريطة لعرض الطريق كاملة بزوم أكثر
    _mapController.move(center, zoomLevel);
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
                              backgroundImage:
                                  (widget.profileImage != null &&
                                      widget.profileImage!.isNotEmpty)
                                  ? NetworkImage(widget.profileImage!)
                                  : null,
                              backgroundColor: const Color(0xFF67CD67),
                              child:
                                  (widget.profileImage == null ||
                                      widget.profileImage!.isEmpty)
                                  ? Text(
                                      widget.driverName.isNotEmpty
                                          ? widget.driverName[0].toUpperCase()
                                          : '?',
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
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
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
                              flex: 2,
                              child: Text(
                                'Order ID #',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            SizedBox(width: 24),
                            Expanded(
                              flex: 5,
                              child: Text(
                                'Customer Name',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            SizedBox(width: 80),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
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
                                    flex: 2,
                                    child: Text(
                                      _orderId != null ? _orderId.toString() : '-',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    flex: 5,
                                    child: Text(
                                      _customerName ?? '-',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 80),
                                ],
                              ),
                            ),
                            if (_orderId != null)
                              Positioned(
                                top: -6,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF2196F3),
                                        Color(0xFF1976D2),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF2196F3).withValues(alpha: 0.4),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.local_shipping,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Active',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_otherOrders.isNotEmpty) ...[
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
                                      padding: const EdgeInsets.only(bottom: 17),
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 14,
                                            ),
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
                                                  flex: 2,
                                                  child: Text(
                                                    o['order_id']?.toString() ?? '-',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 24),
                                                Expanded(
                                                  flex: 5,
                                                  child: Text(
                                                    o['name'] ?? '-',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 100),
                                              ],
                                            ),
                                          ),
                                          Positioned(
                                            top: -6,
                                            right: 8,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [
                                                    Color(0xFFFF9800),
                                                    Color(0xFFF57C00),
                                                  ],
                                                ),
                                                borderRadius: BorderRadius.circular(8),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.orangeAccent.withValues(alpha: 0.3),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.schedule,
                                                    color: Colors.white,
                                                    size: 12,
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'Pending',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w800,
                                                    ),
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
                                if (_deliveredOrders.isNotEmpty) ...[
                                  const SizedBox(height: 24),
                                  const Text(
                                    'Orders Delivered',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ..._deliveredOrders.map(
                                    (o) => Padding(
                                      padding: const EdgeInsets.only(bottom: 16),
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 14,
                                            ),
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
                                                  flex: 2,
                                                  child: Text(
                                                    o['order_id']?.toString() ?? '-',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 24),
                                                Expanded(
                                                  flex: 5,
                                                  child: Text(
                                                    o['name'] ?? '-',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 110),
                                              ],
                                            ),
                                          ),
                                          Positioned(
                                            top: -6,
                                            right: 8,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [
                                                    Color(0xFF4CAF50),
                                                    Color(0xFF388E3C),
                                                  ],
                                                ),
                                                borderRadius: BorderRadius.circular(8),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.green.withValues(alpha: 0.3),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.check_circle,
                                                    color: Colors.white,
                                                    size: 12,
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'Delivered',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w800,
                                                    ),
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
                                if (_deliveredOrders.isEmpty) ...[
                                  const SizedBox(height: 24),
                                  const Text(
                                    'Orders Delivered',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'No Orders Delivered Today',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
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
                            maxZoom: 20,
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
                                onTap: () =>
                                    _mapController.move(_driverLocation, 16),
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
