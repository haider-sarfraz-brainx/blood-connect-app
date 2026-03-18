import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/authentication_bloc/authentication_bloc.dart';
import '../../../bloc/authentication_bloc/authentication_events.dart';
import '../../../bloc/authentication_bloc/authentication_states.dart';
import '../../../bloc/theme_bloc/theme_bloc.dart';
import '../../../config/app_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/view_constants.dart';
import '../../../core/extensions/color.dart';
import '../../../core/services/location_service.dart';
import '../../../core/utils/location_error_handler.dart';
import '../../../data/managers/local/session_manager.dart';
import '../../../injection_container.dart';
import '../../../widgets/chip_selection/blood_group_chip_selection.dart';
import '../../../widgets/chip_selection/gender_chip_selection.dart';
import '../../../widgets/date_picker/cupertino_date_picker_bottom_sheet.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/loading_overlay.dart';

class EditOnboardingScreen extends StatefulWidget {
  const EditOnboardingScreen({super.key});

  @override
  State<EditOnboardingScreen> createState() => _EditOnboardingScreenState();
}

class _EditOnboardingScreenState extends State<EditOnboardingScreen> {
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
  late SessionManager sessionManager;
  bool _isGettingLocation = false;

  bool updateButtonDisable = true;
  late StateSetter updateButtonStateSetter;

  @override
  void initState() {
    super.initState();
    themeBloc = sl<ThemeBloc>();
    authenticationBloc = sl<AuthenticationBloc>();
    locationService = sl<LocationService>();
    sessionManager = sl<SessionManager>();
    _loadUserData();
    _addTextControllersListeners();
  }

  void _loadUserData() {
    final user = sessionManager.getUser();
    if (user != null) {
      _selectedBloodGroup = user.bloodGroup;
      _selectedDateOfBirth = user.dateOfBirth;
      _selectedGender = user.gender;
      _addressController.text = user.address ?? '';
      _emergencyContactNameController.text = user.emergencyContactName ?? '';
      _emergencyContactPhoneController.text = user.emergencyContactPhone ?? '';
      _selectedLastDonationDate = user.lastDonationDate;
      _latitude = user.latitude;
      _longitude = user.longitude;
    }
    _updateButtonState();
  }

  void _addTextControllersListeners() {
    _addressController.addListener(_updateButtonState);
    _emergencyContactNameController.addListener(_updateButtonState);
    _emergencyContactPhoneController.addListener(_updateButtonState);
  }

  void _updateButtonState() {
    final isValid = _validateForm();
    if (updateButtonDisable != !isValid) {
      updateButtonDisable = !isValid;
      updateButtonStateSetter(() {});
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
      _updateButtonState();
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
            content: const Text('Location retrieved successfully'),
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
                      label: 'Settings',
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
            content: Text('Failed to get location: ${e.toString()}'),
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
            text: 'Location Permission Required',
            weight: FontWeight.w700,
            size: AppConstants.font20Px,
            translate: false,
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
                text: 'Open Settings',
                textColor: themeBloc.state.baseTheme.primary,
                weight: FontWeight.w700,
                translate: false,
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

    // Check if any changes were made
    final user = sessionManager.getUser();
    if (user != null) {
      if (_selectedBloodGroup == user.bloodGroup &&
          _selectedDateOfBirth == user.dateOfBirth &&
          _selectedGender == user.gender &&
          _addressController.text.trim() == (user.address ?? '') &&
          _emergencyContactNameController.text.trim() == (user.emergencyContactName ?? '') &&
          _emergencyContactPhoneController.text.trim() == (user.emergencyContactPhone ?? '') &&
          _selectedLastDonationDate == user.lastDonationDate) {
        return false; // No changes made
      }
    }

    return true;
  }

  Future<void> _handleUpdateOnboarding() async {
    if (!_validateForm()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill all required fields or make changes'),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Onboarding information updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          AppRouter.pop(context);
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
                  text: 'Edit Onboarding Information',
                  size: AppConstants.font22Px,
                  weight: FontWeight.w700,
                  translate: false,
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
                                  Icons.edit_outlined,
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
                                      text: 'Update Your Information',
                                      size: AppConstants.font16Px,
                                      weight: FontWeight.w700,
                                      textColor: baseTheme.textColor,
                                      translate: false,
                                    ),
                                    SizedBox(height: AppConstants.gap4Px),
                                    CustomText(
                                      text: 'Update your onboarding information to keep your profile up to date',
                                      size: AppConstants.font12Px,
                                      textColor: baseTheme.textColor.fixedOpacity(0.7),
                                      translate: false,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Required Fields Section
                        CustomText(
                          text: 'Required Information',
                          size: AppConstants.font18Px,
                          weight: FontWeight.w700,
                          textColor: baseTheme.textColor,
                          translate: false,
                        ),

                        // Blood Group (Required)
                        CustomText(
                          text: 'Blood Group *',
                          size: AppConstants.font14Px,
                          weight: FontWeight.w600,
                          translate: false,
                        ),
                        BloodGroupChipSelection(
                          selectedBloodGroup: _selectedBloodGroup,
                          onBloodGroupSelected: _onBloodGroupSelected,
                        ),

                        // Date of Birth (Required)
                        CustomText(
                          text: 'Date of Birth *',
                          size: AppConstants.font14Px,
                          weight: FontWeight.w600,
                          translate: false,
                        ),
                        GestureDetector(
                          onTap: _selectDateOfBirth,
                          child: CustomTextField(
                            labelText: null,
                            hintText: _selectedDateOfBirth != null
                                ? '${_selectedDateOfBirth!.day}/${_selectedDateOfBirth!.month}/${_selectedDateOfBirth!.year}'
                                : 'Select Date of Birth',
                            controller: TextEditingController(),
                            enabled: false,
                            prefixIcon: Icon(
                              Icons.calendar_today_outlined,
                              color: baseTheme.primary,
                            ),
                            translate: false,
                          ),
                        ),

                        // Gender (Required)
                        CustomText(
                          text: 'Gender *',
                          size: AppConstants.font14Px,
                          weight: FontWeight.w600,
                          translate: false,
                        ),
                        GenderChipSelection(
                          selectedGender: _selectedGender,
                          onGenderSelected: _onGenderSelected,
                        ),

                        // Optional Fields Section
                        CustomText(
                          text: 'Optional Information',
                          size: AppConstants.font18Px,
                          weight: FontWeight.w700,
                          textColor: baseTheme.textColor,
                          translate: false,
                        ),

                        // Address
                        CustomTextField(
                          labelText: 'Address',
                          hintText: 'Enter your address or tap location icon to get current location',
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
                                  tooltip: 'Get current location',
                                ),
                          translate: false,
                        ),

                        // Emergency Contact Name (Optional)
                        CustomTextField(
                          labelText: 'Emergency Contact Name',
                          hintText: 'Enter emergency contact name',
                          controller: _emergencyContactNameController,
                          keyboardType: TextInputType.name,
                          prefixIcon: Icon(
                            Icons.contact_emergency_outlined,
                            color: baseTheme.primary,
                          ),
                          translate: false,
                        ),

                        // Emergency Contact Phone (Optional)
                        CustomTextField(
                          labelText: 'Emergency Contact Phone',
                          hintText: 'Enter emergency contact phone',
                          controller: _emergencyContactPhoneController,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          prefixIcon: Icon(
                            Icons.phone_outlined,
                            color: baseTheme.primary,
                          ),
                          translate: false,
                        ),

                        // Last Donation Date (Optional)
                        CustomText(
                          text: 'Last Donation Date',
                          size: AppConstants.font14Px,
                          weight: FontWeight.w600,
                          translate: false,
                        ),
                        GestureDetector(
                          onTap: _selectLastDonationDate,
                          child: CustomTextField(
                            labelText: null,
                            hintText: _selectedLastDonationDate != null
                                ? '${_selectedLastDonationDate!.day}/${_selectedLastDonationDate!.month}/${_selectedLastDonationDate!.year}'
                                : 'Select Last Donation Date',
                            controller: TextEditingController(),
                            enabled: false,
                            prefixIcon: Icon(
                              Icons.event_outlined,
                              color: baseTheme.primary,
                            ),
                            translate: false,
                          ),
                        ),

                        // Update Button
                        StatefulBuilder(
                          builder: (context, state) {
                            updateButtonStateSetter = state;
                            return CustomButton(
                              text: 'Update Information',
                              onPress: updateButtonDisable
                                  ? () {}
                                  : _handleUpdateOnboarding,
                              bgColor: updateButtonDisable
                                  ? baseTheme.disable
                                  : baseTheme.primary,
                              borderColor: updateButtonDisable
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
