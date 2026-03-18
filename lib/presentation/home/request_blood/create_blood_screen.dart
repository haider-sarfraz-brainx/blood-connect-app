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
import '../../../injection_container.dart';
import '../../../mixin/validation_mixin.dart';
import '../../../widgets/chip_selection/blood_group_chip_selection.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/loading_overlay.dart';

class CreateBloodScreen extends StatefulWidget {
  const CreateBloodScreen({super.key});

  @override
  State<CreateBloodScreen> createState() => _CreateBloodScreenState();
}

class _CreateBloodScreenState extends State<CreateBloodScreen> with ValidationMixin {
  final _formKey = GlobalKey<FormState>();
  final _patientNameController = TextEditingController();
  final _unitsRequiredController = TextEditingController();
  final _hospitalNameController = TextEditingController();
  final _hospitalAddressController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedBloodGroup;
  
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

  bool _validateForm() {
    final patientName = _patientNameController.text.trim();
    if (patientName.isEmpty || patientName.length < 2) {
      return false;
    }

    if (_selectedBloodGroup == null || _selectedBloodGroup!.isEmpty) {
      return false;
    }

    final unitsRequired = _unitsRequiredController.text.trim();
    if (unitsRequired.isEmpty) {
      return false;
    }
    final units = int.tryParse(unitsRequired);
    if (units == null || units <= 0) {
      return false;
    }

    final hospitalName = _hospitalNameController.text.trim();
    if (hospitalName.isEmpty) {
      return false;
    }

    final contactNumber = _contactNumberController.text.trim();
    if (contactNumber.isEmpty || contactNumber.length < 10) {
      return false;
    }

    return true;
  }

  void _onBloodGroupSelected(String bloodGroup) {
    setState(() {
      _selectedBloodGroup = bloodGroup;
    });
    _updateButtonState();
  }

  Future<void> _handleSubmitRequest() async {
    if (!_validateForm()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: CustomText(
            text: ViewConstants.pleaseFillAllRequiredFields,
            textColor: Colors.white,
          ),
          backgroundColor: Colors.red,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final baseTheme = themeBloc.state.baseTheme;

    return BlocListener<BloodRequestBloc, BloodRequestState>(
      bloc: bloodRequestBloc,
      listener: (context, state) {
        if (state is BloodRequestCreated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: CustomText(
                text: ViewConstants.requestSubmitted,
                textColor: Colors.white,
              ),
              backgroundColor: Colors.green,
            ),
          );
          // Navigate back with the created request
          AppRouter.pop(context, state.request);
        } else if (state is BloodRequestError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: CustomText(
                text: state.message,
                textColor: Colors.white,
                translate: false,
              ),
              backgroundColor: Colors.red,
            ),
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
              appBar: AppBar(
                title: CustomText(
                  text: ViewConstants.requestBlood,
                  size: AppConstants.font20Px,
                  weight: FontWeight.w600,
                ),
                backgroundColor: baseTheme.background,
                elevation: 0,
              ),
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(AppConstants.gap20Px),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: AppConstants.gap20Px,
                      children: [
                        Column(
                          spacing: AppConstants.gap8Px,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              text: ViewConstants.requestBlood,
                              weight: FontWeight.w800,
                              textColor: baseTheme.primary,
                              size: AppConstants.font28Px,
                            ),
                            CustomText(
                              text: 'Fill in the details to request blood',
                              weight: FontWeight.w400,
                              size: AppConstants.font14Px,
                              textColor: baseTheme.textColor.fixedOpacity(0.7),
                              translate: false,
                            ),
                          ],
                        ),
                        CustomTextField(
                          labelText: ViewConstants.patientName,
                          hintText: ViewConstants.patientNameHint,
                          controller: _patientNameController,
                          keyboardType: TextInputType.name,
                          prefixIcon: Icon(
                            Icons.person_outline,
                            color: baseTheme.primary,
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: AppConstants.gap8Px,
                          children: [
                            CustomText(
                              text: '${ViewConstants.bloodGroup} *',
                              size: AppConstants.font14Px,
                              weight: FontWeight.w600,
                              textColor: baseTheme.textColor,
                            ),
                            BloodGroupChipSelection(
                              selectedBloodGroup: _selectedBloodGroup,
                              onBloodGroupSelected: _onBloodGroupSelected,
                            ),
                          ],
                        ),
                        CustomTextField(
                          labelText: ViewConstants.unitsRequired,
                          hintText: ViewConstants.unitsRequiredHint,
                          controller: _unitsRequiredController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          prefixIcon: Icon(
                            Icons.bloodtype_outlined,
                            color: baseTheme.primary,
                          ),
                        ),
                        CustomTextField(
                          labelText: ViewConstants.hospitalName,
                          hintText: ViewConstants.hospitalNameHint,
                          controller: _hospitalNameController,
                          keyboardType: TextInputType.text,
                          prefixIcon: Icon(
                            Icons.local_hospital_outlined,
                            color: baseTheme.primary,
                          ),
                        ),
                        CustomTextField(
                          labelText: ViewConstants.hospitalAddress,
                          hintText: ViewConstants.hospitalAddressHint,
                          controller: _hospitalAddressController,
                          keyboardType: TextInputType.streetAddress,
                          maxLines: 2,
                          prefixIcon: Icon(
                            Icons.location_on_outlined,
                            color: baseTheme.primary,
                          ),
                        ),
                        CustomTextField(
                          labelText: ViewConstants.contactNumber,
                          hintText: ViewConstants.contactNumberHint,
                          controller: _contactNumberController,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          prefixIcon: Icon(
                            Icons.phone_outlined,
                            color: baseTheme.primary,
                          ),
                        ),
                        CustomTextField(
                          labelText: ViewConstants.notes,
                          hintText: ViewConstants.notesHint,
                          controller: _notesController,
                          keyboardType: TextInputType.multiline,
                          maxLines: 3,
                          prefixIcon: Icon(
                            Icons.note_outlined,
                            color: baseTheme.primary,
                          ),
                        ),
                        StatefulBuilder(
                          builder: (context, state) {
                            submitButtonStateSetter = state;
                            return CustomButton(
                              text: ViewConstants.submitRequest,
                              onPress: submitButtonDisable ? () {} : _handleSubmitRequest,
                              bgColor: submitButtonDisable
                                  ? baseTheme.disable
                                  : baseTheme.primary,
                              borderColor: submitButtonDisable
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
