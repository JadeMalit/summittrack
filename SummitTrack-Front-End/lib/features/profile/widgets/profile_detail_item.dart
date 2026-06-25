import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../helpers/profile_constants.dart';
import '../helpers/profile_models.dart';

class ProfileDetailItem extends StatefulWidget {
  const ProfileDetailItem({
    super.key,
    required this.detail,
    required this.onTap,
    required this.index,
    required this.entryAnimation,
  });

  final ProfileDetail detail;
  final VoidCallback onTap;
  final int index;
  final Animation<double> entryAnimation;

  @override
  State<ProfileDetailItem> createState() => _ProfileDetailItemState();
}

class _ProfileDetailItemState extends State<ProfileDetailItem> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) {
      return;
    }

    setState(() {
      _pressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final start =
        ProfileConstants.detailItemStart +
        (widget.index * ProfileConstants.detailItemStep);
    final end = (start + ProfileConstants.detailItemDuration).clamp(0.0, 1.0);
    final animation = CurvedAnimation(
      parent: widget.entryAnimation,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(animation),
        child: AnimatedScale(
          scale: _pressed ? 0.985 : 1.0,
          duration: ProfileConstants.detailPressDuration,
          curve: Curves.easeOut,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTapDown: (_) => _setPressed(true),
              onTapCancel: () => _setPressed(false),
              onTap: () {
                _setPressed(false);
                widget.onTap();
              },
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: context.isDarkMode
                      ? colors.surfaceHigh
                      : Colors.white.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: context.isDarkMode
                        ? colors.border
                        : ProfileConstants.surfaceBorder,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadow,
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 4,
                      height: ProfileConstants.detailItemHeight,
                      decoration: BoxDecoration(
                        color: colors.accent.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.detail.label,
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.35,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.detail.value,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    AnimatedScale(
                      scale: _pressed ? 1.08 : 1.0,
                      duration: ProfileConstants.detailPressDuration,
                      curve: Curves.easeOut,
                      child: Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
