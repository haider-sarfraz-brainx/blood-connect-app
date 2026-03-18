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
import '../../../widgets/custom_button.dart';
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

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await CupertinoDatePickerBottomSheet.show(
      context: context,
      initialDate: _selectedDateOfBirth ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
      minimumDate: DateTime(1900),
      maximumDate: DateTime.now(),
      title: ViewConstants.selectDateOfBirth,
      mode: CupertinoDatePickerMode.date,
    );
    if (picked != null) {
      setState(() {
        _selectedDateOfBirth = picked;
      });
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
      setState(() {
        _selectedLastDonationDate = picked;
      });
    }
  }

  void _onBloodGroupSelected(String bloodGroup) {
    setState(() {
      _selectedBloodGroup = bloodGroup;
    });
    _updateButtonState();
  }

  void _onGenderSelected(String gender) {
    setState(() {
      _selectedGender = gender;
    });
    _updateButtonState();
  }

  Future<void> _getCurrentLocation() async {
    if (_isGettingLocation) return;

    setState(() {
      _isGettingLocation = true;
    });

    try {
      final locationResult = await locationService.getCurrentLocation();

      setState(() {
        _latitude = locationResult.latitude;
        _longitude = locationResult.longitude;
        if (locationResult.address != null && locationResult.address!.isNotEmpty) {
          _addressController.text = locationResult.address!;
        }
        _isGettingLocation = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ViewConstants.locationRetrievedSuccessfully.tr()),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } on LocationException catch (e) {
      setState(() {
        _isGettingLocation = false;
      });

      if (mounted) {
        final errorMessage = getLocationErrorMessage(e);
        
        // Show dialog for permanently denied permission
        if (e.type == LocationErrorType.permissionPermanentlyDenied) {
          _showPermissionDialog(errorMessage);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
              action: e.type == LocationErrorType.locationDisabled
                  ? SnackBarAction(
                      label: ViewConstants.settings.tr(),
                      textColor: Colors.white,
                      onPressed: () async {
                        await locationService.openSettings();
                      },
                    )
                  : null,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isGettingLocation = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${ViewConstants.failedToGetLocation.tr()}: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showPermissionDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: themeBloc.state.baseTheme.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radius16Px),
          ),
          title: CustomText(
            text: ViewConstants.locationPermissionRequired,
            weight: FontWeight.w700,
            size: AppConstants.font20Px,
          ),
          content: CustomText(
            text: message,
            size: AppConstants.font16Px,
            translate: false,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: CustomText(
                text: ViewConstants.cancel,
                textColor: themeBloc.state.baseTheme.textColor,
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await locationService.openSettings();
              },
              child: CustomText(
                text: ViewConstants.openSettings,
                textColor: themeBloc.state.baseTheme.primary,
                weight: FontWeight.w700,
              ),
            ),
          ],
        );
      },
    );
  }

  bool _validateForm() {
    if (_selectedBloodGroup == null || _selectedBloodGroup!.isEmpty) {
      return false;
    }

    if (_selectedDateOfBirth == null) {
      return false;
    }

    if (_selectedGender == null || _selectedGender!.isEmpty) {
      return false;
    }
    return true;
  }

  Future<void> _handleCompleteOnboarding() async {
    if (!_validateForm()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ViewConstants.pleaseFillAllRequiredFields.tr()),
          backgroundColor: Colors.red,
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
        emergencyContactName: _emergencyContactNameController.text.trim().isNotEmpty
            ? _emergencyContactNameController.text.trim()
            : null,
        emergencyContactPhone: _emergencyContactPhoneController.text.trim().isNotEmpty
            ? _emergencyContactPhoneController.text.trim()
            : null,
        lastDonationDate: _selectedLastDonationDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = themeBloc.state.baseTheme;
    final settingsColors = baseTheme.settings;

    return BlocListener<AuthenticationBloc, AuthenticationState>(
      bloc: authenticationBloc,
      listener: (context, state) {
        if (state is AuthenticationAuthenticated) {
          AppRouter.pushNamedAndRemoveUntil(context, RouteNames.bottomNavbar);
        } else if (state is AuthenticationError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
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
              appBar: AppBar(
                title: CustomText(
                  text: ViewConstants.completeYourProfile,
                  size: AppConstants.font22Px,
                  weight: FontWeight.w700,
                ),
                backgroundColor: baseTheme.background,
                elevation: 0,
                centerTitle: false,
                toolbarHeight: 60,
              ),
              body: SafeArea(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(AppConstants.gap20Px),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: AppConstants.gap14Px,
                      children: [
                        // Header Section
                        Container(
                          padding: EdgeInsets.all(AppConstants.gap20Px),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                baseTheme.primary.fixedOpacity(0.08),
                                baseTheme.primary.fixedOpacity(0.03),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(AppConstants.radius16Px),
                            border: Border.all(
                              color: baseTheme.primary.fixedOpacity(0.15),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(AppConstants.gap12Px),
                                decoration: BoxDecoration(
                                  color: baseTheme.primary.fixedOpacity(0.1),
                                  borderRadius: BorderRadius.circular(AppConstants.radius12Px),
                                ),
                                child: Icon(
                                  Icons.info_outline,
                                  color: baseTheme.primary,
                                  size: 24,
                                ),
                              ),
                              SizedBox(width: AppConstants.gap16Px),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CustomText(
                                      text: ViewConstants.completeYourProfile,
                                      size: AppConstants.font16Px,
                                      weight: FontWeight.w700,
                                      textColor: baseTheme.textColor,
                                    ),
                                    SizedBox(height: AppConstants.gap4Px),
                                    CustomText(
                                      text: ViewConstants.onboardingSubtitle,
                                      size: AppConstants.font12Px,
                                      textColor: baseTheme.textColor.fixedOpacity(0.7),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Required Fields Section
                        CustomText(
                          text: ViewConstants.requiredInformation,
                          size: AppConstants.font18Px,
                          weight: FontWeight.w700,
                          textColor: baseTheme.textColor,
                        ),

                        // Blood Group (Required)
                        CustomText(
                          text: '${ViewConstants.bloodGroup} *',
                          size: AppConstants.font14Px,
                          weight: FontWeight.w600,
                        ),
                        BloodGroupChipSelection(
                          selectedBloodGroup: _selectedBloodGroup,
                          onBloodGroupSelected: _onBloodGroupSelected,
                        ),

                        // Date of Birth (Required)
                        CustomText(
                          text: '${ViewConstants.dateOfBirth} *',
                          size: AppConstants.font14Px,
                          weight: FontWeight.w600,
                        ),
                        GestureDetector(
                          onTap: _selectDateOfBirth,
                          child: CustomTextField(
                            labelText: null,
                            hintText: _selectedDateOfBirth != null
                                ? '${_selectedDateOfBirth!.day}/${_selectedDateOfBirth!.month}/${_selectedDateOfBirth!.year}'
                                : ViewConstants.selectDateOfBirth,
                            controller: TextEditingController(),
                            enabled: false,
                            prefixIcon: Icon(
                              Icons.calendar_today_outlined,
                              color: baseTheme.primary,
                            ),
                          ),
                        ),

                        // Gender (Required)
                        CustomText(
                          text: '${ViewConstants.gender} *',
                          size: AppConstants.font14Px,
                          weight: FontWeight.w600,
                        ),
                        GenderChipSelection(
                          selectedGender: _selectedGender,
                          onGenderSelected: _onGenderSelected,
                        ),

                        // Optional Fields Section
                        CustomText(
                          text: ViewConstants.optionalInformation,
                          size: AppConstants.font18Px,
                          weight: FontWeight.w700,
                          textColor: baseTheme.textColor,
                        ),
                        // Address
                        CustomTextField(
                          labelText: ViewConstants.address,
                          hintText: ViewConstants.addressHint,
                          controller: _addressController,
                          keyboardType: TextInputType.streetAddress,
                          prefixIcon: Icon(
                            Icons.location_on_outlined,
                            color: baseTheme.primary,
                          ),
                          suffixIcon: _isGettingLocation
                              ? Padding(
                                  padding: EdgeInsets.all(AppConstants.gap12Px),
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        baseTheme.primary,
                                      ),
                                    ),
                                  ),
                                )
                              : IconButton(
                                  icon: Icon(
                                    Icons.my_location,
                                    color: baseTheme.primary,
                                  ),
                                  onPressed: _getCurrentLocation,
                                  tooltip: ViewConstants.getCurrentLocation,
                                ),
                        ),

                        // Emergency Contact Name (Optional)
                        CustomTextField(
                          labelText: ViewConstants.emergencyContactName,
                          hintText: ViewConstants.emergencyContactNameHint,
                          controller: _emergencyContactNameController,
                          keyboardType: TextInputType.name,
                          prefixIcon: Icon(
                            Icons.contact_emergency_outlined,
                            color: baseTheme.primary,
                          ),
                        ),

                        // Emergency Contact Phone (Optional)
                        CustomTextField(
                          labelText: ViewConstants.emergencyContactPhone,
                          hintText: ViewConstants.emergencyContactPhoneHint,
                          controller: _emergencyContactPhoneController,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          prefixIcon: Icon(
                            Icons.phone_outlined,
                            color: baseTheme.primary,
                          ),
                        ),

                        // Last Donation Date (Optional)
                        CustomText(
                          text: ViewConstants.lastDonationDate,
                          size: AppConstants.font14Px,
                          weight: FontWeight.w600,
                        ),
                        GestureDetector(
                          onTap: _selectLastDonationDate,
                          child: CustomTextField(
                            labelText: null,
                            hintText: _selectedLastDonationDate != null
                                ? '${_selectedLastDonationDate!.day}/${_selectedLastDonationDate!.month}/${_selectedLastDonationDate!.year}'
                                : ViewConstants.selectLastDonationDate,
                            controller: TextEditingController(),
                            enabled: false,
                            prefixIcon: Icon(
                              Icons.event_outlined,
                              color: baseTheme.primary,
                            ),
                          ),
                        ),


                        // Complete Profile Button
                        StatefulBuilder(
                          builder: (context, state) {
                            completeProfileButtonStateSetter = state;
                            return CustomButton(
                              text: ViewConstants.completeProfile,
                              onPress: completeProfileButtonDisable
                                  ? () {}
                                  : _handleCompleteOnboarding,
                              bgColor: completeProfileButtonDisable
                                  ? baseTheme.disable
                                  : baseTheme.primary,
                              borderColor: completeProfileButtonDisable
                                  ? baseTheme.disable
                                  : baseTheme.primary,
                            );
                          },
                        ),
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
