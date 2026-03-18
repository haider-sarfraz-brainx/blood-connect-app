import 'package:flutter/material.dart';
import '../../bloc/theme_bloc/theme_bloc.dart';
import '../../config/theme/base.dart';
import '../../core/constants/app_constants.dart';
import '../../injection_container.dart';

class BloodGroupChipSelection extends StatelessWidget {
  final String? selectedBloodGroup;
  final Function(String) onBloodGroupSelected;

  const BloodGroupChipSelection({
    super.key,
    this.selectedBloodGroup,
    required this.onBloodGroupSelected,
  });

  static const _bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-',
  ];

  @override
  Widget build(BuildContext context) {
    final baseTheme = sl<ThemeBloc>().state.baseTheme;

    return Wrap(
      spacing: AppConstants.gap8Px,
      runSpacing: AppConstants.gap10Px,
      children: _bloodGroups
          .map(
            (group) => _BloodGroupChip(
              bloodGroup: group,
              isSelected: selectedBloodGroup == group,
              baseTheme: baseTheme,
              onTap: () => onBloodGroupSelected(group),
            ),
          )
          .toList(),
    );
  }
}

class _BloodGroupChip extends StatelessWidget {
  final String bloodGroup;
  final bool isSelected;
  final BaseTheme baseTheme;
  final VoidCallback onTap;

  const _BloodGroupChip({
    required this.bloodGroup,
    required this.isSelected,
    required this.baseTheme,
    required this.onTap,
  });

  static const _kRadius = 50.0;
  static const _kDuration = Duration(milliseconds: 220);

  @override
  Widget build(BuildContext context) {
    final primary = baseTheme.primary;

    return AnimatedContainer(
      duration: _kDuration,
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isSelected ? primary : primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(_kRadius),
        border: Border.all(
          color: isSelected ? primary : primary.withOpacity(0.18),
          width: 1.5,
        ),
      ),
      
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_kRadius),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: isSelected
                ? Colors.white.withOpacity(0.18)
                : primary.withOpacity(0.12),
            highlightColor: isSelected
                ? Colors.white.withOpacity(0.08)
                : primary.withOpacity(0.06),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    transitionBuilder: (child, animation) => ScaleTransition(
                      scale: animation,
                      child: child,
                    ),
                    child: Icon(
                      Icons.water_drop_rounded,
                      key: ValueKey(isSelected),
                      size: 14,
                      color: isSelected
                          ? Colors.white
                          : primary.withOpacity(0.65),
                    ),
                  ),

                  const SizedBox(width: 6),

                  AnimatedDefaultTextStyle(
                    duration: _kDuration,
                    curve: Curves.easeInOut,
                    style: TextStyle(
                      fontFamily: AppConstants.fontFamilyLato,
                      fontSize: AppConstants.font14Px,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : primary.withOpacity(0.75),
                      letterSpacing: 0.3,
                    ),
                    child: Text(bloodGroup),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
