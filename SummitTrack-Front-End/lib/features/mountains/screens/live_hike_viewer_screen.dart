import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LiveHikeViewerScreen extends StatefulWidget {
  const LiveHikeViewerScreen({super.key, required this.hikeId});

  final String hikeId;

  @override
  State<LiveHikeViewerScreen> createState() => _LiveHikeViewerScreenState();
}

class _LiveHikeViewerScreenState extends State<LiveHikeViewerScreen> {
  GoogleMapController? _mapController;

  String get _cleanHikeId => widget.hikeId.trim();

  // 🛰️ Awtomatikong ipopokus ang mapa sa bagong GPS coordinate
  void _updateCameraPosition(double lat, double lng) {
    if (_mapController != null && lat != 0.0 && lng != 0.0) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(lat, lng),
          16.5, // Zoom level (parang sa Messenger)
        ),
      );
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Live Hike Tracking',
          style: GoogleFonts.fredoka(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF1B4D2E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('live_tracks')
            .doc(_cleanHikeId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF3FA65B)),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.location_off_rounded,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tracking Session Not Found',
                      style: GoogleFonts.fredoka(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'The hike session may have ended or the link is invalid.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final double latitude = (data['latitude'] ?? 0.0).toDouble();
          final double longitude = (data['longitude'] ?? 0.0).toDouble();
          final bool isLive = data['isLive'] ?? false;
          final String hikerName = data['hikerName'] ?? 'Hiker';

          final LatLng hikerPosition = LatLng(latitude, longitude);

          // 🚀 FIX: I-move ang camera pagkatapos mag-build ng UI para walang error at smooth ang real-time!
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _updateCameraPosition(latitude, longitude);
          });

          return Stack(
            children: [
              // 🗺️ 1. REAL INTERACTIVE MAP (Google Maps)
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: hikerPosition,
                  zoom: 16.5,
                ),
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                onMapCreated: (controller) {
                  _mapController = controller;
                },
                // 📍 Live Marker Pin ng Hiker
                markers: {
                  Marker(
                    markerId: const MarkerId('hiker_live_location'),
                    position: hikerPosition,
                    infoWindow: InfoWindow(
                      title: '$hikerName\'s Live Location',
                      snippet: 'Lat: $latitude, Lng: $longitude',
                    ),
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueGreen,
                    ),
                  ),
                },
              ),

              // 🟢 2. MESSENGER-STYLE STATUS BANNER (Sa Taas)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  color: isLive ? const Color(0xFF1B4D2E) : Colors.red.shade800,
                  child: SafeArea(
                    bottom: false, // Ensures it doesn't get hidden behind notches
                    child: Row(
                      children: [
                        Icon(
                          isLive
                              ? Icons.sensors_rounded
                              : Icons.sensors_off_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isLive
                                ? 'LIVE: Broadcasting $hikerName\'s GPS'
                                : 'BROADCAST PAUSED / ENDED',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 🎯 3. RE-CENTER BUTTON (Messenger-style Float Button sa Baba)
              Positioned(
                bottom: 24,
                right: 16,
                child: FloatingActionButton(
                  backgroundColor: const Color(0xFF1B4D2E),
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.my_location_rounded),
                  onPressed: () {
                    _updateCameraPosition(latitude, longitude);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}