import 'package:flutter/material.dart';
import 'package:rider_map_poc/core/constants/api_constants.dart';
import 'package:rider_map_poc/modules/longdo_map/data/mock_longdo_route_data.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// WebView widget สำหรับ Longdo Map V2
/// - แสดงหมุด: rider (ตำแหน่ง GPS), ร้านค้า, ลูกค้า
/// - ใช้ Longdo Routing API (map.Route) คำนวณเส้นทาง
///   GPS → ร้านค้า → ลูกค้า
/// - มี JS function moveRider() ให้ Flutter เรียกขยับ marker ตาม GPS
class MapWidget extends StatefulWidget {
  final WebViewController controller;
  final VoidCallback? onMapReady;

  const MapWidget({
    super.key,
    required this.controller,
    this.onMapReady,
  });

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
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
        #result {
            position: absolute;
            bottom: 0; left: 0; right: 0;
            max-height: 0; overflow: hidden;
        }
    </style>
    <script src="https://api.longdo.com/map/?key=${ApiConstants.longDoMapApiKey}"></script>
</head>
<body>
    <div id="map"></div>
    <div id="result"></div>
    <script>
        var map;
        var riderMarker;
        var routeSearched = false;

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
            // ร้านค้า marker (Overlay เท่านั้น — ไม่ใช่ Route point)
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

            // ตั้งศูนย์กลาง
            map.location({ lon: ${MockLongdoRouteData.shopLon}, lat: ${MockLongdoRouteData.shopLat} }, true);
        }

        // ---- เรียกจาก Flutter ----

        // ขยับ rider marker + ค้นหา route ครั้งแรกเมื่อได้พิกัด GPS
        function moveRider(lat, lon) {
            // ลบ rider marker เดิม
            if (riderMarker) {
                map.Overlays.remove(riderMarker);
            }

            // สร้าง rider marker ใหม่
            riderMarker = new longdo.Marker(
                { lon: lon, lat: lat },
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
            map.location({ lon: lon, lat: lat }, true);

            // ค้นหา route ครั้งแรกเท่านั้น (Rider → ร้านค้า → ลูกค้า)
            if (!routeSearched) {
                routeSearched = true;
                searchRoute(lat, lon);
            }
        }

        // ใช้ Longdo Routing API: Rider(GPS) → ร้านค้า → ลูกค้า
        function searchRoute(lat, lon) {
            map.Route.placeholder(document.getElementById('result'));

            // จุดที่ 1 — Rider (ตำแหน่ง GPS ปัจจุบัน)
            map.Route.add(new longdo.Marker(
                { lon: lon, lat: lat },
                { title: 'Rider', detail: 'จุดเริ่มต้น' }
            ));

            // จุดที่ 2 — ร้านค้า
            map.Route.add(new longdo.Marker(
                { lon: ${MockLongdoRouteData.shopLon}, lat: ${MockLongdoRouteData.shopLat} },
                { title: '${MockLongdoRouteData.shopTitle}', detail: '${MockLongdoRouteData.shopDetail}' }
            ));

            // จุดที่ 3 — ลูกค้า
            map.Route.add(new longdo.Marker(
                { lon: ${MockLongdoRouteData.customerLon}, lat: ${MockLongdoRouteData.customerLat} },
                { title: '${MockLongdoRouteData.customerTitle}', detail: '${MockLongdoRouteData.customerDetail}' }
            ));

            // ตั้งค่าเส้นทางสำหรับมอเตอร์ไซค์
            map.Route.enableRestrict(longdo.RouteRestrict.Bike, true);

            // ค้นหาเส้นทาง
            map.Route.search();
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
