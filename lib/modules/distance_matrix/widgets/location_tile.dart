import 'package:flutter/material.dart';
import 'package:rider_map_poc/core/widgets/text_field.dart';

class LocationTile extends StatelessWidget {
  const LocationTile({
    super.key,
    required this.lat,
    required this.lon,
    this.index,
    this.onRemove,
    this.onChangedLat,
    this.onChangedLon,
  });

  final String lat;
  final String lon;
  final Function()? onRemove;
  final Function(String)? onChangedLat;
  final Function(String)? onChangedLon;
  final int? index;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),  
      child: Column(
        children: [

          //index
          if (index != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Location ${index!}',
                style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(height: 8.0),

          //section input location lat lon
            Row(
              children: [
              Expanded(
                child: TextFieldFormBuilder(
                  name: 'latitude', 
                  isEdit: true, 
                  hintText: 'Latitude',
                  initialValue: lat,
                  onChanged: onChangedLat,
                ),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: TextFieldFormBuilder(
                  name: 'longitude', 
                  isEdit: true, 
                  hintText: 'Longitude',
                  initialValue: lon,
                  onChanged: onChangedLon,
                ),
              ),
            ],
          ),

          //section button remove location
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                if (onRemove != null) {
                  onRemove!();
                }
              },
            ),
          ),
        ]
        
       


      ),
    );
  }
}