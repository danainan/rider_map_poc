import 'package:flutter/material.dart';
import 'package:rider_map_poc/core/constants/api_constants.dart';
import 'package:rider_map_poc/modules/longdo_map/data/mock_longdo_route_data.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// WebView widget สำหรับ Longdo Map — ใช้ map.Route API (add/removeAt/insert/search)
/// Route 3 จุด: Rider(0) → Shop(1) → Customer(2)
/// เมื่อ rider ขยับ จะ removeAt(0) แล้ว insert(0, ตำแหน่งใหม่) + search() ใหม่
class MapRouteWidget extends StatefulWidget {
  final WebViewController controller;
  final VoidCallback? onMapReady;

  /// เรียกเมื่อ route search เสร็จ → ส่ง distance + interval กลับ
  final void Function(String distance, String interval)? onRouteComplete;

  /// เรียกเมื่อเริ่ม search route
  final VoidCallback? onRouteSearching;

  /// เรียกเมื่อ rider ออกนอกเส้นทาง (>100m จาก route path)
  final VoidCallback? onOffRoute;

  const MapRouteWidget({
    super.key,
    required this.controller,
    this.onMapReady,
    this.onRouteComplete,
    this.onRouteSearching,
    this.onOffRoute,
  });

  @override
  State<MapRouteWidget> createState() => _MapRouteWidgetState();
}

class _MapRouteWidgetState extends State<MapRouteWidget> {
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
        var riderMarker;       // overlay marker สำหรับแสดง rider icon
        var shopMarker;        // overlay marker ร้านค้า
        var customerMarker;    // overlay marker ลูกค้า
        var routeInitialized = false;
        var routePathPoints = [];  // [{lon, lat}, ...] จาก route guide
        var offRouteNotified = false;

        function init() {
            map = new longdo.Map({
                placeholder: document.getElementById('map'),
                language: 'th',
                zoom: 15,
                lastView: false
            });

            map.Event.bind('ready', function() {
                setupRoute();
                setupMarkers();

                if (window.FlutterChannel) {
                    window.FlutterChannel.postMessage('mapReady');
                }
            });
        }

        // ========================================
        // ตั้งค่าหมุด icon ร้านค้า + ลูกค้า (Overlay markers)
        // ========================================
        function setupMarkers() {
            // ร้านค้า 🏪
            shopMarker = new longdo.Marker(
                { lon: ${MockLongdoRouteData.shopLon}, lat: ${MockLongdoRouteData.shopLat} },
                {
                    title: '${MockLongdoRouteData.shopTitle}',
                    detail: '${MockLongdoRouteData.shopDetail}',
                    icon: {
                        html: '<div style="background:#FF6D00;border:3px solid #fff;border-radius:50%;width:36px;height:36px;display:flex;align-items:center;justify-content:center;box-shadow:0 2px 6px rgba(0,0,0,0.3);font-size:18px;">🏪</div>',
                        offset: { x: 18, y: 18 }
                    }
                }
            );
            map.Overlays.add(shopMarker);

            // ลูกค้า 📍
            customerMarker = new longdo.Marker(
                { lon: ${MockLongdoRouteData.customerLon}, lat: ${MockLongdoRouteData.customerLat} },
                {
                    title: '${MockLongdoRouteData.customerTitle}',
                    detail: '${MockLongdoRouteData.customerDetail}',
                    icon: {
                        html: '<div style="background:#E91E63;border:3px solid #fff;border-radius:50%;width:36px;height:36px;display:flex;align-items:center;justify-content:center;box-shadow:0 2px 6px rgba(0,0,0,0.3);font-size:18px;">📍</div>',
                        offset: { x: 18, y: 18 }
                    }
                }
            );
            map.Overlays.add(customerMarker);
        }

        // ========================================
        // ตั้งค่า Route API
        // ========================================
        function setupRoute() {
            // ตั้งค่า route line style
            map.Route.line('road', {
                lineWidth: 5,
                lineColor: 'rgba(66, 133, 244, 0.8)',
                borderWidth: 1,
                borderColor: 'rgba(30, 80, 180, 0.5)'
            });

            // ตั้งค่า route mode
            // map.Route.mode(longdo.RouteMode.Cost);
            map.Route.enableRestrict(longdo.RouteRestrict.Bike, false);

            // ซ่อน destination line (เส้นตรงจากจุดหมาย)
            map.Route.line('destination', false);

            // ฟัง pathComplete event เพื่อรับผลลัพธ์
            map.Event.bind('pathComplete', function() {
                offRouteNotified = false;

                // ดึง route path จาก guide เพื่อใช้ตรวจ off-route
                try {
                    routePathPoints = [];
                    var guide = map.Route.guide();
                    if (guide && Array.isArray(guide)) {
                        for (var i = 0; i < guide.length; i++) {
                            var step = guide[i];
                            if (step.lon !== undefined && step.lat !== undefined) {
                                routePathPoints.push({ lon: step.lon, lat: step.lat });
                            }
                            if (step.path && Array.isArray(step.path)) {
                                for (var j = 0; j < step.path.length; j++) {
                                    var p = step.path[j];
                                    if (p.lon !== undefined) routePathPoints.push(p);
                                }
                            }
                        }
                    }
                } catch(e) {
                    routePathPoints = [];
                }

                var dist = map.Route.distance();
                var intv = map.Route.interval();
                if (window.FlutterChannel) {
                    window.FlutterChannel.postMessage('routeComplete:' + dist + '|' + intv);
                }
            });

            map.Event.bind('pathError', function() {
                if (window.FlutterChannel) {
                    window.FlutterChannel.postMessage('routeError');
                }
            });
        }

        // ========================================
        // เริ่มค้นหาเส้นทางครั้งแรก: Rider(0) → Shop(1) → Customer(2)
        // ========================================
        function initRoute(startLat, startLon, shopLat, shopLon, custLat, custLon) {
            // เคลียร์ทั้งหมดก่อน (กรณี re-init)
            map.Route.clear();

            // Index 0: Rider (จุดเริ่มต้น — ซ่อน icon เพราะใช้ overlay marker แทน)
            map.Route.add(new longdo.Marker(
                { lon: startLon, lat: startLat },
                {
                    title: 'Rider',
                    icon: {
                        html: '<div style="width:1px;height:1px;"></div>',
                        offset: { x: 0, y: 0 }
                    }
                }
            ));

            // Index 1: Shop (จุดแวะ)
            map.Route.add(new longdo.Marker(
                { lon: shopLon, lat: shopLat },
                {
                    title: 'ร้านค้า',
                    icon: {
                        html: '<div style="background:#FF6D00;border:3px solid #fff;border-radius:50%;width:28px;height:28px;display:flex;align-items:center;justify-content:center;box-shadow:0 2px 6px rgba(0,0,0,0.3);font-size:14px;">🏪</div>',
                        offset: { x: 14, y: 14 }
                    }
                }
            ));

            // Index 2: Customer (จุดหมาย)
            map.Route.add(new longdo.Marker(
                { lon: custLon, lat: custLat },
                {
                    title: 'ลูกค้า',
                    icon: {
                        html: '<div style="background:#E91E63;border:3px solid #fff;border-radius:50%;width:28px;height:28px;display:flex;align-items:center;justify-content:center;box-shadow:0 2px 6px rgba(0,0,0,0.3);font-size:14px;">📍</div>',
                        offset: { x: 14, y: 14 }
                    }
                }
            ));

            routeInitialized = true;

            // ค้นหาเส้นทาง
            map.Route.search();

            if (window.FlutterChannel) {
                window.FlutterChannel.postMessage('routeSearching');
            }
        }

        // ========================================
        // อัพเดทจุดเริ่มต้นเป็นตำแหน่ง rider ใหม่
        // ใช้ removeAt(0) → insert(0, marker ใหม่) → search()
        // Shop ยังอยู่ index 1, Customer ยังอยู่ index 2
        // ========================================
        function updateStartPoint(lat, lon) {
            if (!routeInitialized) return;

            // ลบจุด rider เดิมที่ index 0
            map.Route.removeAt(0);

            // แทรก rider ใหม่ที่ index 0 (ซ่อน icon)
            map.Route.insert(0, new longdo.Marker(
                { lon: lon, lat: lat },
                {
                    title: 'Rider',
                    icon: {
                        html: '<div style="width:1px;height:1px;"></div>',
                        offset: { x: 0, y: 0 }
                    }
                }
            ));

            // search ใหม่
            map.Route.search();

            if (window.FlutterChannel) {
                window.FlutterChannel.postMessage('routeSearching');
            }
        }

        // ========================================
        // ขยับ rider overlay marker (แยกจาก Route marker)
        // ========================================
        function moveRider(lat, lon) {
            if (riderMarker) {
                map.Overlays.remove(riderMarker);
            }

            riderMarker = new longdo.Marker(
                { lon: lon, lat: lat },
                {
                    title: 'Rider',
                    detail: 'ตำแหน่งปัจจุบัน',
                    icon: {
                        html: '<div style="background:#4285F4;border:3px solid #fff;border-radius:50%;width:28px;height:28px;display:flex;align-items:center;justify-content:center;box-shadow:0 2px 6px rgba(0,0,0,0.3);font-size:14px;">🏍</div>',
                        offset: { x: 14, y: 14 }
                    }
                }
            );
            map.Overlays.add(riderMarker);

            // ---- ตรวจ off-route ----
            if (routePathPoints.length > 0) {
                var minDist = Infinity;
                var cosLat = Math.cos(lat * Math.PI / 180);
                for (var i = 0; i < routePathPoints.length; i++) {
                    var dLon = (routePathPoints[i].lon - lon) * cosLat;
                    var dLat = routePathPoints[i].lat - lat;
                    var distM = Math.sqrt(dLon * dLon + dLat * dLat) * 111320;
                    if (distM < minDist) minDist = distM;
                }
                if (minDist > 100) {
                    if (!offRouteNotified && window.FlutterChannel) {
                        offRouteNotified = true;
                        window.FlutterChannel.postMessage('offRoute');
                    }
                } else {
                    offRouteNotified = false;
                }
            }

            // Pan map ตาม rider
            map.location({ lon: lon, lat: lat }, true);
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
          final msg = message.message;
          if (msg == 'mapReady') {
            widget.onMapReady?.call();
          } else if (msg.startsWith('routeComplete:')) {
            // routeComplete:1234|567
            final data = msg.replaceFirst('routeComplete:', '');
            final parts = data.split('|');
            if (parts.length == 2) {
              widget.onRouteComplete?.call(parts[0], parts[1]);
            }
          } else if (msg == 'routeSearching') {
            widget.onRouteSearching?.call();
          } else if (msg == 'offRoute') {
            widget.onOffRoute?.call();
          } else if (msg == 'routeError') {
            // ignore for now
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
