import 'package:equatable/equatable.dart';

/// Model สำหรับ parse GeoJSON response จาก Longdo Routing Web Service
/// Endpoint: https://api.longdo.com/RouteService/geojson/route
class LongdoRouteGeoJson extends Equatable {
  final List<RouteFeature> features;
  final RouteProperties properties;

  const LongdoRouteGeoJson({
    required this.features,
    required this.properties,
  });

  factory LongdoRouteGeoJson.fromJson(Map<String, dynamic> json) {
    final features = (json['features'] as List<dynamic>?)
            ?.map((f) => RouteFeature.fromJson(f as Map<String, dynamic>))
            .toList() ??
        [];

    final props = json['properties'] as Map<String, dynamic>? ?? {};

    return LongdoRouteGeoJson(
      features: features,
      properties: RouteProperties.fromJson(props),
    );
  }

  /// คืน Polyline ทั้งหมดรวมกันเป็น List ของ [lon, lat]
  List<List<double>> get allCoordinates {
    final coords = <List<double>>[];
    for (final feature in features) {
      coords.addAll(feature.coordinates);
    }
    return coords;
  }

  @override
  List<Object?> get props => [features, properties];
}

/// แต่ละ Feature = 1 ถนน/ซอย ที่มี Polyline + properties (ชื่อ, ทิศทาง, ระยะทาง)
class RouteFeature extends Equatable {
  final String name;
  final int turn;
  final double distance;
  final int interval;
  final List<List<double>> coordinates; // [[lon, lat], ...]

  const RouteFeature({
    required this.name,
    required this.turn,
    required this.distance,
    required this.interval,
    required this.coordinates,
  });

  factory RouteFeature.fromJson(Map<String, dynamic> json) {
    final props = json['properties'] as Map<String, dynamic>? ?? {};
    final geometry = json['geometry'] as Map<String, dynamic>? ?? {};

    // coordinates จาก MultiLineString: [[lon, lat], [lon, lat], ...]
    final rawCoords = geometry['coordinates'] as List<dynamic>? ?? [];
    final coordinates = rawCoords.map((c) {
      if (c is List) {
        return [
          (c[0] as num).toDouble(),
          (c[1] as num).toDouble(),
        ];
      }
      return <double>[0, 0];
    }).toList();

    return RouteFeature(
      name: props['name'] as String? ?? '',
      turn: props['turn'] as int? ?? 0,
      distance: (props['distance'] as num?)?.toDouble() ?? 0,
      interval: props['interval'] as int? ?? 0,
      coordinates: coordinates,
    );
  }

  /// คำอธิบาย turn code
  String get turnDescription => switch (turn) {
        0 => 'ถึงจุดหมาย',
        1 => 'กลับรถ',
        2 => 'เลี้ยวซ้าย',
        3 => 'เลี้ยวซ้ายเล็กน้อย',
        4 => 'ตรงไป',
        5 => 'เลี้ยวขวาเล็กน้อย',
        6 => 'เลี้ยวขวา',
        _ => 'ไม่ทราบ',
      };

  @override
  List<Object?> get props => [name, turn, distance, interval, coordinates];
}

/// Properties รวมของ FeatureCollection (ข้อมูลเส้นทางทั้งหมด)
class RouteProperties extends Equatable {
  final double fdistance;
  final double tdistance;
  final int distance;
  final int interval;

  const RouteProperties({
    required this.fdistance,
    required this.tdistance,
    required this.distance,
    required this.interval,
  });

  factory RouteProperties.fromJson(Map<String, dynamic> json) {
    return RouteProperties(
      fdistance: (json['fdistance'] as num?)?.toDouble() ?? 0,
      tdistance: (json['tdistance'] as num?)?.toDouble() ?? 0,
      distance: json['distance'] as int? ?? 0,
      interval: json['interval'] as int? ?? 0,
    );
  }

  /// แปลงระยะทางเป็นข้อความ
  String get distanceText {
    if (distance >= 1000) {
      return '${(distance / 1000).toStringAsFixed(1)} กม.';
    }
    return '$distance ม.';
  }

  /// แปลงเวลาเป็นข้อความ
  String get intervalText {
    if (interval >= 3600) {
      final h = interval ~/ 3600;
      final m = (interval % 3600) ~/ 60;
      return '$h ชม. $m นาที';
    }
    if (interval >= 60) {
      return '${interval ~/ 60} นาที';
    }
    return '$interval วินาที';
  }

  @override
  List<Object?> get props => [fdistance, tdistance, distance, interval];
}
