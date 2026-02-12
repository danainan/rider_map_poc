import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:rider_map_poc/core/constants/api_constants.dart';

class LongdoMapNavigationWidget extends StatefulWidget {
  final WebViewController controller;
  final VoidCallback? onMapReady;
  final ValueChanged<bool>? onCameraFollowChanged;
  final Function(double remainingDistance)? onDistanceUpdated;

  const LongdoMapNavigationWidget({
    super.key,
    required this.controller,
    this.onMapReady,
    this.onCameraFollowChanged,
    this.onDistanceUpdated,
  });

  @override
  State<LongdoMapNavigationWidget> createState() =>
      LongdoMapNavigationWidgetState();
}

class LongdoMapNavigationWidgetState
    extends State<LongdoMapNavigationWidget> {
  @override
  void initState() {
    super.initState();
    _setupWebViewController();
    _loadLongdoMap();
  }

  void _setupWebViewController() {
    widget.controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: (JavaScriptMessage message) {
          _handleJavaScriptMessage(message.message);
        },
      );
  }

  void _handleJavaScriptMessage(String message) {
    final data = jsonDecode(message);
    final type = data['type'] as String?;

    switch (type) {
      case 'mapReady':
        widget.onMapReady?.call();
        break;
      case 'cameraFollowChanged':
        final isFollowing = data['isFollowing'] as bool? ?? true;
        widget.onCameraFollowChanged?.call(isFollowing);
        break;
      case 'distanceUpdated':
        final distance = (data['distance'] as num).toDouble();
        widget.onDistanceUpdated?.call(distance);
        break;
    }
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
        #map { height: 100%; width: 100%; background-color: #eee; }
    </style>
    <script src="https://api.longdo.com/map/?key=${ApiConstants.longDoMapApiKey}"></script>
</head>
<body>
    <div id="map"></div>
    
    <script>
        // ==========================================
        //  Global Variables
        // ==========================================
        let map;
        let shopMarker;
        let customerMarker;
        let riderMarker;
        
        // Route polyline object (ใช้สำหรับ .distance() API)
        let routePolyline = null;
        
        // เก็บ GPS points ที่ snap แล้ว สำหรับวาดเส้นสีเทา
        let snappedPoints = [];
        let passedOverlay = null;
        
        // Route coordinates ทั้งหมด (array of {lat, lon})
        let allRoutePoints = [];
        
        let isMapReady = false;
        
        const PASSED_COLOR = 'rgba(158, 158, 158, 0.8)';
        const PASSED_LINE_WIDTH = 5;
        const ROUTE_COLOR = 'rgba(59, 130, 246, 0.8)';
        const ROUTE_LINE_WIDTH = 5;
        
        // Threshold: ระยะห่างจาก polyline ที่ถือว่า "อยู่บนเส้นทาง" (เมตร)
        const ON_ROUTE_THRESHOLD = 5;
        
        let isCameraFollowing = true;
        let lastRiderLat = null;
        let lastRiderLon = null;
        let isProgrammaticMove = false;

        // ★ Rider icon
        const RIDER_ICON = {
            html: '<div style="position: relative; width: 48px; height: 48px; display: flex; align-items: center; justify-content: center;">' +
                '<div style="position: absolute; width: 40px; height: 40px; border-radius: 50%; background: rgba(59, 130, 246, 0.15); border: 2px solid rgba(59, 130, 246, 0.3);"></div>' +
                '<div style="position: absolute; width: 20px; height: 20px; border-radius: 50%; background: #3b82f6; border: 3px solid white; box-shadow: 0 2px 8px rgba(59, 130, 246, 0.6);"></div>' +
                '</div>',
            offset: { x: 24, y: 24 }
        };
        
        // ==========================================
        //  Map Initialization
        // ==========================================
        function initMap() {
            map = new longdo.Map({
                placeholder: document.getElementById('map'),
                zoom: 15
            });
            
            isMapReady = true;
            setupUserInteractionDetection();
            sendToFlutter({ type: 'mapReady' });
        }
        
        // ==========================================
        //  User Interaction Detection (camera follow)
        // ==========================================
        function setupUserInteractionDetection() {
            const mapEl = document.getElementById('map');
            mapEl.addEventListener('touchstart', onUserInteract, { passive: true });
            mapEl.addEventListener('mousedown', onUserInteract);
            mapEl.addEventListener('wheel', onUserInteract, { passive: true });
        }
        
        function onUserInteract() {
            if (isProgrammaticMove) return;
            if (!isCameraFollowing) return;
            isCameraFollowing = false;
            sendToFlutter({ type: 'cameraFollowChanged', isFollowing: false });
        }
        
        function recenterToRider() {
            isCameraFollowing = true;
            sendToFlutter({ type: 'cameraFollowChanged', isFollowing: true });
            if (lastRiderLat !== null && lastRiderLon !== null) {
                moveCameraTo(lastRiderLon, lastRiderLat);
            }
        }
        
        function moveCameraTo(lon, lat) {
            if (!map) return;
            isProgrammaticMove = true;
            map.location({ lon: lon, lat: lat }, true);
            setTimeout(() => { isProgrammaticMove = false; }, 300);
        }
        
        // ==========================================
        //  Location Markers (Shop + Customer)
        // ==========================================
        function addLocationMarkers(shopLat, shopLon, customerLat, customerLon) {
            if (!map) return;
            
            shopMarker = new longdo.Marker(
                { lon: shopLon, lat: shopLat },
                {
                    title: 'Shop',
                    icon: {
                        html: '<div style="position: relative;"><svg width="40" height="50" viewBox="0 0 40 50" style="filter: drop-shadow(0 2px 4px rgba(0,0,0,0.3));"><path d="M20 0C11.716 0 5 6.716 5 15c0 8.284 15 35 15 35s15-26.716 15-35c0-8.284-6.716-15-15-15z" fill="#10b981"/><circle cx="20" cy="15" r="8" fill="white"/></svg></div>',
                        offset: { x: 20, y: 50 }
                    }
                }
            );
            
            customerMarker = new longdo.Marker(
                { lon: customerLon, lat: customerLat },
                {
                    title: 'Customer',
                    icon: {
                        html: '<div style="position: relative;"><svg width="40" height="50" viewBox="0 0 40 50" style="filter: drop-shadow(0 2px 4px rgba(0,0,0,0.3));"><path d="M20 0C11.716 0 5 6.716 5 15c0 8.284 15 35 15 35s15-26.716 15-35c0-8.284-6.716-15-15-15z" fill="#ef4444"/><circle cx="20" cy="15" r="8" fill="white"/></svg></div>',
                        offset: { x: 20, y: 50 }
                    }
                }
            );
            
            map.Overlays.add(shopMarker);
            map.Overlays.add(customerMarker);
        }
        
        // ==========================================
        //  Rider Marker (ลบ+สร้างใหม่ทุกครั้ง)
        // ==========================================
        function addRiderMarker(lat, lon) {
            if (!map || riderMarker) return;
            lastRiderLat = lat;
            lastRiderLon = lon;
            riderMarker = new longdo.Marker(
                { lon: lon, lat: lat },
                { title: 'You', icon: RIDER_ICON }
            );
            map.Overlays.add(riderMarker);
            if (isCameraFollowing) moveCameraTo(lon, lat);
        }

        function updateRiderPosition(lat, lon) {
            if (!map) return;
            
            lastRiderLat = lat;
            lastRiderLon = lon;
            
            // ลบ marker เก่า
            if (riderMarker) {
                try { map.Overlays.remove(riderMarker); } catch(e) {}
                riderMarker = null;
            }
            
            // สร้างใหม่
            riderMarker = new longdo.Marker(
                { lon: lon, lat: lat },
                { title: 'You', icon: RIDER_ICON }
            );
            map.Overlays.add(riderMarker);
            
            if (isCameraFollowing) {
                moveCameraTo(lon, lat);
            }

            // ★ Logic ใหม่: ใช้ Polyline.distance() + snap-to-line
            processRiderOnRoute(lat, lon);
        }
        
        // ==========================================
        //  ★★★ NEW: Snap-to-Route Logic
        //  ใช้ Polyline.distance() API ของ Longdo
        // ==========================================

        /**
         * processRiderOnRoute:
         * 1. ใช้ routePolyline.distance({lat, lon}) หาระยะห่าง perpendicular จากเส้น
         * 2. ถ้า < threshold → rider อยู่บนเส้นทาง
         * 3. Snap จุดลงบนเส้น (vector projection) 
         * 4. เพิ่มจุด snap ลง snappedPoints[] 
         * 5. วาด gray polyline ทับ
         */
        function processRiderOnRoute(lat, lon) {
            if (!routePolyline || allRoutePoints.length < 2) return;
            
            const riderLoc = { lat: lat, lon: lon };
            
            // ★ ใช้ Longdo Polyline.distance() API
            // คืนค่า minimum perpendicular distance (เมตร) จาก rider ถึง polyline
            let distToRoute;
            try {
                distToRoute = routePolyline.distance(riderLoc);
                console.log('[DEBUG] Polyline.distance() =' + distToRoute + ' meters');
            } catch(e) {
                console.error('Polyline.distance() error:', e);
                return;
            }
            
            // ถ้า rider อยู่นอกเส้นทาง → ไม่ทำอะไร
            if (typeof distToRoute !== 'number' || distToRoute > ON_ROUTE_THRESHOLD) {
                console.log('[DEBUG] Rider is off route. Distance = ' + distToRoute + ' meters');
                return;
            }
            
            // ★ Rider อยู่บนเส้นทาง → Snap จุดลงบน polyline
            // const snapped = snapPointToPolyline(lat, lon, allRoutePoints);
            let snapped;
            try {
                snapped = snapPointToPolyline(lat, lon, allRoutePoints);
                console.log('[4] snap result: ' + JSON.stringify(snapped));
            } catch(e) {
                console.log('[4] snapPointToPolyline ERROR: ' + e.message);
                return;
            }
            
            if (!snapped) {
                console.log('[4b] snap returned null!');
                return;
            }
            
            if (!snapped) return;
            
            // เพิ่มจุด snap ลง array (ตรวจสอบไม่ให้ซ้ำหรือถอยหลัง)
            // addSnappedPoint(snapped);
            try {
                addSnappedPoint(snapped);
                console.log('[5] snappedPoints count: ' + snappedPoints.length);
            } catch(e) {
                console.log('[5] addSnappedPoint ERROR: ' + e.message);
                return;
            }
            
            // วาดเส้นสีเทาทับ
            // drawPassedOverlay();
            try {
                drawPassedOverlay();
                console.log('[6] drawPassedOverlay done ✓');
            } catch(e) {
                console.log('[6] drawPassedOverlay ERROR: ' + e.message);
                return;
            }
            
            // คำนวณระยะทางที่เหลือ
            calculateRemainingDistance(snapped);
        }
        
        /**
         * snapPointToPolyline:
         * ใช้หลักการ vector projection (point-to-segment)
         * หา closest point บน polyline จากจุด P(lat, lon)
         * 
         * สำหรับแต่ละ segment A→B:
         *   t = dot(P-A, B-A) / dot(B-A, B-A)
         *   t = clamp(t, 0, 1)
         *   closestPoint = A + t * (B-A)
         *   
         * คืนค่า { lat, lon, segmentIndex, t }
         */
        function snapPointToPolyline(lat, lon, points) {
            let minDist = Infinity;
            let bestPoint = null;
            let bestSegIndex = -1;
            let bestT = 0;
            
            for (let i = 0; i < points.length - 1; i++) {
                const A = points[i];
                const B = points[i + 1];
                
                const result = closestPointOnSegment(
                    lat, lon,
                    A.lat, A.lon,
                    B.lat, B.lon
                );
                console.log('[DEBUG] closestPointOnSegment distance = ' + result.distance);
                
                if (result.distance < minDist) {
                    minDist = result.distance;
                    bestPoint = { lat: result.lat, lon: result.lon };
                    bestSegIndex = i;
                    bestT = result.t;
                }
            }

            console.log('[DEBUG] snapPointToPolyline best distance = ' + minDist );
            
            if (!bestPoint) return null;
            
            return {
                lat: bestPoint.lat,
                lon: bestPoint.lon,
                segmentIndex: bestSegIndex,
                t: bestT   // 0~1 ตำแหน่งบน segment
            };
        }
        
        /**
         * closestPointOnSegment:
         * คำนวณจุดที่ใกล้ที่สุดบน segment (A→B) จากจุด P
         * ใช้ vector projection ใน lat/lon space
         * (ใช้ได้ดีสำหรับระยะสั้นๆ ไม่ต้อง project เป็น meters)
         */
        function closestPointOnSegment(pLat, pLon, aLat, aLon, bLat, bLon) {
            const dx = bLon - aLon;
            const dy = bLat - aLat;
            
            // ถ้า A == B (segment มีความยาว 0)
            if (dx === 0 && dy === 0) {
                const d = longdo.Util.distance(
                    [{ lat: pLat, lon: pLon }, { lat: aLat, lon: aLon }]
                );
                return { lat: aLat, lon: aLon, distance: d, t: 0 };
            }
            
            // t = dot(P-A, B-A) / dot(B-A, B-A)
            let t = ((pLon - aLon) * dx + (pLat - aLat) * dy) / (dx * dx + dy * dy);
            t = Math.max(0, Math.min(1, t)); // clamp [0, 1]
            
            // Closest point on segment
            const closestLon = aLon + t * dx;
            const closestLat = aLat + t * dy;
            
            // ระยะห่างจริง (เมตร) ด้วย Longdo Util
            const dist = longdo.Util.distance(
                [{ lat: pLat, lon: pLon }, { lat: closestLat, lon: closestLon }]
            );
            
            return { lat: closestLat, lon: closestLon, distance: dist, t: t };
        }
        
        /**
         * addSnappedPoint:
         * เพิ่มจุด snap เข้า snappedPoints[]
         * ป้องกันถอยหลัง: จุดใหม่ต้อง segmentIndex >= จุดก่อนหน้า
         */
        function addSnappedPoint(snapped) {
            if (snappedPoints.length === 0) {
                // จุดแรก: เพิ่มจุดเริ่มต้นของ route จนถึง segment ที่ snap
                // เพื่อให้เส้นสีเทาเริ่มจากต้นทาง
                for (let i = 0; i <= snapped.segmentIndex; i++) {
                    snappedPoints.push({
                        lat: allRoutePoints[i].lat,
                        lon: allRoutePoints[i].lon
                    });
                }
                // เพิ่มจุด snap (อาจอยู่กลาง segment)
                snappedPoints.push({ lat: snapped.lat, lon: snapped.lon });
                return;
            }
            
            // จุดถัดๆ ไป: ตรวจสอบว่าไม่ถอยหลัง
            const lastSnapped = snappedPoints[snappedPoints.length - 1];
            
            // หา segment index ของจุดก่อนหน้า
            const prevSegIndex = findSegmentIndex(lastSnapped.lat, lastSnapped.lon);
            
            if (snapped.segmentIndex < prevSegIndex) {
                // ถอยหลัง → ไม่เพิ่ม
                return;
            }
            
            if (snapped.segmentIndex === prevSegIndex) {
                // อยู่ segment เดียวกัน → แทนที่จุดสุดท้าย (อัพเดทตำแหน่งบน segment)
                snappedPoints[snappedPoints.length - 1] = {
                    lat: snapped.lat,
                    lon: snapped.lon
                };
                return;
            }
            
            // ข้าม segment ไปข้างหน้า → เพิ่มจุดต่อของ route ที่ข้ามมา
            for (let i = prevSegIndex + 1; i <= snapped.segmentIndex; i++) {
                snappedPoints.push({
                    lat: allRoutePoints[i].lat,
                    lon: allRoutePoints[i].lon
                });
            }
            // เพิ่มจุด snap ปัจจุบัน
            snappedPoints.push({ lat: snapped.lat, lon: snapped.lon });
        }
        
        /**
         * findSegmentIndex:
         * หาว่าจุดนี้อยู่บน segment ไหนของ allRoutePoints
         */
        function findSegmentIndex(lat, lon) {
            let minDist = Infinity;
            let bestIndex = 0;
            
            for (let i = 0; i < allRoutePoints.length - 1; i++) {
                const A = allRoutePoints[i];
                const B = allRoutePoints[i + 1];
                const result = closestPointOnSegment(lat, lon, A.lat, A.lon, B.lat, B.lon);
                if (result.distance < minDist) {
                    minDist = result.distance;
                    bestIndex = i;
                }
            }
            return bestIndex;
        }
        
        // ==========================================
        //  Draw Passed Overlay (เส้นสีเทาทับ)
        // ==========================================
        function drawPassedOverlay() {
            if (snappedPoints.length < 2) return;
            
            // ลบเส้นเก่า
            if (passedOverlay) {
                try { map.Overlays.remove(passedOverlay); } catch(e) {}
                passedOverlay = null;
            }
            
            // วาดเส้นสีเทาใหม่จาก snappedPoints ทั้งหมด
            passedOverlay = new longdo.Polyline(snappedPoints, {
                lineWidth: PASSED_LINE_WIDTH,
                lineColor: PASSED_COLOR
            });
            map.Overlays.add(passedOverlay);
        }
        
        // ==========================================
        //  Calculate Remaining Distance
        // ==========================================
        function calculateRemainingDistance(snapped) {
            if (allRoutePoints.length < 2) return;
            
            let totalDist = 0;
            
            // ระยะจากจุด snap ถึง end ของ segment ปัจจุบัน
            if (snapped.segmentIndex < allRoutePoints.length - 1) {
                const nextPoint = allRoutePoints[snapped.segmentIndex + 1];
                totalDist += longdo.Util.distance([
                    { lat: snapped.lat, lon: snapped.lon },
                    nextPoint
                ]);
            }
            
            // ระยะจาก segment ถัดไป ถึงจุดสุดท้าย
            for (let i = snapped.segmentIndex + 1; i < allRoutePoints.length - 1; i++) {
                totalDist += longdo.Util.distance([
                    allRoutePoints[i],
                    allRoutePoints[i + 1]
                ]);
            }
            
            sendToFlutter({ type: 'distanceUpdated', distance: totalDist });
        }
        
        // ==========================================
        //  Draw Route (เรียกครั้งเดียว)
        // ==========================================
        function drawRoute(geoJsonString) {
            if (!map) return;
            clearRoute();
            
            try {
                const geoJson = JSON.parse(geoJsonString);
                if (!geoJson.features || geoJson.features.length === 0) return;
                
                // รวม coordinates ทั้งหมดเป็นเส้นเดียว
                geoJson.features.forEach((feature) => {
                    if (feature.geometry && feature.geometry.type === 'LineString') {
                        feature.geometry.coordinates.forEach(coord => {
                            allRoutePoints.push({ lon: coord[0], lat: coord[1] });
                        });
                    }
                });

                if (allRoutePoints.length < 2) return;

                // ★ สร้าง Polyline object เก็บไว้ — ใช้ .distance() API ตรวจสอบระยะห่าง
                routePolyline = new longdo.Polyline(allRoutePoints, {
                    lineWidth: ROUTE_LINE_WIDTH,
                    lineColor: ROUTE_COLOR
                });
                map.Overlays.add(routePolyline);

                // ส่งระยะทางรวมกลับ Flutter
                let totalDist = 0;
                for (let i = 0; i < allRoutePoints.length - 1; i++) {
                    totalDist += longdo.Util.distance([
                        allRoutePoints[i],
                        allRoutePoints[i + 1]
                    ]);
                }
                sendToFlutter({ type: 'distanceUpdated', distance: totalDist });
                
            } catch (e) { 
                console.error("Error drawRoute: ", e); 
            }
        }
        
        // ==========================================
        //  Clear Route
        // ==========================================
        function clearRoute() {
            if (!map) return;
            
            if (routePolyline) {
                try { map.Overlays.remove(routePolyline); } catch(e) {}
                routePolyline = null;
            }
            if (passedOverlay) {
                try { map.Overlays.remove(passedOverlay); } catch(e) {}
                passedOverlay = null;
            }
            
            allRoutePoints = [];
            snappedPoints = [];
        }

        // ==========================================
        //  Flutter Communication
        // ==========================================
        function sendToFlutter(data) {
            if (window.FlutterChannel) {
                window.FlutterChannel.postMessage(JSON.stringify(data));
            }
        }
        
        window.onload = initMap;
    </script>
</body>
</html>
''';

    widget.controller.loadHtmlString(mapHtml);
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: widget.controller);
  }
}
