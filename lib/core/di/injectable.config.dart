// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:dio/dio.dart' as _i361;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:rider_map_poc/core/di/register_module.dart' as _i554;
import 'package:rider_map_poc/modules/rider_map/bloc/rider_map_bloc.dart'
    as _i916;

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
    gh.factory<_i916.RiderMapBloc>(() => _i916.RiderMapBloc());
    gh.lazySingleton<_i361.Dio>(() => registerModule.dio);
    return this;
  }
}

class _$RegisterModule extends _i554.RegisterModule {}
