import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Centralized page-route builders so every Navigator.push uses consistent
/// Material motion. Both respect the OS "reduce motion" setting (fall back to a
/// plain fade). Use [sharedAxisRoute] for forward navigation into a sibling
/// screen, [fadeThroughRoute] for swapping unrelated destinations.

bool _reduceMotion(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false;

Route<T> fadeThroughRoute<T>(WidgetBuilder builder, {RouteSettings? settings}) {
  return PageRouteBuilder<T>(
    settings: settings,
    transitionDuration: AppMotion.base,
    reverseTransitionDuration: AppMotion.base,
    pageBuilder: (context, animation, secondaryAnimation) => builder(context),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (_reduceMotion(context)) {
        return FadeTransition(opacity: animation, child: child);
      }
      return FadeThroughTransition(
        animation: animation,
        secondaryAnimation: secondaryAnimation,
        fillColor: Theme.of(context).scaffoldBackgroundColor,
        child: child,
      );
    },
  );
}

Route<T> sharedAxisRoute<T>(
  WidgetBuilder builder, {
  SharedAxisTransitionType type = SharedAxisTransitionType.horizontal,
  RouteSettings? settings,
}) {
  return PageRouteBuilder<T>(
    settings: settings,
    transitionDuration: AppMotion.base,
    reverseTransitionDuration: AppMotion.base,
    pageBuilder: (context, animation, secondaryAnimation) => builder(context),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (_reduceMotion(context)) {
        return FadeTransition(opacity: animation, child: child);
      }
      return SharedAxisTransition(
        animation: animation,
        secondaryAnimation: secondaryAnimation,
        transitionType: type,
        fillColor: Theme.of(context).scaffoldBackgroundColor,
        child: child,
      );
    },
  );
}
