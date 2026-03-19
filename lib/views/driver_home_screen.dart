import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:odogo_app/controllers/auth_controller.dart';
import 'package:odogo_app/controllers/trip_controller.dart';
import 'package:odogo_app/controllers/user_controller.dart';
import 'package:odogo_app/models/enums.dart';
import 'package:odogo_app/models/trip_model.dart';
import 'dart:async';

import 'driver_profile_screen.dart';
import 'driver_bookings_screen.dart';
import 'driver_active_pickup_screen.dart';

class DriverHomeScreen extends ConsumerStatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  ConsumerState<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends ConsumerState<DriverHomeScreen> {
  final Color odogoGreen = const Color(0xFF66D2A3);
  final MapController _mapController = MapController();
  static const LatLng _defaultCenter = LatLng(26.5123, 80.2329);
  static const double _recenterThresholdMeters = 25;
  static const double _bottomOverlayInset = 20;
  LatLng? _currentLocation;
  LatLng? _lastRecenterLocation;
  StreamSubscription<Position>? _locationSubscription;
  final GlobalKey _bottomOverlayKey = GlobalKey();
  double _bottomOverlayHeight = 0;

  double get _verticalCenterOffsetPx {
    return (_bottomOverlayHeight + _bottomOverlayInset) / 2;
  }

  void _measureBottomOverlayHeight() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _bottomOverlayKey.currentContext;
      if (context == null || !mounted) return;
      final renderObject = context.findRenderObject();
      if (renderObject is! RenderBox) return;
      final measuredHeight = renderObject.size.height;
      if ((measuredHeight - _bottomOverlayHeight).abs() < 1) return;
      setState(() {
        _bottomOverlayHeight = measuredHeight;
      });
    });
  }

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _startLocationStream();
  }

  Future<void> _startLocationStream() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (!mounted) return;
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled || !mounted) return;

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 3,
    );

    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (position) {
        _applyLocationUpdate(LatLng(position.latitude, position.longitude));
      },
      onError: (_) {},
    );
  }

  void _applyLocationUpdate(LatLng location) {
    if (!mounted) return;
    setState(() {
      _currentLocation = location;
    });

    final shouldRecenter = _lastRecenterLocation == null ||
        Geolocator.distanceBetween(
              _lastRecenterLocation!.latitude,
              _lastRecenterLocation!.longitude,
              location.latitude,
              location.longitude,
            ) >=
            _recenterThresholdMeters;

    if (!shouldRecenter) {
      return;
    }

    _lastRecenterLocation = location;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final zoom = _mapController.camera.zoom;
      _mapController.move(
        location,
        zoom,
        offset: Offset(0, -_verticalCenterOffsetPx),
      );
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    _locationSubscription?.cancel();
    super.dispose();
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _toggleOnlineState() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    final isCurrentlyOnline = currentUser.mode == DriverMode.online;
    final newMode = isCurrentlyOnline ? DriverMode.offline : DriverMode.online;

    await ref.read(userControllerProvider.notifier).updateDriverMode(newMode);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newMode == DriverMode.online ? 'You are now ONLINE.' : 'You are OFFLINE.'),
          backgroundColor: newMode == DriverMode.online ? odogoGreen : Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    _measureBottomOverlayHeight();

    final currentUser = ref.watch(currentUserProvider);
    final _isOnline = currentUser?.mode == DriverMode.online;

    final pendingTripsAsync = ref.watch(pendingTripsProvider);
    final availableTrips = pendingTripsAsync.value ?? [];

    return Scaffold(
      backgroundColor: Colors.white, 
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildMapHome(_isOnline, availableTrips), 
          const DriverBookingsScreen(), 
          const DriverProfileScreen(),   
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTapped,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.confirmation_number_rounded), label: 'Bookings'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildMapHome(bool _isOnline, List<TripModel> availableTrips) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _currentLocation ?? _defaultCenter,
            initialZoom: 16.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.odogo_app',
              tileBuilder: (context, tileWidget, tile) {
                return ColorFiltered(
                  colorFilter: const ColorFilter.matrix([
                    -0.2126, -0.7152, -0.0722, 0, 255,
                    -0.2126, -0.7152, -0.0722, 0, 255,
                    -0.2126, -0.7152, -0.0722, 0, 255,
                    0,       0,       0,       1, 0,
                  ]),
                  child: tileWidget,
                );
              },
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: _currentLocation ?? _defaultCenter,
                  width: 56, 
                  height: 56,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _isOnline ? odogoGreen : Colors.grey,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0), 
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/odogo_logo_black_bg.jpeg',
                          fit: BoxFit.contain, 
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.black),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        Positioned(
          top: 50,
          left: 20,
          right: 20,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  Image.asset(
                    'assets/images/odogo_logo_black_bg.jpeg',
                    height: 40,
                    errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image, color: odogoGreen, size: 40),
                  ),
                  const SizedBox(height: 4),
                  const Text('OdoGo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              GestureDetector(
                onTap: _toggleOnlineState,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isOnline ? Colors.black87 : odogoGreen,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _isOnline ? odogoGreen : Colors.transparent, width: 2),
                  ),
                  child: Row(
                    children: [
                      Switch(
                        value: _isOnline, 
                        onChanged: (v) => _toggleOnlineState(), 
                        activeThumbColor: odogoGreen,
                        inactiveThumbColor: Colors.black,
                        inactiveTrackColor: Colors.black26,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Go', style: TextStyle(color: _isOnline ? Colors.white : Colors.black, fontSize: 14, fontWeight: FontWeight.bold)),
                          Text(_isOnline ? 'Offline' : 'Online', style: TextStyle(color: _isOnline ? Colors.white : Colors.black, fontSize: 14, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: Column(
            key: _bottomOverlayKey,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: _isOnline ? odogoGreen.withOpacity(0.1) : Colors.white,
                  border: Border.all(color: _isOnline ? odogoGreen : Colors.black, width: 2),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: _isOnline 
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (availableTrips.isEmpty) ...[
                            SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: odogoGreen, strokeWidth: 2.5)),
                            const SizedBox(width: 12),
                            const Text('Searching for rides...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                          ] else ...[
                            Text('${availableTrips.length} Ride(s) Found!', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white)),
                          ]
                        ],
                      )
                    : const Text('You are Offline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.black)),
                ),
              ),
              
              if (_isOnline && availableTrips.isNotEmpty) ...[
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.45, 
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: availableTrips.length,
                    itemBuilder: (context, index) {
                      final trip = availableTrips[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 2),
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.white,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Center(
                              child: Text('Incoming Request', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                            const Divider(color: Colors.black12, height: 24, thickness: 1),
                            _buildMapInfoRow('Passenger:', trip.commuterName),
                            _buildMapInfoRow('Pickup:', trip.startLocName),
                            _buildMapInfoRow('Drop:', trip.endLocName),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity, 
                              height: 48,
                              child: ElevatedButton(
                                onPressed: () async {
                                  final currentUserName = ref.read(currentUserProvider)?.name;
                                  final currentUserId = ref.read(currentUserProvider)?.userID;
                                  if (currentUserName != null && currentUserId != null) {
                                    await ref.read(tripControllerProvider.notifier).acceptRide(
                                      trip.tripID,
                                      currentUserName,
                                      currentUserId,
                                    );
                                    
                                    if (mounted) {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => DriverActivePickupScreen(
                                            tripID: trip.tripID,
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: odogoGreen, 
                                  foregroundColor: Colors.black,
                                  side: const BorderSide(color: Colors.black, width: 2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Accept Ride', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMapInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black)),
          Expanded(
            child: Text(
              value, 
              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 15),
              // Let the text wrap to the next line naturally instead of cutting off
            ),
          ),
        ],
      ),
    );
  }
}