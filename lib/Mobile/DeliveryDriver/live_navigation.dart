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

class _LiveNavigationState extends State<LiveNavigation> with TickerProviderStateMixin {
  MapController? _mapController;
  LatLng? _currentDriverLocation;
  LatLng? _previousLocation;
  List<LatLng> _routePoints = [];
  double _remainingDistance = 0;
  double _remainingTime = 0;
  double _currentBearing = 0;
  double _currentSpeed = 0;
  StreamSubscription<Position>? _positionStream;
  Timer? _routeUpdateTimer;
  Timer? _dbUpdateTimer;
  bool _arrivedAtDestination = false;
  bool _isFollowingDriver = true;
  
  late AnimationController _rotationAnimationController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    
    _rotationAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _rotationAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(
        parent: _rotationAnimationController,
        curve: Curves.easeInOut,
      ),
    )..addListener(() {
      if (_isFollowingDriver) {
        _mapController?.rotate(_rotationAnimation.value);
      }
    });
    
    _startLiveTracking();
    _startDatabaseUpdates();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _routeUpdateTimer?.cancel();
    _dbUpdateTimer?.cancel();
    _rotationAnimationController.dispose();
    super.dispose();
  }

  void _startDatabaseUpdates() {
    _dbUpdateTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _updateLocationInDatabase(),
    );
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

      debugPrint('📍 Location updated in DB');
    } catch (e) {
      debugPrint('❌ Error updating location: $e');
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
          _previousLocation = _currentDriverLocation;
        });

        await _updateRoute();

        const LocationSettings locationSettings = LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 3,
          timeLimit: Duration(seconds: 1),
        );

        _positionStream = Geolocator.getPositionStream(
          locationSettings: locationSettings,
        ).listen((Position position) {
          _handleNewPosition(position);
        });

        _routeUpdateTimer = Timer.periodic(
          const Duration(seconds: 20),
          (_) => _updateRoute(),
        );
      }
    } catch (e) {
      debugPrint('Error starting live tracking: $e');
    }
  }

  void _handleNewPosition(Position position) {
    final newLocation = LatLng(position.latitude, position.longitude);

    if (_previousLocation != null) {
      final distance = _calculateDistance(_previousLocation!, newLocation);
      
      // Update speed
      if (position.speed > 0) {
        _currentSpeed = position.speed * 3.6; // m/s to km/h
      } else {
        _currentSpeed = 0;
      }
      
      // Update bearing only if moved significantly
      if (distance > 0.005) { // 5 meters
        final bearing = _calculateBearing(_previousLocation!, newLocation);
        
        setState(() {
          _currentBearing = bearing;
        });
        
        // Rotate map to follow direction
        if (_isFollowingDriver) {
          _smoothRotateMap(-bearing);
        }
        
        debugPrint('🧭 Bearing: ${bearing.toStringAsFixed(1)}°, Speed: ${_currentSpeed.toStringAsFixed(1)} km/h');
      }
    }

    setState(() {
      _previousLocation = _currentDriverLocation;
      _currentDriverLocation = newLocation;
    });

    // Auto-follow driver
    if (_isFollowingDriver && _currentDriverLocation != null) {
      _followDriver();
    }

    // Check arrival - 5 meters
    final distanceToDestination = _calculateDistance(
      newLocation,
      LatLng(widget.customerLatitude, widget.customerLongitude),
    );

    if (distanceToDestination < 0.005 && !_arrivedAtDestination) {
      setState(() => _arrivedAtDestination = true);
      _showArrivalDialog();
      debugPrint('🎯 Arrived! Distance: ${(distanceToDestination * 1000).toStringAsFixed(1)}m');
    }
  }

  void _followDriver() {
    if (_mapController == null || _currentDriverLocation == null) return;
    
    // Dynamic zoom based on speed
    double zoom = 17.0;
    if (_currentSpeed > 60) {
      zoom = 15.5;
    } else if (_currentSpeed > 40) {
      zoom = 16.0;
    } else if (_currentSpeed > 20) {
      zoom = 16.5;
    } else {
      zoom = 17.0;
    }

    _mapController!.move(_currentDriverLocation!, zoom);
  }

  void _smoothRotateMap(double targetRotation) {
    double normalizeAngle(double angle) {
      while (angle > 180) angle -= 360;
      while (angle < -180) angle += 360;
      return angle;
    }

    final currentRotation = _mapController?.camera.rotation ?? 0;
    final normalizedTarget = normalizeAngle(targetRotation);
    final normalizedCurrent = normalizeAngle(currentRotation);
    
    double delta = normalizeAngle(normalizedTarget - normalizedCurrent);
    final newTarget = normalizedCurrent + delta;

    _rotationAnimation = Tween<double>(
      begin: normalizedCurrent,
      end: newTarget,
    ).animate(
      CurvedAnimation(
        parent: _rotationAnimationController,
        curve: Curves.easeOut,
      ),
    );

    _rotationAnimationController.forward(from: 0);
  }

  double _calculateBearing(LatLng start, LatLng end) {
    final lat1 = start.latitude * math.pi / 180;
    final lat2 = end.latitude * math.pi / 180;
    final dLon = (end.longitude - start.longitude) * math.pi / 180;

    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    final bearing = math.atan2(y, x) * 180 / math.pi;
    return (bearing + 360) % 360;
  }

  Future<void> _updateRoute() async {
    if (_currentDriverLocation == null) return;

    try {
      final startPoint = _currentDriverLocation!;
      final endPoint = LatLng(widget.customerLatitude, widget.customerLongitude);

      final String url =
          'https://router.project-osrm.org/route/v1/driving/${startPoint.longitude},${startPoint.latitude};${endPoint.longitude},${endPoint.latitude}?overview=full&geometries=geojson';

      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 8),
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
          });

          debugPrint('🔄 Route updated: ${newDistance.toStringAsFixed(1)} km');
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
              Navigator.pop(context);
              Navigator.pop(context);
              Navigator.pop(context);
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
                initialZoom: 17.0,
                minZoom: 10.0,
                maxZoom: 19.0,
                keepAlive: true,
                interactionOptions: InteractionOptions(
                  flags: _isFollowingDriver 
                    ? InteractiveFlag.all & ~InteractiveFlag.rotate
                    : InteractiveFlag.all,
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
                
                // Route line - Blue path on streets
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
                    // Driver marker - Directional arrow pointing to movement direction
                    if (_currentDriverLocation != null)
                      Marker(
                        point: _currentDriverLocation!,
                        width: 70.0,
                        height: 70.0,
                        alignment: Alignment.center,
                        rotate: false, // We handle rotation manually
                        child: Transform.rotate(
                          angle: _currentBearing * math.pi / 180,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outer glow
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2196F3).withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              // Middle white circle
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
                              // Blue arrow icon
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
                    
                    // Destination marker
                    Marker(
                      point: destinationLocation,
                      width: 50.0,
                      height: 50.0,
                      alignment: Alignment.center,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5252),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 3,
                          ),
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
            
            // Customer info card (top)
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
            
            // Controls (right side)
            Positioned(
              top: 130,
              right: 16,
              child: Column(
                children: [
                  // Follow driver button
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D2D2D).withOpacity(0.95),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isFollowingDriver
                              ? const Color(0xFF2196F3)
                              : Colors.white60,  
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
                            ? const Color(0xFF2196F3)
                            : Colors.white60,  
                        size: 28,
                      ),
                      onPressed: () {
                        setState(() {
                          _isFollowingDriver = true;
                        });
                        if (_currentDriverLocation != null) {
                          _followDriver();
                        }
                      },
                      tooltip: _isFollowingDriver 
                          ? 'Following your location' 
                          : 'Center on my location',
                    ),
                  ),
                  
                  // Speed indicator
                  if (_currentSpeed > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D2D2D).withOpacity(0.95),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF2196F3).withOpacity(0.3),
                            width: 2,
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
                            Text(
                              '${_currentSpeed.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Color(0xFF2196F3),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'km/h',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Navigation info (bottom)
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
                                  Navigator.pop(context);
                                  Navigator.pop(context);
                                  Navigator.pop(context);
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