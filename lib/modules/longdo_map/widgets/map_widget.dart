import 'package:flutter/material.dart';
import 'package:longdo_maps_api3_flutter/longdo_maps_api3_flutter.dart';
import 'package:rider_map_poc/core/constants/api_constants.dart';

class MapWidget extends StatelessWidget {
  const MapWidget({
    super.key,
    required this.mapKey,
    this.eventName = const [],
    this.options = const {},
  });

  final Key mapKey;
  final List<IJavascriptChannel> eventName;
  final Object options;

  @override
  Widget build(BuildContext context) {
    return LongdoMapWidget(
      key: mapKey,
      apiKey: ApiConstants.longDoMapApiKey,
      eventName: eventName,
      options: options,
    );
  }
}