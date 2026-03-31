import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/authentication_bloc/authentication_bloc.dart';
import '../../../bloc/authentication_bloc/authentication_events.dart';
import '../../../bloc/authentication_bloc/authentication_states.dart';
import '../../../bloc/theme_bloc/theme_bloc.dart';
import '../../../config/app_router.dart';
import '../../../config/theme/base.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/view_constants.dart';
import '../../../core/extensions/color.dart';
import '../../../data/managers/local/session_manager.dart';
import '../../../injection_container.dart';
import '../../../widgets/chip_selection/blood_group_chip_selection.dart';
import '../../../widgets/chip_selection/gender_chip_selection.dart';
import '../../../widgets/date_picker/cupertino_date_picker_bottom_sheet.dart';
import '../../../widgets/custom_text.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/loading_overlay.dart';
import '../../../widgets/bottom_sheets/location_selection_bottom_sheet.dart';

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
  String? _selectedCountry;
  String? _selectedCity;

  late ThemeBloc themeBloc;
  late AuthenticationBloc authenticationBloc;
  late SessionManager sessionManager;

  bool updateButtonDisable = true;
  late StateSetter updateButtonStateSetter;

  @override
  void initState() {
    super.initState();
    themeBloc = sl<ThemeBloc>();
    authenticationBloc = sl<AuthenticationBloc>();
    sessionManager = sl<SessionManager>();
    _loadUserData();
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
      _selectedCountry = user.country;
      _selectedCity = user.city;
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
      _updateButtonState();
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

  Future<void> _showLocationSelection() async {
    final result = await LocationSelectionBottomSheet.show(
      context: context,
      initialCountry: _selectedCountry,
      initialCity: _selectedCity,
    );

    if (result != null) {
      setState(() {
        _selectedCountry = result['country'];
        _selectedCity = result['city'];
        _addressController.text = '${_selectedCity ?? ""}${_selectedCity != null ? ", " : ""}${_selectedCountry ?? ""}';
      });
      _updateButtonState();
    }
  }

  bool _validateForm() {
    if (_selectedBloodGroup == null || _selectedBloodGroup!.isEmpty) {
      return false;
    }
    if (_selectedDateOfBirth == null) return false;
    if (_selectedGender == null || _selectedGender!.isEmpty) return false;

    final user = sessionManager.getUser();
    if (user != null) {
      if (_selectedBloodGroup == user.bloodGroup &&
          _selectedDateOfBirth == user.dateOfBirth &&
          _selectedGender == user.gender &&
          _addressController.text.trim() == (user.address ?? '') &&
          _emergencyContactPhoneController.text.trim() ==
              (user.emergencyContactPhone ?? '') &&
          _selectedLastDonationDate == user.lastDonationDate &&
          _selectedCountry == user.country &&
          _selectedCity == user.city) {
        return false;
      }
    }
    return true;
  }

  Future<void> _handleUpdateOnboarding() async {
    if (!_validateForm()) {
      ScaffoldMessenger.of(context).showSnackBar(
        _snackBar(
          'Please fill all required fields or make changes',
          Colors.red,
        ),
      );
      return;
    }
    authenticationBloc.add(
      CompleteOnboardingEvent(
        bloodGroup: _selectedBloodGroup,
        country: _selectedCountry,
        city: _selectedCity,
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
          ScaffoldMessenger.of(context).showSnackBar(
            _snackBar(
              'Onboarding information updated successfully',
              Colors.green,
            ),
          );
          AppRouter.pop(context);
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
                        
                        InkWell(
                          onTap: () => AppRouter.pop(context),
                          borderRadius: BorderRadius.circular(
                              AppConstants.radius8Px),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.arrow_back_ios,
                              size: 25,
                              color: baseTheme.textColor,
                            ),
                          ),
                        ),

                        const SizedBox(height: AppConstants.gap20Px),

                        CustomText(
                          text: ViewConstants.editOnboarding,
                          weight: FontWeight.w800,
                          textColor: baseTheme.primary,
                          size: AppConstants.font28Px,
                        ),
                        const SizedBox(height: AppConstants.gap8Px),
                        CustomText(
                          text:
                              'Update your blood and health information to keep your profile accurate',
                          weight: FontWeight.w400,
                          size: AppConstants.font14Px,
                          textColor:
                              baseTheme.textColor.fixedOpacity(0.7),
                          translate: false,
                        ),

                        const SizedBox(height: AppConstants.gap30Px),

                        
                        
                        _SectionHeader(
                          label: 'Required Information',
                          baseTheme: baseTheme,
                        ),

                        const SizedBox(height: AppConstants.gap12Px),

                        _FieldCard(
                          label: 'Blood Group',
                          isRequired: true,
                          baseTheme: baseTheme,
                          child: BloodGroupChipSelection(
                            selectedBloodGroup: _selectedBloodGroup,
                            onBloodGroupSelected: _onBloodGroupSelected,
                          ),
                        ),

                        const SizedBox(height: AppConstants.gap12Px),

                        _DatePickerCard(
                          label: 'Date of Birth',
                          isRequired: true,
                          selectedDate: _selectedDateOfBirth,
                          icon: Icons.cake_rounded,
                          hint: 'Tap to select your date of birth',
                          onTap: _selectDateOfBirth,
                          baseTheme: baseTheme,
                        ),

                        const SizedBox(height: AppConstants.gap12Px),

                        _FieldCard(
                          label: 'Gender',
                          isRequired: true,
                          baseTheme: baseTheme,
                          child: GenderChipSelection(
                            selectedGender: _selectedGender,
                            onGenderSelected: _onGenderSelected,
                          ),
                        ),

                        const SizedBox(height: AppConstants.gap30Px),

                        
                        
                        _SectionHeader(
                          label: 'Optional Information',
                          baseTheme: baseTheme,
                        ),

                        const SizedBox(height: AppConstants.gap12Px),

                        CustomTextField(
                          labelText: ViewConstants.location, 
                          hintText: 'Select your country and city',
                          controller: _addressController,
                          readOnly: true,
                          onTap: _showLocationSelection,
                          prefixIcon: Icon(
                            Icons.location_on_rounded,
                            color: baseTheme.primary,
                          ),
                          suffixIcon: (_selectedCountry != null || _selectedCity != null)
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    setState(() {
                                      _selectedCountry = null;
                                      _selectedCity = null;
                                      _addressController.clear();
                                    });
                                    _updateButtonState();
                                  },
                                )
                              : null,
                          translate: false,
                        ),

                        const SizedBox(height: AppConstants.gap12Px),

                        CustomTextField(
                          labelText: 'Emergency Contact Name',
                          hintText: 'Enter emergency contact name',
                          controller: _emergencyContactNameController,
                          keyboardType: TextInputType.name,
                          prefixIcon: Icon(
                            Icons.contact_emergency_rounded,
                            color: baseTheme.primary,
                          ),
                          translate: false,
                        ),

                        const SizedBox(height: AppConstants.gap12Px),

                        CustomTextField(
                          labelText: 'Emergency Contact Phone',
                          hintText: 'Enter emergency contact phone',
                          controller: _emergencyContactPhoneController,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          prefixIcon: Icon(
                            Icons.phone_rounded,
                            color: baseTheme.primary,
                          ),
                          translate: false,
                        ),

                        const SizedBox(height: AppConstants.gap12Px),

                        _DatePickerCard(
                          label: 'Last Donation Date',
                          isRequired: false,
                          selectedDate: _selectedLastDonationDate,
                          icon: Icons.volunteer_activism_rounded,
                          hint: 'Tap to select last donation date',
                          onTap: _selectLastDonationDate,
                          baseTheme: baseTheme,
                        ),

                        const SizedBox(height: AppConstants.gap30Px),

                        StatefulBuilder(
                          builder: (context, setState) {
                            updateButtonStateSetter = setState;
                            return _UpdateButton(
                              isDisabled: updateButtonDisable,
                              baseTheme: baseTheme,
                              onPressed: updateButtonDisable
                                  ? null
                                  : _handleUpdateOnboarding,
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

class _SectionHeader extends StatelessWidget {
  final String label;
  final BaseTheme baseTheme;

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
        color: baseTheme.textColor.fixedOpacity(0.38),
      ),
    );
  }
}

class _FieldCard extends StatelessWidget {
  final String label;
  final bool isRequired;
  final BaseTheme baseTheme;
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
                  color: baseTheme.textColor.fixedOpacity(0.5),
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
  final BaseTheme baseTheme;

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
            borderRadius:
                BorderRadius.circular(AppConstants.radius16Px),
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
                      color: baseTheme.textColor.fixedOpacity(0.5),
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
                      borderRadius: BorderRadius.circular(
                          AppConstants.radius10Px),
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
                            : baseTheme.textColor.fixedOpacity(0.35),
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: baseTheme.textColor.fixedOpacity(0.25),
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

class _UpdateButton extends StatelessWidget {
  final bool isDisabled;
  final BaseTheme baseTheme;
  final VoidCallback? onPressed;

  const _UpdateButton({
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
            Icons.check_circle_rounded,
            size: 18,
            color: isDisabled
                ? baseTheme.textColor.fixedOpacity(0.5)
                : baseTheme.white,
          ),
          label: Text(
            'Update Information',
            style: TextStyle(
              fontFamily: AppConstants.fontFamilyLato,
              fontSize: AppConstants.font16Px,
              fontWeight: FontWeight.w700,
              color: isDisabled
                  ? baseTheme.textColor.fixedOpacity(0.5)
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
