import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:quick_blood/config/app_router.dart';
import 'package:quick_blood/core/constants/app_constants.dart';
import 'package:quick_blood/core/constants/view_constants.dart';
import 'package:quick_blood/utils/app_asset.dart';
import 'package:quick_blood/widgets/custom_text.dart';
import '../../../bloc/authentication_bloc/authentication_bloc.dart';
import '../../../bloc/authentication_bloc/authentication_events.dart';
import '../../../bloc/authentication_bloc/authentication_states.dart';
import '../../../bloc/theme_bloc/theme_bloc.dart';
import '../../../config/named_router.dart';
import '../../../data/managers/local/session_manager.dart';
import '../../../injection_container.dart';

class SplashScreen extends StatefulWidget {
  final String? deepLinkError;
  const SplashScreen({super.key, this.deepLinkError});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  
  ThemeBloc themeBloc = sl<ThemeBloc>();
  AuthenticationBloc authenticationBloc = sl<AuthenticationBloc>();
  SessionManager sessionManager = sl<SessionManager>();

  late AnimationController _entryController;
  late AnimationController _pulseController;

  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<Offset> _titleSlide;
  late Animation<double> _titleFade;
  late Animation<double> _taglineFade;
  late Animation<double> _loaderFade;

  late Animation<double> _dot1;
  late Animation<double> _dot2;
  late Animation<double> _dot3;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _entryController.forward();
      if (widget.deepLinkError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.deepLinkError!),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      initializeComponent();
    });
  }

  void _setupAnimations() {
    
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _logoScale = Tween<double>(begin: 0.70, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.58, curve: Curves.elasticOut),
      ),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.38, curve: Curves.easeOut),
      ),
    );

    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.45),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.38, 0.72, curve: Curves.easeOut),
      ),
    );

    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.38, 0.72, curve: Curves.easeOut),
      ),
    );

    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.56, 0.90, curve: Curves.easeOut),
      ),
    );

    _loaderFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.82, 1.0, curve: Curves.easeOut),
      ),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _dot1 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: const Interval(0.0, 0.60, curve: Curves.easeInOut),
      ),
    );

    _dot2 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: const Interval(0.15, 0.75, curve: Curves.easeInOut),
      ),
    );

    _dot3 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: const Interval(0.30, 0.90, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  void dispose() {
    _entryController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final primary = themeBloc.state.baseTheme.primary;

    return BlocListener<AuthenticationBloc, AuthenticationState>(
      bloc: authenticationBloc,
      listener: (context, state) {
        
        if (state is AuthenticationAuthenticated) {
          final user = state.userModel ?? sessionManager.getUser();
          if (user != null && user.isOnboardingCompleted) {
            AppRouter.pushNamedAndRemoveUntil(context, RouteNames.bottomNavbar);
          } else {
            AppRouter.pushNamedAndRemoveUntil(context, RouteNames.onboarding);
          }
        } else if (state is AuthenticationUnauthenticated) {
          AppRouter.pushNamedAndRemoveUntil(context, RouteNames.welcome);
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            
            Positioned.fill(
              child: CustomPaint(
                painter: _BackgroundPainter(primary: primary),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          
                          FadeTransition(
                            opacity: _logoFade,
                            child: ScaleTransition(
                              scale: _logoScale,
                              child: _LogoBadge(
                                primary: primary,
                                svgSize: size.width * 0.22,
                              ),
                            ),
                          ),

                          const SizedBox(height: AppConstants.gap30Px),

                          FadeTransition(
                            opacity: _titleFade,
                            child: SlideTransition(
                              position: _titleSlide,
                              child: CustomText(
                                text: ViewConstants.bloodConnect,
                                size: AppConstants.font28Px,
                                weight: FontWeight.w800,
                                textColor: primary,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),

                          const SizedBox(height: AppConstants.gap8Px),

                          FadeTransition(
                            opacity: _taglineFade,
                            child: CustomText(
                              text: 'Connecting Donors · Saving Lives',
                              size: AppConstants.font14Px,
                              weight: FontWeight.w400,
                              textColor: primary.withOpacity(0.48),
                              letterSpacing: 0.3,
                              translate: false,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  FadeTransition(
                    opacity: _loaderFade,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppConstants.gap50Px,
                      ),
                      child: _PulsingDots(
                        dot1: _dot1,
                        dot2: _dot2,
                        dot3: _dot3,
                        color: primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void initializeComponent() {
    Future.delayed(const Duration(seconds: 2), () {
      final currentState = authenticationBloc.state;
      if (currentState is AuthenticationAuthenticated) {
        final user = currentState.userModel ?? sessionManager.getUser();
        if (user != null && user.isOnboardingCompleted) {
          AppRouter.pushNamedAndRemoveUntil(context, RouteNames.bottomNavbar);
        } else {
          AppRouter.pushNamedAndRemoveUntil(context, RouteNames.onboarding);
        }
      } else if (currentState is AuthenticationUnauthenticated) {
        AppRouter.pushNamedAndRemoveUntil(context, RouteNames.welcome);
      } else if (currentState is AuthenticationPasswordRecovery) {
        
      } else {
        authenticationBloc.add(const CheckAuthenticationStatusEvent());
      }
    });
  }
}

class _BackgroundPainter extends CustomPainter {
  final Color primary;

  const _BackgroundPainter({required this.primary});

  @override
  void paint(Canvas canvas, Size size) {
    
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            primary.withOpacity(0.07),
            Colors.white,
          ],
          stops: const [0.0, 0.68],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawCircle(
      Offset(size.width * 1.18, -size.height * 0.04),
      size.width * 0.55,
      Paint()..color = primary.withOpacity(0.055),
    );

    canvas.drawCircle(
      Offset(-size.width * 0.22, size.height * 1.06),
      size.width * 0.50,
      Paint()..color = primary.withOpacity(0.045),
    );

    canvas.drawCircle(
      Offset(size.width * 0.07, size.height * 0.27),
      size.width * 0.13,
      Paint()..color = primary.withOpacity(0.04),
    );

    canvas.drawCircle(
      Offset(size.width * 0.90, size.height * 0.73),
      size.width * 0.10,
      Paint()..color = primary.withOpacity(0.035),
    );
  }

  @override
  bool shouldRepaint(_BackgroundPainter oldDelegate) =>
      oldDelegate.primary != primary;
}

class _LogoBadge extends StatelessWidget {
  final Color primary;
  final double svgSize;

  const _LogoBadge({required this.primary, required this.svgSize});

  @override
  Widget build(BuildContext context) {
    final badgeSize = svgSize * 1.85;

    return Stack(
      alignment: Alignment.center,
      children: [
        
        Container(
          width: badgeSize * 1.22,
          height: badgeSize * 1.22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: primary.withOpacity(0.05),
          ),
        ),

        Container(
          width: badgeSize,
          height: badgeSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: primary.withOpacity(0.09),
            border: Border.all(
              color: primary.withOpacity(0.16),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: primary.withOpacity(0.18),
                blurRadius: 40,
                spreadRadius: 4,
                offset: Offset.zero,
              ),
              BoxShadow(
                color: primary.withOpacity(0.08),
                blurRadius: 70,
                spreadRadius: 14,
                offset: Offset.zero,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: SvgPicture.asset(
            AppAsset.bloodDonationIcon,
            width: svgSize,
            height: svgSize,
          ),
        ),
      ],
    );
  }
}

class _PulsingDots extends StatelessWidget {
  final Animation<double> dot1;
  final Animation<double> dot2;
  final Animation<double> dot3;
  final Color color;

  const _PulsingDots({
    required this.dot1,
    required this.dot2,
    required this.dot3,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Dot(animation: dot1, color: color),
        const SizedBox(width: AppConstants.gap8Px),
        _Dot(animation: dot2, color: color),
        const SizedBox(width: AppConstants.gap8Px),
        _Dot(animation: dot3, color: color),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final Animation<double> animation;
  final Color color;

  const _Dot({required this.animation, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {

        
        final scale = 0.55 + 0.45 * animation.value;
        final opacity = 0.30 + 0.70 * animation.value;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(opacity),
            ),
          ),
        );
      },
    );
  }
}
