import 'package:flutter/material.dart';

/// Enum untuk jenis transisi navigasi
enum TransitionType {
  fade,
  slide,
  scale,
  slideFromBottom,
}

/// Navigation helper untuk mengelola semua navigasi dalam aplikasi
/// dengan smooth transitions
class NavigationHelper {
  // Private constructor untuk singleton pattern
  NavigationHelper._();

  /// Durasi default untuk animasi transisi
  static const Duration _defaultDuration = Duration(milliseconds: 300);

  /// Navigate dengan custom page route transition
  static Future<T?> navigateTo<T>(
    BuildContext context,
    Widget page, {
    TransitionType transition = TransitionType.fade,
    Duration duration = _defaultDuration,
    bool replace = false,
  }) {
    final route = _createRoute<T>(page, transition, duration);

    if (replace) {
      return Navigator.pushReplacement<T, dynamic>(context, route);
    } else {
      return Navigator.push<T>(context, route);
    }
  }

  /// Navigate dengan named route dan custom transition
  static Future<T?> navigateToNamed<T>(
    BuildContext context,
    String routeName, {
    TransitionType transition = TransitionType.fade,
    Duration duration = _defaultDuration,
    bool replace = false,
    Object? arguments,
  }) {
    // Untuk named routes, kita akan menggunakan custom route builder
    // yang didefinisikan di main.dart
    if (replace) {
      return Navigator.pushReplacementNamed(
        context,
        routeName,
        arguments: arguments,
      );
    } else {
      return Navigator.pushNamed(
        context,
        routeName,
        arguments: arguments,
      );
    }
  }

  /// Navigate dan hapus semua route sebelumnya
  static Future<T?> navigateAndRemoveUntil<T>(
    BuildContext context,
    Widget page, {
    TransitionType transition = TransitionType.fade,
    Duration duration = _defaultDuration,
  }) {
    final route = _createRoute<T>(page, transition, duration);
    return Navigator.pushAndRemoveUntil<T>(context, route, (route) => false);
  }

  /// Navigate dan hapus semua route sebelumnya menggunakan named route
  static Future<T?> navigateAndRemoveUntilNamed<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushNamedAndRemoveUntil(
      context,
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  /// Pop current route
  static void pop<T>(BuildContext context, [T? result]) {
    Navigator.pop(context, result);
  }

  /// Pop sampai route tertentu
  static void popUntil(BuildContext context, String routeName) {
    Navigator.popUntil(context, ModalRoute.withName(routeName));
  }

  /// Cek apakah bisa pop
  static bool canPop(BuildContext context) {
    return Navigator.canPop(context);
  }

  /// Create custom page route berdasarkan transition type
  static PageRoute<T> _createRoute<T>(
    Widget page,
    TransitionType transition,
    Duration duration,
  ) {
    switch (transition) {
      case TransitionType.fade:
        return _fadeTransition(page, duration);
      case TransitionType.slide:
        return _slideTransition(page, duration);
      case TransitionType.scale:
        return _scaleTransition(page, duration);
      case TransitionType.slideFromBottom:
        return _slideFromBottomTransition(page, duration);
    }
  }

  /// Fade transition
  static PageRoute<T> _fadeTransition<T>(Widget page, Duration duration) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }

  /// Slide transition (dari kanan ke kiri)
  static PageRoute<T> _slideTransition<T>(Widget page, Duration duration) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  /// Scale transition
  static PageRoute<T> _scaleTransition<T>(Widget page, Duration duration) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeInOutCubic;

        var scaleTween = Tween(begin: 0.8, end: 1.0).chain(
          CurveTween(curve: curve),
        );

        var fadeTween = Tween(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: curve),
        );

        return ScaleTransition(
          scale: animation.drive(scaleTween),
          child: FadeTransition(
            opacity: animation.drive(fadeTween),
            child: child,
          ),
        );
      },
    );
  }

  /// Slide from bottom transition
  static PageRoute<T> _slideFromBottomTransition<T>(
    Widget page,
    Duration duration,
  ) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }
}

/// Extension untuk memudahkan navigasi dari BuildContext
extension NavigationExtension on BuildContext {
  /// Navigate dengan fade transition
  Future<T?> navigateTo<T>(Widget page) {
    return NavigationHelper.navigateTo(this, page);
  }

  /// Navigate dengan named route
  Future<T?> navigateToNamed<T>(String routeName, {Object? arguments}) {
    return NavigationHelper.navigateToNamed(
      this,
      routeName,
      arguments: arguments,
    );
  }

  /// Navigate dan replace
  Future<T?> navigateAndReplace<T>(Widget page) {
    return NavigationHelper.navigateTo(this, page, replace: true);
  }

  /// Navigate dan remove all
  Future<T?> navigateAndRemoveAll<T>(Widget page) {
    return NavigationHelper.navigateAndRemoveUntil(this, page);
  }

  /// Navigate dan remove all dengan named route
  Future<T?> navigateAndRemoveAllNamed<T>(String routeName) {
    return NavigationHelper.navigateAndRemoveUntilNamed(this, routeName);
  }

  /// Pop
  void pop<T>([T? result]) {
    NavigationHelper.pop(this, result);
  }

  /// Pop until
  void popUntil(String routeName) {
    NavigationHelper.popUntil(this, routeName);
  }

  /// Can pop
  bool get canPop {
    return NavigationHelper.canPop(this);
  }
}
