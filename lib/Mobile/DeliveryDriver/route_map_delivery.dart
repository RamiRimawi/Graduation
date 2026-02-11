import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
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
  mapbox.MapboxMap? _mapboxMap;
  mapbox.PointAnnotationManager? _driverPointManager;
  mapbox.PointAnnotationManager? _destPointManager;
  mapbox.PolylineAnnotationManager? _routeLineManager;

  mapbox.PointAnnotation? _driverPoint;
  mapbox.PointAnnotation? _destPoint;
  mapbox.PolylineAnnotation? _routeLine;

  Uint8List? _driverIconBytes;
  Uint8List? _destIconBytes;
  bool _isCreatingDriverMarker = false;
  bool _isCreatingDestMarker = false;
  bool _isStyleReady = false;

  static const String _mapboxAccessToken =
      'pk.eyJ1IjoicmFtYWRhbjk2IiwiYSI6ImNtbGh4eHMyMzA1d20zY3Fzem54aHZtNGQifQ.sB2yvST_wLvszakHkT7Npg';
  static const String _mapStyleUri =
      'mapbox://styles/mapbox/streets-v12';
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
    mapbox.MapboxOptions.setAccessToken(_mapboxAccessToken);
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
      _updateDriverMarker(current);
      _updateDestinationMarker();
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
    _updateDriverMarker(_fallbackDriverLocation);
    _updateDestinationMarker();
    _getShortestRoute(_fallbackDriverLocation);
  }

  // Function to fit the entire route in view
  Future<void> _fitRouteInView() async {
    if (_mapboxMap == null || deliveryDriverLocation == null) return;

    final endPoint = LatLng(widget.latitude, widget.longitude);
    
    final south = math.min(deliveryDriverLocation!.latitude, endPoint.latitude);
    final north = math.max(deliveryDriverLocation!.latitude, endPoint.latitude);
    final west = math.min(deliveryDriverLocation!.longitude, endPoint.longitude);
    final east = math.max(deliveryDriverLocation!.longitude, endPoint.longitude);

    final bounds = mapbox.CoordinateBounds(
      southwest: mapbox.Point(
        coordinates: mapbox.Position(west, south),
      ),
      northeast: mapbox.Point(
        coordinates: mapbox.Position(east, north),
      ),
      infiniteBounds: false,
    );

    final camera = await _mapboxMap!.cameraForCoordinateBounds(
      bounds,
      mapbox.MbxEdgeInsets(top: 110, left: 50, bottom: 290, right: 60),
      null,
      null,
      null,
      null,
    );

    _mapboxMap!.setCamera(camera);

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

          _updateRouteLine();
          if (deliveryDriverLocation != null) {
            _updateDriverMarker(deliveryDriverLocation!);
          }
          _updateDestinationMarker();

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

  Future<void> _zoomBy(double delta) async {
    if (_mapboxMap == null) return;

    final state = await _mapboxMap!.getCameraState();
    final nextZoom = (state.zoom + delta).clamp(8.0, 18.0);

    _mapboxMap!.easeTo(
      mapbox.CameraOptions(
        center: state.center,
        zoom: nextZoom,
        bearing: state.bearing,
        pitch: state.pitch,
      ),
      mapbox.MapAnimationOptions(duration: 250),
    );
  }

  mapbox.Point _pointFromLatLng(LatLng point) {
    return mapbox.Point(
      coordinates: mapbox.Position(point.longitude, point.latitude),
    );
  }

  void _onMapCreated(mapbox.MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
    _isStyleReady = false;

    _mapboxMap!.gestures.updateSettings(
      mapbox.GesturesSettings(rotateEnabled: false),
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
  }

  Future<void> _onStyleLoaded(mapbox.StyleLoadedEventData data) async {
    if (_mapboxMap == null) return;

    _driverPointManager =
        await _mapboxMap!.annotations.createPointAnnotationManager();
    _destPointManager =
        await _mapboxMap!.annotations.createPointAnnotationManager();
    _routeLineManager =
        await _mapboxMap!.annotations.createPolylineAnnotationManager();

    _driverPoint = null;
    _destPoint = null;
    _routeLine = null;
    _isStyleReady = true;

    await _ensureMarkerImages();

    if (deliveryDriverLocation != null) {
      await _updateDriverMarker(deliveryDriverLocation!);
    }
    await _updateDestinationMarker();
    await _updateRouteLine();

    if (deliveryDriverLocation != null) {
      await _fitRouteInView();
    }
  }

  Future<void> _updateDriverMarker(LatLng loc) async {
    if (!_isStyleReady) return;
    if (_driverPointManager == null || _driverIconBytes == null) return;

    if (_driverPoint == null) {
      if (_isCreatingDriverMarker) return;
      _isCreatingDriverMarker = true;
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

    final dest = LatLng(widget.latitude, widget.longitude);

    if (_destPoint == null) {
      if (_isCreatingDestMarker) return;
      _isCreatingDestMarker = true;
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

  Future<void> _updateRouteLine() async {
    if (!_isStyleReady) return;
    if (_routeLineManager == null) return;

    if (routePoints.isEmpty) {
      if (_routeLine != null) {
        await _routeLineManager!.delete(_routeLine!);
        _routeLine = null;
      }
      return;
    }

    final geometry = mapbox.LineString(
      coordinates: routePoints
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

    final icon = Icons.local_shipping;
    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          fontSize: size * 0.34,
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

  @override
  Widget build(BuildContext context) {
    final deliveryLocation = LatLng(widget.latitude, widget.longitude);

    return Scaffold(
      backgroundColor: const Color(0xFF202020),
      body: SafeArea(
        child: Stack(
          children: [
            mapbox.MapWidget(
              key: const ValueKey('route-mapbox'),
              styleUri: _mapStyleUri,
              cameraOptions: mapbox.CameraOptions(
                center: mapbox.Point(
                  coordinates: mapbox.Position(
                    (deliveryDriverLocation ?? deliveryLocation).longitude,
                    (deliveryDriverLocation ?? deliveryLocation).latitude,
                  ),
                ),
                zoom: 13.0,
              ),
              onMapCreated: _onMapCreated,
              onStyleLoadedListener: _onStyleLoaded,
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
                        _zoomBy(1.0);
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
                        _zoomBy(-1.0);
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