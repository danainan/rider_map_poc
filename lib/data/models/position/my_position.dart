import 'package:equatable/equatable.dart';

class MyPosition extends Equatable {
  final double latitude;
  final double longitude;

  const MyPosition({
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object?> get props => [latitude, longitude];
}