// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:dio/dio.dart' as _i361;
import 'package:get_it/get_it.dart' as _i174;
import 'package:hive_flutter/adapters.dart' as _i744;
import 'package:injectable/injectable.dart' as _i526;
import 'package:rider_map_poc/core/di/register_module.dart' as _i554;
import 'package:rider_map_poc/data/local/hive/hive_encryption.dart' as _i324;
import 'package:rider_map_poc/data/local/hive/hive_manager.dart' as _i101;
import 'package:rider_map_poc/data/local/hive/hive_operation.dart' as _i610;
import 'package:rider_map_poc/data/local/primitive/primitive_database.dart'
    as _i950;
import 'package:rider_map_poc/data/models/permission/app_permission_status.dart'
    as _i598;
import 'package:rider_map_poc/data/services/distance_matrix/distance_matrix_service.dart'
    as _i1013;
import 'package:rider_map_poc/data/services/distance_matrix/distance_matrix_service_impl.dart'
    as _i971;
import 'package:rider_map_poc/data/services/geolocator/geolocator_service.dart'
    as _i197;
import 'package:rider_map_poc/data/services/geolocator/geolocator_service_impl.dart'
    as _i877;
import 'package:rider_map_poc/data/services/longdo_map/longdo_map_service.dart'
    as _i823;
import 'package:rider_map_poc/data/services/longdo_map/longdo_map_service_impl.dart'
    as _i177;
import 'package:rider_map_poc/data/services/permission_status/app_permission_status_service.dart'
    as _i537;
import 'package:rider_map_poc/data/services/permission_status/app_permission_status_service_impl.dart'
    as _i161;
import 'package:rider_map_poc/data/services/rider/rider_route_service.dart'
    as _i460;
import 'package:rider_map_poc/data/services/rider/rider_route_service_impl.dart'
    as _i277;
import 'package:rider_map_poc/data/services/routes/routes_service.dart'
    as _i857;
import 'package:rider_map_poc/data/services/routes/routes_service_impl.dart'
    as _i211;
import 'package:rider_map_poc/modules/distance_matrix/cubit/distance_metrix_cubit.dart'
    as _i748;
import 'package:rider_map_poc/modules/longdo_map/cubit/longdo_map_cubit.dart'
    as _i200;
import 'package:rider_map_poc/modules/rider/cubit/rider_cubit.dart' as _i635;
import 'package:rider_map_poc/modules/rider_map/bloc/rider_map_bloc.dart'
    as _i916;
import 'package:rider_map_poc/modules/route_navigation/bloc/route_navigation_bloc.dart'
    as _i51;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    final registerModule = _$RegisterModule();
    gh.singleton<_i744.HiveInterface>(() => registerModule.hive);
    gh.lazySingleton<_i361.Dio>(() => registerModule.dio);
    gh.lazySingleton<_i610.HiveOperation<_i598.AppPermissionStatus>>(
        () => registerModule.appPermissionStatusHiveOperation);
    gh.factory<_i197.GeolocatorService>(() => _i877.GeolocatorServiceImpl());
    gh.factory<_i857.RoutesService>(() => _i211.RoutesServiceImpl());
    gh.factory<_i460.RiderRouteService>(() => _i277.RiderRouteServiceImpl());
    gh.factory<_i916.RiderMapBloc>(
        () => _i916.RiderMapBloc(gh<_i197.GeolocatorService>()));
    gh.factory<_i823.LongdoMapService>(() => _i177.LongdoMapServiceImpl());
    gh.lazySingleton<_i950.PrimitiveDatabase<dynamic>>(
        () => registerModule.secureStorageManager);
    gh.factory<_i537.AppPermissionStatusService>(() =>
        _i161.AppPermissionStatusServiceImpl(
            gh<_i610.HiveOperation<_i598.AppPermissionStatus>>()));
    gh.factory<_i1013.DistanceMatrixService>(
        () => _i971.DistanceMatrixServiceImpl());
    gh.factory<_i101.HiveManager>(
        () => _i101.HiveManager(gh<_i744.HiveInterface>()));
    gh.factoryParam<_i610.HiveOperation<dynamic>, _i324.HiveEncryption?,
        dynamic>((
      hiveEncryption,
      _,
    ) =>
        _i610.HiveOperation<dynamic>(
          gh<_i744.HiveInterface>(),
          gh<_i950.PrimitiveDatabase<dynamic>>(),
          hiveEncryption: hiveEncryption,
        ));
    gh.factory<_i51.RouteNavigationBloc>(() => _i51.RouteNavigationBloc(
          gh<_i197.GeolocatorService>(),
          gh<_i857.RoutesService>(),
        ));
    gh.factory<_i200.LongdoMapCubit>(() => _i200.LongdoMapCubit(
          gh<_i197.GeolocatorService>(),
          gh<_i537.AppPermissionStatusService>(),
        ));
    gh.lazySingleton<_i324.HiveEncryption>(() => _i324.HiveEncryption(
          gh<_i744.HiveInterface>(),
          gh<_i950.PrimitiveDatabase<dynamic>>(),
        ));
    gh.factory<_i635.RiderCubit>(() => _i635.RiderCubit(
          gh<_i197.GeolocatorService>(),
          gh<_i460.RiderRouteService>(),
          gh<_i537.AppPermissionStatusService>(),
        ));
    gh.factory<_i748.DistanceMetrixCubit>(() => _i748.DistanceMetrixCubit(
          gh<_i1013.DistanceMatrixService>(),
          gh<_i823.LongdoMapService>(),
        ));
    return this;
  }
}

class _$RegisterModule extends _i554.RegisterModule {}
