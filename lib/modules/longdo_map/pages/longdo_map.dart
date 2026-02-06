import 'package:flutter/material.dart';
import 'package:longdo_maps_api3_flutter/longdo.dart';
import 'package:longdo_maps_api3_flutter/view.dart';
import 'package:rider_map_poc/modules/longdo_map/widgets/map_widget.dart';

class LongDoMapPage extends StatefulWidget {
  const LongDoMapPage({super.key});

  @override
  State<LongDoMapPage> createState() => _LongDoMapPageState();
}

class _LongDoMapPageState extends State<LongDoMapPage> {
  final mapKey = GlobalKey<LongdoMapState>();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Longdo Map'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Stack(
          children: [
            MapWidget(
              mapKey: mapKey,             
            ),
          ],
        ),
      ),
    );
  }
}