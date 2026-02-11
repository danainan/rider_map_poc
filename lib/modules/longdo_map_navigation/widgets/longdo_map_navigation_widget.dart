// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:webview_flutter/webview_flutter.dart';
// import 'package:rider_map_poc/core/constants/api_constants.dart';

// class LongdoMapNavigationWidget extends StatefulWidget {
//   final WebViewController controller;
//   final VoidCallback? onMapReady;
//   final ValueChanged<bool>? onCameraFollowChanged;
//   final Function(double remainingDistance)? onDistanceUpdated;

//   const LongdoMapNavigationWidget({
//     super.key,
//     required this.controller,
//     this.onMapReady,
//     this.onCameraFollowChanged,
//     this.onDistanceUpdated,
//   });

//   @override
//   State<LongdoMapNavigationWidget> createState() =>
//       LongdoMapNavigationWidgetState();
// }

// class LongdoMapNavigationWidgetState
//     extends State<LongdoMapNavigationWidget> {
//   @override
//   void initState() {
//     super.initState();
//     _setupWebViewController();
//     _loadLongdoMap();
//   }

//   void _setupWebViewController() {
//     widget.controller
//       ..setJavaScriptMode(JavaScriptMode.unrestricted)
//       ..addJavaScriptChannel(
//         'FlutterChannel',
//         onMessageReceived: (JavaScriptMessage message) {
//           _handleJavaScriptMessage(message.message);
//         },
//       );
//   }

//   void _handleJavaScriptMessage(String message) {
//     final data = jsonDecode(message);
//     final type = data['type'] as String?;

//     switch (type) {
//       case 'mapReady':
//         widget.onMapReady?.call();
//         break;
//       case 'cameraFollowChanged':
//         final isFollowing = data['isFollowing'] as bool? ?? true;
//         widget.onCameraFollowChanged?.call(isFollowing);
//         break;
//       case 'distanceUpdated':
//         final distance = (data['distance'] as num).toDouble();
//         widget.onDistanceUpdated?.call(distance);
//         break;
//     }
//   }

//   void _loadLongdoMap() {
//     String mapHtml = '''
// <!DOCTYPE html>
// <html>
// <head>
//     <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
//     <style>
//         * { margin: 0; padding: 0; box-sizing: border-box; }
//         html, body { height: 100%; width: 100%; overflow: hidden; }
//         #map { height: 100%; width: 100%; background-color: #eee; }
//     </style>
//     <script src="https://api.longdo.com/map/?key=${ApiConstants.longDoMapApiKey}"></script>
// </head>
// <body>
//     <div id="map"></div>
    
//     <script>
//         let map;
//         let shopMarker;
//         let customerMarker;
//         let riderMarker;
        
//         // ========== Route Data ==========
//         // routeSegments เก็บ segments ทั้งหมดของ polyline
//         // แต่ละ segment มี:
//         //   - id, locations[], color (สีต้นฉบับ)
//         //   - overlay (polyline ปัจจุบันที่แสดงอยู่บนแผนที่)
//         //   - passed: boolean (ผ่านแล้วหรือยัง)
//         //   - passedOverlay: polyline สีเทาที่วาดทับส่วนที่ผ่านแล้ว
//         let routeSegments = [];
        
//         // เก็บ polyline สีเทาของส่วนที่ผ่านแล้ว (สำหรับ segment ปัจจุบันที่ถูกตัดครึ่ง)
//         let currentPassedOverlay = null;
        
//         let isMapReady = false;
        
//         // สีเทาสำหรับเส้นที่ผ่านแล้ว (เหมือน Google Maps)
//         const PASSED_COLOR = 'rgba(158, 158, 158, 0.6)';
//         const PASSED_LINE_WIDTH = 5;
        
//         // ========== Camera Follow ==========
//         let isCameraFollowing = true;
//         let lastRiderLat = null;
//         let lastRiderLon = null;
//         let isProgrammaticMove = false;
        
//         function initMap() {
//             map = new longdo.Map({
//                 placeholder: document.getElementById('map'),
//                 zoom: 15
//             });
            
//             isMapReady = true;
//             setupUserInteractionDetection();
//             sendToFlutter({ type: 'mapReady' });
//         }
        
//         // ========== User Interaction Detection ==========
//         function setupUserInteractionDetection() {
//             const mapEl = document.getElementById('map');
//             mapEl.addEventListener('touchstart', onUserInteract, { passive: true });
//             mapEl.addEventListener('mousedown', onUserInteract);
//             mapEl.addEventListener('wheel', onUserInteract, { passive: true });
//         }
        
//         function onUserInteract() {
//             if (isProgrammaticMove) return;
//             if (!isCameraFollowing) return;
            
//             isCameraFollowing = false;
//             sendToFlutter({ type: 'cameraFollowChanged', isFollowing: false });
//         }
        
//         function recenterToRider() {
//             isCameraFollowing = true;
//             sendToFlutter({ type: 'cameraFollowChanged', isFollowing: true });
            
//             if (lastRiderLat !== null && lastRiderLon !== null) {
//                 moveCameraTo(lastRiderLon, lastRiderLat);
//             }
//         }
        
//         function moveCameraTo(lon, lat) {
//             if (!map) return;
//             isProgrammaticMove = true;
//             map.location({ lon: lon, lat: lat }, true);
//             setTimeout(() => { isProgrammaticMove = false; }, 300);
//         }
        
//         // ========== Markers ==========
//         function addLocationMarkers(shopLat, shopLon, customerLat, customerLon) {
//             if (!map) return;
            
//             shopMarker = new longdo.Marker(
//                 { lon: shopLon, lat: shopLat },
//                 {
//                     title: 'Shop',
//                     icon: {
//                         html: '<div style="position: relative;"><svg width="40" height="50" viewBox="0 0 40 50" style="filter: drop-shadow(0 2px 4px rgba(0,0,0,0.3));"><path d="M20 0C11.716 0 5 6.716 5 15c0 8.284 15 35 15 35s15-26.716 15-35c0-8.284-6.716-15-15-15z" fill="#10b981"/><circle cx="20" cy="15" r="8" fill="white"/></svg></div>',
//                         offset: { x: 20, y: 50 }
//                     }
//                 }
//             );
            
//             customerMarker = new longdo.Marker(
//                 { lon: customerLon, lat: customerLat },
//                 {
//                     title: 'Customer',
//                     icon: {
//                         html: '<div style="position: relative;"><svg width="40" height="50" viewBox="0 0 40 50" style="filter: drop-shadow(0 2px 4px rgba(0,0,0,0.3));"><path d="M20 0C11.716 0 5 6.716 5 15c0 8.284 15 35 15 35s15-26.716 15-35c0-8.284-6.716-15-15-15z" fill="#ef4444"/><circle cx="20" cy="15" r="8" fill="white"/></svg></div>',
//                         offset: { x: 20, y: 50 }
//                     }
//                 }
//             );
            
//             map.Overlays.add(shopMarker);
//             map.Overlays.add(customerMarker);
//         }
        
//         function addRiderMarker(lat, lon) {
//             if (!map) return;
            
//             // if (riderMarker) map.Overlays.remove(riderMarker);
//             if (riderMarker) return;
            
//             lastRiderLat = lat;
//             lastRiderLon = lon;
            
//             riderMarker = new longdo.Marker(
//                 { lon: lon, lat: lat },
//                 {
//                     title: 'You',
//                     // icon: {
//                     //     html: '<div style="position: relative; width: 100px; height: 100px; display: flex; align-items: center; justify-content: center;">' +
//                     //         '<div style="position: absolute; width: 80px; height: 80px; border-radius: 50%; background: rgba(59, 130, 246, 0.1); animation: pulse 2s ease-in-out infinite;"></div>' +
//                     //         '<div style="position: absolute; width: 60px; height: 60px; border-radius: 50%; background: rgba(59, 130, 246, 0.15); border: 2px solid rgba(59, 130, 246, 0.3);"></div>' +
//                     //         '<div style="position: absolute; width: 40px; height: 40px; border-radius: 50%; background: radial-gradient(circle, rgba(59, 130, 246, 0.3) 0%, rgba(59, 130, 246, 0) 70%);"></div>' +
//                     //         '<div style="position: absolute; width: 20px; height: 20px; border-radius: 50%; background: #3b82f6; border: 3px solid white; box-shadow: 0 2px 8px rgba(59, 130, 246, 0.6), 0 0 0 1px rgba(59, 130, 246, 0.1);"></div>' +
//                     //         '</div>' +
//                     //         '<style>@keyframes pulse { 0% { transform: scale(1); opacity: 1; } 50% { transform: scale(1.2); opacity: 0.6; } 100% { transform: scale(1); opacity: 1; } }</style>',
//                     //     offset: { x: 50, y: 50 }
//                     // }
//                     icon: {
//                       html: '<div style="position: relative; width: 48px; height: 48px; display: flex; align-items: center; justify-content: center;">' +
//                           '<div style="position: absolute; width: 40px; height: 40px; border-radius: 50%; background: rgba(59, 130, 246, 0.15); border: 2px solid rgba(59, 130, 246, 0.3);"></div>' +
//                           '<div style="position: absolute; width: 20px; height: 20px; border-radius: 50%; background: #3b82f6; border: 3px solid white; box-shadow: 0 2px 8px rgba(59, 130, 246, 0.6);"></div>' +
//                           '</div>',
//                       offset: { x: 24, y: 24 }
//                   }
//                 }
//             );
            
//             map.Overlays.add(riderMarker);
            
//             if (isCameraFollowing) {
//                 moveCameraTo(lon, lat);
//             }
//         }
        
//         // ========== Update Rider Position ==========
//         function updateRiderPosition(lat, lon) {
//             if (!map) return;
            
//             lastRiderLat = lat;
//             lastRiderLon = lon;
            
//             if (!riderMarker) {
//                 addRiderMarker(lat, lon);
//             } else {
//                 riderMarker.location({ lon: lon, lat: lat });
//             }

//             if (isCameraFollowing) {
//                 moveCameraTo(lon, lat);
//             }
            
//             // ===== Snap to route + gray out passed =====
//             if (routeSegments.length > 0) {
//                 snapAndGrayOutPassed(lat, lon);
//             }
//         }
        
//         // ========== Draw Route ==========
//         function drawRoute(geoJsonString) {
//             if (!map) return;
//             clearRoute();
            
//             try {
//                 const geoJson = JSON.parse(geoJsonString);
//                 if (!geoJson.features || geoJson.features.length === 0) return;
                
//                 geoJson.features.forEach((feature, index) => {
//                     if (feature.geometry && feature.geometry.type === 'LineString') {
//                         const coordinates = feature.geometry.coordinates;
//                         if (!coordinates || coordinates.length < 2) return;
                        
//                         const locations = coordinates.map(coord => ({
//                             lon: coord[0], lat: coord[1]
//                         }));
                        
//                         // สีหลักของเส้นทาง (ฟ้า)
//                         const lineColor = 'rgba(59, 130, 246, 0.8)';
                        
//                         const polyline = new longdo.Polyline(locations, {
//                             lineWidth: 5, lineColor: lineColor
//                         });
                        
//                         map.Overlays.add(polyline);
                        
//                         routeSegments.push({
//                             id: index,
//                             overlay: polyline,
//                             locations: locations,
//                             originalLocations: [...locations], // เก็บ locations ดั้งเดิมไว้
//                             color: lineColor,
//                             passed: false,
//                             passedOverlay: null,
//                         });
//                     }
//                 });
                
//             } catch (e) {
//                 console.error('Error drawing route:', e);
//             }
//         }
        
//         // ==========================================================
//         //  CORE: Snap rider to route + เปลี่ยนส่วนที่ผ่านแล้วเป็นสีเทา
//         //  - ไม่ลบ segment ออก แค่วาดเส้นเทาทับส่วนที่ผ่านแล้ว
//         //  - ตัด polyline สีฟ้าให้เหลือเฉพาะส่วนข้างหน้า
//         // ==========================================================
        
//         function snapAndGrayOutPassed(riderLat, riderLon) {
//             if (routeSegments.length === 0) return;
            
//             const riderLoc = { lon: riderLon, lat: riderLat };
            
//             // --------------------------------------------------
//             // Step 1: หา segment ที่ใกล้ rider ที่สุด
//             // --------------------------------------------------
//             let minDist = Infinity;
//             let closestSegIdx = -1;
            
//             for (let i = 0; i < routeSegments.length; i++) {
//                 const seg = routeSegments[i];
//                 if (seg.passed) continue; // ข้าม segment ที่ผ่านแล้วทั้งหมด
                
//                 try {
//                     if (seg.overlay) {
//                         const dist = seg.overlay.distance(riderLoc);
//                         if (typeof dist === 'number' && dist < minDist) {
//                             minDist = dist;
//                             closestSegIdx = i;
//                         }
//                     }
//                 } catch (e) {
//                     const dist = manualMinDistToPolyline(riderLoc, seg.locations);
//                     if (dist < minDist) {
//                         minDist = dist;
//                         closestSegIdx = i;
//                     }
//                 }
//             }
            
//             // ถ้าห่างเกิน 50m หรือหาไม่เจอ → ไม่ทำอะไร (ไม่สนใจ off-route)
//             if (minDist > 50 || closestSegIdx === -1) return;
            
//             // ถ้ายังห่าง > 30m ไม่ต้อง snap/trim
//             if (minDist > 30) return;
            
//             // --------------------------------------------------
//             // Step 2: หา snap point บน segment ที่ใกล้ที่สุด
//             // --------------------------------------------------
//             const closestSeg = routeSegments[closestSegIdx];
//             const locs = closestSeg.locations;
            
//             let snapPoint = null;
//             let snapSegmentIdx = 0;
//             let bestDist = Infinity;
            
//             for (let j = 0; j < locs.length - 1; j++) {
//                 const projected = projectPointOnSegment(riderLoc, locs[j], locs[j + 1]);
//                 const d = longdo.Util.distance([riderLoc, projected]);
                
//                 if (d < bestDist) {
//                     bestDist = d;
//                     snapPoint = projected;
//                     snapSegmentIdx = j;
//                 }
//             }
            
//             if (!snapPoint) return;
            
//             // --------------------------------------------------
//             // Step 3: Mark segments ก่อน closestSegIdx เป็น "passed" (สีเทา)
//             // --------------------------------------------------
//             for (let i = 0; i < closestSegIdx; i++) {
//                 if (!routeSegments[i].passed) {
//                     markSegmentAsPassed(i);
//                 }
//             }
            
//             // --------------------------------------------------
//             // Step 4: ตัด segment ปัจจุบัน — ส่วนที่ผ่านแล้วเป็นเทา, ส่วนที่เหลือเป็นฟ้า
//             // --------------------------------------------------
//             updateCurrentSegment(closestSegIdx, snapPoint, snapSegmentIdx);
            
//             // --------------------------------------------------
//             // Step 5: คำนวณระยะทางเหลือ (เฉพาะส่วนที่ยังไม่ passed)
//             // --------------------------------------------------
//             let totalRemaining = 0;
//             for (let i = 0; i < routeSegments.length; i++) {
//                 const seg = routeSegments[i];
//                 if (!seg.passed && seg.locations && seg.locations.length >= 2) {
//                     totalRemaining += longdo.Util.distance(seg.locations);
//                 }
//             }
            
//             sendToFlutter({ type: 'distanceUpdated', distance: totalRemaining });
//         }
        
//         // ==========================================================
//         //  Mark segment ทั้งอันเป็น "passed" → วาดเส้นเทาทับ, ลบเส้นฟ้าเดิม
//         // ==========================================================
//         function markSegmentAsPassed(segIdx) {
//             const seg = routeSegments[segIdx];
//             seg.passed = true;
            
//             // ลบ polyline สีฟ้าเดิม
//             if (seg.overlay) {
//                 map.Overlays.remove(seg.overlay);
//                 seg.overlay = null;
//             }
            
//             // วาด polyline สีเทาแทน (ใช้ originalLocations เพื่อให้เห็นเส้นทางเดิมทั้งหมด)
//             if (seg.passedOverlay) {
//                 map.Overlays.remove(seg.passedOverlay);
//             }
            
//             const locsToUse = seg.originalLocations || seg.locations;
//             if (locsToUse && locsToUse.length >= 2) {
//                 seg.passedOverlay = new longdo.Polyline(locsToUse, {
//                     lineWidth: PASSED_LINE_WIDTH,
//                     lineColor: PASSED_COLOR,
//                 });
//                 map.Overlays.add(seg.passedOverlay);
//             }
//         }
        
//         // ==========================================================
//         //  ตัด segment ปัจจุบัน:
//         //    - ส่วนก่อน snapPoint → วาดเป็นสีเทา
//         //    - ส่วนหลัง snapPoint → วาดเป็นสีฟ้า (เส้นที่เหลือ)
//         // ==========================================================
//         function updateCurrentSegment(segIdx, snapPoint, snapLocIdx) {
//             const seg = routeSegments[segIdx];
//             const locs = seg.locations;
            
//             // ส่วนที่ผ่านแล้ว: [จุดเริ่มต้น ... snapPoint]
//             const passedLocations = [
//                 ...locs.slice(0, snapLocIdx + 1),
//                 snapPoint
//             ];
            
//             // ส่วนที่เหลือ: [snapPoint ... จุดปลาย]
//             const remainingLocations = [
//                 snapPoint,
//                 ...locs.slice(snapLocIdx + 1)
//             ];
            
//             // --- ลบ passed overlay เดิมของ segment นี้ (ถ้ามี) ---
//             if (currentPassedOverlay) {
//                 map.Overlays.remove(currentPassedOverlay);
//                 currentPassedOverlay = null;
//             }
            
//             // --- วาดส่วนที่ผ่านแล้วเป็นสีเทา ---
//             if (passedLocations.length >= 2) {
//                 currentPassedOverlay = new longdo.Polyline(passedLocations, {
//                     lineWidth: PASSED_LINE_WIDTH,
//                     lineColor: PASSED_COLOR,
//                 });
//                 map.Overlays.add(currentPassedOverlay);
//             }
            
//             // --- ลบ polyline สีฟ้าเดิม ---
//             if (seg.overlay) {
//                 map.Overlays.remove(seg.overlay);
//                 seg.overlay = null;
//             }
            
//             // --- วาด polyline สีฟ้าใหม่ (เฉพาะส่วนที่เหลือ) ---
//             if (remainingLocations.length >= 2) {
//                 const newPolyline = new longdo.Polyline(remainingLocations, {
//                     lineWidth: 5,
//                     lineColor: seg.color,
//                 });
//                 map.Overlays.add(newPolyline);
//                 seg.overlay = newPolyline;
//                 seg.locations = remainingLocations;
//             } else {
//                 // เหลือไม่ถึง 2 จุด → mark เป็น passed ทั้งอัน
//                 seg.passed = true;
//                 seg.locations = [];
//             }
//         }
        
//         // ==========================================================
//         //  Project จุด P ลงบน segment AB → จุดที่ใกล้ที่สุดบนเส้น
//         // ==========================================================
//         function projectPointOnSegment(point, segStart, segEnd) {
//             const A = point.lon - segStart.lon;
//             const B = point.lat - segStart.lat;
//             const C = segEnd.lon - segStart.lon;
//             const D = segEnd.lat - segStart.lat;
            
//             const dot = A * C + B * D;
//             const lenSq = C * C + D * D;
            
//             let t = lenSq !== 0 ? dot / lenSq : -1;
            
//             if (t < 0) t = 0;
//             if (t > 1) t = 1;
            
//             return {
//                 lon: segStart.lon + t * C,
//                 lat: segStart.lat + t * D
//             };
//         }
        
//         // ==========================================================
//         //  Fallback: Manual min distance from point to polyline (เมตร)
//         // ==========================================================
//         function manualMinDistToPolyline(point, locations) {
//             let minDist = Infinity;
//             for (let i = 0; i < locations.length - 1; i++) {
//                 const projected = projectPointOnSegment(point, locations[i], locations[i + 1]);
//                 const d = longdo.Util.distance([point, projected]);
//                 if (d < minDist) minDist = d;
//             }
//             return minDist;
//         }
        
//         function clearRoute() {
//             if (!map) return;
            
//             // ลบ overlay ทั้งหมด (ทั้งสีฟ้าและสีเทา)
//             routeSegments.forEach(seg => {
//                 if (seg.overlay) map.Overlays.remove(seg.overlay);
//                 if (seg.passedOverlay) map.Overlays.remove(seg.passedOverlay);
//             });
            
//             if (currentPassedOverlay) {
//                 map.Overlays.remove(currentPassedOverlay);
//                 currentPassedOverlay = null;
//             }
            
//             routeSegments = [];
//         }
        
//         function sendToFlutter(data) {
//             if (window.FlutterChannel) {
//                 window.FlutterChannel.postMessage(JSON.stringify(data));
//             }
//         }
        
//         window.onload = initMap;
//     </script>
// </body>
// </html>
// ''';

//     widget.controller.loadHtmlString(mapHtml);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return WebViewWidget(controller: widget.controller);
//   }
// }


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
        let map;
        let shopMarker;
        let customerMarker;
        let riderMarker;
        
        let routeSegments = [];
        let currentPassedOverlay = null;
        let isMapReady = false;
        
        const PASSED_COLOR = 'rgba(158, 158, 158, 0.6)';
        const PASSED_LINE_WIDTH = 5;
        
        let isCameraFollowing = true;
        let lastRiderLat = null;
        let lastRiderLon = null;
        let isProgrammaticMove = false;

        // ★ Rider icon — reuse ทุกครั้ง
        const RIDER_ICON = {
            html: '<div style="position: relative; width: 48px; height: 48px; display: flex; align-items: center; justify-content: center;">' +
                '<div style="position: absolute; width: 40px; height: 40px; border-radius: 50%; background: rgba(59, 130, 246, 0.15); border: 2px solid rgba(59, 130, 246, 0.3);"></div>' +
                '<div style="position: absolute; width: 20px; height: 20px; border-radius: 50%; background: #3b82f6; border: 3px solid white; box-shadow: 0 2px 8px rgba(59, 130, 246, 0.6);"></div>' +
                '</div>',
            offset: { x: 24, y: 24 }
        };
        
        function initMap() {
            map = new longdo.Map({
                placeholder: document.getElementById('map'),
                zoom: 15
            });
            
            isMapReady = true;
            setupUserInteractionDetection();
            sendToFlutter({ type: 'mapReady' });
        }
        
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
        
        // ==========================================================
        //  ★★★ FIX: ลบ marker เก่า + สร้างใหม่ทุกครั้ง
        //  เพราะ riderMarker.location() ไม่ขยับ custom HTML icon
        // ==========================================================
        function updateRiderPosition(lat, lon) {
            if (!map) return;
            
            lastRiderLat = lat;
            lastRiderLon = lon;
            
            // ลบ marker เก่า
            if (riderMarker) {
                try { map.Overlays.remove(riderMarker); } catch(e) {}
                riderMarker = null;
            }
            
            // สร้างใหม่ตำแหน่งใหม่
            riderMarker = new longdo.Marker(
                { lon: lon, lat: lat },
                { title: 'You', icon: RIDER_ICON }
            );
            map.Overlays.add(riderMarker);
            
            if (isCameraFollowing) {
                moveCameraTo(lon, lat);
            }
            
            if (routeSegments.length > 0) {
                snapAndGrayOutPassed(lat, lon);
            }
        }

        // addRiderMarker — ใช้ตอนเริ่มต้นครั้งแรก
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
        
        function drawRoute(geoJsonString) {
            if (!map) return;
            clearRoute();
            
            try {
                const geoJson = JSON.parse(geoJsonString);
                if (!geoJson.features || geoJson.features.length === 0) return;
                
                geoJson.features.forEach((feature, index) => {
                    if (feature.geometry && feature.geometry.type === 'LineString') {
                        const coordinates = feature.geometry.coordinates;
                        if (!coordinates || coordinates.length < 2) return;
                        
                        const locations = coordinates.map(coord => ({
                            lon: coord[0], lat: coord[1]
                        }));
                        
                        const lineColor = 'rgba(59, 130, 246, 0.8)';
                        const polyline = new longdo.Polyline(locations, {
                            lineWidth: 5, lineColor: lineColor
                        });
                        map.Overlays.add(polyline);
                        
                        routeSegments.push({
                            id: index,
                            overlay: polyline,
                            locations: locations,
                            originalLocations: [...locations],
                            color: lineColor,
                            passed: false,
                            passedOverlay: null,
                        });
                    }
                });
            } catch (e) {}
        }
        
        function snapAndGrayOutPassed(riderLat, riderLon) {
            if (routeSegments.length === 0) return;
            const riderLoc = { lon: riderLon, lat: riderLat };
            
            let minDist = Infinity;
            let closestSegIdx = -1;
            
            for (let i = 0; i < routeSegments.length; i++) {
                const seg = routeSegments[i];
                if (seg.passed) continue;
                try {
                    if (seg.overlay) {
                        const dist = seg.overlay.distance(riderLoc);
                        if (typeof dist === 'number' && dist < minDist) {
                            minDist = dist;
                            closestSegIdx = i;
                        }
                    }
                } catch (e) {
                    const dist = manualMinDistToPolyline(riderLoc, seg.locations);
                    if (dist < minDist) { minDist = dist; closestSegIdx = i; }
                }
            }
            
            if (minDist > 50 || closestSegIdx === -1) return;
            if (minDist > 30) return;
            
            const closestSeg = routeSegments[closestSegIdx];
            const locs = closestSeg.locations;
            let snapPoint = null;
            let snapSegmentIdx = 0;
            let bestDist = Infinity;
            
            for (let j = 0; j < locs.length - 1; j++) {
                const projected = projectPointOnSegment(riderLoc, locs[j], locs[j + 1]);
                const d = longdo.Util.distance([riderLoc, projected]);
                if (d < bestDist) { bestDist = d; snapPoint = projected; snapSegmentIdx = j; }
            }
            if (!snapPoint) return;
            
            for (let i = 0; i < closestSegIdx; i++) {
                if (!routeSegments[i].passed) markSegmentAsPassed(i);
            }
            updateCurrentSegment(closestSegIdx, snapPoint, snapSegmentIdx);
            
            let totalRemaining = 0;
            for (let i = 0; i < routeSegments.length; i++) {
                const seg = routeSegments[i];
                if (!seg.passed && seg.locations && seg.locations.length >= 2) {
                    totalRemaining += longdo.Util.distance(seg.locations);
                }
            }
            sendToFlutter({ type: 'distanceUpdated', distance: totalRemaining });
        }
        
        function markSegmentAsPassed(segIdx) {
            const seg = routeSegments[segIdx];
            seg.passed = true;
            if (seg.overlay) { map.Overlays.remove(seg.overlay); seg.overlay = null; }
            if (seg.passedOverlay) map.Overlays.remove(seg.passedOverlay);
            const locsToUse = seg.originalLocations || seg.locations;
            if (locsToUse && locsToUse.length >= 2) {
                seg.passedOverlay = new longdo.Polyline(locsToUse, {
                    lineWidth: PASSED_LINE_WIDTH, lineColor: PASSED_COLOR,
                });
                map.Overlays.add(seg.passedOverlay);
            }
        }
        
        function updateCurrentSegment(segIdx, snapPoint, snapLocIdx) {
            const seg = routeSegments[segIdx];
            const locs = seg.locations;
            const passedLocations = [...locs.slice(0, snapLocIdx + 1), snapPoint];
            const remainingLocations = [snapPoint, ...locs.slice(snapLocIdx + 1)];
            
            if (currentPassedOverlay) { map.Overlays.remove(currentPassedOverlay); currentPassedOverlay = null; }
            if (passedLocations.length >= 2) {
                currentPassedOverlay = new longdo.Polyline(passedLocations, { lineWidth: PASSED_LINE_WIDTH, lineColor: PASSED_COLOR });
                map.Overlays.add(currentPassedOverlay);
            }
            if (seg.overlay) { map.Overlays.remove(seg.overlay); seg.overlay = null; }
            if (remainingLocations.length >= 2) {
                const newPolyline = new longdo.Polyline(remainingLocations, { lineWidth: 5, lineColor: seg.color });
                map.Overlays.add(newPolyline);
                seg.overlay = newPolyline;
                seg.locations = remainingLocations;
            } else {
                seg.passed = true;
                seg.locations = [];
            }
        }
        
        function projectPointOnSegment(point, segStart, segEnd) {
            const A = point.lon - segStart.lon, B = point.lat - segStart.lat;
            const C = segEnd.lon - segStart.lon, D = segEnd.lat - segStart.lat;
            const dot = A * C + B * D, lenSq = C * C + D * D;
            let t = lenSq !== 0 ? dot / lenSq : -1;
            if (t < 0) t = 0; if (t > 1) t = 1;
            return { lon: segStart.lon + t * C, lat: segStart.lat + t * D };
        }
        
        function manualMinDistToPolyline(point, locations) {
            let minDist = Infinity;
            for (let i = 0; i < locations.length - 1; i++) {
                const projected = projectPointOnSegment(point, locations[i], locations[i + 1]);
                const d = longdo.Util.distance([point, projected]);
                if (d < minDist) minDist = d;
            }
            return minDist;
        }
        
        function clearRoute() {
            if (!map) return;
            routeSegments.forEach(seg => {
                if (seg.overlay) map.Overlays.remove(seg.overlay);
                if (seg.passedOverlay) map.Overlays.remove(seg.passedOverlay);
            });
            if (currentPassedOverlay) { map.Overlays.remove(currentPassedOverlay); currentPassedOverlay = null; }
            routeSegments = [];
        }
        
        function sendToFlutter(data) {
            if (window.FlutterChannel) window.FlutterChannel.postMessage(JSON.stringify(data));
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