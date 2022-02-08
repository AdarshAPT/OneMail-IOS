import 'package:flutter/material.dart';

class NavigationService {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Future<dynamic> navigateTo(Widget route) {
    return navigatorKey.currentState!.push(
      MaterialPageRoute(
        builder: (context) {
          return route;
        },
      ),
    );
  }

  Future<dynamic> navigateToReplacement(Widget route) {
    return navigatorKey.currentState!.pushReplacement(
      MaterialPageRoute(
        builder: (context) {
          return route;
        },
      ),
    );
  }

  pop(Widget route) {
    navigatorKey.currentState!.pop();
  }
}
