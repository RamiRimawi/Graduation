import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'dart:async';
import 'live_navigation.dart';
import '../../supabase_config.dart';

class RouteMapDeleviry extends StatefulWidget {
  final String customerName;
  final String locationLabel;
  final String address;
  final double latitude;
  final double longitude;
  final int? orderId;
  final int deliveryDriverId;

  const RouteMapDeleviry({
    super.key,
    required this.customerName,
    required this.locationLabel,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.orderId,
    required this.deliveryDriverId,
  });

  @override
  State<RouteMapDeleviry> createState() => _RouteMapDeleviryState();
}

class _RouteMapDeleviryState extends State<RouteMapDeleviry> {
  MapController? _mapController;
  bool _mapLoading = true;
  bool _locationObtained = false;
  List<LatLng> routePoints = [];
  double distance = 0;
  double duration = 0;
  LatLng? deliveryDriverLocation;
  static const LatLng _fallbackDriverLocation = LatLng(31.9454, 35.2075);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();

      while (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        _useFallbackLocation();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 12),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint('Location timeout, using fallback');
          _useFallbackLocation();
          throw Exception('Location timeout');
        },
      );

      final current = LatLng(position.latitude, position.longitude);
      debugPrint('Driver real location: $current');
      setState(() {
        deliveryDriverLocation = current;
        _locationObtained = true;
      });
      await _getShortestRoute(current);
    } catch (e) {
      debugPrint('Error getting location: $e');
      _useFallbackLocation();
    }
  }

  void _useFallbackLocation() {
    debugPrint('Using fallback driver location: $_fallbackDriverLocation');
    setState(() {
      deliveryDriverLocation = _fallbackDriverLocation;
      _locationObtained = true;
    });
    _getShortestRoute(_fallbackDriverLocation);
  }

  // Function to fit the entire route in view
  void _fitRouteInView() {
    if (_mapController == null || deliveryDriverLocation == null) return;

    final endPoint = LatLng(widget.latitude, widget.longitude);
    
    // Create bounds that include both start and end points
    final bounds = LatLngBounds.fromPoints([
      deliveryDriverLocation!,
      endPoint,
    ]);

    // Fit the camera to show the entire route with padding
    _mapController!.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.only(
          top: 110,    // Space for back button
          bottom: 290, // Space for bottom info card
          left: 50,
          right: 60,
        ),
      ),
    );

    debugPrint('📍 Map fitted to show entire route');
  }

  Future<void> _getShortestRoute(LatLng startPoint) async {
    try {
      final endPoint = LatLng(widget.latitude, widget.longitude);

      setState(() => deliveryDriverLocation = startPoint);

      final String url =
          'https://router.project-osrm.org/route/v1/driving/${startPoint.longitude},${startPoint.latitude};${endPoint.longitude},${endPoint.latitude}?overview=full&geometries=geojson';

      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('Routing request timeout');
          return http.Response('{}', 500);
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];

          // Extract route coordinates
          final coordinates = route['geometry']['coordinates'] as List;
          routePoints = coordinates
              .map((coord) => LatLng(coord[1] as double, coord[0] as double))
              .toList();

          // Get distance and duration
          distance = (route['distance'] as num).toDouble() / 1000;
          duration = (route['duration'] as num).toDouble() / 60;

          setState(() {
            _mapLoading = false;
          });

          // Fit the entire route in view after map is ready
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _fitRouteInView();
            }
          });

          debugPrint('Route calculated: $distance km, $duration min');
        }
      }
    } catch (e) {
      debugPrint('Error getting route: $e');
      setState(() => _mapLoading = false);
    }
  }

  Future<void> _startNavigation() async {
    debugPrint('🚀 GO button pressed!');
    debugPrint('📦 orderId = ${widget.orderId}');
    debugPrint('👤 deliveryDriverId = ${widget.deliveryDriverId}');
    
    // ✅ Set current_order_id in database when GO is pressed
    if (widget.orderId != null) {
      try {
        debugPrint('🔄 Attempting to update current_order_id...');
        
        final response = await supabase
            .from('delivery_driver')
            .update({'current_order_id': widget.orderId})
            .eq('delivery_driver_id', widget.deliveryDriverId)
            .select();
        
        debugPrint('✅ Update successful! Response: $response');
        debugPrint('✅ Set current_order_id = ${widget.orderId} for driver ${widget.deliveryDriverId}');
      } catch (e) {
        debugPrint('❌ Error setting current_order_id: $e');
        debugPrint('❌ Error type: ${e.runtimeType}');
      }
    } else {
      debugPrint('⚠️ orderId is NULL! Cannot set current_order_id');
    }

    if (!mounted) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LiveNavigation(
          customerName: widget.customerName,
          address: widget.address,
          customerLatitude: widget.latitude,
          customerLongitude: widget.longitude,
          orderId: widget.orderId,
          deliveryDriverId: widget.deliveryDriverId,
          initialDriverLocation:
              deliveryDriverLocation ?? _fallbackDriverLocation,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deliveryLocation = LatLng(widget.latitude, widget.longitude);

    return Scaffold(
      backgroundColor: const Color(0xFF202020),
      body: SafeArea(
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: deliveryDriverLocation ?? deliveryLocation,
                initialZoom: 13.0,
                minZoom: 8.0,
                maxZoom: 18.0,
                initialCameraFit: CameraFit.bounds(
                  bounds: LatLngBounds(
                    LatLng(31.45, 34.70),
                    LatLng(32.60, 35.70),
                  ),
                  padding: const EdgeInsets.all(50.0),
                ),
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
                onMapReady: () {
                  // Fit route when map is ready
                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (mounted && deliveryDriverLocation != null) {
                      _fitRouteInView();
                    }
                  });
                },
              ),

            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.dolphin',
                tileProvider: NetworkTileProvider(),
              ),
              
              // ✅ غيّر الخط الأزرق فقط
              if (routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routePoints,
                      strokeWidth: 8.0,  // ✅ نفس live_navigation
                      color: const Color(0xFF42A5F5),  // ✅ نفس live_navigation
                    ),
                  ],
                ),
              
              MarkerLayer(
                markers: [
                  // ✅ غيّر أيقونة السائق
                  if (deliveryDriverLocation != null)
                    Marker(
                      point: deliveryDriverLocation!,
                      width: 70.0,
                      height: 70.0,
                      alignment: Alignment.center,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer glow
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2196F3).withValues(alpha: 0.15),
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
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                          // Blue truck icon
                          Container(
                            width: 45,
                            height: 45,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.local_shipping,
                              color: Color(0xFF2196F3),
                              size: 28,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // ✅ غيّر أيقونة الوجهة
                  Marker(
                    point: deliveryLocation,
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
                            color: Colors.black.withValues(alpha: 0.3),
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

            // Zoom In/Out Buttons
            Positioned(
              right: 16,
              top: 20,
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D2D2D),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.add,
                        color: Color(0xFFB7A447),
                        size: 24,
                      ),
                      onPressed: () {
                        if (_mapController != null) {
                          final currentZoom = _mapController!.camera.zoom;
                          if (currentZoom < 18.0) {
                            _mapController!.move(
                              _mapController!.camera.center,
                              currentZoom + 1,
                            );
                          }
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D2D2D),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.remove,
                        color: Color(0xFFB7A447),
                        size: 24,
                      ),
                      onPressed: () {
                        if (_mapController != null) {
                          final currentZoom = _mapController!.camera.zoom;
                          if (currentZoom > 8.0) {
                            _mapController!.move(
                              _mapController!.camera.center,
                              currentZoom - 1,
                            );
                          }
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Fit to route button
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D2D2D),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.fit_screen,
                        color: Color(0xFFB7A447),
                        size: 24,
                      ),
                      onPressed: _fitRouteInView,
                      tooltip: 'Show full route',
                    ),
                  ),
                ],
              ),
            ),
          
            // Loading indicator
            if (_mapLoading || !_locationObtained)
              Container(
                color: const Color(0xFF202020),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        color: Color(0xFFB7A447),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _locationObtained ? 'Loading Map...' : 'Getting your location...',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Back button
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF2D2D2D),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Color(0xFFB7A447),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            
            // Customer info and action button
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D2D).withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFB7A447).withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Customer Name',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                widget.customerName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Location',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                widget.address,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // GO Button
                        GestureDetector(
                          onTap: _startNavigation,
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: const Color(0xFF67CD67),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF67CD67).withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                'GO',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Distance and Duration Info
                    if (distance > 0)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Text(
                                duration.toStringAsFixed(0),
                                style: const TextStyle(
                                  color: Color(0xFFB7A447),
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'min',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.white30,
                          ),
                          Column(
                            children: [
                              Text(
                                distance.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Color(0xFFB7A447),
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'km',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
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