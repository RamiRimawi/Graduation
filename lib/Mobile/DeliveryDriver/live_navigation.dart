import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;
import '../../supabase_config.dart';

class LiveNavigation extends StatefulWidget {
  final String customerName;
  final String address;
  final double customerLatitude;
  final double customerLongitude;
  final int? orderId;
  final int deliveryDriverId;

  const LiveNavigation({
    super.key,
    required this.customerName,
    required this.address,
    required this.customerLatitude,
    required this.customerLongitude,
    this.orderId,
    required this.deliveryDriverId,
  });

  @override
  State<LiveNavigation> createState() => _LiveNavigationState();
}

class _LiveNavigationState extends State<LiveNavigation>
    with SingleTickerProviderStateMixin {
  MapController? _mapController;
  LatLng? _currentDriverLocation;
  LatLng? _previousLocation;

  // ✅ Smooth marker location (displayed point)
  LatLng? _animatedDriverLocation;

  // ✅ Marker animation
  late final AnimationController _markerAnimController;
  LatLng? _animFrom;
  LatLng? _animTo;

  List<LatLng> _routePoints = [];
  double _remainingDistance = 0;
  double _remainingTime = 0;

  double _currentBearing = 0; // exposed to UI
  double _smoothedBearing = 0; // internal smoothing
  double _currentSpeed = 0; // km/h
  double _gpsAccuracy = 0;

  StreamSubscription<Position>? _positionStream;
  Timer? _routeUpdateTimer;
  bool _arrivedAtDestination = false;
  bool _isFollowingDriver = true;

  // -------------------- ARRIVAL (5-10m only) --------------------
  int _arrivalHitCount = 0; // consecutive confirmations
  static const int _requiredArrivalHits = 4; // stricter
  static const double _arrivalMinMeters = 5.0; // do NOT show before 5m
  static const double _arrivalMaxMeters = 10.0; // show within 10m
  static const double _maxArrivalSpeedMps = 0.6; // ~2.1 km/h
  static const double _maxGpsAccuracyMeters = 25.0;

  // -------------------- Smooth / Filters --------------------
  static const int _markerAnimMs = 450;
  static const double _maxJumpMeters = 80.0;
  static const double _stationarySpeedMps = 0.05;
  static const double _stationaryMoveMeters = 0.5;

  // -------------------- SMART DB UPDATES --------------------
  DateTime? _lastDbUpdateAt;
  LatLng? _lastDbSentLocation;

  // send faster when driving, slower when stopped
  static const Duration _dbMinIntervalFast = Duration(seconds: 2);
  static const Duration _dbMidInterval = Duration(seconds: 4);
  static const Duration _dbMaxIntervalSlow = Duration(seconds: 7);

  static const double _dbMinMoveMetersFast = 8.0;  // if moving fast, send if >= 8m
  static const double _dbMinMoveMetersMid = 12.0;  // mid speed
  static const double _dbMinMoveMetersSlow = 18.0; // slow/stationary (reduce noise)

  // -------------------- SMART ROUTE UPDATES --------------------
  DateTime? _lastRouteUpdateAt;
  LatLng? _lastRouteFrom;
  bool _isRouting = false;
  bool _isOffRoute = false;
  
  static const double _offRouteThresholdMeters = 50.0; // 50 متر
  static const Duration _routeMinInterval = Duration(seconds: 12);
  static const Duration _routeFastInterval = Duration(seconds: 4); // ✅ جديد
  static const double _routeUpdateMoveMeters = 25.0;
  static const double _routeFastMoveMeters = 10.0; // ✅ جديد

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    _markerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _markerAnimMs),
    );

    _markerAnimController.addListener(() {
      if (_animFrom == null || _animTo == null) return;
      final t = _markerAnimController.value;

      final lat =
          _animFrom!.latitude + (_animTo!.latitude - _animFrom!.latitude) * t;
      final lng =
          _animFrom!.longitude + (_animTo!.longitude - _animFrom!.longitude) * t;

      _animatedDriverLocation = LatLng(lat, lng);

      if (_isFollowingDriver && _animatedDriverLocation != null) {
        _followDriver();
      }

      if (mounted) setState(() {});
    });

    _startLiveTracking();

    // ✅ route timer موجود، لكن “ذكي” (مش كل مرة فعلاً بعمل update)
    _routeUpdateTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _maybeUpdateRoute(),
    );
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _routeUpdateTimer?.cancel();
    _markerAnimController.dispose();
    super.dispose();
  }

  // -------------------- LIVE GPS --------------------
  Future<void> _startLiveTracking() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final initialPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.bestForNavigation,
        );

        final initLoc = LatLng(
          initialPosition.latitude,
          initialPosition.longitude,
        );

        _gpsAccuracy = initialPosition.accuracy;

        final initialBearing = _calculateBearing(
          initLoc,
          LatLng(widget.customerLatitude, widget.customerLongitude),
        );

        setState(() {
          _currentDriverLocation = initLoc;
          _previousLocation = initLoc;
          _animatedDriverLocation = initLoc;
          _smoothedBearing = initialBearing;
          _currentBearing = initialBearing;
        });

        // ✅ Zoom على موقع السائق عند بداية الصفحة
        _mapController?.move(initLoc, 17.0);

        await _updateRoute(); // initial route

        const LocationSettings locationSettings = LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 5,
        );

        _positionStream = Geolocator.getPositionStream(
          locationSettings: locationSettings,
        ).listen((Position position) {
          _handleNewPosition(position);
        });
      }
    } catch (e) {
      debugPrint('Error starting live tracking: $e');
    }
  }

  void _handleNewPosition(Position position) {
    final newLocation = LatLng(position.latitude, position.longitude);
    _gpsAccuracy = position.accuracy;

    // ignore bad accuracy
    if (position.accuracy > _maxGpsAccuracyMeters) {
      debugPrint(
        '⏳ Ignoring update (poor GPS accuracy): ${position.accuracy.toStringAsFixed(1)}m',
      );
      return;
    }

    double movedMeters = double.infinity;
    if (_currentDriverLocation != null) {
      movedMeters = _calculateDistance(_currentDriverLocation!, newLocation) * 1000;

      // ignore crazy jumps
      if (movedMeters > _maxJumpMeters && position.speed < 5) {
        debugPrint('⚠️ Ignoring GPS jump: ${movedMeters.toStringAsFixed(1)}m');
        return;
      }
    }

    // speed
    if (position.speed > 0) {
      _currentSpeed = position.speed * 3.6;
    } else {
      _currentSpeed = 0;
    }

    final isStationary =
        movedMeters <= _stationaryMoveMeters && position.speed <= _stationarySpeedMps;

    // ✅ look-ahead point for bearing (car-like)
    final lookAheadPoint = _getLookAheadPoint(newLocation, position.speed);

    double rawBearing;
    if (_previousLocation != null && _currentSpeed > 1) {
      rawBearing = _calculateBearing(_previousLocation!, lookAheadPoint);
    } else {
      rawBearing = _calculateBearing(
        newLocation,
        LatLng(widget.customerLatitude, widget.customerLongitude),
      );
    }

    // ✅ smoothAngle
    final smooth = _smoothAngleDegrees(
      current: _smoothedBearing,
      target: rawBearing,
      factor: 0.18, // smaller = smoother
    );

    setState(() {
      _previousLocation = _currentDriverLocation;
      _currentDriverLocation = newLocation;

      _smoothedBearing = smooth;
      _currentBearing = smooth;
    });

    if (!isStationary) {
      _animateMarkerTo(newLocation);
    }

    // ✅ SMART DB update here (no fixed timer)
    _maybeUpdateLocationInDatabase(newLocation, position.speed);

    // ✅ off-route check (smart)
    _checkIfOffRoute(newLocation);

    // ✅ arrival (5-10m only)
    _checkArrival(newLocation, position.accuracy, position.speed);
  }

  // -------------------- SMART DB UPDATES --------------------
  Future<void> _maybeUpdateLocationInDatabase(LatLng loc, double speedMps) async {
    final now = DateTime.now();
    final lastAt = _lastDbUpdateAt;

    // Decide thresholds by speed
    final speedKmh = speedMps * 3.6;

    Duration minInterval;
    double minMoveMeters;

    if (speedKmh > 40) {
      minInterval = _dbMinIntervalFast;
      minMoveMeters = _dbMinMoveMetersFast;
    } else if (speedKmh > 10) {
      minInterval = _dbMidInterval;
      minMoveMeters = _dbMinMoveMetersMid;
    } else {
      minInterval = _dbMaxIntervalSlow;
      minMoveMeters = _dbMinMoveMetersSlow;
    }

    // If never sent, send once
    if (_lastDbSentLocation == null || lastAt == null) {
      await _updateLocationInDatabase(loc);
      _lastDbSentLocation = loc;
      _lastDbUpdateAt = now;
      return;
    }

    // time gate
    if (now.difference(lastAt) < minInterval) return;

    // movement gate
    final moved = Distance().as(LengthUnit.Meter, _lastDbSentLocation!, loc);
    if (moved < minMoveMeters) return;

    await _updateLocationInDatabase(loc);
    _lastDbSentLocation = loc;
    _lastDbUpdateAt = now;
  }

  Future<void> _updateLocationInDatabase(LatLng loc) async {
    try {
      await supabase
          .from('delivery_driver')
          .update({
            'latitude_location': loc.latitude,
            'longitude_location': loc.longitude,
          })
          .eq('delivery_driver_id', widget.deliveryDriverId);

      debugPrint('📍 Location updated in DB (smart)');
    } catch (e) {
      debugPrint('❌ Error updating location: $e');
    }
  }

  // -------------------- ROUTE SMART UPDATES --------------------
  void _checkIfOffRoute(LatLng driverLoc) {
    if (_routePoints.isEmpty) {
      if (_isOffRoute) setState(() => _isOffRoute = false);
      return;
    }

    final distToRoute = _getMinDistanceToRoute(driverLoc, _routePoints);
    final nowOff = distToRoute > _offRouteThresholdMeters;

    if (nowOff != _isOffRoute) {
      setState(() => _isOffRoute = nowOff);
      debugPrint(nowOff
          ? '⚠️ Off-route: ${distToRoute.toStringAsFixed(1)}m'
          : '✅ Back on route');
    }
  }

  Future<void> _maybeUpdateRoute() async {
  if (_currentDriverLocation == null) return;

  final now = DateTime.now();

  // ✅ لو سريع أو خارج المسار: تحديث أسرع
  final bool fast = _isOffRoute || _currentSpeed > 50;

  final minInterval = fast ? _routeFastInterval : _routeMinInterval;
  final minMove = fast ? _routeFastMoveMeters : _routeUpdateMoveMeters;

  // time gate
  if (_lastRouteUpdateAt != null &&
      now.difference(_lastRouteUpdateAt!) < minInterval) {
    return;
  }

  // movement gate
  if (_lastRouteFrom != null) {
    final moved = Distance().as(
      LengthUnit.Meter,
      _lastRouteFrom!,
      _currentDriverLocation!,
    );
    if (moved < minMove) return;
  }

  await _updateRoute();
  _lastRouteUpdateAt = now;
  _lastRouteFrom = _currentDriverLocation;
}

  Future<void> _updateRoute() async {
    if (_currentDriverLocation == null) return;
    if (_isRouting) return;

    _isRouting = true;

    try {
      final startPoint = _currentDriverLocation!;
      final endPoint = LatLng(widget.customerLatitude, widget.customerLongitude);

      final String url =
          'https://router.project-osrm.org/route/v1/driving/${startPoint.longitude},${startPoint.latitude};${endPoint.longitude},${endPoint.latitude}?overview=full&geometries=geojson';

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];

          final coordinates = route['geometry']['coordinates'] as List;
          final newRoutePoints = coordinates
              .map((coord) => LatLng(coord[1] as double, coord[0] as double))
              .toList();

          final newDistance = (route['distance'] as num).toDouble() / 1000;
          final newDuration = (route['duration'] as num).toDouble() / 60;

          if (!mounted) return;
          setState(() {
            _routePoints = newRoutePoints;
            _remainingDistance = newDistance;
            _remainingTime = newDuration;
          });

          debugPrint(
            '🔄 Route updated (smart): ${newDistance.toStringAsFixed(1)} km, ${newDuration.toStringAsFixed(0)} min',
          );
        }
      }
    } catch (e) {
      debugPrint('Error updating route: $e');
    } finally {
      _isRouting = false;
    }
  }

  // -------------------- ARRIVAL (5-10m window) --------------------
  void _checkArrival(
    LatLng currentLocation,
    double gpsAccuracy,
    double speedMps,
  ) {
    if (_arrivedAtDestination) return;

    if (gpsAccuracy > _maxGpsAccuracyMeters) {
      _arrivalHitCount = 0;
      return;
    }

    final destinationPoint = LatLng(widget.customerLatitude, widget.customerLongitude);

    final distanceInMeters =
        _calculateDistance(currentLocation, destinationPoint) * 1000;

    final withinWindow =
        distanceInMeters >= _arrivalMinMeters &&
        distanceInMeters <= _arrivalMaxMeters;

    final inside = withinWindow && speedMps <= _maxArrivalSpeedMps;

    if (inside) {
      _arrivalHitCount++;
      debugPrint(
        '🎯 Arrival window: ${distanceInMeters.toStringAsFixed(1)}m, speed ${speedMps.toStringAsFixed(2)} m/s, hit #$_arrivalHitCount/$_requiredArrivalHits',
      );

      if (_arrivalHitCount >= _requiredArrivalHits) {
        setState(() => _arrivedAtDestination = true);
        _showArrivalDialog();
      }
    } else {
      _arrivalHitCount = 0;
    }
  }

  // -------------------- Utils --------------------
  double _calculateBearing(LatLng start, LatLng end) {
    final lat1 = start.latitude * math.pi / 180;
    final lat2 = end.latitude * math.pi / 180;
    final dLon = (end.longitude - start.longitude) * math.pi / 180;

    final y = math.sin(dLon) * math.cos(lat2);
    final x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    final bearing = math.atan2(y, x) * 180 / math.pi;
    return (bearing + 360) % 360;
  }

  double _smoothAngleDegrees({
    required double current,
    required double target,
    required double factor,
  }) {
    // shortest delta in [-180, 180]
    double delta = (target - current) % 360;
    if (delta > 180) delta -= 360;
    if (delta < -180) delta += 360;

    final next = (current + delta * factor) % 360;
    return next < 0 ? next + 360 : next;
  }

  LatLng _getLookAheadPoint(LatLng current, double speedMps) {
    // look ahead distance depends on speed (clamped)
    final double lookAheadMeters = (speedMps * 2.0).clamp(8.0, 35.0);

    final double bearingRad = _smoothedBearing * math.pi / 180;

    // simple "move point" on earth
    const double earthRadius = 6378137.0;
    final double lat1 = current.latitude * math.pi / 180;
    final double lon1 = current.longitude * math.pi / 180;
    final double d = lookAheadMeters / earthRadius;

    final double lat2 = math.asin(
      math.sin(lat1) * math.cos(d) +
          math.cos(lat1) * math.sin(d) * math.cos(bearingRad),
    );

    final double lon2 = lon1 +
        math.atan2(
          math.sin(bearingRad) * math.sin(d) * math.cos(lat1),
          math.cos(d) - math.sin(lat1) * math.sin(lat2),
        );

    return LatLng(lat2 * 180 / math.pi, lon2 * 180 / math.pi);
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Kilometer, point1, point2);
  }

  double _getMinDistanceToRoute(LatLng point, List<LatLng> route) {
    if (route.isEmpty) return double.infinity;

    double minDistance = double.infinity;
    final Distance distance = Distance();

    for (int i = 0; i < route.length - 1; i++) {
      final a = route[i];
      final b = route[i + 1];
      final d = _distanceToSegmentMeters(point, a, b, distance);
      if (d < minDistance) minDistance = d;
    }

    return minDistance;
  }

  double _distanceToSegmentMeters(
    LatLng p,
    LatLng a,
    LatLng b,
    Distance distance,
  ) {
    final ax = a.longitude;
    final ay = a.latitude;
    final bx = b.longitude;
    final by = b.latitude;
    final px = p.longitude;
    final py = p.latitude;

    final abx = bx - ax;
    final aby = by - ay;
    final apx = px - ax;
    final apy = py - ay;

    final ab2 = abx * abx + aby * aby;
    if (ab2 == 0) return distance.as(LengthUnit.Meter, p, a);

    double t = (apx * abx + apy * aby) / ab2;
    t = t.clamp(0.0, 1.0);

    final cx = ax + abx * t;
    final cy = ay + aby * t;

    return distance.as(LengthUnit.Meter, p, LatLng(cy, cx));
  }

  void _animateMarkerTo(LatLng target) {
    final from = _animatedDriverLocation ?? _currentDriverLocation ?? target;

    _animFrom = from;
    _animTo = target;

    _markerAnimController.stop();
    _markerAnimController.duration = const Duration(milliseconds: _markerAnimMs);
    _markerAnimController.forward(from: 0);
  }

  void _followDriver() {
    if (_mapController == null) return;

    final followPoint = _animatedDriverLocation ?? _currentDriverLocation;
    if (followPoint == null) return;

    double zoom = 17.0;
    if (_currentSpeed > 60) {
      zoom = 15.5;
    } else if (_currentSpeed > 40) {
      zoom = 16.0;
    } else if (_currentSpeed > 20) {
      zoom = 16.5;
    }

    _mapController!.move(followPoint, zoom);
  }

  Future<void> _clearCurrentOrderId() async {
    try {
      await supabase
          .from('delivery_driver')
          .update({'current_order_id': null})
          .eq('delivery_driver_id', widget.deliveryDriverId);

      debugPrint('✅ Cleared current_order_id for driver ${widget.deliveryDriverId}');
    } catch (e) {
      debugPrint('❌ Error clearing current_order_id: $e');
    }
  }

  void _showArrivalDialog() {
    _clearCurrentOrderId();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text(
          'Arrived at Destination!',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'You have arrived at the customer location.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK', style: TextStyle(color: Color(0xFFB7A447))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final destinationLocation = LatLng(widget.customerLatitude, widget.customerLongitude);

    return Scaffold(
      backgroundColor: const Color(0xFF202020),
      body: SafeArea(
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentDriverLocation ?? destinationLocation,
                initialZoom: 17.0,
                minZoom: 10.0,
                maxZoom: 19.0,
                keepAlive: true,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
                onPositionChanged: (position, hasGesture) {
                  if (hasGesture) {
                    setState(() {
                      _isFollowingDriver = false;
                    });
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.dolphin',
                  tileProvider: NetworkTileProvider(),
                ),

                if (_routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routePoints,
                        strokeWidth: 8.0,
                        color: const Color(0xFF42A5F5),
                      ),
                    ],
                  ),

                MarkerLayer(
                  markers: [
                    if ((_animatedDriverLocation ?? _currentDriverLocation) != null)
                      Marker(
                        point: _animatedDriverLocation ?? _currentDriverLocation!,
                        width: 70.0,
                        height: 70.0,
                        alignment: Alignment.center,
                        child: Transform.rotate(
                          angle: _currentBearing * math.pi / 180,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2196F3).withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 45,
                                height: 45,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.navigation,
                                  color: Color(0xFF2196F3),
                                  size: 30,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    Marker(
                      point: destinationLocation,
                      width: 50.0,
                      height: 50.0,
                      alignment: Alignment.center,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5252),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.place,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D2D).withOpacity(0.95),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFB7A447).withOpacity(0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person, color: Color(0xFFB7A447), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.customerName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Color(0xFFFF4444), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.address,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            Positioned(
              top: 130,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D2D).withOpacity(0.95),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _isFollowingDriver ? const Color(0xFF2196F3) : Colors.white60,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.my_location,
                    color: _isFollowingDriver ? const Color(0xFF2196F3) : Colors.white60,
                    size: 28,
                  ),
                  onPressed: () {
                    setState(() {
                      _isFollowingDriver = true;
                    });
                    if ((_animatedDriverLocation ?? _currentDriverLocation) != null) {
                      _followDriver();
                    }
                  },
                ),
              ),
            ),

            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D2D).withOpacity(0.98),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF2196F3).withOpacity(0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            Text(
                              _remainingTime > 0 ? _remainingTime.toStringAsFixed(0) : '--',
                              style: const TextStyle(
                                color: Color(0xFF2196F3),
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text('min', style: TextStyle(color: Colors.white70, fontSize: 14)),
                          ],
                        ),
                        Container(width: 2, height: 40, color: Colors.white30),
                        Column(
                          children: [
                            Text(
                              _remainingDistance > 0 ? _remainingDistance.toStringAsFixed(1) : '--',
                              style: const TextStyle(
                                color: Color(0xFF2196F3),
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text('km', style: TextStyle(color: Colors.white70, fontSize: 14)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: const Color(0xFF2D2D2D),
                            title: const Text('End Navigation?', style: TextStyle(color: Colors.white)),
                            content: const Text(
                              'Are you sure you want to stop navigation?',
                              style: TextStyle(color: Colors.white70),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel', style: TextStyle(color: Color(0xFFB7A447))),
                              ),
                              TextButton(
                                onPressed: () async {
                                  await _clearCurrentOrderId();
                                  if (!mounted) return;
                                  Navigator.pop(context);
                                  Navigator.pop(context);
                                  Navigator.pop(context);
                                },
                                child: const Text('End Route', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF4444),
                        minimumSize: const Size(double.infinity, 42),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'End Route',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
