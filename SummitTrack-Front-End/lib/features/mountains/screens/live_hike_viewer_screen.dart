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

  /// 🧹 Linisin ang hike ID na galing sa shared link.
  ///
  /// Supported:
  /// abc123
  /// https://summittrack-10481.web.app/track?hikeId=abc123
  /// summittrack://track?hikeId=abc123
  String get _cleanHikeId {
    final String rawValue = widget.hikeId.trim();

    if (rawValue.isEmpty) {
      return '';
    }

    // Kung full URL ang naipasa.
    final Uri? uri = Uri.tryParse(rawValue);

    if (uri != null) {
      final String? queryHikeId = uri.queryParameters['hikeId'];

      if (queryHikeId != null && queryHikeId.trim().isNotEmpty) {
        return queryHikeId.trim();
      }
    }

    // Kung may hikeId= pero hindi ma-parse nang maayos bilang URI.
    if (rawValue.contains('hikeId=')) {
      final int index = rawValue.indexOf('hikeId=');

      String extracted = rawValue.substring(index + 'hikeId='.length);

      if (extracted.contains('&')) {
        extracted = extracted.split('&').first;
      }

      try {
        extracted = Uri.decodeComponent(extracted);
      } catch (_) {
        // Keep original extracted value.
      }

      return extracted.trim();
    }

    // Normal case: hikeId lang talaga ang ipinasa.
    try {
      return Uri.decodeComponent(rawValue).trim();
    } catch (_) {
      return rawValue.trim();
    }
  }

  // 🛰️ Awtomatikong ipopokus ang mapa sa bagong GPS coordinate.
  void _updateCameraPosition(double lat, double lng) {
    if (_mapController == null) {
      return;
    }

    if (lat == 0.0 && lng == 0.0) {
      return;
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(lat, lng), 16.5),
    );
  }

  @override
  void initState() {
    super.initState();

    debugPrint('🛰️ LiveHikeViewer raw hikeId: "${widget.hikeId}"');

    debugPrint('🧹 LiveHikeViewer cleaned hikeId: "$_cleanHikeId"');

    debugPrint('🔥 Reading Firestore: live_tracks/$_cleanHikeId');
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String hikeId = _cleanHikeId;

    // Invalid/missing hike ID.
    if (hikeId.isEmpty) {
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
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.link_off_rounded,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  'Invalid Tracking Link',
                  style: GoogleFonts.fredoka(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'The shared link does not contain a valid hike ID.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final DocumentReference<Map<String, dynamic>> liveTrackRef =
        FirebaseFirestore.instance.collection('live_tracks').doc(hikeId);

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

      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: liveTrackRef.snapshots(),
        builder: (context, snapshot) {
          // =========================================================
          // LOADING
          // =========================================================

          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData &&
              !snapshot.hasError) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF3FA65B)),
            );
          }

          // =========================================================
          // FIRESTORE ERROR
          //
          // Important fix:
          // Dati diretso "Tracking Session Not Found" kahit
          // Firestore permission/network error pala.
          // =========================================================

          if (snapshot.hasError) {
            final Object error = snapshot.error!;

            debugPrint('❌ Live tracking Firestore error: $error');

            final String errorMessage = error.toString();

            final bool permissionDenied = errorMessage.contains(
              'permission-denied',
            );

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      permissionDenied
                          ? Icons.lock_outline_rounded
                          : Icons.error_outline_rounded,
                      size: 64,
                      color: Colors.red.shade400,
                    ),
                    const SizedBox(height: 16),

                    Text(
                      permissionDenied
                          ? 'Tracking Access Denied'
                          : 'Unable to Load Tracking',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.fredoka(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      permissionDenied
                          ? 'The live tracking session may exist, '
                                'but this device is not allowed to read it.'
                          : 'An error occurred while loading the '
                                'live tracking session.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),

                    const SizedBox(height: 18),

                    SelectableText(
                      'Hike ID: $hikeId',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // =========================================================
          // DOCUMENT DOES NOT EXIST
          // =========================================================

          if (!snapshot.hasData || !snapshot.data!.exists) {
            debugPrint('❌ live_tracks/$hikeId does not exist.');

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
                      'The hike session does not exist or '
                      'the shared link contains an incorrect hike ID.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),

                    const SizedBox(height: 18),

                    SelectableText(
                      'Hike ID: $hikeId',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // =========================================================
          // READ LIVE TRACK DATA
          // =========================================================

          final Map<String, dynamic> data =
              snapshot.data!.data() ?? <String, dynamic>{};

          final dynamic latitudeValue = data['latitude'];
          final dynamic longitudeValue = data['longitude'];

          final double latitude = latitudeValue is num
              ? latitudeValue.toDouble()
              : 0.0;

          final double longitude = longitudeValue is num
              ? longitudeValue.toDouble()
              : 0.0;

          final bool isLive = data['isLive'] == true;

          final String hikerName =
              data['hikerName'] is String &&
                  (data['hikerName'] as String).trim().isNotEmpty
              ? (data['hikerName'] as String).trim()
              : 'Hiker';

          debugPrint(
            '✅ Live track found: $hikeId | '
            'isLive=$isLive | '
            'lat=$latitude | '
            'lng=$longitude',
          );

          // =========================================================
          // SESSION EXISTS BUT FIRST GPS UPDATE HASN'T ARRIVED YET
          // =========================================================

          if (latitude == 0.0 && longitude == 0.0) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Color(0xFF3FA65B)),

                    const SizedBox(height: 24),

                    Text(
                      'Waiting for GPS Location...',
                      style: GoogleFonts.fredoka(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      '$hikerName has started live tracking. '
                      'Waiting for the first GPS update.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            );
          }

          final LatLng hikerPosition = LatLng(latitude, longitude);

          // 🚀 Move camera pagkatapos mabuild ang UI.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) {
              return;
            }

            _updateCameraPosition(latitude, longitude);
          });

          return Stack(
            children: [
              // =====================================================
              // 🗺️ 1. REAL INTERACTIVE MAP
              // =====================================================
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: hikerPosition,
                  zoom: 16.5,
                ),
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,

                onMapCreated: (controller) {
                  _mapController = controller;

                  _updateCameraPosition(latitude, longitude);
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

              // =====================================================
              // 🟢 2. LIVE STATUS BANNER
              // =====================================================
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
                    top: false,
                    bottom: false,
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

              // =====================================================
              // 🎯 3. RE-CENTER BUTTON
              // =====================================================
              Positioned(
                bottom: 16,
                right: 16,
                child: SafeArea(
                  top: false,
                  left: false,
                  child: FloatingActionButton(
                    backgroundColor: const Color(0xFF1B4D2E),
                    foregroundColor: Colors.white,
                    onPressed: () {
                      _updateCameraPosition(latitude, longitude);
                    },
                    child: const Icon(Icons.my_location_rounded),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
