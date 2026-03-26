import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/blood_request_bloc/blood_request_bloc.dart';
import '../../../bloc/blood_request_bloc/blood_request_events.dart';
import '../../../bloc/blood_request_bloc/blood_request_states.dart';
import '../../../bloc/theme_bloc/theme_bloc.dart';
import '../../../config/app_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/view_constants.dart';
import '../../../core/extensions/color.dart';
import '../../../config/theme/base.dart';
import '../../../injection_container.dart';
import '../../../mixin/validation_mixin.dart';
import '../../../widgets/chip_selection/blood_group_chip_selection.dart';
import '../../../widgets/custom_text.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/loading_overlay.dart';

class CreateBloodScreen extends StatefulWidget {
  const CreateBloodScreen({super.key});

  @override
  State<CreateBloodScreen> createState() => _CreateBloodScreenState();
}

class _CreateBloodScreenState extends State<CreateBloodScreen>
    with ValidationMixin {
  
  final _formKey = GlobalKey<FormState>();
  final _patientNameController = TextEditingController();
  final _unitsRequiredController = TextEditingController();
  final _hospitalNameController = TextEditingController();
  final _hospitalAddressController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _notesController = TextEditingController();

    String? _selectedBloodGroup;
    bool _isEmergency = false;

  late ThemeBloc themeBloc;
  late BloodRequestBloc bloodRequestBloc;

  bool submitButtonDisable = true;
  late StateSetter submitButtonStateSetter;

  @override
  void initState() {
    super.initState();
    themeBloc = sl<ThemeBloc>();
    bloodRequestBloc = sl<BloodRequestBloc>();
    _addTextControllersListeners();
  }

  @override
  void dispose() {
    _patientNameController.removeListener(_updateButtonState);
    _unitsRequiredController.removeListener(_updateButtonState);
    _hospitalNameController.removeListener(_updateButtonState);
    _contactNumberController.removeListener(_updateButtonState);
    _patientNameController.dispose();
    _unitsRequiredController.dispose();
    _hospitalNameController.dispose();
    _hospitalAddressController.dispose();
    _contactNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addTextControllersListeners() {
    _patientNameController.addListener(_updateButtonState);
    _unitsRequiredController.addListener(_updateButtonState);
    _hospitalNameController.addListener(_updateButtonState);
    _contactNumberController.addListener(_updateButtonState);
  }

  void _updateButtonState() {
    final isValid = _validateForm();
    if (submitButtonDisable != !isValid) {
      submitButtonDisable = !isValid;
      submitButtonStateSetter(() {});
    }
  }

  bool _validateForm() {
    final patientName = _patientNameController.text.trim();
    if (patientName.isEmpty || patientName.length < 2) return false;
    if (_selectedBloodGroup == null || _selectedBloodGroup!.isEmpty) {
      return false;
    }
    final unitsRequired = _unitsRequiredController.text.trim();
    if (unitsRequired.isEmpty) return false;
    final units = int.tryParse(unitsRequired);
    if (units == null || units <= 0) return false;
    final hospitalName = _hospitalNameController.text.trim();
    if (hospitalName.isEmpty) return false;
    final contactNumber = _contactNumberController.text.trim();
    if (contactNumber.isEmpty || contactNumber.length < 10) return false;
    return true;
  }

  void _onBloodGroupSelected(String bloodGroup) {
    setState(() => _selectedBloodGroup = bloodGroup);
    _updateButtonState();
  }

  Future<void> _handleSubmitRequest() async {
    if (!_validateForm()) {
      ScaffoldMessenger.of(context).showSnackBar(
        _snackBar(
          ViewConstants.pleaseFillAllRequiredFields.tr(),
          Colors.red,
        ),
      );
      return;
    }
    bloodRequestBloc.add(
      CreateBloodRequestEvent(
        patientName: _patientNameController.text.trim(),
        bloodGroup: _selectedBloodGroup!,
        unitsRequired: int.parse(_unitsRequiredController.text.trim()),
        hospitalName: _hospitalNameController.text.trim(),
        hospitalAddress: _hospitalAddressController.text.trim().isEmpty
            ? null
            : _hospitalAddressController.text.trim(),
        contactNumber: _contactNumberController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        isEmergency: _isEmergency,
      ),
    );
  }

  SnackBar _snackBar(String message, Color color) {
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = themeBloc.state.baseTheme;

    return BlocListener<BloodRequestBloc, BloodRequestState>(
      bloc: bloodRequestBloc,
      listener: (context, state) {
        if (state is BloodRequestCreated) {
          ScaffoldMessenger.of(context).showSnackBar(
            _snackBar(ViewConstants.requestSubmitted.tr(), Colors.green),
          );
          AppRouter.pop(context, state.request);
        } else if (state is BloodRequestError) {
          ScaffoldMessenger.of(context).showSnackBar(
            _snackBar(state.message, Colors.red),
          );
        }
      },
      child: BlocBuilder<BloodRequestBloc, BloodRequestState>(
        bloc: bloodRequestBloc,
        builder: (context, state) {
          return LoadingOverlay(
            isLoading: state is BloodRequestLoading,
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
                            AppConstants.radius8Px,
                          ),
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
                          text: ViewConstants.requestBlood,
                          weight: FontWeight.w800,
                          textColor: baseTheme.primary,
                          size: AppConstants.font28Px,
                        ),
                        const SizedBox(height: AppConstants.gap8Px),
                        CustomText(
                          text: 'Fill in the details below to submit a blood request',
                          weight: FontWeight.w400,
                          size: AppConstants.font14Px,
                          textColor: baseTheme.textColor.fixedOpacity(0.7),
                          translate: false,
                        ),

                        const SizedBox(height: AppConstants.gap30Px),

                        
                        
                        _SectionHeader(
                          label: 'Required Information',
                          baseTheme: baseTheme,
                        ),

                        const SizedBox(height: AppConstants.gap12Px),

                        CustomTextField(
                          labelText: ViewConstants.patientName,
                          hintText: ViewConstants.patientNameHint,
                          controller: _patientNameController,
                          keyboardType: TextInputType.name,
                          prefixIcon: Icon(
                            Icons.person_rounded,
                            color: baseTheme.primary,
                          ),
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

                        CustomTextField(
                          labelText: ViewConstants.unitsRequired,
                          hintText: ViewConstants.unitsRequiredHint,
                          controller: _unitsRequiredController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          prefixIcon: Icon(
                            Icons.water_drop_rounded,
                            color: baseTheme.primary,
                          ),
                        ),

                        const SizedBox(height: AppConstants.gap12Px),

                        CustomTextField(
                          labelText: ViewConstants.hospitalName,
                          hintText: ViewConstants.hospitalNameHint,
                          controller: _hospitalNameController,
                          keyboardType: TextInputType.text,
                          prefixIcon: Icon(
                            Icons.local_hospital_rounded,
                            color: baseTheme.primary,
                          ),
                        ),

                        const SizedBox(height: AppConstants.gap12Px),

                        CustomTextField(
                          labelText: ViewConstants.contactNumber,
                          hintText: ViewConstants.contactNumberHint,
                          controller: _contactNumberController,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          prefixIcon: Icon(
                            Icons.phone_rounded,
                            color: baseTheme.primary,
                          ),
                        ),

                        const SizedBox(height: AppConstants.gap30Px),

                        
                        
                        _SectionHeader(
                          label: 'Optional Information',
                          baseTheme: baseTheme,
                        ),

                        const SizedBox(height: AppConstants.gap12Px),

                        CustomTextField(
                          labelText: ViewConstants.hospitalAddress,
                          hintText: ViewConstants.hospitalAddressHint,
                          controller: _hospitalAddressController,
                          keyboardType: TextInputType.streetAddress,
                          maxLines: 2,
                          prefixIcon: Icon(
                            Icons.location_on_rounded,
                            color: baseTheme.primary,
                          ),
                        ),

                        const SizedBox(height: AppConstants.gap12Px),

                        CustomTextField(
                          labelText: ViewConstants.notes,
                          hintText: ViewConstants.notesHint,
                          controller: _notesController,
                          keyboardType: TextInputType.multiline,
                          maxLines: 3,
                          prefixIcon: Icon(
                            Icons.edit_note_rounded,
                            color: baseTheme.primary,
                          ),
                        ),

                        const SizedBox(height: AppConstants.gap12Px),

                        StatefulBuilder(
                          builder: (context, setCheckState) {
                            return CheckboxListTile(
                              value: _isEmergency,
                              onChanged: (value) {
                                setCheckState(() {
                                  _isEmergency = value ?? false;
                                });
                              },
                              title: CustomText(
                                text: 'Emergency Request',
                                weight: FontWeight.w600,
                                size: AppConstants.font14Px,
                                translate: false,
                              ),
                              subtitle: CustomText(
                                text: 'This will mark the request as urgent',
                                weight: FontWeight.w400,
                                size: AppConstants.font12Px,
                                textColor: baseTheme.textColor.fixedOpacity(0.5),
                                translate: false,
                              ),
                              activeColor: baseTheme.primary,
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                            );
                          },
                        ),

                        const SizedBox(height: AppConstants.gap30Px),

                        StatefulBuilder(
                          builder: (context, setState) {
                            submitButtonStateSetter = setState;
                            return _ActionButton(
                              label: ViewConstants.submitRequest.tr(),
                              icon: Icons.send_rounded,
                              isDisabled: submitButtonDisable,
                              baseTheme: baseTheme,
                              onPressed: submitButtonDisable
                                  ? null
                                  : _handleSubmitRequest,
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

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isDisabled;
  final BaseTheme baseTheme;
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
                ? baseTheme.textColor.fixedOpacity(0.5)
                : baseTheme.white,
          ),
          label: Text(
            label,
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
              borderRadius: BorderRadius.circular(AppConstants.radius16Px),
            ),
            elevation: 0,
            shadowColor: Colors.transparent,
          ),
        ),
      ),
    );
  }
}
