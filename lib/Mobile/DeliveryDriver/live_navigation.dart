import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'dart:convert';
import 'dart:async';
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

class _LiveNavigationState extends State<LiveNavigation> {
  MapController? _mapController;
  LatLng? _currentDriverLocation;
  List<LatLng> _routePoints = [];
  double _remainingDistance = 0;
  double _remainingTime = 0;
  StreamSubscription<Position>? _positionStream;
  StreamSubscription<CompassEvent>? _compassStream;
  Timer? _routeUpdateTimer;
  Timer? _locationUpdateTimer;
  bool _arrivedAtDestination = false;
  // Arrival detection helpers
  DateTime? _arrivalEnteredAt;
  final Duration _arrivalDwell = const Duration(seconds: 5);
  final double _arrivalThresholdKm = 0.05; // 50 meters
  final double _speedThresholdMps = 1.5; // ~5.4 km/h
  DateTime? _lastUpdate;
  int _updateCount = 0;
  bool _compassMode = true;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _startLiveTracking();
    _startLocationUpdates();
    _startCompassTracking();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _compassStream?.cancel();
    _routeUpdateTimer?.cancel();
    _locationUpdateTimer?.cancel();
    super.dispose();
  }

  void _startLocationUpdates() {
    _locationUpdateTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _updateLocationInDatabase(),
    );
  }

  void _startCompassTracking() {
    _compassStream = FlutterCompass.events?.listen((CompassEvent event) {
      if (_compassMode && _currentDriverLocation != null) {
        double heading = event.heading ?? 0;
        
        // تحويل الاتجاه من 0-360 درجة إلى راديان للخريطة
        // نستخدم القيمة السالبة لأن الدوران في الخريطة عكس عقارب الساعة
        double rotation = -heading * (3.141592653589793 / 180.0);

        // تدوير الخريطة بناءً على اتجاه الجهاز
        _mapController?.rotate(rotation);
        
        debugPrint('🧭 Compass heading: ${heading.toStringAsFixed(1)}°');
      }
    });
  }

  Future<void> _updateLocationInDatabase() async {
    if (_currentDriverLocation == null) return;

    try {
      await supabase
          .from('delivery_driver')
          .update({
            'latitude_location': _currentDriverLocation!.latitude,
            'longitude_location': _currentDriverLocation!.longitude,
          })
          .eq('delivery_driver_id', widget.deliveryDriverId);

      debugPrint('📍 Location updated in DB: ${_currentDriverLocation!.latitude}, ${_currentDriverLocation!.longitude}');
    } catch (e) {
      debugPrint('❌ Error updating location in database: $e');
    }
  }

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
          desiredAccuracy: LocationAccuracy.high,
        );
        
        setState(() {
          _currentDriverLocation = LatLng(
            initialPosition.latitude, 
            initialPosition.longitude
          );
        });

        await _updateRoute();

        const LocationSettings locationSettings = LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        );

        _positionStream = Geolocator.getPositionStream(
          locationSettings: locationSettings,
        ).listen((Position position) {
          final newLocation = LatLng(position.latitude, position.longitude);
          
          setState(() {
            _currentDriverLocation = newLocation;
          });

          _mapController?.move(newLocation, 17.0);
          
          final distanceToDestination = _calculateDistance(
            newLocation,
            LatLng(widget.customerLatitude, widget.customerLongitude),
          );

          // Arrival logic: require either low speed OR dwell inside radius
          if (!_arrivedAtDestination) {
            final bool withinRadius = distanceToDestination < _arrivalThresholdKm;
            final double speed = position.speed; // m/s, 0 if unknown/stationary

            if (withinRadius) {
              // If device moving slowly (stopped/near stopped), treat as arrived
              if (speed >= 0 && speed <= _speedThresholdMps) {
                _handleArrival();
              } else {
                // not slow enough yet: start dwell timer
                _arrivalEnteredAt ??= DateTime.now();
                final entered = _arrivalEnteredAt!;
                if (DateTime.now().difference(entered) >= _arrivalDwell) {
                  _handleArrival();
                }
              }
            } else {
              // left the radius: reset dwell timestamp
              _arrivalEnteredAt = null;
            }
          }

          debugPrint('🚚 Driver moved to: $newLocation');
          debugPrint('📏 Distance to destination: ${distanceToDestination.toStringAsFixed(3)} km');
        });

        _routeUpdateTimer = Timer.periodic(
          const Duration(seconds: 30),
          (_) => _updateRoute(),
        );
      }
    } catch (e) {
      debugPrint('Error starting live tracking: $e');
    }
  }

  Future<void> _updateRoute() async {
    if (_currentDriverLocation == null) return;

    try {
      final startPoint = _currentDriverLocation!;
      final endPoint = LatLng(widget.customerLatitude, widget.customerLongitude);

      final String url =
          'https://router.project-osrm.org/route/v1/driving/${startPoint.longitude},${startPoint.latitude};${endPoint.longitude},${endPoint.latitude}?overview=full&geometries=geojson';

      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
      );

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

          setState(() {
            _routePoints = newRoutePoints;
            _remainingDistance = newDistance;
            _remainingTime = newDuration;
            _lastUpdate = DateTime.now();
            _updateCount++;
          });

          debugPrint('🔄 Route updated (#$_updateCount): ${newDistance.toStringAsFixed(1)} km, ${newDuration.toStringAsFixed(0)} min');
          debugPrint('⏰ Update time: ${_lastUpdate.toString()}');
        }
      }
    } catch (e) {
      debugPrint('Error updating route: $e');
    }
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Kilometer, point1, point2);
  }



  void _showArrivalDialog() {
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
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close live_navigation
              Navigator.pop(context); // Close route_map_deleviry
            },
            child: const Text(
              'OK',
              style: TextStyle(color: Color(0xFFB7A447)),
            ),
          ),
        ],
      ),
    );
  }

  void _handleArrival() {
    if (_arrivedAtDestination) return;
    setState(() {
      _arrivedAtDestination = true;
    });

    // Show arrival dialog (keeps the previous behavior)
    _showArrivalDialog();
  }

  @override
  Widget build(BuildContext context) {
    final destinationLocation = LatLng(
      widget.customerLatitude, 
      widget.customerLongitude
    );

    return Scaffold(
      backgroundColor: const Color(0xFF202020),
      body: SafeArea(
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentDriverLocation ?? destinationLocation,
                initialZoom: 16.0,
                minZoom: 8.0,
                maxZoom: 18.0,
                bounds: LatLngBounds(
                  LatLng(31.45, 34.70),
                  LatLng(32.60, 35.70),
                ),
                boundsOptions: const FitBoundsOptions(
                  padding: EdgeInsets.all(50.0),
                ),
                interactiveFlags: _compassMode 
                    ? InteractiveFlag.all 
                    : InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              children: [
                TileLayer(
                  // استخدم مزود بمفتاح لتفادي حجب OSM
                  urlTemplate: 'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=dkYOU5miikUvzB2wvCgJ',
                  userAgentPackageName: 'com.example.dolphin',
                  tileProvider: NetworkTileProvider(),
                ),
                if (_routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routePoints,
                        strokeWidth: 5.0,
                        color: const Color(0xFF2196F3),
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    if (_currentDriverLocation != null)
                      Marker(
                        point: _currentDriverLocation!,
                        width: 60.0,
                        height: 60.0,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2196F3).withOpacity(0.3),
                                shape: BoxShape.circle,
                              ),
                            ),
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2196F3),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.4),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.navigation,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Marker(
                      point: destinationLocation,
                      width: 50.0,
                      height: 50.0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF4444),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
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
            Positioned(
              top: 130,
              right: 16,
              child: Column(
                children: [
                  // زر تبديل وضع البوصلة
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D2D2D).withOpacity(0.95),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _compassMode 
                            ? const Color(0xFF2196F3) 
                            : const Color(0xFFB7A447).withOpacity(0.3),
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
                        Icons.explore,
                        color: _compassMode 
                            ? const Color(0xFF2196F3) 
                            : Colors.white70,
                        size: 28,
                      ),
                      onPressed: () {
                        setState(() {
                          _compassMode = !_compassMode;
                          if (!_compassMode) {
                            // إعادة تعيين دوران الخريطة عند إيقاف وضع البوصلة
                            _mapController?.rotate(0);
                          }
                        });
                      },
                      tooltip: _compassMode 
                          ? 'تعطيل وضع البوصلة' 
                          : 'تفعيل وضع البوصلة',
                    ),
                  ),
                  const SizedBox(height: 12),
                  // زر العودة إلى الموقع الحالي
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D2D2D).withOpacity(0.95),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFB7A447).withOpacity(0.3),
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
                      icon: const Icon(
                        Icons.my_location,
                        color: Colors.white70,
                        size: 28,
                      ),
                      onPressed: () {
                        if (_currentDriverLocation != null) {
                          _mapController?.move(_currentDriverLocation!, 16.0);
                        }
                      },
                      tooltip: 'العودة إلى موقعي',
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D2D).withOpacity(0.98),
                  borderRadius: BorderRadius.circular(20),
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
                              _remainingTime > 0 
                                  ? '${_remainingTime.toStringAsFixed(0)}'
                                  : '--',
                              style: const TextStyle(
                                color: Color(0xFF2196F3),
                                fontSize: 36,
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
                        Container(
                          width: 2,
                          height: 50,
                          color: Colors.white30,
                        ),
                        Column(
                          children: [
                            Text(
                              _remainingDistance > 0
                                  ? '${_remainingDistance.toStringAsFixed(1)}'
                                  : '--',
                              style: const TextStyle(
                                color: Color(0xFF2196F3),
                                fontSize: 36,
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
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
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
                                onPressed: () => Navigator.pop(context),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(color: Color(0xFFB7A447)),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context); // Close dialog
                                  Navigator.pop(context); // Close live_navigation
                                  Navigator.pop(context); // Close route_map_deleviry, return to deleviry_detail
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
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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
