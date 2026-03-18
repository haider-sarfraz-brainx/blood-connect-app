import '../core/constants/view_constants.dart';

mixin ValidationMixin {

  bool validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return false;
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return false;
    }
    return true;
  }

}