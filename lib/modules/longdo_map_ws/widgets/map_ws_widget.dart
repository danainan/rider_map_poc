import 'package:flutter/material.dart';
import 'package:rider_map_poc/core/constants/api_constants.dart';
import 'package:rider_map_poc/modules/longdo_map/data/mock_longdo_route_data.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// WebView widget สำหรับ Longdo Map — ใช้ Web Service routing
/// - วาด Polyline จาก GeoJSON response
/// - Snap ตำแหน่ง rider ลง Polyline ที่ใกล้สุด
/// - ตัด Polyline ที่ผ่านแล้วออก (แสดงเฉพาะเส้นทางข้างหน้า)
class MapWsWidget extends StatefulWidget {
  final WebViewController controller;
  final VoidCallback? onMapReady;
  final VoidCallback? onOffRoute;

  const MapWsWidget({
    super.key,
    required this.controller,
    this.onMapReady,
    this.onOffRoute,
  });

  @override
  State<MapWsWidget> createState() => _MapWsWidgetState();
}

class _MapWsWidgetState extends State<MapWsWidget> {
  @override
  void initState() {
    super.initState();
    _loadLongdoMap();
  }

  void _loadLongdoMap() {
    String mapHtml = '''
<!DOCTYPE html>
<html>
<head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        html, body { height: 100%; width: 100%; overflow: hidden; }
        #map { height: 100%; width: 100%; }
    </style>
    <script src="https://api.longdo.com/map/?key=${ApiConstants.longDoMapApiKey}"></script>
</head>
<body>
    <div id="map"></div>
    <script>
        var map;
        var riderMarker;
        var routePolylines = [];         // เก็บ Polyline overlay ทั้งหมดบนแผนที่
        var allRouteSegments = [];        // เก็บ segment data [{coords:[[lon,lat],...], name, ...}, ...]
        var snappedPolylines = [];        // เก็บ Polyline overlay หลัง snap
        var offRouteNotified = false;     // ป้องกันส่ง offRoute ซ้ำ

        function init() {
            map = new longdo.Map({
                placeholder: document.getElementById('map'),
                language: 'th',
                zoom: 15,
                lastView: false
            });

            map.Event.bind('ready', function() {
                setupMarkers();
                if (window.FlutterChannel) {
                    window.FlutterChannel.postMessage('mapReady');
                }
            });
        }

        function setupMarkers() {
            // ร้านค้า marker
            var shopMarker = new longdo.Marker(
                { lon: ${MockLongdoRouteData.shopLon}, lat: ${MockLongdoRouteData.shopLat} },
                {
                    title: '${MockLongdoRouteData.shopTitle}',
                    detail: '${MockLongdoRouteData.shopDetail}',
                    icon: {
                        html: '<div style="background:#FF6B35;border:3px solid #fff;border-radius:50%;width:32px;height:32px;display:flex;align-items:center;justify-content:center;box-shadow:0 2px 6px rgba(0,0,0,0.3);"><span style="font-size:16px;">🏪</span></div>',
                        offset: { x: 16, y: 16 }
                    }
                }
            );
            map.Overlays.add(shopMarker);

            // ลูกค้า marker
            var customerMarker = new longdo.Marker(
                { lon: ${MockLongdoRouteData.customerLon}, lat: ${MockLongdoRouteData.customerLat} },
                {
                    title: '${MockLongdoRouteData.customerTitle}',
                    detail: '${MockLongdoRouteData.customerDetail}',
                    icon: {
                        html: '<div style="background:#34A853;border:3px solid #fff;border-radius:50%;width:32px;height:32px;display:flex;align-items:center;justify-content:center;box-shadow:0 2px 6px rgba(0,0,0,0.3);"><span style="font-size:16px;">📍</span></div>',
                        offset: { x: 16, y: 16 }
                    }
                }
            );
            map.Overlays.add(customerMarker);

            map.location({ lon: ${MockLongdoRouteData.shopLon}, lat: ${MockLongdoRouteData.shopLat} }, true);
        }

        // ========================================
        // ฟังก์ชัน Geometry สำหรับ Snap-to-Polyline
        // ========================================

        // หาจุดที่ใกล้ที่สุดบนเส้นตรง AB จากจุด P (projection)
        // คืน { lon, lat, t } — ใช้หา snap point ที่แน่นอนภายใน segment
        function closestPointOnSegment(pLon, pLat, aLon, aLat, bLon, bLat) {
            var dx = bLon - aLon;
            var dy = bLat - aLat;
            if (dx === 0 && dy === 0) {
                return { lon: aLon, lat: aLat, t: 0 };
            }
            var t = ((pLon - aLon) * dx + (pLat - aLat) * dy) / (dx * dx + dy * dy);
            t = Math.max(0, Math.min(1, t));
            return {
                lon: aLon + t * dx,
                lat: aLat + t * dy,
                t: t
            };
        }

        // หา snap point บน polyline ทั้งหมด
        // ใช้ longdo.Polyline.distance() หา segment ที่ใกล้ที่สุด
        // แล้วค่อยหา snap point ที่แน่นอนภายใน segment นั้น
        function findSnapPoint(riderLon, riderLat) {
            if (routePolylines.length === 0) return null;

            var riderLocation = { lon: riderLon, lat: riderLat };

            // 1) ใช้ longdo.Polyline.distance() หา Polyline ที่ใกล้ที่สุด
            var bestSegIndex = 0;
            var bestSegDist = Infinity;

            for (var s = 0; s < routePolylines.length; s++) {
                var dist = routePolylines[s].distance(riderLocation);
                if (dist < bestSegDist) {
                    bestSegDist = dist;
                    bestSegIndex = s;
                }
            }

            // 2) หาจุด snap ที่แน่นอนบน segment ที่ใกล้ที่สุด
            var coords = allRouteSegments[bestSegIndex].coords;
            var bestSubDist = Infinity;
            var bestSnap = null;

            for (var i = 0; i < coords.length - 1; i++) {
                var pt = closestPointOnSegment(
                    riderLon, riderLat,
                    coords[i][0], coords[i][1],
                    coords[i + 1][0], coords[i + 1][1]
                );
                // เปรียบเทียบ Euclidean distance² (จุดใกล้กัน ไม่ต้อง haversine)
                var dLon = pt.lon - riderLon;
                var dLat = pt.lat - riderLat;
                var dist2 = dLon * dLon + dLat * dLat;
                if (dist2 < bestSubDist) {
                    bestSubDist = dist2;
                    bestSnap = {
                        lon: pt.lon,
                        lat: pt.lat,
                        dist: bestSegDist,
                        segmentIndex: bestSegIndex,
                        pointIndex: i,
                        t: pt.t
                    };
                }
            }

            return bestSnap;
        }

        // ========================================
        // วาด Polyline จาก route data (เรียกจาก Flutter)
        // ========================================

        // routeDataJson: JSON string ที่มี features[]
        function drawRoute(routeDataJson) {
            // ลบ polyline เดิม
            clearRoutePolylines();
            offRouteNotified = false; // ได้เส้นทางใหม่แล้ว reset flag

            var routeData = JSON.parse(routeDataJson);
            allRouteSegments = [];

            for (var i = 0; i < routeData.features.length; i++) {
                var feature = routeData.features[i];
                var coords = feature.coordinates; // [[lon, lat], ...]
                
                allRouteSegments.push({
                    coords: coords,
                    name: feature.name,
                    turn: feature.turn,
                    distance: feature.distance,
                    interval: feature.interval
                });

                // วาด polyline ลงแผนที่
                if (coords.length >= 2) {
                    var locationList = coords.map(function(c) {
                        return { lon: c[0], lat: c[1] };
                    });

                    var polyline = new longdo.Polyline(locationList, {
                        lineWidth: 5,
                        lineColor: 'rgba(66, 133, 244, 0.8)',
                        borderWidth: 1,
                        borderColor: 'rgba(30, 80, 180, 0.5)'
                    });
                    map.Overlays.add(polyline);
                    routePolylines.push(polyline);
                }
            }

            // ส่งข้อมูลสรุปกลับ Flutter
            if (window.FlutterChannel) {
                window.FlutterChannel.postMessage('routeDrawn:' + routeData.distanceText + '|' + routeData.intervalText);
            }
        }

        // ========================================
        // ขยับ rider + Snap บน Polyline
        // ========================================

        function moveRider(lat, lon) {
            // ลบ rider marker เดิม
            if (riderMarker) {
                map.Overlays.remove(riderMarker);
            }

            var snapLon = lon;
            var snapLat = lat;

            // ---- Snap-to-Polyline ----
            if (allRouteSegments.length > 0) {
                var snap = findSnapPoint(lon, lat);
                if (snap && snap.dist < 100) {
                    // snap ได้ (ภายใน 100m จาก route)
                    snapLon = snap.lon;
                    snapLat = snap.lat;
                    offRouteNotified = false; // กลับมาบนเส้นแล้ว reset flag

                    // ลบ polyline เก่าออก แล้ววาดเฉพาะเส้นทางข้างหน้า
                    redrawRouteFromSnap(snap);
                } else {
                    // ออกนอกเส้นทาง (>= 100m) → แจ้ง Flutter ให้ยิง route ใหม่
                    if (!offRouteNotified && window.FlutterChannel) {
                        offRouteNotified = true;
                        window.FlutterChannel.postMessage('offRoute');
                    }
                }
            }

            // สร้าง rider marker ที่ตำแหน่ง snap
            riderMarker = new longdo.Marker(
                { lon: snapLon, lat: snapLat },
                {
                    title: 'Rider',
                    detail: 'ตำแหน่งปัจจุบัน',
                    icon: {
                        html: '<div style="background:#4285F4;border:3px solid #fff;border-radius:50%;width:28px;height:28px;display:flex;align-items:center;justify-content:center;box-shadow:0 2px 6px rgba(0,0,0,0.3);"><span style="font-size:14px;">🏍</span></div>',
                        offset: { x: 14, y: 14 }
                    }
                }
            );
            map.Overlays.add(riderMarker);

            // Pan map ตาม rider
            map.location({ lon: snapLon, lat: snapLat }, true);
        }

        // ========================================
        // วาดเส้นทางข้างหน้าจากจุด snap
        // ========================================

        function redrawRouteFromSnap(snap) {
            // ลบ polyline ทั้งหมดออกก่อน
            clearRoutePolylines();

            for (var s = snap.segmentIndex; s < allRouteSegments.length; s++) {
                var coords = allRouteSegments[s].coords;
                var locationList = [];

                if (s === snap.segmentIndex) {
                    // Segment ที่ snap อยู่: เริ่มจากจุด snap แล้วต่อด้วยจุดที่เหลือ
                    locationList.push({ lon: snap.lon, lat: snap.lat });
                    for (var i = snap.pointIndex + 1; i < coords.length; i++) {
                        locationList.push({ lon: coords[i][0], lat: coords[i][1] });
                    }
                } else {
                    // Segment ถัดไป: วาดทั้งหมด
                    locationList = coords.map(function(c) {
                        return { lon: c[0], lat: c[1] };
                    });
                }

                if (locationList.length >= 2) {
                    var polyline = new longdo.Polyline(locationList, {
                        lineWidth: 5,
                        lineColor: 'rgba(66, 133, 244, 0.8)',
                        borderWidth: 1,
                        borderColor: 'rgba(30, 80, 180, 0.5)'
                    });
                    map.Overlays.add(polyline);
                    routePolylines.push(polyline);
                }
            }
        }

        // ลบ polyline ทั้งหมดบนแผนที่
        function clearRoutePolylines() {
            for (var i = 0; i < routePolylines.length; i++) {
                map.Overlays.remove(routePolylines[i]);
            }
            routePolylines = [];
        }

        // Zoom ให้เห็นทุก overlay
        function fitBounds() {
            map.Overlays.boundsAll(true);
        }

        window.onload = init;
    </script>
</body>
</html>
''';

    widget.controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: (message) {
          if (message.message == 'mapReady') {
            widget.onMapReady?.call();
          } else if (message.message == 'offRoute') {
            widget.onOffRoute?.call();
          }
        },
      )
      ..loadHtmlString(mapHtml);
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(
      controller: widget.controller,
    );
  }
}
