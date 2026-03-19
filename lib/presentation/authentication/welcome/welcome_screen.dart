import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:quick_blood/core/constants/view_constants.dart';
import '../../../bloc/theme_bloc/theme_bloc.dart';
import '../../../config/theme/base.dart';
import '../../../config/app_router.dart';
import '../../../config/named_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/extensions/color.dart';
import '../../../injection_container.dart';
import '../../../utils/app_asset.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  ThemeBloc get _themeBloc => sl<ThemeBloc>();

  late final AnimationController _logoController;
  late final AnimationController _contentController;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _titleOpacity;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _subtitleOpacity;
  late final Animation<Offset> _subtitleSlide;
  late final Animation<double> _buttonsOpacity;
  late final Animation<Offset> _buttonsSlide;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _logoOpacity = CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic),
    );
    _logoScale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.85, curve: Curves.easeOutBack),
      ),
    );

    _titleOpacity = CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.05, 0.5, curve: Curves.easeOutCubic),
    ));

    _subtitleOpacity = CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.15, 0.55, curve: Curves.easeOut),
    );
    _subtitleSlide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.2, 0.6, curve: Curves.easeOutCubic),
    ));

    _buttonsOpacity = CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.35, 0.85, curve: Curves.easeOut),
    );
    _buttonsSlide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.4, 0.95, curve: Curves.easeOutCubic),
    ));

    _logoController.forward();
    _logoController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _contentController.forward();
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = _themeBloc.state.baseTheme;
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final horizontal = AppConstants.gap24Px;
    final logoSize = math.min(size.width * 0.38, 168.0);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          _WelcomeGradientBackground(theme: theme),
          _DecorativeBackdrop(theme: theme, size: size),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.symmetric(horizontal: horizontal),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight - padding.bottom - 200,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(height: size.height * 0.04),
                              FadeTransition(
                                opacity: _logoOpacity,
                                child: ScaleTransition(
                                  scale: _logoScale,
                                  child: _LogoHero(
                                    theme: theme,
                                    logoSize: logoSize,
                                  ),
                                ),
                              ),
                              SizedBox(height: AppConstants.gap40Px),
                              SlideTransition(
                                position: _titleSlide,
                                child: FadeTransition(
                                  opacity: _titleOpacity,
                                  child: CustomText(
                                    text: ViewConstants.welcomeToBloodConnect,
                                    weight: FontWeight.w800,
                                    textColor: theme.textColor,
                                    size: AppConstants.font28Px + 4,
                                    align: TextAlign.center,
                                    height: 1.2,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                              SizedBox(height: AppConstants.gap16Px),
                              SlideTransition(
                                position: _subtitleSlide,
                                child: FadeTransition(
                                  opacity: _subtitleOpacity,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppConstants.gap8Px,
                                    ),
                                    child: CustomText(
                                      text: ViewConstants
                                          .connectWithDonorsAndSaveLives,
                                      weight: FontWeight.w400,
                                      size: AppConstants.font16Px + 1,
                                      align: TextAlign.center,
                                      maxLines: 4,
                                      height: 1.55,
                                      textColor: theme.textColor
                                          .fixedOpacity(0.72),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: AppConstants.gap24Px),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SlideTransition(
                      position: _buttonsSlide,
                      child: FadeTransition(
                        opacity: _buttonsOpacity,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontal,
                            AppConstants.gap12Px,
                            horizontal,
                            math.max(padding.bottom, AppConstants.gap24Px),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CustomButton(
                                text: ViewConstants.getStarted,
                                elevation: 8,
                                onPress: () => AppRouter.pushNamed(
                                  context,
                                  RouteNames.signup,
                                ),
                              ),
                              SizedBox(height: AppConstants.gap14Px),
                              CustomButton(
                                text: ViewConstants.signIn,
                                outlined: true,
                                onPress: () => AppRouter.pushNamed(
                                  context,
                                  RouteNames.signIn,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeGradientBackground extends StatelessWidget {
  const _WelcomeGradientBackground({required this.theme});

  final BaseTheme theme;

  @override
  Widget build(BuildContext context) {
    final bg = theme.background;
    final p = theme.primary;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(bg, p, 0.14)!,
            Color.lerp(bg, p, 0.04)!,
            bg,
            Color.lerp(bg, p, 0.07)!,
          ],
          stops: const [0.0, 0.28, 0.62, 1.0],
        ),
      ),
    );
  }
}

class _DecorativeBackdrop extends StatelessWidget {
  const _DecorativeBackdrop({
    required this.theme,
    required this.size,
  });

  final BaseTheme theme;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final p = theme.primary;
    final soft = p.fixedOpacity(0.09);
    final softer = p.fixedOpacity(0.05);

    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            right: -size.width * 0.15,
            top: -size.height * 0.02,
            child: _Blob(
              diameter: size.width * 0.72,
              color: soft,
            ),
          ),
          Positioned(
            left: -size.width * 0.22,
            top: size.height * 0.18,
            child: _Blob(
              diameter: size.width * 0.55,
              color: softer,
            ),
          ),
          Positioned(
            left: size.width * 0.35,
            bottom: size.height * 0.12,
            child: _Blob(
              diameter: size.width * 0.42,
              color: soft,
            ),
          ),
          Positioned(
            right: size.width * 0.08,
            bottom: size.height * 0.28,
            child: Icon(
              Icons.favorite_rounded,
              size: 28,
              color: p.fixedOpacity(0.12),
            ),
          ),
          Positioned(
            left: size.width * 0.1,
            top: size.height * 0.32,
            child: Icon(
              Icons.bloodtype_rounded,
              size: 32,
              color: p.fixedOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({
    required this.diameter,
    required this.color,
  });

  final double diameter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: diameter * 0.25,
            spreadRadius: 0,
          ),
        ],
      ),
    );
  }
}

class _LogoHero extends StatelessWidget {
  const _LogoHero({
    required this.theme,
    required this.logoSize,
  });

  final BaseTheme theme;
  final double logoSize;

  @override
  Widget build(BuildContext context) {
    final p = theme.primary;
    return Container(
      padding: const EdgeInsets.all(AppConstants.gap24Px),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.white.fixedOpacity(0.85),
        boxShadow: [
          BoxShadow(
            color: p.fixedOpacity(0.22),
            blurRadius: 32,
            offset: const Offset(0, 14),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: p.fixedOpacity(0.12),
            blurRadius: 48,
            spreadRadius: 2,
          ),
        ],
      ),
      child: SvgPicture.asset(
        AppAsset.bloodDonationIcon,
        width: logoSize,
        height: logoSize,
        fit: BoxFit.contain,
      ),
    );
  }
}
