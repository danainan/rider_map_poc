import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'package:rider_map_poc/core/di/injectable.config.dart';

final GetIt getIt = GetIt.instance;

@injectableInit
Future<void> configureDependencies() async => getIt.init();
