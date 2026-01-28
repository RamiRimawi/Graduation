import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

class _DeliveryLivePopupState extends State<DeliveryLivePopup>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();

  LatLng _driverLocation = const LatLng(31.9522, 35.2332); // Default: Ramallah
  LatLng _driverMarkerLocation = const LatLng(31.9522, 35.2332);
  bool _hasInitialDriverLocation = false;
  LatLng? _customerLocation;
  String? _customerName;
  int? _orderId;
  int? _previousOrderId; // تتبع الأوردار السابق للكشف عن التغيير
  List<Map<String, dynamic>> _otherOrders = [];
  List<Map<String, dynamic>> _deliveredOrders = [];
  List<LatLng> _routePoints = const [];
  bool _isRouting = false;
  String? _currentVehicleBrand;
  String? _currentVehicleModel;

  Timer? _pollingTimer;
  RealtimeChannel? _driverChannel;

  bool _isOffRoute = false; // تتبع ما إذا كان السائق خارج المسار
  static const double _routeThresholdMeters = 50.0; // 50 متر

  // متغيرات لحساب السرعة وتعديل وقت التحديث
  LatLng? _previousDriverLocation;
  DateTime? _lastLocationUpdateTime;
  double _currentSpeed = 0.0; // كم/س
  Duration _currentPollingInterval = const Duration(seconds: 2);

  // ✅ Smart route update
  Timer? _routeSmartTimer;
  DateTime? _lastRouteUpdateAt;
  LatLng? _lastRouteFrom;

  // ✅ Smooth driver animation
  AnimationController? _driverAnimController;
  Animation<LatLng>? _driverAnim;
  static const Duration _driverAnimDuration = Duration(milliseconds: 600);

  static const Duration _routeMinIntervalNormal = Duration(seconds: 12);
  static const Duration _routeMinIntervalFast = Duration(seconds: 4);
  static const double _routeMinMoveNormalMeters = 25.0;
  static const double _routeMinMoveFastMeters = 10.0;
  static const double _fastSpeedKmh = 50.0;

  // Helper: حساب أقرب مسافة من نقطة إلى خط (المسار)
  double _getMinDistanceToRoute(LatLng point, List<LatLng> route) {
    if (route.isEmpty) return double.infinity;

    double minDistance = double.infinity;
    final Distance distance = Distance();

    for (int i = 0; i < route.length - 1; i++) {
      final segmentStart = route[i];
      final segmentEnd = route[i + 1];
      final distToSegment = _distanceToSegment(
        point,
        segmentStart,
        segmentEnd,
        distance,
      );
      if (distToSegment < minDistance) {
        minDistance = distToSegment;
      }
    }

    return minDistance;
  }

  // Helper: حساب المسافة من نقطة إلى قطعة مستقيمة
  double _distanceToSegment(
    LatLng point,
    LatLng segStart,
    LatLng segEnd,
    Distance distance,
  ) {
    final double distToStart = distance.as(LengthUnit.Meter, point, segStart);
    final double segmentLength = distance.as(
      LengthUnit.Meter,
      segStart,
      segEnd,
    );

    if (segmentLength < 0.1) return distToStart;

    final double t = max(
      0.0,
      min(
        1.0,
        ((point.latitude - segStart.latitude) *
                    (segEnd.latitude - segStart.latitude) +
                (point.longitude - segStart.longitude) *
                    (segEnd.longitude - segStart.longitude)) /
            (segmentLength * segmentLength / 111320.0),
      ),
    );

    final closestLat =
        segStart.latitude + t * (segEnd.latitude - segStart.latitude);
    final closestLng =
        segStart.longitude + t * (segEnd.longitude - segStart.longitude);
    final closestPoint = LatLng(closestLat, closestLng);

    return distance.as(LengthUnit.Meter, point, closestPoint);
  }

  // Helper: حساب السرعة وتحديث فترة الـ polling
  void _updateSpeedAndPolling(LatLng newLocation) {
    if (_previousDriverLocation != null && _lastLocationUpdateTime != null) {
      final distance = Distance();
      final distanceMeters = distance.as(
        LengthUnit.Meter,
        _previousDriverLocation!,
        newLocation,
      );

      final timeDiff = DateTime.now().difference(_lastLocationUpdateTime!);
      final timeSeconds = timeDiff.inMilliseconds / 1000.0;

      if (timeSeconds > 0 && distanceMeters > 1) {
        _currentSpeed = (distanceMeters / timeSeconds) * 3.6;

        Duration newInterval;
        if (_currentSpeed > 60) {
          newInterval = const Duration(milliseconds: 500);
        } else if (_currentSpeed > 40) {
          newInterval = const Duration(seconds: 1);
        } else if (_currentSpeed > 20) {
          newInterval = const Duration(milliseconds: 1500);
        } else if (_currentSpeed > 5) {
          newInterval = const Duration(seconds: 2);
        } else {
          newInterval = const Duration(seconds: 3);
        }

        if (newInterval != _currentPollingInterval) {
          _currentPollingInterval = newInterval;
          _restartPollingTimer();
          debugPrint(
            '🚗 السرعة: ${_currentSpeed.toStringAsFixed(1)} كم/س - فترة التحديث: ${newInterval.inMilliseconds}ms',
          );
        }
      }
    }

    _previousDriverLocation = newLocation;
    _lastLocationUpdateTime = DateTime.now();
  }

  void _restartPollingTimer() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(_currentPollingInterval, (_) {
      if (mounted) {
        _fetchLocations(updateOnly: true);
      }
    });
  }

  void _onDriverAnimTick() {
    if (!mounted || _driverAnim == null) return;
    setState(() {
      _driverMarkerLocation = _driverAnim!.value;
    });
  }

  void _startDriverAnimation(LatLng newLocation) {
    if (_driverAnimController == null) return;

    _driverAnimController!.stop();
    _driverAnimController!.reset();

    _driverAnim = LatLngTween(begin: _driverMarkerLocation, end: newLocation)
        .animate(
          CurvedAnimation(
            parent: _driverAnimController!,
            curve: Curves.easeOut,
          ),
        );

    _driverAnimController!.removeListener(_onDriverAnimTick);
    _driverAnimController!.addListener(_onDriverAnimTick);
    _driverAnimController!.forward();
  }

  void _applyDriverLocationUpdate(LatLng newLocation, {bool animate = true}) {
    setState(() {
      _driverLocation = newLocation;
      if (!_hasInitialDriverLocation || !animate) {
        _driverMarkerLocation = newLocation;
      }
    });

    if (!_hasInitialDriverLocation || !animate) {
      _hasInitialDriverLocation = true;
      return;
    }

    _startDriverAnimation(newLocation);
  }

  // Helper: التحقق وتحديث حالة الانحراف عن المسار
  void _checkIfOffRoute() {
    if (_routePoints.isEmpty || _customerLocation == null) {
      if (_isOffRoute) {
        setState(() => _isOffRoute = false);
      }
      return;
    }

    final distanceToRoute = _getMinDistanceToRoute(
      _driverLocation,
      _routePoints,
    );
    final bool wasOffRoute = _isOffRoute;
    final bool isNowOffRoute = distanceToRoute > _routeThresholdMeters;

    if (wasOffRoute != isNowOffRoute) {
      setState(() {
        _isOffRoute = isNowOffRoute;
      });

      if (_isOffRoute) {
        debugPrint(
          '⚠️ السائق خارج المسار! المسافة: ${distanceToRoute.toStringAsFixed(1)} متر',
        );
      } else {
        debugPrint('✅ السائق عاد إلى المسار');
      }
    }
  }

  // Helper: حساب الزوم المناسب حسب المسافة (بـ كم)
  double _getZoomForDistance(double distanceMeters) {
    if (distanceMeters < 100) return 18;
    if (distanceMeters < 250) return 17;
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

  void _startDriverRealtime() {
    if (_driverChannel != null) return;

    _driverChannel = supabase.channel('driver_${widget.driverId}_live');

    _driverChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'delivery_driver',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'delivery_driver_id',
            value: widget.driverId,
          ),
          callback: (payload) {
            if (!mounted) return;

            final rec = payload.newRecord;

            final latRaw = rec['latitude_location'];
            final lngRaw = rec['longitude_location'];

            final double? lat = (latRaw is num)
                ? latRaw.toDouble()
                : double.tryParse(latRaw?.toString() ?? '');
            final double? lng = (lngRaw is num)
                ? lngRaw.toDouble()
                : double.tryParse(lngRaw?.toString() ?? '');

            if (lat == null || lng == null) return;

            final newDriverLoc = LatLng(lat, lng);

            _applyDriverLocationUpdate(newDriverLoc, animate: true);

            _updateSpeedAndPolling(newDriverLoc);
            _checkIfOffRoute();
            // تحديث المسار الذكي رح يصير من التايمر (_routeSmartTimer)
          },
        )
        .subscribe();
  }

  @override
  void initState() {
    super.initState();

    _driverMarkerLocation = _driverLocation;
    _driverAnimController = AnimationController(
      vsync: this,
      duration: _driverAnimDuration,
    );

    _startDriverRealtime();

    _fetchLocations().then((_) {
      if (mounted) _positionMapView();
    });

    // Polling موجود عندك
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) {
        _fetchLocations(updateOnly: true);
      }
    });

    // ✅ Smart route timer: يقرر متى يحدث المسار فعلياً
    _routeSmartTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _maybeUpdateRouteSmart();
    });
  }

  void _positionMapView() {
    if (_customerLocation != null) {
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
      _mapController.move(_driverLocation, 14);
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _routeSmartTimer?.cancel();

    _driverAnimController?.removeListener(_onDriverAnimTick);
    _driverAnimController?.dispose();

    if (_driverChannel != null) {
      supabase.removeChannel(_driverChannel!);
      _driverChannel = null;
    }

    super.dispose();
  }

  // ✅ Smart route decision
  Future<void> _maybeUpdateRouteSmart() async {
    if (_orderId == null || _customerLocation == null) return;

    final now = DateTime.now();

    final bool fast = _isOffRoute || _currentSpeed >= _fastSpeedKmh;

    final minInterval = fast ? _routeMinIntervalFast : _routeMinIntervalNormal;
    final minMove = fast ? _routeMinMoveFastMeters : _routeMinMoveNormalMeters;

    if (_lastRouteUpdateAt != null &&
        now.difference(_lastRouteUpdateAt!) < minInterval) {
      return;
    }

    if (_lastRouteFrom != null) {
      final moved = Distance().as(
        LengthUnit.Meter,
        _lastRouteFrom!,
        _driverLocation,
      );
      if (moved < minMove) return;
    }

    await _fetchRoute(force: true);

    _lastRouteUpdateAt = now;
    _lastRouteFrom = _driverLocation;

    debugPrint(
      fast
          ? '⚡ Smart route update (FAST) speed=${_currentSpeed.toStringAsFixed(1)} offRoute=$_isOffRoute'
          : '🧠 Smart route update (NORMAL)',
    );
  }

  Future<void> _fetchLocations({bool updateOnly = false}) async {
    if (!mounted) return;

    try {
      // Fetch current vehicle assignment
      final now = DateTime.now();
      final todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final vehicleDataList =
          await supabase
                  .from('delivery_vehicle')
                  .select(
                    'vehicle!delivery_vehicle_plate_id_fkey(brand, model)',
                  )
                  .eq('delivery_driver_id', widget.driverId)
                  .lte('from_date', todayStr)
                  .gte('to_date', todayStr)
                  .order('from_date', ascending: false)
                  .limit(1)
              as List<dynamic>;

      if (vehicleDataList.isNotEmpty && mounted) {
        final vehicleData = vehicleDataList.first as Map<String, dynamic>;
        final vehicle = vehicleData['vehicle'] as Map<String, dynamic>?;
        setState(() {
          _currentVehicleBrand = vehicle?['brand'] as String?;
          _currentVehicleModel = vehicle?['model'] as String?;
        });
      }

      final driverData = await supabase
          .from('delivery_driver')
          .select(
            'delivery_driver_id, latitude_location, longitude_location, current_order_id',
          )
          .eq('delivery_driver_id', widget.driverId)
          .maybeSingle();

      if (driverData == null || !mounted) {
        debugPrint('⚠️ Driver data not found');
        return;
      }

      final lat = driverData['latitude_location'] as num?;
      final lng = driverData['longitude_location'] as num?;
      final currentOrderId = driverData['current_order_id'] as int?;

      if (lat != null && lng != null && mounted) {
        final newDriverLoc = LatLng(lat.toDouble(), lng.toDouble());
        _applyDriverLocationUpdate(newDriverLoc, animate: true);

        _updateSpeedAndPolling(newDriverLoc);
        _checkIfOffRoute();
      }

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
            .maybeSingle();

        if (orderData == null || !mounted) {
          debugPrint('⚠️ Order data not found for ID: $currentOrderId');
          return;
        }

        final customer = orderData['customer'] as Map<String, dynamic>?;
        final custLat = customer?['latitude_location'] as num?;
        final custLng = customer?['longitude_location'] as num?;

        if (custLat != null && custLng != null && mounted) {
          final newCustomerLoc = LatLng(custLat.toDouble(), custLng.toDouble());

          setState(() {
            _customerLocation = newCustomerLoc;
            _customerName = customer?['name'];
            _orderId = currentOrderId;
            _otherOrders = _otherOrders
                .where((o) => o['order_id'] != currentOrderId)
                .toList();
          });

          // ✅ أول ما يختار أوردر جديد: جيب مسار مباشرة (force)
          if (_previousOrderId != currentOrderId) {
            _fetchRoute(force: true);
            _previousOrderId = currentOrderId;
          }
        }

        // Other orders
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

          // Delivered today
          final deliveredOrdersRaw =
              await supabase
                      .from('customer_order')
                      .select(
                        'customer_order_id, customer:customer_id(name), customer_order_description(delivered_date)',
                      )
                      .eq('delivered_by_id', widget.driverId)
                      .eq('order_status', 'Delivered')
                      .limit(50)
                  as List<dynamic>;

          final today = DateTime.now();
          final todayStart = DateTime(today.year, today.month, today.day);
          final todayEnd = todayStart.add(const Duration(days: 1));

          final deliveredOrders =
              deliveredOrdersRaw.where((o) {
                final descriptions =
                    (o as Map<String, dynamic>)['customer_order_description']
                        as List<dynamic>?;
                if (descriptions == null ||
                    descriptions.isEmpty ||
                    descriptions.first['delivered_date'] == null) {
                  return false;
                }
                final deliveredDate = DateTime.parse(
                  descriptions.first['delivered_date'] as String,
                );
                return deliveredDate.isAfter(todayStart) &&
                    deliveredDate.isBefore(todayEnd);
              }).toList()..sort((a, b) {
                final aDate =
                    ((a as Map<String, dynamic>)['customer_order_description']
                                as List<dynamic>)
                            .first['delivered_date']
                        as String;
                final bDate =
                    ((b as Map<String, dynamic>)['customer_order_description']
                                as List<dynamic>)
                            .first['delivered_date']
                        as String;
                return DateTime.parse(bDate).compareTo(DateTime.parse(aDate));
              });

          final limitedDeliveredOrders = deliveredOrders.take(10).toList();

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
      } else if (mounted) {
        // current_order_id = null (انتهى الأوردر)
        final orderEnded = _previousOrderId != null && currentOrderId == null;

        if (orderEnded) {
          final endedOrderId = _previousOrderId;
          final endedCustomerName = _customerName;

          _mapController.move(_driverLocation, 14);

          setState(() {
            if (endedOrderId != null) {
              _otherOrders = [
                {'order_id': endedOrderId, 'name': endedCustomerName},
                ..._otherOrders.where((o) => o['order_id'] != endedOrderId),
              ];
            }
            _customerLocation = null;
            _customerName = null;
            _orderId = null;
            _routePoints = [];
          });

          _previousOrderId = null;
          _lastRouteFrom = null;
          _lastRouteUpdateAt = null;
        }

        final allOrders =
            await supabase
                    .from('customer_order')
                    .select('customer_order_id, customer:customer_id(name)')
                    .eq('delivered_by_id', widget.driverId)
                    .eq('order_status', 'Delivery')
                    .order('order_date', ascending: false)
                as List<dynamic>;

        final deliveredOrdersRaw =
            await supabase
                    .from('customer_order')
                    .select(
                      'customer_order_id, customer:customer_id(name), customer_order_description(delivered_date)',
                    )
                    .eq('delivered_by_id', widget.driverId)
                    .eq('order_status', 'Delivered')
                    .limit(50)
                as List<dynamic>;

        final today = DateTime.now();
        final todayStart = DateTime(today.year, today.month, today.day);
        final todayEnd = todayStart.add(const Duration(days: 1));

        final deliveredOrders =
            deliveredOrdersRaw.where((o) {
              final descriptions =
                  (o as Map<String, dynamic>)['customer_order_description']
                      as List<dynamic>?;
              if (descriptions == null ||
                  descriptions.isEmpty ||
                  descriptions.first['delivered_date'] == null) {
                return false;
              }
              final deliveredDate = DateTime.parse(
                descriptions.first['delivered_date'] as String,
              );
              return deliveredDate.isAfter(todayStart) &&
                  deliveredDate.isBefore(todayEnd);
            }).toList()..sort((a, b) {
              final aDate =
                  ((a as Map<String, dynamic>)['customer_order_description']
                              as List<dynamic>)
                          .first['delivered_date']
                      as String;
              final bDate =
                  ((b as Map<String, dynamic>)['customer_order_description']
                              as List<dynamic>)
                          .first['delivered_date']
                      as String;
              return DateTime.parse(bDate).compareTo(DateTime.parse(aDate));
            });

        final limitedDeliveredOrders = deliveredOrders.take(10).toList();

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
    } catch (e) {
      debugPrint('❌ Error fetching locations: $e');
    }
  }

  Future<void> _fetchRoute({bool force = false}) async {
    if (_customerLocation == null || _isRouting) return;

    // لو ما في أوردر شغال، لا تطلب مسار
    if (_orderId == null) return;

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

            if (_routePoints.isNotEmpty) {
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

  void _fitMapToRoute() {
    if (_routePoints.isEmpty) return;

    double minLat = _routePoints.first.latitude;
    double maxLat = _routePoints.first.latitude;
    double minLng = _routePoints.first.longitude;
    double maxLng = _routePoints.first.longitude;

    for (final point in _routePoints) {
      minLat = minLat > point.latitude ? point.latitude : minLat;
      maxLat = maxLat < point.latitude ? point.latitude : maxLat;
      minLng = minLng > point.longitude ? point.longitude : minLng;
      maxLng = maxLng < point.longitude ? point.longitude : maxLng;
    }

    final latPadding = (maxLat - minLat) * 0.002;
    final lngPadding = (maxLng - minLng) * 0.002;

    final paddedMinLat = minLat - latPadding;
    final paddedMaxLat = maxLat + latPadding;
    final paddedMinLng = minLng - lngPadding;
    final paddedMaxLng = maxLng + lngPadding;

    final centerLat = (paddedMinLat + paddedMaxLat) / 2;
    final centerLng = (paddedMinLng + paddedMaxLng) / 2;
    final center = LatLng(centerLat, centerLng);

    final latDelta = (paddedMaxLat - paddedMinLat).abs();
    final lngDelta = (paddedMaxLng - paddedMinLng).abs();

    double zoomLevel = 10.0;

    if (latDelta > 0 && lngDelta > 0) {
      final maxDelta = latDelta > lngDelta ? latDelta : lngDelta;
      zoomLevel = (log(360 / maxDelta) / log(2)) + 0.60;

      if (zoomLevel > 19.5) zoomLevel = 19.5;
      if (zoomLevel < 4) zoomLevel = 4;
    }

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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    widget.driverName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (_currentVehicleBrand != null &&
                                      _currentVehicleModel != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        'Vehicle: $_currentVehicleBrand $_currentVehicleModel',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                ],
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
                                      _orderId != null
                                          ? _orderId.toString()
                                          : '-',
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
                                        color: const Color(
                                          0xFF2196F3,
                                        ).withValues(alpha: 0.4),
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
                                      padding: const EdgeInsets.only(
                                        bottom: 17,
                                      ),
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
                                              borderRadius:
                                                  BorderRadius.circular(14),
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
                                                    o['order_id']?.toString() ??
                                                        '-',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.w700,
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
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
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
                                              padding:
                                                  const EdgeInsets.symmetric(
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
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.orangeAccent
                                                        .withValues(alpha: 0.3),
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
                                                      fontWeight:
                                                          FontWeight.w800,
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
                                      padding: const EdgeInsets.only(
                                        bottom: 16,
                                      ),
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
                                              borderRadius:
                                                  BorderRadius.circular(14),
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
                                                    o['order_id']?.toString() ??
                                                        '-',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.w700,
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
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
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
                                              padding:
                                                  const EdgeInsets.symmetric(
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
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.green
                                                        .withValues(alpha: 0.3),
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
                                                      fontWeight:
                                                          FontWeight.w800,
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
                            initialCenter: _driverMarkerLocation,
                            initialZoom: 14,
                            maxZoom: 20,
                          ),
                          children: [
                            TileLayer(
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
                                    // ✅ ما غيرنا اللون حسب طلبك
                                    color: Colors.blueAccent,
                                  ),
                                ],
                              ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: _driverMarkerLocation,
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

class LatLngTween extends Tween<LatLng> {
  LatLngTween({super.begin, super.end});

  @override
  LatLng lerp(double t) {
    final beginLat = begin?.latitude ?? 0.0;
    final beginLng = begin?.longitude ?? 0.0;
    final endLat = end?.latitude ?? 0.0;
    final endLng = end?.longitude ?? 0.0;

    final lat = beginLat + (endLat - beginLat) * t;
    final lng = beginLng + (endLng - beginLng) * t;
    return LatLng(lat, lng);
  }
}
