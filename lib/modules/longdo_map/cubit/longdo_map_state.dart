part of 'longdo_map_cubit.dart';


enum LongdoMapStatus { 
  initial, 
  loading, 
  success, 
  failure 
}

final class LongdoMapState extends Equatable {
  const LongdoMapState({
    this.status = LongdoMapStatus.initial,  
  });

  final LongdoMapStatus status;

  @override
  List<Object> get props => [status];
}
