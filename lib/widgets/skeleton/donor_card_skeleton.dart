import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/theme_bloc/theme_bloc.dart';
import '../../config/theme/base.dart';
import '../../core/constants/app_constants.dart';
import '../../core/extensions/color.dart';

class DonorCardSkeleton extends StatefulWidget {
  final BaseTheme? baseTheme;

  const DonorCardSkeleton({super.key, this.baseTheme});

  @override
  State<DonorCardSkeleton> createState() => _DonorCardSkeletonState();
}

class _DonorCardSkeletonState extends State<DonorCardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme =
        widget.baseTheme ?? context.read<ThemeBloc>().state.baseTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.gap12Px),
      decoration: BoxDecoration(
        color: baseTheme.white,
        borderRadius: BorderRadius.circular(AppConstants.radius16Px),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.gap16Px),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: avatar + name/subtitle + blood group badge ───────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar circle
                _buildShimmer(
                  height: 52,
                  width: 52,
                  baseTheme: baseTheme,
                  borderRadius: 26,
                ),
                const SizedBox(width: AppConstants.gap12Px),

                // Name + subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 2),
                      _buildShimmer(
                        height: 16,
                        width: 150,
                        baseTheme: baseTheme,
                        borderRadius: AppConstants.radius4Px,
                      ),
                      const SizedBox(height: 6),
                      _buildShimmer(
                        height: 13,
                        width: 100,
                        baseTheme: baseTheme,
                        borderRadius: AppConstants.radius4Px,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppConstants.gap8Px),

                // Blood group badge
                _buildShimmer(
                  height: 26,
                  width: 44,
                  baseTheme: baseTheme,
                  borderRadius: 20,
                ),
              ],
            ),

            const SizedBox(height: AppConstants.gap14Px),

            // ── Divider ──────────────────────────────────────────────────
            _buildShimmer(
              height: 1,
              width: double.infinity,
              baseTheme: baseTheme,
              borderRadius: 0,
            ),

            const SizedBox(height: AppConstants.gap12Px),

            // ── Meta info rows ────────────────────────────────────────────
            Wrap(
              spacing: AppConstants.gap16Px,
              runSpacing: AppConstants.gap6Px,
              children: [
                _buildMetaSkeleton(baseTheme, width: 130),
                _buildMetaSkeleton(baseTheme, width: 100),
              ],
            ),

            const SizedBox(height: AppConstants.gap14Px),

            // ── Divider ──────────────────────────────────────────────────
            _buildShimmer(
              height: 1,
              width: double.infinity,
              baseTheme: baseTheme,
              borderRadius: 0,
            ),

            const SizedBox(height: AppConstants.gap14Px),

            // ── Action buttons ────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _buildShimmer(
                    height: 40,
                    width: double.infinity,
                    baseTheme: baseTheme,
                    borderRadius: AppConstants.radius12Px,
                  ),
                ),
                const SizedBox(width: AppConstants.gap10Px),
                Expanded(
                  child: _buildShimmer(
                    height: 40,
                    width: double.infinity,
                    baseTheme: baseTheme,
                    borderRadius: AppConstants.radius12Px,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaSkeleton(BaseTheme baseTheme, {required double width}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildShimmer(
          height: 13,
          width: 13,
          baseTheme: baseTheme,
          borderRadius: 4,
        ),
        const SizedBox(width: 4),
        _buildShimmer(
          height: 12,
          width: width,
          baseTheme: baseTheme,
          borderRadius: AppConstants.radius4Px,
        ),
      ],
    );
  }

  Widget _buildShimmer({
    required double height,
    required double width,
    required BaseTheme baseTheme,
    double? borderRadius,
  }) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: height,
          width: width == double.infinity ? null : width,
          decoration: BoxDecoration(
            color: baseTheme.shimmer.fixedOpacity(_animation.value),
            borderRadius: BorderRadius.circular(
              borderRadius ?? AppConstants.radius4Px,
            ),
          ),
        );
      },
    );
  }
}
