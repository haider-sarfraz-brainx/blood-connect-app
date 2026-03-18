import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:training_projects/core/extensions/color.dart';
import '../../../bloc/theme_bloc/theme_bloc.dart';
import '../../../config/theme/base.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/view_constants.dart';
import '../../../injection_container.dart';
import '../donors/donors_screen.dart';
import '../home/home_screen.dart';
import '../request_blood/blood_request_screen.dart';
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

  void _onTabTapped(int index) {
    if (_currentIndex == index) return;
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = themeBloc.state.baseTheme;
    final navColors = baseTheme.bottomNavBar;

    return Scaffold(
      backgroundColor: baseTheme.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _FloatingNavBar(
        currentIndex: _currentIndex,
        baseTheme: baseTheme,
        navColors: navColors,
        onTap: _onTabTapped,
        items: const [
          _NavItemData(
            icon: Icons.home_rounded,
            label: ViewConstants.home,
          ),
          _NavItemData(
            icon: Icons.people_rounded,
            label: ViewConstants.donors,
          ),
          _NavItemData(
            icon: Icons.bloodtype_rounded,
            label: ViewConstants.requestBlood,
          ),
          _NavItemData(
            icon: Icons.settings_rounded,
            label: ViewConstants.setting,
          ),
        ],
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final String label;

  const _NavItemData({required this.icon, required this.label});
}

class _FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final BaseTheme baseTheme;
  final BottomNavBarColors navColors;
  final ValueChanged<int> onTap;
  final List<_NavItemData> items;

  const _FloatingNavBar({
    required this.currentIndex,
    required this.baseTheme,
    required this.navColors,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      decoration: BoxDecoration(
        color: navColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radius24Px),
        boxShadow: [
          BoxShadow(
            color: Colors.black.fixedOpacity(0.12),
            blurRadius: 28,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.fixedOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            children: List.generate(
              items.length,
              (i) => _NavItem(
                icon: items[i].icon,
                label: items[i].label,
                isSelected: currentIndex == i,
                baseTheme: baseTheme,
                navColors: navColors,
                onTap: () => onTap(i),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final BaseTheme baseTheme;
  final BottomNavBarColors navColors;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.baseTheme,
    required this.navColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selectedColor = baseTheme.primary;
    final unselectedColor = baseTheme.disable;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? selectedColor.withOpacity(0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: child,
                ),
                child: Icon(
                  icon,
                  key: ValueKey(isSelected),
                  size: 22,
                  color: isSelected ? selectedColor : unselectedColor,
                ),
              ),
            ),

            const SizedBox(height: 3),

            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              style: TextStyle(
                fontFamily: AppConstants.fontFamilyLato,
                fontSize: AppConstants.font10Px,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected ? selectedColor : unselectedColor,
                letterSpacing: isSelected ? 0.2 : 0.0,
              ),
              child: Text(
                label.tr(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
