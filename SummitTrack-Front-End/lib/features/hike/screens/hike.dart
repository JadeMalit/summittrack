import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

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
  bool _isTestModeActive = false; // Toggle para sa testing sa bahay

  @override
  void initState() {
    super.initState();
    _scheduleStore.load();
  }

  /// Direct Share Link Generator
  void _shareLiveLocation(ScheduledHike hike) {
    // 🟢 Updated URL using your active Firebase Hosting domain
    final String trackingUrl =
        "https://summittrack-10481.web.app/track.html?hikeId=${hike.id}";

    final String message = '''
🏔️ Follow my live hike on SummitTrack!
I am currently on my trail at ${hike.mountainName} (${hike.trailName}).

Click the link below to view my real-time GPS location and progress:
$trackingUrl

Stay safe and connected!
''';

    Share.share(message, subject: 'SummitTrack Live Location');
  }

  /// Toggle Live GPS Broadcasting
  Future<void> _toggleTracking(ScheduledHike hike) async {
    if (_isLiveTrackingActive) {
      await _trackingService.stopLiveBroadcast(hike.id);
      setState(() {
        _isLiveTrackingActive = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Live tracking broadcast stopped.')),
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

      _trackingService.startLiveBroadcast(hike.id);
      setState(() {
        _isLiveTrackingActive = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              readiness.status == LocationReadinessStatus.poorAccuracy
                  ? '🟢 Live Tracking Started (${readiness.message})'
                  : '🟢 Live GPS Broadcasting Started! Updates sent in real-time.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Hike Dashboard'),
        actions: [
          IconButton(
            icon: Icon(
              _isTestModeActive ? Icons.bug_report : Icons.bug_report_outlined,
              color: _isTestModeActive ? Colors.amber : null,
            ),
            tooltip: 'Toggle Test Mode (Simulate Today)',
            onPressed: () {
              setState(() {
                _isTestModeActive = !_isTestModeActive;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _isTestModeActive
                        ? '🧪 Test Mode ON: Simulating Hike Day Today!'
                        : 'Test Mode OFF: Real Date Checking Restored.',
                  ),
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
            return const Center(child: CircularProgressIndicator());
          }

          final hikes = _scheduleStore.scheduledHikes;

          if (hikes.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'No scheduled hikes found.\nGo to Mountain details and schedule a hike first!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
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
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isTestModeActive)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.science, color: Colors.amber),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'TEST MODE ACTIVE: Unlocking Live Sharing controls for demo/testing.',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),

                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                activeHike.mountainName,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                            Chip(
                              label: Text(
                                hasHikeToday ? 'HIKE DAY' : 'UPCOMING',
                                style: const TextStyle(color: Colors.white),
                              ),
                              backgroundColor:
                                  hasHikeToday ? Colors.green : Colors.orange,
                            ),
                          ],
                        ),
                        Text(
                          'Trail: ${activeHike.trailName}',
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Scheduled Date: ${ScheduledHike.dateKey(activeHike.hikeDate)}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const Divider(height: 24),

                        if (hasHikeToday) ...[
                          const Text(
                            '🟢 Live Location Sharing Ready!',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              icon: const Icon(Icons.share_location),
                              label: const Text('Share Live Location Link'),
                              onPressed: () => _shareLiveLocation(activeHike),
                            ),
                          ),
                          const SizedBox(height: 8),

                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                foregroundColor: _isLiveTrackingActive
                                    ? Colors.red
                                    : Colors.green,
                              ),
                              icon: Icon(_isLiveTrackingActive
                                  ? Icons.stop
                                  : Icons.play_arrow),
                              label: Text(_isLiveTrackingActive
                                  ? 'Stop Live Broadcast'
                                  : 'Start Real-Time Tracking'),
                              onPressed: () => _toggleTracking(activeHike),
                            ),
                          ),
                        ] else ...[
                          const Row(
                            children: [
                              Icon(Icons.lock_clock, color: Colors.orange),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Live Location Sharing will automatically activate on your scheduled hike day.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'Your Scheduled Hikes (${hikes.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),

                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: hikes.length,
                  itemBuilder: (context, index) {
                    final item = hikes[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(
                          item.isHikeToday
                              ? Icons.hiking
                              : Icons.calendar_month,
                          color: item.isHikeToday ? Colors.green : Colors.blue,
                        ),
                        title: Text(item.mountainName),
                        subtitle: Text(
                            '${item.trailName} • ${ScheduledHike.dateKey(item.hikeDate)}'),
                        trailing: item.isHikeToday
                            ? const Chip(
                                label: Text('Today',
                                    style: TextStyle(fontSize: 10, color: Colors.white)),
                                backgroundColor: Colors.green,
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