import 'package:flutter/material.dart';
import '../../bloc/theme_bloc/theme_bloc.dart';
import '../../config/theme/base.dart';
import '../../core/constants/app_constants.dart';
import '../../core/extensions/color.dart';
import '../../injection_container.dart';

class DonorCardSkeleton extends StatefulWidget {
  const DonorCardSkeleton({super.key});

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
    final baseTheme = sl<ThemeBloc>().state.baseTheme;

    return Container(
      margin: EdgeInsets.only(bottom: AppConstants.gap14Px),
      decoration: BoxDecoration(
        color: baseTheme.white,
        borderRadius: BorderRadius.circular(AppConstants.radius16Px),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.radius16Px),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left accent bar
            _buildShimmer(
              height: double.infinity,
              width: 5,
              baseTheme: baseTheme,
              borderRadius: 0,
            ),
            // Card body
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(AppConstants.gap16Px),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Top: avatar + name/info ──────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar circle
                        _buildShimmer(
                          height: 60,
                          width: 60,
                          baseTheme: baseTheme,
                          borderRadius: 30,
                        ),
                        const SizedBox(width: AppConstants.gap14Px),
                        // Name / subtitle / address
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: AppConstants.gap4Px),
                              _buildShimmer(
                                height: 18,
                                width: 160,
                                baseTheme: baseTheme,
                                borderRadius: AppConstants.radius4Px,
                              ),
                              const SizedBox(height: AppConstants.gap8Px),
                              _buildShimmer(
                                height: 13,
                                width: 110,
                                baseTheme: baseTheme,
                                borderRadius: AppConstants.radius4Px,
                              ),
                              const SizedBox(height: AppConstants.gap6Px),
                              _buildShimmer(
                                height: 12,
                                width: 140,
                                baseTheme: baseTheme,
                                borderRadius: AppConstants.radius4Px,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppConstants.gap14Px),
                    _buildShimmer(
                      height: 1,
                      width: double.infinity,
                      baseTheme: baseTheme,
                      borderRadius: 0,
                    ),
                    const SizedBox(height: AppConstants.gap12Px),

                    // ── Info rows ────────────────────────────────────
                    _buildInfoRowSkeleton(baseTheme),
                    const SizedBox(height: AppConstants.gap8Px),
                    _buildInfoRowSkeleton(baseTheme, width: 200),

                    const SizedBox(height: AppConstants.gap14Px),
                    _buildShimmer(
                      height: 1,
                      width: double.infinity,
                      baseTheme: baseTheme,
                      borderRadius: 0,
                    ),
                    const SizedBox(height: AppConstants.gap12Px),

                    // ── Action buttons ───────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _buildShimmer(
                            height: 40,
                            width: double.infinity,
                            baseTheme: baseTheme,
                            borderRadius: AppConstants.radius10Px,
                          ),
                        ),
                        const SizedBox(width: AppConstants.gap10Px),
                        Expanded(
                          child: _buildShimmer(
                            height: 40,
                            width: double.infinity,
                            baseTheme: baseTheme,
                            borderRadius: AppConstants.radius10Px,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRowSkeleton(BaseTheme baseTheme, {double width = 170}) {
    return Row(
      children: [
        _buildShimmer(
          height: 28,
          width: 28,
          baseTheme: baseTheme,
          borderRadius: AppConstants.radius8Px,
        ),
        const SizedBox(width: AppConstants.gap10Px),
        _buildShimmer(
          height: 13,
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
