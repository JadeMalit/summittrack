import 'package:flutter/material.dart';

import '../helpers/profile_constants.dart';
import '../helpers/profile_models.dart';
import 'profile_action_buttons.dart';
import 'profile_detail_item.dart';

class ProfileInfoCard extends StatelessWidget {
  const ProfileInfoCard({
    super.key,
    required this.primaryName,
    required this.details,
    required this.onDetailTap,
    required this.onLogout,
    required this.entryAnimation,
  });

  final String primaryName;
  final List<ProfileDetail> details;
  final ValueChanged<ProfileEditableField> onDetailTap;
  final Future<void> Function() onLogout;
  final Animation<double> entryAnimation;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ProfileConstants.cardTop,
            ProfileConstants.cardMiddle,
            ProfileConstants.cardBottom,
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: EdgeInsets.fromLTRB(18, 70, 18, 24 + bottomInset),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        Text(
                          primaryName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: 84,
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.82),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        const SizedBox(height: 20),
                        for (final entry in details.asMap().entries) ...[
                          ProfileDetailItem(
                            detail: entry.value,
                            onTap: () => onDetailTap(entry.value.field),
                            index: entry.key,
                            entryAnimation: entryAnimation,
                          ),
                          if (entry.key != details.length - 1)
                            const SizedBox(height: 12),
                        ],
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 26),
                      child: ProfileActionButtons(onLogout: onLogout),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
