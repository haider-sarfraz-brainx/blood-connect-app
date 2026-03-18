import 'package:flutter/material.dart';

class AppRouter {

  static Future<T?> pushNamed<T extends Object?>(
      BuildContext context, String name, {dynamic argument}) async {
    return await Navigator.pushNamed(context, name, arguments: argument);
  }

  static Future<void> pushReplacementNamed(BuildContext context, String name, {dynamic argument}) {
    return Navigator.pushReplacementNamed(context, name,arguments: argument);
  }

  static Future<void> pushNamedAndRemoveUntil(BuildContext context,  String name,{ dynamic argument}) {
    return Navigator.pushNamedAndRemoveUntil(context,
       name, arguments: argument, (route) => false);
  }

  static Future<void> pushReplacement(BuildContext context, Widget widget) {
    return Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => widget),
    );
  }

  static Future<T?> push<T extends Object?>(
      BuildContext context, Widget widget) async {
    return await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => widget),
    );
  }

  static Future<void> pushAndRemoveUntil(BuildContext context, Widget widget) {
    return Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (context) => widget), (route) => false);
  }

  static void pop<T extends Object?>(BuildContext context, [T? result]) {
    Navigator.pop(context, result);
  }

  static bool canPop(BuildContext context) {
    return Navigator.canPop(context);
  }
}
