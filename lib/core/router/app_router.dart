import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:rider_map_poc/core/router/routes.dart';
import 'package:rider_map_poc/modules/distance_matrix/pages/distance_matrix_screen.dart';
import 'package:rider_map_poc/modules/home/pages/home_page.dart';
import 'package:rider_map_poc/modules/longdo_map/pages/longdo_map.dart';
import 'package:rider_map_poc/modules/rider/pages/rider_screen.dart';
import 'package:rider_map_poc/modules/rider_map/pages/rider_map_page.dart';
import 'package:rider_map_poc/modules/route_navigation/pages/route_navigation_page.dart';
import 'package:rider_map_poc/modules/splash/pages/splash_page.dart';

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
    ],
  );

  static CustomTransitionPage<void> _fadeTransitionPage({
    required BuildContext context,
    required GoRouterState state,
    required Widget child,
  }) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }

  static CustomTransitionPage<void> _slideTransitionPage({
    required BuildContext context,
    required GoRouterState state,
    required Widget child,
  }) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

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
