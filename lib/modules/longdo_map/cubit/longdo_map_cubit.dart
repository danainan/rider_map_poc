import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'longdo_map_state.dart';

class LongdoMapCubit extends Cubit<LongdoMapState> {
  LongdoMapCubit() : super(const LongdoMapState());
}
