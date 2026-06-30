import 'package:flutter/material.dart';

import '../../../core/routing/app_routes.dart';
import '../../../data/trail_data/kapatagan_trail_data.dart';
import 'trail_detail_screen.dart';

class KapataganTrailDetailsScreen extends StatelessWidget {
  const KapataganTrailDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TrailDetailScreen(
      trail: kapataganTrail,
      parentRoute: AppRoutes.mountain(AppRoutes.mtApoMountainId),
      trailPhotoId: 'kapatagan',
    );
  }
}
