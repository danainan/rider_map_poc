import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:rider_map_poc/core/router/routes.dart';
import 'package:rider_map_poc/modules/distance_matrix/pages/distance_matrix_screen.dart';
import 'package:rider_map_poc/modules/home/pages/home_page.dart';
import 'package:rider_map_poc/modules/longdo_map/pages/longdo_map.dart';
import 'package:rider_map_poc/modules/longdo_map_route/pages/longdo_map_route_page.dart';
import 'package:rider_map_poc/modules/longdo_map_ws/pages/longdo_map_ws_page.dart';
import 'package:rider_map_poc/modules/rider/pages/rider_screen.dart';
import 'package:rider_map_poc/modules/rider_map/pages/rider_map_page.dart';
import 'package:rider_map_poc/modules/route_navigation/pages/route_navigation_page.dart';
import 'package:rider_map_poc/modules/splash/pages/splash_page.dart';
import 'package:swipeable_page_route/swipeable_page_route.dart';

final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root_navigator');

final class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    debugLogDiagnostics: true,
    navigatorKey: rootNavigatorKey,
    initialLocation: Routes.splash,
    errorBuilder: (context, state) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (state.uri.toString() != Routes.home) {
          context.go(Routes.home);
        }
      });
      return const SizedBox();
    },
    routes: <RouteBase>[
      GoRoute(
        path: Routes.splash,
        pageBuilder: (context, state) => _fadeTransitionPage(
          context: context,
          state: state,
          child: const SplashPage(),
        ),
      ),
      GoRoute(
        path: Routes.home,
        pageBuilder: (context, state) => _fadeTransitionPage(
          context: context,
          state: state,
          child: const HomePage(),
        ),
      ),
      GoRoute(
        path: Routes.riderMap,
        pageBuilder: (context, state) => _slideTransitionPage(
          context: context,
          state: state,
          child: const RiderMapPage(),
        ),
      ),
      GoRoute(
        path: Routes.routeNavigation,
        pageBuilder: (context, state) => _slideTransitionPage(
          context: context,
          state: state,
          child: const RouteNavigationPage(),
        ),
      ),
      GoRoute(
        path: Routes.rider,
        pageBuilder: (context, state) => _slideTransitionPage(
          context: context,
          state: state,
          child: const RiderScreen(),
        ),
      ),
      GoRoute(
        path: Routes.distanceMatrix,
        pageBuilder: (context, state) => _slideTransitionPage(
          context: context,
          state: state,
          child: const DistanceMatrixScreen(),
        ),
      ),
      GoRoute(
        path: Routes.longdoMap,
        pageBuilder: (context, state) => _slideTransitionPage(
          context: context,
          state: state,
          child: const LongDoMapPage(),
        ),
      ),
      GoRoute(
        path: Routes.longdoMapWs,
        pageBuilder: (context, state) => _slideTransitionPage(
          context: context,
          state: state,
          child: const LongDoMapWsPage(),
        ),
      ),
      GoRoute(
        path: Routes.longdoMapRoute,
        pageBuilder: (context, state) => _slideTransitionPage(
          context: context,
          state: state,
          child: const LongDoMapRoutePage(),
        ),
      ),
    ],
  );

  static Page _fadeTransitionPage({
    required BuildContext context,
    required GoRouterState state,
    required Widget child,
  }) {
    return Platform.isIOS
        ? SwipeablePage(
            canOnlySwipeFromEdge: true,
            key: state.pageKey,
            builder: (context) {
              return child;
            },
          )
        : CustomTransitionPage(
            key: state.pageKey,
            child: child,
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) =>
                    FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
  }

  static Page _slideTransitionPage({
    required BuildContext context,
    required GoRouterState state,
    required Widget child,
  }) {
    return Platform.isIOS
        ? SwipeablePage(
            canOnlySwipeFromEdge: true,
            key: state.pageKey,
            builder: (context) {
              return child;
            },
          )
        : CustomTransitionPage(
            key: state.pageKey,
            child: child,
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) =>
                    SlideTransition(
              position: animation.drive(
                Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).chain(CurveTween(curve: Curves.easeIn)),
              ),
              child: child,
            ),
          );
  }
}

/// Extension to easily navigate using GoRouter
extension GoRouterExtension on BuildContext {
  void pushRoute(String route, {Object? extra}) {
    GoRouter.of(this).push(route, extra: extra);
  }

  void goRoute(String route, {Object? extra}) {
    GoRouter.of(this).go(route, extra: extra);
  }

  void popRoute<T extends Object?>([T? result]) {
    GoRouter.of(this).pop(result);
  }

  bool canPopRoute() {
    return GoRouter.of(this).canPop();
  }

  void popUntilRoute(String routePath) {
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
