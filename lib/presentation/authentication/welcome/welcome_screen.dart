import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:training_projects/core/constants/view_constants.dart';
import '../../../bloc/theme_bloc/theme_bloc.dart';
import '../../../config/app_router.dart';
import '../../../config/named_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../injection_container.dart';
import '../../../utils/app_asset.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  ThemeBloc themeBloc = sl<ThemeBloc>();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppConstants.gap24Px),
          child: Column(
            children: [
              SizedBox(height: size.height * 0.08),
              SvgPicture.asset(
                AppAsset.bloodDonationIcon,
                width: size.width * 0.4,
                height: size.width * 0.4,
              ),
              SizedBox(height: AppConstants.gap40Px),
              CustomText(
                text: ViewConstants.welcomeToBloodConnect,
                weight: FontWeight.w800,
                textColor: themeBloc.state.baseTheme.primary,
                size: AppConstants.font28Px,
                align: TextAlign.center,
              ),
              SizedBox(height: AppConstants.gap20Px),
              CustomText(
                text: ViewConstants.connectWithDonorsAndSaveLives,
                weight: FontWeight.w400,
                size: AppConstants.font16Px,
                align: TextAlign.center,
                maxLines: 3,
                height: 1.5,
              ),
              
              const Spacer(),

              CustomButton(
                text: ViewConstants.getStarted,
                onPress: ()=> AppRouter.pushNamed(context, RouteNames.signup),
              ),
              
              SizedBox(height: AppConstants.gap16Px),

              CustomButton(
                text: ViewConstants.signIn,
                onPress: () => AppRouter.pushNamed(context, RouteNames.signIn),
                borderColor: themeBloc.state.baseTheme.white,
                textColor: themeBloc.state.baseTheme.primary,
                bgColor: themeBloc.state.baseTheme.white,
              ),
              
              SizedBox(height: size.height * 0.06),
            ],
          ),
        ),
      ),
    );
  }
}
