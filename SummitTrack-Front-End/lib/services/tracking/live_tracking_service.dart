import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LiveTrackingSenderService {
  StreamSubscription<Position>? _positionSubscription;

  // 👤 Helper Function: Kukunin ang pangalan ng kasalukuyang naka-login na user
  Future<String> _fetchCurrentHikerName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'Hiker';

    // 1. Subukan munang kunin sa Auth Display Name
    if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
      return user.displayName!;
    }

    // 2. Kung wala doon, kunin mula sa Firestore 'users' document niya
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        // Palitan batay sa exact field name mo sa Firestore (e.g., 'fullName', 'name', 'username')
        return data['fullName'] ?? data['name'] ?? data['username'] ?? 'Hiker';
      }
    } catch (e) {
      print('Error fetching hiker name: $e');
    }

    return 'Hiker';
  }

  // 🚀 Tawagin ito kapag pinindot ang "Start Live Broadcast"
  Future<void> startLiveBroadcasting({
    required String hikeId,
    String? hikerName, // Optional na lang ito ngayon!
  }) async {
    // 1. Siguraduhing may Permission ang GPS
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    // 2. Kunin ang totoong pangalan ng naka-login na user (kung walang ipinasa)
    final String activeHikerName = hikerName ?? await _fetchCurrentHikerName();

    // 3. I-set muna bilang Active sa Firestore
    await FirebaseFirestore.instance.collection('live_tracks').doc(hikeId).set({
      'isLive': true,
      'hikerName': activeHikerName,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // 4. Makinig sa Live GPS Position ng Device
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // Mag-u-update bawat galaw ng 5 meters
    );

    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            // 🛰️ I-UPDATE ANG TOTOONG COORDINATES SA FIRESTORE
            FirebaseFirestore.instance
                .collection('live_tracks')
                .doc(hikeId)
                .set({
                  'latitude': position.latitude,
                  'longitude': position.longitude,
                  'isLive': true,
                  'hikerName': activeHikerName,
                  'updatedAt': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true))
                .catchError((e) {
                  debugPrint(
                    '[TRACK DEBUG] Error updating position in stream: $e',
                  );
                });
          },
          onError: (e) {
            debugPrint('[TRACK DEBUG] Position stream error: $e');
          },
        );
  }

  // 🛑 Tawagin ito kapag pinindot ang "Stop Live Broadcast"
  Future<void> stopLiveBroadcasting(String hikeId) async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;

    await FirebaseFirestore.instance
        .collection('live_tracks')
        .doc(hikeId)
        .update({'isLive': false, 'updatedAt': FieldValue.serverTimestamp()});
  }
}
