import 'package:flutter/material.dart';

extension SafeContext on State {
  void safeNavigate(VoidCallback navigation) {
    if (!mounted) return;
    navigation();
  }

  Future<T?>? safePushReplacementNamed<T>(
    String routeName, {
    Object? arguments,
  }) {
    if (!mounted) return null;
    return Navigator.pushReplacementNamed<T, Object?>(
      context,
      routeName,
      arguments: arguments,
    );
  }

  Future<T?>? safePushNamed<T>(String routeName, {Object? arguments}) {
    if (!mounted) return null;
    return Navigator.pushNamed<T>(context, routeName, arguments: arguments);
  }

  void safePop<T>([T? result]) {
    if (!mounted) return;
    Navigator.pop(context, result);
  }

  void safeShowSnackBar(String message, {Duration? duration}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration ?? const Duration(seconds: 3),
      ),
    );
  }

  Future<T?>? safeShowDialog<T>(Widget dialog) {
    if (!mounted) return null;
    return showDialog<T>(context: context, builder: (context) => dialog);
  }
}
