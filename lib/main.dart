import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rider_map_poc/app.dart';
import 'package:rider_map_poc/core/di/injectable.dart';
import 'package:rider_map_poc/data/local/hive/hive_manager.dart';

void main() async {
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Configure dependencies
    await configureDependencies();
    
    // Initialize Hive
    final hiveManager = getIt<HiveManager>();
    await hiveManager.init();
    
    // Run app
    runApp(const RiderMapApp());
  }, (error, stack) {
    if (kDebugMode) {
      FlutterError.presentError(
        FlutterErrorDetails(exception: error, stack: stack),
      );
    }
  });
}
