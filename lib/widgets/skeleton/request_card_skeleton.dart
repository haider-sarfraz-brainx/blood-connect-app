import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/theme_bloc/theme_bloc.dart';
import '../../config/theme/base.dart';
import '../../core/constants/app_constants.dart';
import '../../core/extensions/color.dart';

class RequestCardSkeleton extends StatefulWidget {
  final BaseTheme? baseTheme;

  const RequestCardSkeleton({super.key, this.baseTheme});

  @override
  State<RequestCardSkeleton> createState() => _RequestCardSkeletonState();
}

class _RequestCardSkeletonState extends State<RequestCardSkeleton>
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
            color: Colors.black.withOpacity(0.05),
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
            
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                _buildShimmer(
                  height: 52,
                  width: 52,
                  baseTheme: baseTheme,
                  borderRadius: 26,
                ),
                const SizedBox(width: AppConstants.gap12Px),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 2),
                      _buildShimmer(
                        height: 16,
                        width: 160,
                        baseTheme: baseTheme,
                        borderRadius: AppConstants.radius4Px,
                      ),
                      const SizedBox(height: 6),
                      _buildShimmer(
                        height: 13,
                        width: 110,
                        baseTheme: baseTheme,
                        borderRadius: AppConstants.radius4Px,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppConstants.gap8Px),

                _buildShimmer(
                  height: 24,
                  width: 72,
                  baseTheme: baseTheme,
                  borderRadius: 20,
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

            Wrap(
              spacing: AppConstants.gap16Px,
              runSpacing: AppConstants.gap6Px,
              children: [
                _buildShimmer(
                  height: 14,
                  width: 70,
                  baseTheme: baseTheme,
                  borderRadius: AppConstants.radius4Px,
                ),
                _buildShimmer(
                  height: 14,
                  width: 130,
                  baseTheme: baseTheme,
                  borderRadius: AppConstants.radius4Px,
                ),
                _buildShimmer(
                  height: 14,
                  width: 100,
                  baseTheme: baseTheme,
                  borderRadius: AppConstants.radius4Px,
                ),
              ],
            ),

            const SizedBox(height: AppConstants.gap10Px),

            _buildShimmer(
              height: 12,
              width: 80,
              baseTheme: baseTheme,
              borderRadius: AppConstants.radius4Px,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer({
    required double height,
    required double width,
    required BaseTheme baseTheme,
    double borderRadius = AppConstants.radius4Px,
  }) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: height,
          width: width == double.infinity ? null : width,
          decoration: BoxDecoration(
            color: baseTheme.shimmer.fixedOpacity(_animation.value),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        );
      },
    );
  }
}
