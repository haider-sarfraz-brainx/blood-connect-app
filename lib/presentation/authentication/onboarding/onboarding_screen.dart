import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/authentication_bloc/authentication_bloc.dart';
import '../../../bloc/authentication_bloc/authentication_events.dart';
import '../../../bloc/authentication_bloc/authentication_states.dart';
import '../../../bloc/theme_bloc/theme_bloc.dart';
import '../../../config/app_router.dart';
import '../../../config/named_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/view_constants.dart';
import '../../../core/extensions/color.dart';
import '../../../core/services/location_service.dart';
import '../../../core/utils/location_error_handler.dart';
import '../../../injection_container.dart';
import '../../../widgets/chip_selection/blood_group_chip_selection.dart';
import '../../../widgets/chip_selection/gender_chip_selection.dart';
import '../../../widgets/date_picker/cupertino_date_picker_bottom_sheet.dart';
import '../../../widgets/custom_text.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/loading_overlay.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _emergencyContactNameController = TextEditingController();
  final _emergencyContactPhoneController = TextEditingController();

  String? _selectedBloodGroup;
  DateTime? _selectedDateOfBirth;
  DateTime? _selectedLastDonationDate;
  String? _selectedGender;
  double? _latitude;
  double? _longitude;

  late ThemeBloc themeBloc;
  late AuthenticationBloc authenticationBloc;
  late LocationService locationService;
  bool _isGettingLocation = false;

  bool completeProfileButtonDisable = true;
  late StateSetter completeProfileButtonStateSetter;

  @override
  void initState() {
    super.initState();
    themeBloc = sl<ThemeBloc>();
    authenticationBloc = sl<AuthenticationBloc>();
    locationService = sl<LocationService>();
    _addTextControllersListeners();
  }

  @override
  void dispose() {
    _addressController.removeListener(_updateButtonState);
    _emergencyContactNameController.removeListener(_updateButtonState);
    _emergencyContactPhoneController.removeListener(_updateButtonState);
    _addressController.dispose();
    _emergencyContactNameController.dispose();
    _emergencyContactPhoneController.dispose();
    super.dispose();
  }

  void _addTextControllersListeners() {
    _addressController.addListener(_updateButtonState);
    _emergencyContactNameController.addListener(_updateButtonState);
    _emergencyContactPhoneController.addListener(_updateButtonState);
  }

  void _updateButtonState() {
    final isValid = _validateForm();
    if (completeProfileButtonDisable != !isValid) {
      completeProfileButtonDisable = !isValid;
      completeProfileButtonStateSetter(() {});
    }
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await CupertinoDatePickerBottomSheet.show(
      context: context,
      initialDate: _selectedDateOfBirth ??
          DateTime.now().subtract(const Duration(days: 365 * 18)),
      minimumDate: DateTime(1900),
      maximumDate: DateTime.now(),
      title: ViewConstants.selectDateOfBirth,
      mode: CupertinoDatePickerMode.date,
    );
    if (picked != null) {
      setState(() => _selectedDateOfBirth = picked);
      _updateButtonState();
    }
  }

  Future<void> _selectLastDonationDate() async {
    final DateTime? picked = await CupertinoDatePickerBottomSheet.show(
      context: context,
      initialDate: _selectedLastDonationDate ?? DateTime.now(),
      minimumDate: DateTime(2000),
      maximumDate: DateTime.now(),
      title: ViewConstants.selectLastDonationDate,
      mode: CupertinoDatePickerMode.date,
    );
    if (picked != null) {
      setState(() => _selectedLastDonationDate = picked);
    }
  }

  void _onBloodGroupSelected(String bloodGroup) {
    setState(() => _selectedBloodGroup = bloodGroup);
    _updateButtonState();
  }

  void _onGenderSelected(String gender) {
    setState(() => _selectedGender = gender);
    _updateButtonState();
  }

  Future<void> _getCurrentLocation() async {
    if (_isGettingLocation) return;
    setState(() => _isGettingLocation = true);

    try {
      final locationResult = await locationService.getCurrentLocation();
      setState(() {
        _latitude = locationResult.latitude;
        _longitude = locationResult.longitude;
        if (locationResult.address != null &&
            locationResult.address!.isNotEmpty) {
          _addressController.text = locationResult.address!;
        }
        _isGettingLocation = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          _snackBar(
            ViewConstants.locationRetrievedSuccessfully.tr(),
            Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } on LocationException catch (e) {
      setState(() => _isGettingLocation = false);
      if (mounted) {
        final errorMessage = getLocationErrorMessage(e);
        if (e.type == LocationErrorType.permissionPermanentlyDenied) {
          _showPermissionDialog(errorMessage);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            _snackBar(
              errorMessage,
              Colors.red,
              action: e.type == LocationErrorType.locationDisabled
                  ? SnackBarAction(
                      label: ViewConstants.settings.tr(),
                      textColor: Colors.white,
                      onPressed: () async =>
                          await locationService.openSettings(),
                    )
                  : null,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isGettingLocation = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          _snackBar(
            '${ViewConstants.failedToGetLocation.tr()}: ${e.toString()}',
            Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  bool _validateForm() {
    if (_selectedBloodGroup == null || _selectedBloodGroup!.isEmpty) {
      return false;
    }
    if (_selectedDateOfBirth == null) return false;
    if (_selectedGender == null || _selectedGender!.isEmpty) return false;
    return true;
  }

  Future<void> _handleCompleteOnboarding() async {
    if (!_validateForm()) {
      ScaffoldMessenger.of(context).showSnackBar(
        _snackBar(
          ViewConstants.pleaseFillAllRequiredFields.tr(),
          Colors.red,
        ),
      );
      return;
    }
    authenticationBloc.add(
      CompleteOnboardingEvent(
        bloodGroup: _selectedBloodGroup,
        latitude: _latitude,
        longitude: _longitude,
        address: _addressController.text.trim().isNotEmpty
            ? _addressController.text.trim()
            : null,
        dateOfBirth: _selectedDateOfBirth,
        gender: _selectedGender,
        emergencyContactName:
            _emergencyContactNameController.text.trim().isNotEmpty
                ? _emergencyContactNameController.text.trim()
                : null,
        emergencyContactPhone:
            _emergencyContactPhoneController.text.trim().isNotEmpty
                ? _emergencyContactPhoneController.text.trim()
                : null,
        lastDonationDate: _selectedLastDonationDate,
      ),
    );
  }

  void _showPermissionDialog(String message) {
    final baseTheme = themeBloc.state.baseTheme;
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            decoration: BoxDecoration(
              color: baseTheme.background,
              borderRadius: BorderRadius.circular(AppConstants.radius20Px),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 32,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.10),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.location_off_rounded,
                        color: Colors.orange.shade700,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        ViewConstants.locationPermissionRequired.tr(),
                        style: TextStyle(
                          fontFamily: AppConstants.fontFamilyLato,
                          fontSize: AppConstants.font16Px,
                          fontWeight: FontWeight.w700,
                          color: baseTheme.textColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: TextStyle(
                    fontFamily: AppConstants.fontFamilyLato,
                    fontSize: AppConstants.font14Px,
                    fontWeight: FontWeight.w400,
                    color: baseTheme.textColor.fixedOpacity(0.55),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppConstants.radius12Px,
                            ),
                          ),
                          side: BorderSide(
                            color: baseTheme.textColor.fixedOpacity(0.18),
                          ),
                        ),
                        child: Text(
                          ViewConstants.cancel.tr(),
                          style: TextStyle(
                            fontFamily: AppConstants.fontFamilyLato,
                            fontSize: AppConstants.font14Px,
                            fontWeight: FontWeight.w600,
                            color: baseTheme.textColor.fixedOpacity(0.7),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await locationService.openSettings();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: baseTheme.primary,
                          foregroundColor: baseTheme.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppConstants.radius12Px,
                            ),
                          ),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                        ),
                        child: Text(
                          ViewConstants.openSettings.tr(),
                          style: TextStyle(
                            fontFamily: AppConstants.fontFamilyLato,
                            fontSize: AppConstants.font14Px,
                            fontWeight: FontWeight.w700,
                            color: baseTheme.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  SnackBar _snackBar(
    String message,
    Color color, {
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 3),
  }) {
    return SnackBar(
      content: Text(
        message,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radius12Px),
      ),
      action: action,
      duration: duration,
    );
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = themeBloc.state.baseTheme;

    return BlocListener<AuthenticationBloc, AuthenticationState>(
      bloc: authenticationBloc,
      listener: (context, state) {
        if (state is AuthenticationAuthenticated) {
          AppRouter.pushNamedAndRemoveUntil(context, RouteNames.bottomNavbar);
        } else if (state is AuthenticationError) {
          ScaffoldMessenger.of(context).showSnackBar(
            _snackBar(state.message, Colors.red),
          );
        }
      },
      child: BlocBuilder<AuthenticationBloc, AuthenticationState>(
        bloc: authenticationBloc,
        builder: (context, state) {
          return LoadingOverlay(
            isLoading: state is AuthenticationLoading,
            overlayColor: baseTheme.background,
            opacity: AppConstants.opacity20Px,
            child: Scaffold(
              backgroundColor: baseTheme.background,
              body: SafeArea(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppConstants.gap20Px),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        
                        _HeroCard(baseTheme: baseTheme),

                        const SizedBox(height: AppConstants.gap30Px),

                        
                        
                        _SectionHeader(
                          label: ViewConstants.requiredInformation.tr(),
                          baseTheme: baseTheme,
                        ),

                        const SizedBox(height: AppConstants.gap12Px),

                        _FieldCard(
                          label: ViewConstants.bloodGroup.tr(),
                          isRequired: true,
                          baseTheme: baseTheme,
                          child: BloodGroupChipSelection(
                            selectedBloodGroup: _selectedBloodGroup,
                            onBloodGroupSelected: _onBloodGroupSelected,
                          ),
                        ),

                        const SizedBox(height: AppConstants.gap12Px),

                        _DatePickerCard(
                          label: ViewConstants.dateOfBirth.tr(),
                          isRequired: true,
                          selectedDate: _selectedDateOfBirth,
                          icon: Icons.cake_rounded,
                          hint: ViewConstants.selectDateOfBirth.tr(),
                          onTap: _selectDateOfBirth,
                          baseTheme: baseTheme,
                        ),

                        const SizedBox(height: AppConstants.gap12Px),

                        _FieldCard(
                          label: ViewConstants.gender.tr(),
                          isRequired: true,
                          baseTheme: baseTheme,
                          child: GenderChipSelection(
                            selectedGender: _selectedGender,
                            onGenderSelected: _onGenderSelected,
                          ),
                        ),

                        const SizedBox(height: AppConstants.gap30Px),

                        
                        
                        _SectionHeader(
                          label: ViewConstants.optionalInformation.tr(),
                          baseTheme: baseTheme,
                        ),

                        const SizedBox(height: AppConstants.gap12Px),

                        CustomTextField(
                          labelText: ViewConstants.address,
                          hintText: ViewConstants.addressHint,
                          controller: _addressController,
                          keyboardType: TextInputType.streetAddress,
                          prefixIcon: Icon(
                            Icons.location_on_rounded,
                            color: baseTheme.primary,
                          ),
                          suffixIcon: _isGettingLocation
                              ? Padding(
                                  padding: const EdgeInsets.all(
                                    AppConstants.gap12Px,
                                  ),
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                        baseTheme.primary,
                                      ),
                                    ),
                                  ),
                                )
                              : IconButton(
                                  icon: Icon(
                                    Icons.my_location_rounded,
                                    color: baseTheme.primary,
                                  ),
                                  onPressed: _getCurrentLocation,
                                  tooltip: ViewConstants.getCurrentLocation,
                                ),
                        ),

                        const SizedBox(height: AppConstants.gap12Px),

                        CustomTextField(
                          labelText: ViewConstants.emergencyContactName,
                          hintText: ViewConstants.emergencyContactNameHint,
                          controller: _emergencyContactNameController,
                          keyboardType: TextInputType.name,
                          prefixIcon: Icon(
                            Icons.contact_emergency_rounded,
                            color: baseTheme.primary,
                          ),
                        ),

                        const SizedBox(height: AppConstants.gap12Px),

                        CustomTextField(
                          labelText: ViewConstants.emergencyContactPhone,
                          hintText: ViewConstants.emergencyContactPhoneHint,
                          controller: _emergencyContactPhoneController,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          prefixIcon: Icon(
                            Icons.phone_rounded,
                            color: baseTheme.primary,
                          ),
                        ),

                        const SizedBox(height: AppConstants.gap12Px),

                        _DatePickerCard(
                          label: ViewConstants.lastDonationDate.tr(),
                          isRequired: false,
                          selectedDate: _selectedLastDonationDate,
                          icon: Icons.volunteer_activism_rounded,
                          hint: ViewConstants.selectLastDonationDate.tr(),
                          onTap: _selectLastDonationDate,
                          baseTheme: baseTheme,
                        ),

                        const SizedBox(height: AppConstants.gap30Px),

                        StatefulBuilder(
                          builder: (context, setState) {
                            completeProfileButtonStateSetter = setState;
                            return _ActionButton(
                              label: ViewConstants.completeProfile.tr(),
                              icon: Icons.check_circle_rounded,
                              isDisabled: completeProfileButtonDisable,
                              baseTheme: baseTheme,
                              onPressed: completeProfileButtonDisable
                                  ? null
                                  : _handleCompleteOnboarding,
                            );
                          },
                        ),

                        const SizedBox(height: AppConstants.gap20Px),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final dynamic baseTheme;

  const _HeroCard({required this.baseTheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.gap20Px),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            baseTheme.primary.withOpacity(0.10),
            baseTheme.primary.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(AppConstants.radius20Px),
        border: Border.all(
          color: baseTheme.primary.withOpacity(0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  baseTheme.primary,
                  baseTheme.primary.withOpacity(0.72),
                ],
              ),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.volunteer_activism_rounded,
              color: baseTheme.white,
              size: 26,
            ),
          ),

          const SizedBox(height: AppConstants.gap16Px),

          Text(
            ViewConstants.completeYourProfile.tr(),
            style: TextStyle(
              fontFamily: AppConstants.fontFamilyLato,
              fontSize: AppConstants.font28Px,
              fontWeight: FontWeight.w800,
              color: baseTheme.primary,
            ),
          ),

          const SizedBox(height: AppConstants.gap8Px),

          Text(
            ViewConstants.onboardingSubtitle.tr(),
            style: TextStyle(
              fontFamily: AppConstants.fontFamilyLato,
              fontSize: AppConstants.font14Px,
              fontWeight: FontWeight.w400,
              color: baseTheme.textColor.withOpacity(0.65),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final dynamic baseTheme;

  const _SectionHeader({required this.label, required this.baseTheme});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontFamily: AppConstants.fontFamilyLato,
        fontSize: AppConstants.font12Px,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
        color: baseTheme.textColor.withOpacity(0.38),
      ),
    );
  }
}

class _FieldCard extends StatelessWidget {
  final String label;
  final bool isRequired;
  final dynamic baseTheme;
  final Widget child;

  const _FieldCard({
    required this.label,
    required this.isRequired,
    required this.baseTheme,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
      padding: const EdgeInsets.all(AppConstants.gap16Px),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppConstants.fontFamilyLato,
                  fontSize: AppConstants.font13Px,
                  fontWeight: FontWeight.w600,
                  color: baseTheme.textColor.withOpacity(0.5),
                ),
              ),
              if (isRequired)
                Text(
                  ' *',
                  style: TextStyle(
                    fontFamily: AppConstants.fontFamilyLato,
                    fontSize: AppConstants.font13Px,
                    fontWeight: FontWeight.w700,
                    color: baseTheme.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppConstants.gap12Px),
          child,
        ],
      ),
    );
  }
}

class _DatePickerCard extends StatelessWidget {
  final String label;
  final bool isRequired;
  final DateTime? selectedDate;
  final IconData icon;
  final String hint;
  final VoidCallback onTap;
  final dynamic baseTheme;

  const _DatePickerCard({
    required this.label,
    required this.isRequired,
    required this.selectedDate,
    required this.icon,
    required this.hint,
    required this.onTap,
    required this.baseTheme,
  });

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d / $m / ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final hasDate = selectedDate != null;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppConstants.radius16Px),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radius16Px),
        splashColor: baseTheme.primary.withOpacity(0.06),
        highlightColor: baseTheme.primary.withOpacity(0.03),
        child: Container(
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
          padding: const EdgeInsets.all(AppConstants.gap16Px),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: AppConstants.fontFamilyLato,
                      fontSize: AppConstants.font13Px,
                      fontWeight: FontWeight.w600,
                      color: baseTheme.textColor.withOpacity(0.5),
                    ),
                  ),
                  if (isRequired)
                    Text(
                      ' *',
                      style: TextStyle(
                        fontFamily: AppConstants.fontFamilyLato,
                        fontSize: AppConstants.font13Px,
                        fontWeight: FontWeight.w700,
                        color: baseTheme.primary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppConstants.gap12Px),
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: hasDate
                          ? baseTheme.primary.withOpacity(0.10)
                          : baseTheme.textColor.withOpacity(0.06),
                      borderRadius:
                          BorderRadius.circular(AppConstants.radius10Px),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      icon,
                      size: 18,
                      color: hasDate
                          ? baseTheme.primary
                          : baseTheme.textColor.withOpacity(0.35),
                    ),
                  ),
                  const SizedBox(width: AppConstants.gap12Px),
                  Expanded(
                    child: Text(
                      hasDate ? _formatDate(selectedDate!) : hint,
                      style: TextStyle(
                        fontFamily: AppConstants.fontFamilyLato,
                        fontSize: AppConstants.font16Px,
                        fontWeight:
                            hasDate ? FontWeight.w500 : FontWeight.w400,
                        color: hasDate
                            ? baseTheme.textColor
                            : baseTheme.textColor.withOpacity(0.35),
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: baseTheme.textColor.withOpacity(0.25),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isDisabled;
  final dynamic baseTheme;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.isDisabled,
    required this.baseTheme,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: isDisabled ? 0.5 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(
            icon,
            size: 18,
            color: isDisabled
                ? baseTheme.textColor.withOpacity(0.5)
                : baseTheme.white,
          ),
          label: Text(
            label,
            style: TextStyle(
              fontFamily: AppConstants.fontFamilyLato,
              fontSize: AppConstants.font16Px,
              fontWeight: FontWeight.w700,
              color: isDisabled
                  ? baseTheme.textColor.withOpacity(0.5)
                  : baseTheme.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isDisabled ? baseTheme.disable : baseTheme.primary,
            foregroundColor:
                isDisabled ? baseTheme.textColor : baseTheme.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(AppConstants.radius16Px),
            ),
            elevation: 0,
            shadowColor: Colors.transparent,
          ),
        ),
      ),
    );
  }
}
