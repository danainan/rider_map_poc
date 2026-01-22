import 'package:flutter/material.dart';
import 'package:rider_map_poc/core/router/app_router.dart';
extension BuildContextX on BuildContext {
  /// Pop until specific route
  void popUntilPath(String routePath) {
    while (AppRouter.router.routerDelegate.currentConfiguration.matches.last
            .matchedLocation !=
        routePath) {
      if (!canPopRoute()) {
        return;
      }
      popRoute();
    }
  }
}
