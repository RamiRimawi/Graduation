import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'dart:async';
import '../../supabase_config.dart';

class LiveNavigation extends StatefulWidget {
  final String customerName;
  final String address;
  final double customerLatitude;
  final double customerLongitude;
  final int? orderId;

  const LiveNavigation({
    super.key,
    required this.customerName,
    required this.address,
    required this.customerLatitude,
    required this.customerLongitude,
    this.orderId,
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
  Timer? _routeUpdateTimer;
  bool _arrivedAtDestination = false;
  DateTime? _lastUpdate;
  int _updateCount = 0;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _startLiveTracking();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _routeUpdateTimer?.cancel();
    super.dispose();
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

          _mapController?.move(newLocation, 16.0);
          
          final distanceToDestination = _calculateDistance(
            newLocation,
            LatLng(widget.customerLatitude, widget.customerLongitude),
          );
          
          if (distanceToDestination < 0.05 && !_arrivedAtDestination) {
            setState(() => _arrivedAtDestination = true);
            _showArrivalDialog();
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

  Future<void> _completeDelivery() async {
    try {
      if (widget.orderId != null) {
        await supabase
            .from('customer_order')
            .update({
              'order_status': 'Delivered',
              'last_action_time': DateTime.now().toIso8601String(),
            })
            .eq('customer_order_id', widget.orderId!);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Delivery completed successfully!'),
              backgroundColor: Color(0xFF67CD67),
            ),
          );
          
          Navigator.pop(context);
        }
      }
    } catch (e) {
      debugPrint('Error completing delivery: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
          'You have arrived at the customer location. Complete the delivery?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Not Yet',
              style: TextStyle(color: Color(0xFFB7A447)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _completeDelivery();
            },
            child: const Text(
              'Complete Delivery',
              style: TextStyle(color: Color(0xFF67CD67)),
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
                interactiveFlags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.dolphin',
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
