import 'package:flutter/material.dart';

/// Centralized page transitions so navigation feels consistent across Thryfto.
class AppPageRoute {
  AppPageRoute._();

  static const Duration transitionDuration = Duration(milliseconds: 240);
  static const Duration reverseTransitionDuration = Duration(milliseconds: 200);

  static Route<T> fadeThrough<T>({
    required WidgetBuilder builder,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: transitionDuration,
      reverseTransitionDuration: reverseTransitionDuration,
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return FadeTransition(
          opacity: curvedAnimation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.985, end: 1).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );
  }
}
