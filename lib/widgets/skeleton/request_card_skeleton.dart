import 'package:flutter/material.dart';
import '../../bloc/theme_bloc/theme_bloc.dart';
import '../../config/theme/base.dart';
import '../../core/constants/app_constants.dart';
import '../../core/extensions/color.dart';
import '../../injection_container.dart';

class RequestCardSkeleton extends StatefulWidget {
  const RequestCardSkeleton({super.key});

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
    final themeBloc = sl<ThemeBloc>();
    final baseTheme = themeBloc.state.baseTheme;

    return Card(
      margin: EdgeInsets.only(bottom: AppConstants.gap12Px),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radius12Px),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppConstants.gap16Px),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildShimmer(
                        height: 20,
                        width: double.infinity,
                        baseTheme: baseTheme,
                      ),
                      const SizedBox(height: AppConstants.gap8Px),
                      _buildShimmer(
                        height: 16,
                        width: 150,
                        baseTheme: baseTheme,
                      ),
                    ],
                  ),
                ),
                _buildShimmer(
                  height: 30,
                  width: 80,
                  baseTheme: baseTheme,
                  borderRadius: AppConstants.radius8Px,
                ),
              ],
            ),
            const SizedBox(height: AppConstants.gap12Px),
            Row(
              children: [
                _buildShimmer(
                  height: 20,
                  width: 50,
                  baseTheme: baseTheme,
                ),
                const SizedBox(width: AppConstants.gap16Px),
                _buildShimmer(
                  height: 16,
                  width: 80,
                  baseTheme: baseTheme,
                ),
              ],
            ),
            const SizedBox(height: AppConstants.gap8Px),
            _buildShimmer(
              height: 14,
              width: double.infinity,
              baseTheme: baseTheme,
            ),
            const SizedBox(height: AppConstants.gap8Px),
            _buildShimmer(
              height: 14,
              width: 120,
              baseTheme: baseTheme,
            ),
            const SizedBox(height: AppConstants.gap16Px),
            _buildShimmer(
              height: 48,
              width: double.infinity,
              baseTheme: baseTheme,
              borderRadius: AppConstants.radius12Px,
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
    double? borderRadius,
  }) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            color: baseTheme.shimmer.fixedOpacity(_animation.value),
            borderRadius: borderRadius != null
                ? BorderRadius.circular(borderRadius)
                : BorderRadius.circular(AppConstants.radius4Px),
          ),
        );
      },
    );
  }
}
