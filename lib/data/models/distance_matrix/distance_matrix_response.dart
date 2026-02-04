import 'package:equatable/equatable.dart';

class DistanceMatrixResponse extends Equatable {
  const DistanceMatrixResponse({
    this.destinationAddresses,
    this.originAddresses ,
    this.rows,
    this.status,
  });

  final List<String>? destinationAddresses;
  final List<String>? originAddresses;
  final List<DistanceMatrixRow>? rows;
  final String? status;

  //from json
  factory DistanceMatrixResponse.fromJson(Map<String, dynamic> json) {
    return DistanceMatrixResponse(
      destinationAddresses: List<String>.from(json['destination_addresses'] ?? []),
      originAddresses: List<String>.from(json['origin_addresses'] ?? []),
      rows: (json['rows'] as List<dynamic>?)
          ?.map((e) => DistanceMatrixRow.fromJson(e as Map<String, dynamic>))
          .toList(),
      status: json['status'] as String?,
    );
  }
  
  static const empty = DistanceMatrixResponse(
    destinationAddresses: [],
    originAddresses: [],
    rows: [],
    status: '',
  );

  @override
  List<Object?> get props => [destinationAddresses, originAddresses, rows, status];
}

class DistanceMatrixRow extends Equatable {
  const DistanceMatrixRow({
    this.elements,
  });

  final List<DistanceMatrixElement>? elements;

  //from json
  factory DistanceMatrixRow.fromJson(Map<String, dynamic> json) {
    return DistanceMatrixRow(
      elements: (json['elements'] as List<dynamic>?)
          ?.map((e) => DistanceMatrixElement.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [elements];
}

class DistanceMatrixElement extends Equatable {
  const DistanceMatrixElement({
    this.distance,
    this.duration,
    this.durationInTraffic,
    this.status,
  });

  final DistanceMatrixValue? distance;
  final DistanceMatrixValue? duration;
  final DistanceMatrixValue? durationInTraffic;
  final String? status;

  //from json
  factory DistanceMatrixElement.fromJson(Map<String, dynamic> json) {
    return DistanceMatrixElement(
      distance: json['distance'] != null
          ? DistanceMatrixValue.fromJson(json['distance'] as Map<String, dynamic>)
          : null,
      duration: json['duration'] != null
          ? DistanceMatrixValue.fromJson(json['duration'] as Map<String, dynamic>)
          : null,
      durationInTraffic: json['duration_in_traffic'] != null
          ? DistanceMatrixValue.fromJson(json['duration_in_traffic'] as Map<String, dynamic>)
          : null,
      status: json['status'] as String?,
    );
  }
      

  @override
  List<Object?> get props => [distance, duration, durationInTraffic, status];
}


class DistanceMatrixValue extends Equatable {
  const DistanceMatrixValue({
    this.text,
    this.value,
  });

  final String? text;
  final int? value;

  factory DistanceMatrixValue.fromJson(Map<String, dynamic> json) {
    return DistanceMatrixValue(
      text: json['text'] as String?,
      value: json['value'] as int?,
    );
  } 

  @override
  List<Object?> get props => [text, value];
}