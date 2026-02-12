import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import '../../supabase_config.dart';

// ✅ Top-level helper (Dart ما بسمح class جوّا class)
class _SnapResult {
  final LatLng point;
  final double distMeters;
  const _SnapResult(this.point, this.distMeters);
}

class _RouteSnapResult {
  final LatLng point;
  final double distMeters;
  final int segmentIndex;
  const _RouteSnapResult(this.point, this.distMeters, this.segmentIndex);
}

// -------------------- 1D KALMAN FILTER --------------------
class _Kalman1D {
  double x; // state
  double p; // covariance
  final double q; // process noise
  final double r; // measurement noise

  _Kalman1D({
    required this.x,
    required this.p,
    required this.q,
    required this.r,
  });

  double update(double z) {
    // predict
    p = p + q;

    // update
    final k = p / (p + r);
    x = x + k * (z - x);
    p = (1 - k) * p;
    return x;
  }
}

// -------------------- 2D KALMAN (Lat/Lng) --------------------
class _Kalman2D {
  _Kalman1D lat;
  _Kalman1D lng;

  _Kalman2D({
    required double lat0,
    required double lng0,
    required double q,
    required double r,
  }) : lat = _Kalman1D(x: lat0, p: 1, q: q, r: r),
       lng = _Kalman1D(x: lng0, p: 1, q: q, r: r);

  LatLng update(LatLng z) {
    final fLat = lat.update(z.latitude);
    final fLng = lng.update(z.longitude);
    return LatLng(fLat, fLng);
  }

  LatLng get state => LatLng(lat.x, lng.x);
}

// -----------------------------------------------------------

class LiveNavigation extends StatefulWidget {
  final String customerName;
  final String address;
  final double customerLatitude;
  final double customerLongitude;
  final int? orderId;
  final int deliveryDriverId;
  final LatLng? initialDriverLocation;

  const LiveNavigation({
    super.key,
    required this.customerName,
    required this.address,
    required this.customerLatitude,
    required this.customerLongitude,
    this.orderId,
    required this.deliveryDriverId,
    this.initialDriverLocation,
  });

  @override
  State<LiveNavigation> createState() => _LiveNavigationState();
}

class _LiveNavigationState extends State<LiveNavigation>
    with SingleTickerProviderStateMixin {
  mapbox.MapboxMap? _mapboxMap;
  bool _isMapReady = false;
  mapbox.CameraOptions? _pendingCamera;

  mapbox.PointAnnotationManager? _driverPointManager;
  mapbox.PointAnnotation? _driverPoint;
  mapbox.PointAnnotationManager? _destPointManager;
  mapbox.PointAnnotation? _destPoint;
  mapbox.PolylineAnnotationManager? _routeLineManager;
  mapbox.PolylineAnnotation? _routeLine;

  Uint8List? _driverIconBytes;
  Uint8List? _destIconBytes;
  bool _isCreatingDriverMarker = false;
  bool _isCreatingDestMarker = false;
  bool _isStyleReady = false;

  LatLng? _currentDriverLocation; // ✅ filtered + locked (the truth in UI)
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
  double _routeBearing = 0; // route direction bearing
  double _currentSpeed = 0; // km/h
  double _gpsAccuracy = 0;

  StreamSubscription<Position>? _positionStream;
  Timer? _routeUpdateTimer;
  bool _isFollowingDriver = true;

  // -------------------- Smooth / Filters --------------------
  static const int _markerAnimMsDefault = 450;

  // قفزات (لما تحرك الموبايل بسرعة أو GPS يخرب)
  static const double _maxJumpMeters = 60.0; // كان 80 -> شددناه
  static const double _maxJumpWhenSlowMeters = 25.0; // لو السرعة قليلة: شد أكتر
  static const double _ignoreJumpIfSpeedLessThan = 1.0; // m/s

  // Max allowed GPS accuracy before ignoring the sample
  static const double _maxGpsAccuracyMeters = 35.0;

  // Stop lock
  static const double _stopSpeedMps = 0.8; // أقل من هيك اعتبره واقف
  static const double _stopLockRadiusMeters =
      6.0; // وهو واقف: لا تسمح يتحرك أكثر من 6m
  static const int _stopLockHitsToEnable = 4; // كم قراءة “واقف” قبل ما نقفل
  int _stopHits = 0;
  bool _stopLocked = false;
  LatLng? _stopAnchor; // النقطة اللي بنثبت عليها وهو واقف

  // -------------------- KALMAN --------------------
  _Kalman2D? _kalman;
  bool _kalmanReady = false;

  // Kalman tuning (أساسي)
  // q أقل = smoother أكثر بس بطئ بالاستجابة
  // r أعلى = ثقة أقل بالGPS (فلترة أكثر)
  static const double _kalmanQ = 1e-6;
  static const double _kalmanRGood = 2e-5;
  static const double _kalmanRBad = 8e-5;

  // -------------------- SMART DB UPDATES --------------------
  DateTime? _lastDbUpdateAt;
  LatLng? _lastDbSentLocation;

  static const Duration _dbMinIntervalFast = Duration(seconds: 2);
  static const Duration _dbMidInterval = Duration(seconds: 4);
  static const Duration _dbMaxIntervalSlow = Duration(seconds: 7);

  static const double _dbMinMoveMetersFast = 8.0;
  static const double _dbMinMoveMetersMid = 12.0;
  static const double _dbMinMoveMetersSlow = 18.0;

  // -------------------- SMART ROUTE UPDATES --------------------
  DateTime? _lastRouteUpdateAt;
  LatLng? _lastRouteFrom;
  bool _isRouting = false;
  bool _isOffRoute = false;
  bool _didSetInitialRouteBearing = false;

  static const double _offRouteThresholdMeters = 50.0;
  static const Duration _routeMinInterval = Duration(seconds: 2);
  static const Duration _routeFastInterval = Duration(seconds: 1); // ✅ أسرع للخروج من المسار
  static const double _routeUpdateMoveMeters = 4.0;
  static const double _routeFastMoveMeters = 4.0; // ✅ أقل مسافة = تحديث أسرع

  // -------------------- PREDICTION (LIVE) --------------------
  Timer? _predictionTimer;
  DateTime _lastGpsAt = DateTime.now();
  double _lastSpeedMps = 0.0;
  double _lastHeadingDeg = 0.0;

  static const int _predictionTickMs = 60; // ~16fps
  static const int _predictionMaxAgeMs = 900; // كان 1200 -> قللناه لتخفيف الوهم
  static const double _predictionMinSpeedMps = 1.3; // prediction فقط لو سريع

  // -------------------- CAMERA THROTTLE --------------------
  DateTime _lastFollowAt = DateTime.fromMillisecondsSinceEpoch(0);

  // -------------------- SNAP TO ROUTE --------------------
  bool _snapEnabled = true;
  static const double _snapMaxDistanceMeters = 25.0;
  static const double _snapMinSpeedMps = 2.0;

  // -------------------- DESTINATION SNAP OVERRIDE --------------------
  // لما تقرب من الزبون: خلي القياس raw/kalman بدون snap قوي عشان ما يمنع الوصول
  static const double _nearDestNoSnapMeters = 60.0;

  // -------------------- MAPBOX --------------------
  static const String _mapboxAccessToken =
      'pk.eyJ1IjoicmFtYWRhbjk2IiwiYSI6ImNtbGh4eHMyMzA1d20zY3Fzem54aHZtNGQifQ.sB2yvST_wLvszakHkT7Npg';
    static const String _mapStyleUri =
      'mapbox://styles/mapbox/streets-v12';
      static const String _mapStyleUriDark =
        'mapbox://styles/mapbox/dark-v11';
  static const double _navPitchDeg = 60.0;
      static const Duration _cameraAnimDuration = Duration(milliseconds: 500);

      bool _isDarkStyle = false;

  @override
  void initState() {
    super.initState();
    mapbox.MapboxOptions.setAccessToken(_mapboxAccessToken);

    if (widget.initialDriverLocation != null) {
      _primeFromInitialLocation(widget.initialDriverLocation!);
    }

    _markerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _markerAnimMsDefault),
    );

    _markerAnimController.addListener(() {
      if (_animFrom == null || _animTo == null) return;
      final t = _markerAnimController.value;

      final lat =
          _animFrom!.latitude + (_animTo!.latitude - _animFrom!.latitude) * t;
      final lng =
          _animFrom!.longitude +
          (_animTo!.longitude - _animFrom!.longitude) * t;

      _animatedDriverLocation = LatLng(lat, lng);
      if (_animatedDriverLocation != null) {
        _updateDriverMarker(_animatedDriverLocation!);
      }

      if (_isFollowingDriver && _animatedDriverLocation != null) {
        _followDriverThrottled();
      }

      if (mounted) setState(() {});
    });

    _startPredictionTimer(); // ✅ live movement between GPS updates
    _startLiveTracking();

    _routeUpdateTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _maybeUpdateRoute(),
    );
  }

  void _primeFromInitialLocation(LatLng initial) {
    final heading = _calculateBearing(
      initial,
      LatLng(widget.customerLatitude, widget.customerLongitude),
    );

    _kalman = _Kalman2D(
      lat0: initial.latitude,
      lng0: initial.longitude,
      q: _kalmanQ,
      r: _kalmanRGood,
    );
    _kalmanReady = true;

    setState(() {
      _currentDriverLocation = initial;
      _previousLocation = initial;
      _animatedDriverLocation = initial;
      _smoothedBearing = heading;
      _currentBearing = heading;
    });

    _updateDestinationMarker();
    _updateDriverMarker(initial);

    _safeMove(initial, 17.0); // ✅ زوم مثل الصورة
    _updateRoute();
  }

  @override
  void dispose() {
    _predictionTimer?.cancel();
    _positionStream?.cancel();
    _routeUpdateTimer?.cancel();
    _markerAnimController.dispose();
    super.dispose();
  }

  // -------------------- PREDICTION TIMER --------------------
  void _startPredictionTimer() {
    _predictionTimer?.cancel();
    _predictionTimer = Timer.periodic(
      const Duration(milliseconds: _predictionTickMs),
      (_) => _tickPrediction(),
    );
  }

  void _tickPrediction() {
    // ✅ Simplified - removed stop lock check for smoother animation
    final base = _animatedDriverLocation ?? _currentDriverLocation;
    if (base == null) return;

    final ageMs = DateTime.now().difference(_lastGpsAt).inMilliseconds;
    if (ageMs > _predictionMaxAgeMs) return;

    if (_lastSpeedMps < _predictionMinSpeedMps) return;
    if (_currentSpeed < (_predictionMinSpeedMps * 3.6)) return;

    final dt = _predictionTickMs / 1000.0;
    final moveMeters = _lastSpeedMps * dt;

    final rawNext = _movePointMeters(base, _lastHeadingDeg, moveMeters);

    // ✅ prediction يستخدم snap فقط إذا مش قريب من الوجهة
    final next = _applySnapSmart(rawNext, speedMps: _lastSpeedMps);

    _animatedDriverLocation = next;
    _updateDriverMarker(next);

    if (_isFollowingDriver) _followDriverThrottled();
    if (mounted) setState(() {});
  }

  LatLng _movePointMeters(LatLng start, double bearingDeg, double meters) {
    const double earthRadius = 6378137.0;
    final double br = bearingDeg * math.pi / 180;

    final double lat1 = start.latitude * math.pi / 180;
    final double lon1 = start.longitude * math.pi / 180;
    final double d = meters / earthRadius;

    final double lat2 = math.asin(
      math.sin(lat1) * math.cos(d) +
          math.cos(lat1) * math.sin(d) * math.cos(br),
    );

    final double lon2 =
        lon1 +
        math.atan2(
          math.sin(br) * math.sin(d) * math.cos(lat1),
          math.cos(d) - math.sin(lat1) * math.sin(lat2),
        );

    return LatLng(lat2 * 180 / math.pi, lon2 * 180 / math.pi);
  }

  // -------------------- LIVE GPS --------------------
  Future<void> _startLiveTracking() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled && !kIsWeb) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final accuracy = kIsWeb
          ? LocationAccuracy.high
          : LocationAccuracy.bestForNavigation;

      final initialPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: accuracy,
        timeLimit: const Duration(seconds: 10),
      );

      final initLoc = LatLng(
        initialPosition.latitude,
        initialPosition.longitude,
      );
      _gpsAccuracy = initialPosition.accuracy;

      // init kalman
      _kalman = _Kalman2D(
        lat0: initLoc.latitude,
        lng0: initLoc.longitude,
        q: _kalmanQ,
        r: (initialPosition.accuracy <= 15) ? _kalmanRGood : _kalmanRBad,
      );
      _kalmanReady = true;

      // initial heading/bearing
      if (initialPosition.heading.isFinite && initialPosition.heading >= 0) {
        _lastHeadingDeg = initialPosition.heading;
      } else {
        _lastHeadingDeg = _calculateBearing(
          initLoc,
          LatLng(widget.customerLatitude, widget.customerLongitude),
        );
      }

      setState(() {
        _currentDriverLocation = initLoc;
        _previousLocation = initLoc;
        _animatedDriverLocation = initLoc;
        _smoothedBearing = _lastHeadingDeg;
        _currentBearing = _lastHeadingDeg;
      });

      _updateDestinationMarker();
      _updateDriverMarker(initLoc);

      _safeMove(initLoc, 17.0); // ✅ زوم مثل الصورة
      await _updateRoute(); // initial route

      // ✅ faster stream on Android
      final LocationSettings locationSettings = kIsWeb
          ? const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 5,
            )
          : AndroidSettings(
              accuracy: LocationAccuracy.bestForNavigation,
              distanceFilter: 1,
              intervalDuration: const Duration(milliseconds: 300),
            );

      _positionStream =
          Geolocator.getPositionStream(
            locationSettings: locationSettings,
          ).listen(
            (Position position) => _handleNewPosition(position),
            onError: (e) => debugPrint('❌ Position stream error: $e'),
          );
    } catch (e) {
      debugPrint('❌ Error starting live tracking: $e');
    }
  }

  void _handleNewPosition(Position position) {
    final rawGps = LatLng(position.latitude, position.longitude);
    _gpsAccuracy = position.accuracy;

    // store for prediction
    _lastGpsAt = DateTime.now();
    _lastSpeedMps = (position.speed.isFinite && position.speed > 0)
        ? position.speed
        : 0.0;

    // ignore poor accuracy
    final maxAccuracy = kIsWeb ? 50.0 : _maxGpsAccuracyMeters;
    if (position.accuracy > maxAccuracy) {
      debugPrint(
        '⏳ Ignoring poor accuracy: ${position.accuracy.toStringAsFixed(1)}m',
      );
      return;
    }

    // speed (km/h)
    _currentSpeed = (position.speed > 0) ? position.speed * 3.6 : 0;

    // -------------------- KALMAN UPDATE --------------------
    LatLng filtered = rawGps;
    if (_kalmanReady && _kalman != null) {
      // dynamic R based on accuracy
      final r = (position.accuracy <= 15) ? _kalmanRGood : _kalmanRBad;
      _kalman!.lat.p = _kalman!.lat.p; // no-op (just clarity)
      _kalman!.lng.p = _kalman!.lng.p; // no-op
      // recreate r by updating internal (simple approach)
      _kalman!.lat = _Kalman1D(
        x: _kalman!.lat.x,
        p: _kalman!.lat.p,
        q: _kalmanQ,
        r: r,
      );
      _kalman!.lng = _Kalman1D(
        x: _kalman!.lng.x,
        p: _kalman!.lng.p,
        q: _kalmanQ,
        r: r,
      );

      filtered = _kalman!.update(rawGps);
    }

    // -------------------- JUMP FILTER --------------------
    if (_currentDriverLocation != null) {
      final jump = Distance().as(
        LengthUnit.Meter,
        _currentDriverLocation!,
        filtered,
      );

      final speedMps = position.speed.isFinite ? position.speed : 0.0;
      final jumpLimit = (speedMps < _ignoreJumpIfSpeedLessThan)
          ? _maxJumpWhenSlowMeters
          : _maxJumpMeters;

      if (jump > jumpLimit) {
        debugPrint(
          '⚠️ Ignoring jump: ${jump.toStringAsFixed(1)}m (limit $jumpLimit)',
        );
        return;
      }
    }

    // -------------------- STOP LOCK (DISABLED FOR SMOOTH MOVEMENT) --------------------
    // ✅ Disabled stop lock to allow continuous smooth movement like old code
    _stopHits = 0;
    _stopLocked = false;
    _stopAnchor = null;

    // ✅ Define speedMps BEFORE using it
    final speedMps = position.speed.isFinite ? position.speed : 0.0;

    // -------------------- SNAP (SMART) --------------------
    final snapped = _applySnapSmart(filtered, speedMps: speedMps);

    // moved meters (after filters)
    double movedMeters = double.infinity;
    if (_currentDriverLocation != null) {
      movedMeters = _calculateDistance(_currentDriverLocation!, snapped) * 1000;
    }

    // bearing
    final lookAheadPoint = _getLookAheadPoint(snapped, speedMps);
    final routeBearing = _calculateRouteBearing(snapped);

    double rawBearing;
    final speedKmh = speedMps * 3.6;

    if (position.heading.isFinite && position.heading >= 0 && speedKmh >= 5.0) {
      // ✅ Use device heading when moving fast and heading is valid
      rawBearing = position.heading;
    } else if (_previousLocation != null && speedKmh > 1.0) {
      // ✅ Use look-ahead point for smoother car-like rotation
      rawBearing = _calculateBearing(_previousLocation!, lookAheadPoint);
    } else {
      // fallback: point to destination or keep last heading
      rawBearing = _calculateBearing(
        snapped,
        LatLng(widget.customerLatitude, widget.customerLongitude),
      );
    }

    final didSnap = Distance().as(LengthUnit.Meter, filtered, snapped) > 1;
    if (didSnap && _routePoints.length > 1 && !_isOffRoute) {
      rawBearing = routeBearing;
    }

    final bearingDiff = _angleDiffDegrees(_smoothedBearing, rawBearing).abs();

    double speedFactor;
    if (speedKmh >= 40) {
      speedFactor = 0.45;
    } else if (speedKmh >= 20) {
      speedFactor = 0.32;
    } else if (speedKmh >= 5) {
      speedFactor = 0.22;
    } else {
      speedFactor = 0.14;
    }

    final diffFactor = bearingDiff > 45
        ? 0.50
        : (bearingDiff > 25)
        ? 0.36
        : 0.24;

    final bearingFactor = math.max(speedFactor, diffFactor);

    final smooth = _smoothAngleDegrees(
      current: _smoothedBearing,
      target: rawBearing,
      factor: bearingFactor,
    );

    final smoothRouteBearing = _smoothAngleDegrees(
      current: _routeBearing,
      target: routeBearing,
      factor: 0.22,
    );

    setState(() {
      _previousLocation = _currentDriverLocation;
      _currentDriverLocation = snapped;

      _smoothedBearing = smooth;
      _currentBearing = smooth;
      _routeBearing = smoothRouteBearing;

      _lastHeadingDeg = smooth;
    });

    // -------------------- MARKER UPDATE --------------------
    // ✅ Simple animation like old code - always animate when position changes
    if (movedMeters.isFinite && movedMeters > 0.5) {
      _animateMarkerToSmart(snapped, speedMps);
    } else {
      _animatedDriverLocation = snapped;
      _updateDriverMarker(snapped);
      if (mounted) setState(() {});
    }

    // -------------------- DB + OFF-ROUTE --------------------
    _maybeUpdateLocationInDatabase(snapped, speedMps);

    _checkIfOffRoute(snapped);
    if (!_isOffRoute) {
      _trimRouteBehind(snapped);
    }
  }

  // -------------------- SMART SNAP --------------------
  LatLng _applySnapSmart(LatLng raw, {required double speedMps}) {
    // لو قريب من الوجهة: لا تعمل snap قوي
    final dest = LatLng(widget.customerLatitude, widget.customerLongitude);
    final distToDest = Distance().as(LengthUnit.Meter, raw, dest);
    if (distToDest <= _nearDestNoSnapMeters) return raw;

    if (_isOffRoute) return raw;

    return _applySnapIfNeeded(raw, speedMps: speedMps);
  }

  // -------------------- SMART DB UPDATES --------------------
  Future<void> _maybeUpdateLocationInDatabase(
    LatLng loc,
    double speedMps,
  ) async {
    final now = DateTime.now();
    final lastAt = _lastDbUpdateAt;

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

    // لو واقف: لا تبعت DB كثير (خفف الداتا)
    if (_stopLocked) {
      minInterval = const Duration(seconds: 10);
      minMoveMeters = 20.0;
    }

    if (_lastDbSentLocation == null || lastAt == null) {
      await _updateLocationInDatabase(loc);
      _lastDbSentLocation = loc;
      _lastDbUpdateAt = now;
      return;
    }

    if (now.difference(lastAt) < minInterval) return;

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
    }
  }

  Future<void> _maybeUpdateRoute() async {
    if (_currentDriverLocation == null) return;

    final now = DateTime.now();
    final bool fast = _isOffRoute || _currentSpeed > 50;

    final minInterval = fast ? _routeFastInterval : _routeMinInterval;
    final minMove = fast ? _routeFastMoveMeters : _routeUpdateMoveMeters;

    if (_lastRouteUpdateAt != null &&
        now.difference(_lastRouteUpdateAt!) < minInterval) {
      return;
    }

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
      final endPoint = LatLng(
        widget.customerLatitude,
        widget.customerLongitude,
      );

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

          if (!_didSetInitialRouteBearing && _currentDriverLocation != null) {
            final initialBearing = _calculateRouteBearing(_currentDriverLocation!);
            setState(() {
              _routeBearing = initialBearing;
              _smoothedBearing = initialBearing;
              _currentBearing = initialBearing;
            });
            _didSetInitialRouteBearing = true;
            if (_isFollowingDriver) {
              _followDriverThrottled();
            }
          }

          _updateRouteLine();

          debugPrint(
            '🔄 Route updated: ${newDistance.toStringAsFixed(1)} km, ${newDuration.toStringAsFixed(0)} min',
          );
        }
      }
    } catch (e) {
      debugPrint('Error updating route: $e');
    } finally {
      _isRouting = false;
    }
  }

  // -------------------- SNAP HELPERS --------------------
  _SnapResult _closestPointOnSegmentMeters(LatLng p, LatLng a, LatLng b) {
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
    if (ab2 == 0) {
      final d = const Distance().as(LengthUnit.Meter, p, a);
      return _SnapResult(a, d);
    }

    double t = (apx * abx + apy * aby) / ab2;
    t = t.clamp(0.0, 1.0);

    final cx = ax + abx * t;
    final cy = ay + aby * t;

    final c = LatLng(cy, cx);
    final d = const Distance().as(LengthUnit.Meter, p, c);
    return _SnapResult(c, d);
  }

  _SnapResult? _snapToRoutePoint(LatLng p) {
    if (_routePoints.length < 2) return null;

    double best = double.infinity;
    LatLng? bestPoint;

    for (int i = 0; i < _routePoints.length - 1; i++) {
      final a = _routePoints[i];
      final b = _routePoints[i + 1];

      final res = _closestPointOnSegmentMeters(p, a, b);
      if (res.distMeters < best) {
        best = res.distMeters;
        bestPoint = res.point;
      }
    }

    if (bestPoint == null) return null;
    return _SnapResult(bestPoint, best);
  }

  _RouteSnapResult? _snapToRoutePointWithIndex(LatLng p) {
    if (_routePoints.length < 2) return null;

    double best = double.infinity;
    LatLng? bestPoint;
    int bestIndex = 0;

    for (int i = 0; i < _routePoints.length - 1; i++) {
      final a = _routePoints[i];
      final b = _routePoints[i + 1];

      final res = _closestPointOnSegmentMeters(p, a, b);
      if (res.distMeters < best) {
        best = res.distMeters;
        bestPoint = res.point;
        bestIndex = i;
      }
    }

    if (bestPoint == null) return null;
    return _RouteSnapResult(bestPoint, best, bestIndex);
  }

  void _trimRouteBehind(LatLng current) {
    if (_routePoints.length < 2) return;

    final snap = _snapToRoutePointWithIndex(current);
    if (snap == null) return;

    if (snap.segmentIndex < 0 || snap.segmentIndex >= _routePoints.length - 1) {
      return;
    }

    if (snap.distMeters > _snapMaxDistanceMeters * 2) {
      return;
    }

    final newPoints = <LatLng>[snap.point, ..._routePoints.sublist(snap.segmentIndex + 1)];
    if (newPoints.length == _routePoints.length) return;

    setState(() {
      _routePoints = newPoints;
    });
    _updateRouteLine();
  }

  LatLng _applySnapIfNeeded(LatLng raw, {required double speedMps}) {
    if (!_snapEnabled) return raw;
    if (_routePoints.length < 2) return raw;
    if (speedMps < _snapMinSpeedMps) return raw;

    final snapRes = _snapToRoutePoint(raw);
    if (snapRes == null) return raw;

    if (snapRes.distMeters <= _snapMaxDistanceMeters) {
      return snapRes.point;
    }
    return raw;
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

  double _calculateRouteBearing(LatLng currentLocation) {
    if (_routePoints.isEmpty || _routePoints.length < 2) {
      return _calculateBearing(
        currentLocation,
        LatLng(widget.customerLatitude, widget.customerLongitude),
      );
    }

    double minDistance = double.infinity;
    int closestSegmentIndex = 0;
    final Distance distance = Distance();

    for (int i = 0; i < _routePoints.length - 1; i++) {
      final segmentDist = _distanceToSegmentMeters(
        currentLocation,
        _routePoints[i],
        _routePoints[i + 1],
        distance,
      );

      if (segmentDist < minDistance) {
        minDistance = segmentDist;
        closestSegmentIndex = i;
      }
    }

    final segmentStart = _routePoints[closestSegmentIndex];
    final segmentEnd = _routePoints[closestSegmentIndex + 1];

    return _calculateBearing(segmentStart, segmentEnd);
  }

  double _smoothAngleDegrees({
    required double current,
    required double target,
    required double factor,
  }) {
    double delta = (target - current) % 360;
    if (delta > 180) delta -= 360;
    if (delta < -180) delta += 360;

    final next = (current + delta * factor) % 360;
    return next < 0 ? next + 360 : next;
  }

  double _angleDiffDegrees(double from, double to) {
    double delta = (to - from) % 360;
    if (delta > 180) delta -= 360;
    if (delta < -180) delta += 360;
    return delta;
  }

  LatLng _getLookAheadPoint(LatLng current, double speedMps) {
    final double lookAheadMeters = (speedMps * 2.0).clamp(8.0, 35.0);
    final double bearingRad = _smoothedBearing * math.pi / 180;

    const double earthRadius = 6378137.0;
    final double lat1 = current.latitude * math.pi / 180;
    final double lon1 = current.longitude * math.pi / 180;
    final double d = lookAheadMeters / earthRadius;

    final double lat2 = math.asin(
      math.sin(lat1) * math.cos(d) +
          math.cos(lat1) * math.sin(d) * math.cos(bearingRad),
    );

    final double lon2 =
        lon1 +
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

  // ✅ Simple animation like old code
  void _animateMarkerTo(LatLng target) {
    final from = _animatedDriverLocation ?? _currentDriverLocation ?? target;

    _animFrom = from;
    _animTo = target;

    _markerAnimController.stop();
    _markerAnimController.duration = const Duration(milliseconds: _markerAnimMsDefault);
    _markerAnimController.forward(from: 0);
  }

  // ✅ smart animation duration based on move distance
  void _animateMarkerToSmart(LatLng target, double speedMps) {
    final from = _animatedDriverLocation ?? _currentDriverLocation ?? target;

    final moved = Distance().as(LengthUnit.Meter, from, target);
    final ms = (moved * 8)
        .clamp(140.0, 650.0)
        .toInt();

    _animFrom = from;
    _animTo = target;

    _markerAnimController.stop();
    _markerAnimController.duration = Duration(milliseconds: ms);
    _markerAnimController.forward(from: 0);
  }

  mapbox.Point _pointFromLatLng(LatLng point) {
    return mapbox.Point(
      coordinates: mapbox.Position(point.longitude, point.latitude),
    );
  }

  void _onMapCreated(mapbox.MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
    _isMapReady = true;
    _isStyleReady = false;

    _mapboxMap!.compass.updateSettings(
      mapbox.CompassSettings(enabled: false),
    );
    _mapboxMap!.scaleBar.updateSettings(
      mapbox.ScaleBarSettings(enabled: false),
    );
    _mapboxMap!.logo.updateSettings(
      mapbox.LogoSettings(enabled: false),
    );
    _mapboxMap!.attribution.updateSettings(
      mapbox.AttributionSettings(enabled: false),
    );
    _mapboxMap!.location.updateSettings(
      mapbox.LocationComponentSettings(enabled: false),
    );

    if (_pendingCamera != null) {
      _mapboxMap!.setCamera(_pendingCamera!);
      _pendingCamera = null;
    }
  }

  Future<void> _onStyleLoaded(mapbox.StyleLoadedEventData data) async {
    if (_mapboxMap == null) return;

    _routeLineManager =
      await _mapboxMap!.annotations.createPolylineAnnotationManager();
    _driverPointManager =
      await _mapboxMap!.annotations.createPointAnnotationManager();
    _destPointManager =
      await _mapboxMap!.annotations.createPointAnnotationManager();

    _driverPoint = null;
    _destPoint = null;
    _routeLine = null;
    _isStyleReady = true;

    await _ensureMarkerImages();

    await _updateRouteLine();
    await _updateDestinationMarker();

    final driverPoint = _animatedDriverLocation ?? _currentDriverLocation;
    if (driverPoint != null) {
      await _updateDriverMarker(driverPoint);
    }
  }

  Future<void> _updateDriverMarker(LatLng loc) async {
    if (!_isStyleReady) return;
    if (_driverPointManager == null || _driverIconBytes == null) return;

    if (_driverPoint == null) {
      if (_isCreatingDriverMarker) return;
      _isCreatingDriverMarker = true;
      await _driverPointManager!.deleteAll();
      _driverPoint = await _driverPointManager!.create(
        mapbox.PointAnnotationOptions(
          geometry: _pointFromLatLng(loc),
          image: _driverIconBytes!,
        ),
      );
      _isCreatingDriverMarker = false;
      return;
    }

    _driverPoint!..geometry = _pointFromLatLng(loc);
    await _driverPointManager!.update(_driverPoint!);
  }

  Future<void> _updateDestinationMarker() async {
    if (!_isStyleReady) return;
    if (_destPointManager == null || _destIconBytes == null) return;

    final dest = LatLng(widget.customerLatitude, widget.customerLongitude);

    if (_destPoint == null) {
      if (_isCreatingDestMarker) return;
      _isCreatingDestMarker = true;
      await _destPointManager!.deleteAll();
      _destPoint = await _destPointManager!.create(
        mapbox.PointAnnotationOptions(
          geometry: _pointFromLatLng(dest),
          image: _destIconBytes!,
        ),
      );
      _isCreatingDestMarker = false;
      return;
    }

    _destPoint!..geometry = _pointFromLatLng(dest);
    await _destPointManager!.update(_destPoint!);
  }

  Future<void> _ensureMarkerImages() async {
    if (_driverIconBytes == null) {
      _driverIconBytes = await _renderDriverIconBytes(120);
    }
    if (_destIconBytes == null) {
      _destIconBytes = await _renderDestinationIconBytes(96);
    }
  }

  Future<Uint8List> _renderDriverIconBytes(double size) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final center = Offset(size / 2, size / 2);

    final outerPaint = Paint()..color = const Color(0x262196F3);
    canvas.drawCircle(center, size * 0.48, outerPaint);

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.18)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 6);
    canvas.drawCircle(center, size * 0.33, shadowPaint);

    final whitePaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, size * 0.32, whitePaint);
    canvas.drawCircle(center, size * 0.28, whitePaint);

    final icon = Icons.navigation;
    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          fontSize: size * 0.36,
          color: const Color(0xFF2196F3),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final iconOffset = Offset(
      center.dx - iconPainter.width / 2,
      center.dy - iconPainter.height / 2,
    );
    iconPainter.paint(canvas, iconOffset);

    final image = await recorder.endRecording().toImage(
      size.toInt(),
      size.toInt(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<Uint8List> _renderDestinationIconBytes(double size) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final center = Offset(size / 2, size / 2);

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.25)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 6);
    canvas.drawCircle(center, size * 0.36, shadowPaint);

    final redPaint = Paint()..color = const Color(0xFFFF5252);
    canvas.drawCircle(center, size * 0.32, redPaint);

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.08
      ..color = Colors.white;
    canvas.drawCircle(center, size * 0.32, strokePaint);

    final icon = Icons.place;
    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          fontSize: size * 0.42,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final iconOffset = Offset(
      center.dx - iconPainter.width / 2,
      center.dy - iconPainter.height / 2,
    );
    iconPainter.paint(canvas, iconOffset);

    final image = await recorder.endRecording().toImage(
      size.toInt(),
      size.toInt(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<void> _updateRouteLine() async {
    if (!_isStyleReady) return;
    if (_routeLineManager == null) return;

    if (_routePoints.isEmpty) {
      if (_routeLine != null) {
        await _routeLineManager!.delete(_routeLine!);
        _routeLine = null;
      }
      return;
    }

    final geometry = mapbox.LineString(
      coordinates: _routePoints
          .map((p) => mapbox.Position(p.longitude, p.latitude))
          .toList(),
    );

    if (_routeLine == null) {
      _routeLine = await _routeLineManager!.create(
        mapbox.PolylineAnnotationOptions(
          geometry: geometry,
          lineColor: 0xFF42A5F5,
          lineWidth: 6.0,
        ),
      );
      return;
    }

    _routeLine!
      ..geometry = geometry
      ..lineColor = 0xFF42A5F5
      ..lineWidth = 6.0;

    await _routeLineManager!.update(_routeLine!);
  }

  void _followDriverThrottled() {
    final now = DateTime.now();
    if (now.difference(_lastFollowAt) < const Duration(milliseconds: 200))
      return;
    _lastFollowAt = now;

    if (_mapboxMap == null) return;
    if (!_isMapReady) return;

    final followPoint = _animatedDriverLocation ?? _currentDriverLocation;
    if (followPoint == null) return;

    // ✅ Fixed zoom for smoother experience - no zoom changes during navigation
    const double zoom = 17.0; // رؤية واسعة ومستقرة

    // ✅ Rotate map so movement direction is always up (Navigation Mode)
    // Prefer current bearing, but fall back to route bearing when speed is low.
    final mapBearing = _getFollowBearing();
    _safeMoveAndRotate(followPoint, zoom, mapBearing);
  }

  double _getFollowBearing() {
    if (_currentSpeed >= 5) {
      return _currentBearing % 360;
    }

    if (_routePoints.length > 1) {
      return _routeBearing % 360;
    }

    return _currentBearing % 360;
  }

  Future<void> _clearCurrentOrderId() async {
    try {
      await supabase
          .from('delivery_driver')
          .update({'current_order_id': null})
          .eq('delivery_driver_id', widget.deliveryDriverId);
    } catch (e) {
      debugPrint('❌ Error clearing current_order_id: $e');
    }
  }

  void _popAfterDialog(BuildContext context, int times) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      for (var i = 0; i < times; i++) {
        if (!mounted) return;
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          return;
        }
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final destinationLocation = LatLng(
      widget.customerLatitude,
      widget.customerLongitude,
    );
    return Scaffold(
      backgroundColor: const Color(0xFF202020),
      body: SafeArea(
        child: Stack(
          children: [
            mapbox.MapWidget(
              key: const ValueKey('live-nav-mapbox'),
              styleUri: _isDarkStyle ? _mapStyleUriDark : _mapStyleUri,
              cameraOptions: mapbox.CameraOptions(
                center: mapbox.Point(
                  coordinates: mapbox.Position(
                    (_currentDriverLocation ?? destinationLocation).longitude,
                    (_currentDriverLocation ?? destinationLocation).latitude,
                  ),
                ),
                zoom: 17.0,
                bearing: _currentBearing,
                pitch: _navPitchDeg,
              ),
              onMapCreated: _onMapCreated,
              onStyleLoadedListener: _onStyleLoaded,
              onScrollListener: (_) {
                if (_isFollowingDriver) {
                  setState(() => _isFollowingDriver = false);
                }
              },
            ),

            // Top card
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
                        const Icon(
                          Icons.person,
                          color: Color(0xFFB7A447),
                          size: 20,
                        ),
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
                        const Icon(
                          Icons.location_on,
                          color: Color(0xFFFF4444),
                          size: 20,
                        ),
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

            // Follow button
            Positioned(
              top: 130,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D2D).withOpacity(0.95),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _isFollowingDriver
                        ? const Color(0xFF2196F3) // أزرق - نشط
                        : const Color(0xFF9E9E9E), // رمادي سكني - غير نشط
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
                    color: _isFollowingDriver
                        ? const Color(0xFF2196F3) // أزرق - متابعة نشطة
                        : const Color(0xFF9E9E9E), // رمادي سكني - غير نشط
                    size: 28,
                  ),
                  // ✅ لا يمكن الضغط إذا كان نشط بالفعل
                  onPressed: _isFollowingDriver ? null : () {
                    setState(() => _isFollowingDriver = true);
                    
                    // ✅ Recalculate correct bearing to fix inverted map issue
                    final followPoint = _animatedDriverLocation ?? _currentDriverLocation;
                    if (followPoint != null && _mapboxMap != null && _isMapReady) {
                      // Use the current smoothed bearing from state (most accurate)
                      final mapBearing = _getFollowBearing();
                      const double zoom = 17.0;
                      _safeMoveAndRotate(followPoint, zoom, mapBearing);
                    }
                  },
                ),
              ),
            ),

            // Dark mode toggle
            Positioned(
              top: 200,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D2D).withOpacity(0.95),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _isDarkStyle
                        ? const Color(0xFF90CAF9)
                        : const Color(0xFF9E9E9E),
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
                    _isDarkStyle ? Icons.dark_mode : Icons.light_mode,
                    color: _isDarkStyle
                        ? const Color(0xFF90CAF9)
                        : const Color(0xFFB0BEC5),
                    size: 26,
                  ),
                  onPressed: () async {
                    final nextStyle = !_isDarkStyle;
                    setState(() => _isDarkStyle = nextStyle);
                    await _setMapStyle(nextStyle);
                  },
                ),
              ),
            ),

            // Bottom card
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
                    if (_isOffRoute)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.warning, color: Colors.orange, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Off route',
                              style: TextStyle(color: Colors.orange),
                            ),
                          ],
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            Text(
                              _remainingTime > 0
                                  ? _remainingTime.toStringAsFixed(0)
                                  : '--',
                              style: const TextStyle(
                                color: Color(0xFF2196F3),
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'min',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        Container(width: 2, height: 40, color: Colors.white30),
                        Column(
                          children: [
                            Text(
                              _remainingDistance > 0
                                  ? _remainingDistance.toStringAsFixed(1)
                                  : '--',
                              style: const TextStyle(
                                color: Color(0xFF2196F3),
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'km',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                          final parentContext = context;
                        showDialog(
                            context: parentContext,
                            builder: (dialogContext) => AlertDialog(
                            backgroundColor: const Color(0xFF2D2D2D),
                            title: const Text(
                              'End Navigation?',
                              style: TextStyle(color: Colors.white),
                            ),
                            content: const Text(
                              'Are you sure you want to stop navigation?',
                              style: TextStyle(color: Colors.white70),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialogContext),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(color: Color(0xFFB7A447)),
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  await _clearCurrentOrderId();
                                  if (!mounted) return;
                                  Navigator.pop(dialogContext);
                                  _popAfterDialog(parentContext, 2);
                                },
                                child: const Text(
                                  'End Route',
                                  style: TextStyle(color: Colors.red),
                                ),
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

  void _safeMove(LatLng center, double zoom) {
    _setCamera(center, zoom, null, animate: false);
  }

  void _safeMoveAndRotate(LatLng center, double zoom, double bearingDeg) {
    _setCamera(center, zoom, bearingDeg, animate: true);
  }

  void _setCamera(
    LatLng center,
    double zoom,
    double? bearingDeg, {
    required bool animate,
  }) {
    final camera = mapbox.CameraOptions(
      center: mapbox.Point(
        coordinates: mapbox.Position(center.longitude, center.latitude),
      ),
      zoom: zoom,
      bearing: bearingDeg,
      pitch: _navPitchDeg,
    );

    if (_mapboxMap == null || !_isMapReady) {
      _pendingCamera = camera;
      return;
    }

    if (animate) {
      _mapboxMap!.easeTo(
        camera,
        mapbox.MapAnimationOptions(duration: _cameraAnimDuration.inMilliseconds),
      );
    } else {
      _mapboxMap!.setCamera(camera);
    }
  }

  Future<void> _setMapStyle(bool isDark) async {
    if (_mapboxMap == null) return;

    _isStyleReady = false;
    await _driverPointManager?.deleteAll();
    await _destPointManager?.deleteAll();
    await _routeLineManager?.deleteAll();

    _driverPointManager = null;
    _destPointManager = null;
    _routeLineManager = null;
    _driverPoint = null;
    _destPoint = null;
    _routeLine = null;

    final styleUri = isDark ? _mapStyleUriDark : _mapStyleUri;
    _mapboxMap!.loadStyleURI(styleUri);
  }
}