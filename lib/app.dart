import 'package:flutter/material.dart';
import 'package:rider_map_poc/core/router/app_router.dart';
import 'package:rider_map_poc/core/theme/app_theme.dart';

class RiderMapApp extends StatelessWidget {
  const RiderMapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Rider Map POC',
      debugShowCheckedModeBanner: false,
      routerDelegate: AppRouter.router.routerDelegate,
      routeInformationParser: AppRouter.router.routeInformationParser,
      routeInformationProvider: AppRouter.router.routeInformationProvider,
      theme: ThemeData.light().copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
        extensions: <ThemeExtension<dynamic>>[
          AppTheme.light,
        ],
      ),

    );
  }
}

