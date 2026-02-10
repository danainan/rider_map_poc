import 'package:equatable/equatable.dart';

// --- Main Class ---
class LongDoMapGeoJson extends Equatable {
  final String? type;
  final List<LongDoMapFeature>? features;
  final LongDoMapMeta? meta;
  final LongDoMapData? data;

  const LongDoMapGeoJson({
    this.type,
    this.features,
    this.meta,
    this.data,
  });

  factory LongDoMapGeoJson.fromJson(Map<String, dynamic> json) {
    return LongDoMapGeoJson(
      type: json['type'] as String?,
      features: (json['features'] as List<dynamic>?)
          ?.map((e) => LongDoMapFeature.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: json['meta'] != null
          ? LongDoMapMeta.fromJson(json['meta'] as Map<String, dynamic>)
          : null,
      data: json['data'] != null
          ? LongDoMapData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  //implement toJson
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'features': features?.map((e) => {
            'type': e.type,
            'geometry': {
              'type': e.geometry?.type,
              'coordinates': e.geometry?.coordinates,
            },
            'properties': {
              'turn': e.properties?.turn,
              'name': e.properties?.name,
              'distance': e.properties?.distance,
              'interval': e.properties?.interval,
            },
          }).toList(),
      'meta': {
        'from': {
          'lon': meta?.from?.lon,
          'lat': meta?.from?.lat,
        },
        'to': {
          'lon': meta?.to?.lon,
          'lat': meta?.to?.lat,
        },
        'config': meta?.config,
      },
      'data': {
        'fdistance': data?.fdistance,
        'tdistance': data?.tdistance,
        'distance': data?.distance,
        'interval': data?.interval,
      },
    };
  }


  @override
  List<Object?> get props => [type, features, meta, data];
}

// --- Feature ---
class LongDoMapFeature extends Equatable {
  final String? type;
  final LongDoMapGeometry? geometry;
  final LongDoMapProperties? properties;

  const LongDoMapFeature({
    this.type,
    this.geometry,
    this.properties,
  });

  factory LongDoMapFeature.fromJson(Map<String, dynamic> json) {
    return LongDoMapFeature(
      type: json['type'] as String?,
      geometry: json['geometry'] != null
          ? LongDoMapGeometry.fromJson(json['geometry'] as Map<String, dynamic>)
          : null,
      properties: json['properties'] != null
          ? LongDoMapProperties.fromJson(json['properties'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  List<Object?> get props => [type, geometry, properties];
}

// --- Geometry ---
class LongDoMapGeometry extends Equatable {
  final String? type;
  // coordinates เป็น List ซ้อน List [[lon, lat], [lon, lat]]
  final List<List<double>>? coordinates; 

  const LongDoMapGeometry({
    this.type,
    this.coordinates,
  });

  factory LongDoMapGeometry.fromJson(Map<String, dynamic> json) {
    return LongDoMapGeometry(
      type: json['type'] as String?,
      coordinates: (json['coordinates'] as List<dynamic>?)?.map((item) {
        // แปลงแต่ละจุดเป็น List<double>
        return (item as List<dynamic>).map((coord) => (coord as num).toDouble()).toList();
      }).toList(),
    );
  }

  @override
  List<Object?> get props => [type, coordinates];
}

// --- Properties ---
class LongDoMapProperties extends Equatable {
  final num? turn;
  final String? name;
  final num? distance;
  final num? interval;

  const LongDoMapProperties({
    this.turn,
    this.name,
    this.distance,
    this.interval,
  });

  factory LongDoMapProperties.fromJson(Map<String, dynamic> json) {
    return LongDoMapProperties(
      turn: json['turn'] as num?,
      name: json['name'] as String?,
      distance: json['distance'] as num?,
      interval: json['interval'] as num?,
    );
  }

  @override
  List<Object?> get props => [turn, name, distance, interval];
}

// --- Meta ---
class LongDoMapMeta extends Equatable {
  final LongDoMapLocation? from;
  final LongDoMapLocation? to;
  final String? config;

  const LongDoMapMeta({
    this.from,
    this.to,
    this.config,
  });

  factory LongDoMapMeta.fromJson(Map<String, dynamic> json) {
    return LongDoMapMeta(
      from: json['from'] != null
          ? LongDoMapLocation.fromJson(json['from'] as Map<String, dynamic>)
          : null,
      to: json['to'] != null
          ? LongDoMapLocation.fromJson(json['to'] as Map<String, dynamic>)
          : null,
      config: json['config'] as String?,
    );
  }

  @override
  List<Object?> get props => [from, to, config];
}

// --- Helper: Location (Lat/Lon) ---
class LongDoMapLocation extends Equatable {
  final double? lon;
  final double? lat;

  const LongDoMapLocation({this.lon, this.lat});

  factory LongDoMapLocation.fromJson(Map<String, dynamic> json) {
    return LongDoMapLocation(
      lon: (json['lon'] as num?)?.toDouble(),
      lat: (json['lat'] as num?)?.toDouble(),
    );
  }

  @override
  List<Object?> get props => [lon, lat];
}

// --- Data ---
class LongDoMapData extends Equatable {
  final num? fdistance;
  final num? tdistance;
  final num? distance;
  final num? interval;

  const LongDoMapData({
    this.fdistance,
    this.tdistance,
    this.distance,
    this.interval,
  });

  factory LongDoMapData.fromJson(Map<String, dynamic> json) {
    return LongDoMapData(
      fdistance: json['fdistance'] as num?,
      tdistance: json['tdistance'] as num?,
      distance: json['distance'] as num?,
      interval: json['interval'] as num?,
    );
  }

  @override
  List<Object?> get props => [fdistance, tdistance, distance, interval];
}