import 'package:flutter/material.dart';
import '../../../bloc/theme_bloc/theme_bloc.dart';
import '../../../config/theme/base.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/view_constants.dart';
import '../../../core/extensions/color.dart';
import '../../../injection_container.dart';
import '../../../widgets/custom_text.dart';
import '../donors/donors_screen.dart';
import '../home/home_screen.dart';
import '../request_blood/blood_request_screen.dart';
import '../request_blood/create_blood_screen.dart';
import '../setting/setting_screen.dart';

class BottomNavbarScreen extends StatefulWidget {
  const BottomNavbarScreen({super.key});

  @override
  State<BottomNavbarScreen> createState() => _BottomNavbarScreenState();
}

class _BottomNavbarScreenState extends State<BottomNavbarScreen> {
  int _currentIndex = 0;
  late final ThemeBloc themeBloc;

  final List<Widget> _screens = [
    const HomeScreen(),
    const DonorsScreen(),
    const BloodRequestScreen(),
    const SettingScreen(),
  ];

  @override
  void initState() {
    super.initState();
    themeBloc = sl<ThemeBloc>();
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = themeBloc.state.baseTheme;
    final bottomNavBarColors = baseTheme.bottomNavBar;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: bottomNavBarColors.surface,
          boxShadow: [
            BoxShadow(
              color: themeBloc.state.baseTheme.white,
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  icon: Icons.home_rounded,
                  label: ViewConstants.home,
                  index: 0,
                  baseTheme: baseTheme,
                  bottomNavBarColors: bottomNavBarColors,
                ),
                _buildNavItem(
                  icon: Icons.people_rounded,
                  label: ViewConstants.donors,
                  index: 1,
                  baseTheme: baseTheme,
                  bottomNavBarColors: bottomNavBarColors,
                ),
                _buildNavItem(
                  icon: Icons.bloodtype_rounded,
                  label: ViewConstants.requestBlood,
                  index: 2,
                  baseTheme: baseTheme,
                  bottomNavBarColors: bottomNavBarColors,
                ),
                _buildNavItem(
                  icon: Icons.settings_rounded,
                  label: ViewConstants.setting,
                  index: 3,
                  baseTheme: baseTheme,
                  bottomNavBarColors: bottomNavBarColors,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required BaseTheme baseTheme,
    required BottomNavBarColors bottomNavBarColors,
  }) {
    final isSelected = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isSelected
                    ? bottomNavBarColors.indicator.fixedOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? bottomNavBarColors.foreground
                    : bottomNavBarColors.foreground.fixedOpacity(0.5),
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            Flexible(
              child: CustomText(
                text: label,
                size: AppConstants.font10Px,
                weight: isSelected ? FontWeight.w600 : FontWeight.w400,
                textColor: isSelected
                    ? bottomNavBarColors.foreground
                    : bottomNavBarColors.foreground.fixedOpacity(0.5),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
