import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Relative imports mula sa lib/features/hike/screens/hike.dart
import '../models/scheduled_hike.dart';
import '../services/hike_schedule_store.dart';
import '../../../services/location/location_service.dart';
import '../../../services/data_service.dart';

class HikeScreen extends StatefulWidget {
  const HikeScreen({super.key});

  @override
  State<HikeScreen> createState() => _HikeScreenState();
}

class _HikeScreenState extends State<HikeScreen> {
  final HikeScheduleStore _scheduleStore = HikeScheduleStore.instance;
  final LocationService _locationService = const LocationService();
  final LiveTrackingService _trackingService = LiveTrackingService();

  bool _isLiveTrackingActive = false;
  bool _isTestModeActive = false;

  // 🎨 Brand Colors
  static const Color primaryGreen = Color(0xFF1B4D2E);
  static const Color accentGreen = Color(0xFF2E7D32);
  static const Color cardBg = Colors.white;

  @override
  void initState() {
    super.initState();
    _scheduleStore.load();
  }

  /// Direct Copy Tracking Link
  Future<void> _copyLiveLocationLink(ScheduledHike hike) async {
    final String trackingUrl =
        "https://summittrack-10481.web.app/track.html?hikeId=${hike.id}";

    await Clipboard.setData(ClipboardData(text: trackingUrl));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(width: 10),
              Text('Live tracking link copied to clipboard!'),
            ],
          ),
          backgroundColor: primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Toggle Live GPS Broadcasting
  Future<void> _toggleTracking(ScheduledHike hike) async {
    if (_isLiveTrackingActive) {
      setState(() {
        _isLiveTrackingActive = false;
      });

      try {
        await _trackingService.stopLiveBroadcast(hike.id);
      } catch (e) {
        debugPrint('Error stopping broadcast: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.power_settings_new, color: Colors.white),
                SizedBox(width: 10),
                Text('Live tracking broadcast stopped.'),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      final readiness = await _locationService.requestNavigationReadiness();

      if (readiness.status == LocationReadinessStatus.permissionDenied ||
          readiness.status == LocationReadinessStatus.permissionDeniedForever ||
          readiness.status == LocationReadinessStatus.serviceDisabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(readiness.message)),
          );
        }
        return;
      }

      setState(() {
        _isLiveTrackingActive = true;
      });

      try {
        _trackingService.startLiveBroadcast(hike.id);
      } catch (e) {
        debugPrint('Error starting broadcast: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.sensors, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    readiness.status == LocationReadinessStatus.poorAccuracy
                        ? 'Live Tracking Started (${readiness.message})'
                        : 'Live GPS Broadcasting Started!',
                  ),
                ),
              ],
            ),
            backgroundColor: primaryGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        title: const Text(
          'Live Hike Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(
              _isTestModeActive ? Icons.bug_report : Icons.bug_report_outlined,
              color: _isTestModeActive ? Colors.amber.shade800 : Colors.grey.shade600,
            ),
            tooltip: 'Toggle Test Mode',
            onPressed: () {
              setState(() {
                _isTestModeActive = !_isTestModeActive;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _isTestModeActive
                        ? '🧪 Test Mode ON: Unlocking today\'s hike controls.'
                        : 'Test Mode OFF: Real Date Checking Restored.',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _scheduleStore,
        builder: (context, _) {
          if (_scheduleStore.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: primaryGreen),
            );
          }

          final hikes = _scheduleStore.scheduledHikes;

          if (hikes.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.hiking_outlined, size: 72, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'No Scheduled Hikes',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Go to Mountain details and schedule a hike first to unlock live location broadcasting!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600, height: 1.4),
                    ),
                  ],
                ),
              ),
            );
          }

          final todayHikes = _scheduleStore.todayHikes;
          final bool hasHikeToday = todayHikes.isNotEmpty || _isTestModeActive;

          final activeHike = _isTestModeActive
              ? hikes.first
              : (todayHikes.isNotEmpty ? todayHikes.first : hikes.first);

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isTestModeActive)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      border: Border.all(color: Colors.amber.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.science_outlined, color: Colors.amber.shade900),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'TEST MODE ACTIVE: Live controls forced ON for testing.',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // 🌟 ACTIVE HIKE CARD
                Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                activeHike.mountainName,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: hasHikeToday
                                    ? accentGreen.withOpacity(0.12)
                                    : Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: hasHikeToday
                                      ? accentGreen
                                      : Colors.orange.shade300,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    hasHikeToday
                                        ? Icons.verified
                                        : Icons.schedule,
                                    size: 14,
                                    color: hasHikeToday
                                        ? accentGreen
                                        : Colors.orange.shade800,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    hasHikeToday ? 'HIKE DAY' : 'UPCOMING',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: hasHikeToday
                                          ? accentGreen
                                          : Colors.orange.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.alt_route_rounded,
                                size: 16, color: Colors.grey.shade600),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                activeHike.trailName,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.calendar_today_rounded,
                                size: 15, color: Colors.grey.shade600),
                            const SizedBox(width: 6),
                            Text(
                              ScheduledHike.dateKey(activeHike.hikeDate),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Divider(height: 1),
                        ),

                        if (hasHikeToday) ...[
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _isLiveTrackingActive
                                      ? Colors.red
                                      : Colors.green,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isLiveTrackingActive
                                    ? 'Live GPS Broadcast Active'
                                    : 'Live Location Sharing Ready!',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: _isLiveTrackingActive
                                      ? Colors.red.shade700
                                      : primaryGreen,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // 📋 COPY LINK BUTTON
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryGreen,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: const Icon(Icons.copy_rounded, size: 18),
                              label: const Text(
                                'Copy Tracking Link',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              onPressed: () =>
                                  _copyLiveLocationLink(activeHike),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // ⏯️ START / STOP BUTTON
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                foregroundColor: _isLiveTrackingActive
                                    ? Colors.red.shade700
                                    : primaryGreen,
                                side: BorderSide(
                                  color: _isLiveTrackingActive
                                      ? Colors.red.shade300
                                      : primaryGreen,
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: Icon(
                                _isLiveTrackingActive
                                    ? Icons.stop_circle_outlined
                                    : Icons.play_arrow_rounded,
                                size: 20,
                              ),
                              label: Text(
                                _isLiveTrackingActive
                                    ? 'Stop Live Broadcast'
                                    : 'Start Real-Time Tracking',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              onPressed: () => _toggleTracking(activeHike),
                            ),
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.lock_clock,
                                    color: Colors.orange.shade700, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Live location sharing automatically unlocks on your scheduled hike day.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // 📅 SCHEDULED HIKES LIST
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(
                    'Your Scheduled Hikes (${hikes.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: hikes.length,
                  itemBuilder: (context, index) {
                    final item = hikes[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        leading: CircleAvatar(
                          backgroundColor: item.isHikeToday
                              ? primaryGreen.withOpacity(0.1)
                              : Colors.blue.shade50,
                          child: Icon(
                            item.isHikeToday
                                ? Icons.hiking
                                : Icons.calendar_month_rounded,
                            color: item.isHikeToday
                                ? primaryGreen
                                : Colors.blue.shade700,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          item.mountainName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        subtitle: Text(
                          '${item.trailName} • ${ScheduledHike.dateKey(item.hikeDate)}',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                        ),
                        trailing: item.isHikeToday
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: primaryGreen,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Today',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}