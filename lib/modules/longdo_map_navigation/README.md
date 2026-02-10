# Longdo Map Navigation Module

## Overview
Module สำหรับการนำทาง (Navigation) โดยใช้ Longdo Map API พร้อมระบบ snap-to-polyline เพื่อให้ตำแหน่ง rider อยู่บนเส้นทางเสมอ

**🌟 Auto-Start Navigation**: เมื่อเข้ามาหน้าจอและได้รับตำแหน่งปัจจุบัน จะแสดงเส้นทางและเริ่มนำทางอัตโนมัติทันที ไม่ต้องกดปุ่ม

## Features

### 1. Permission & Location Management
- ตรวจสอบ Location Permission โดยใช้ `AppPermissionStatusService`
- ตรวจสอบ Location Service โดยใช้ `GeolocatorService`
- แสดง Dialog เมื่อ permission หรือ location service ไม่พร้อม

### 2. Mock Locations & Markers
- ร้านค้า (Shop): Siam Paragon Food Court
- ลูกค้า (Customer): Central World
- แสดงมาร์กเกอร์บนแผนที่พร้อมไอคอนและข้อมูล

### 3. Auto Route Calculation ⭐
- **คำนวณเส้นทางอัตโนมัติ** เมื่อได้ตำแหน่งปัจจุบันของ rider
- เส้นทางเริ่มต้นจาก **ตำแหน่งปัจจุบัน** → Shop → Customer
- ใช้ `LongdoRoutingService` (GeoJSON endpoint) เพื่อรับเส้นทาง
- วาด Polyline แต่ละ segment บนแผนที่ทันที

### 4. Rider Tracking
- Tracking ตำแหน่ง rider แบบ real-time ด้วย `GeolocatorService.getPositionStream()`
- อัพเดทตำแหน่งทุก 5 เมตร
- แสดงมาร์กเกอร์ rider บนแผนที่
- **เริ่มอัตโนมัติ** เมื่อได้เส้นทาง

### 5. Snap-to-Polyline Algorithm
เมื่อมีการอัพเดทตำแหน่ง rider:
1. **หา Polyline ที่ใกล้ที่สุด**: ใช้ `Polyline.distance()` API ของ Longdo Map
2. **คำนวณจุด Snap**: ใช้ projection คำนวณหาจุดที่ใกล้ที่สุดบน line segment
3. **ตรวจสอบระยะห่าง**:
   - ถ้า < 100 เมตร: Snap ตำแหน่ง rider ไปบนเส้นถนน
   - ถ้า >= 100 เมตร: ถือว่า off-route และยิง route ใหม่
4. **อัพเดท Polyline**: ลบ segment ที่ผ่านแล้ว และวาด segment ปัจจุบันใหม่โดยเริ่มจากจุดที่ snap

### 6. Off-Route Detection
- เมื่อ rider ออกนอกเส้นทาง (ระยะห่าง > 100m)
- ระบบจะคำนวณเส้นทางใหม่อัตโนมัติ

## Architecture

```
lib/modules/longdo_map_navigation/
├── longdo_map_navigation.dart          # Barrel export
├── cubit/
│   ├── longdo_map_navigation_cubit.dart    # Business logic
│   └── longdo_map_navigation_state.dart    # State management
├── data/
│   └── longdo_navigation_mock_data.dart    # Mock locations
├── screen/
│   └── longdo_map_navigation.dart          # Main screen
└── widgets/
    └── longdo_map_navigation_widget.dart   # WebView map widget
```

## Key Components

### CubitLongdoMapNavigationCubit
- `initialize()`: เริ่มต้น - ขอ permission
- `startNavigation()`: เริ่มนำทาง - คำนวณเส้นทางและ tracking
- `stopNavigation()`: หยุดนำทาง
- `refreshRoute()`: คำนวณเส้นทางใหม่
- `_snapToPolyline()`: Algorithm สำหรับ snap ตำแหน่ง

### State
ข้อมูลสำคัญใน state:
- `currentLat`, `currentLon`: ตำแหน่งปัจจุบันของ rider
- `snappedLat`, `snappedLon`: ตำแหน่งหลัง snap
- `routeFeatures`: รายการ polyline segments จาก routing API
- `currentFeatureIndex`: Index ของ segment ที่ rider อยู่
- `isNavigating`: สถานะการนำทาง
- `isTracking`: สถานะการ track GPS

### WebView Widget
- ใช้ Longdo Map JavaScript API
- มี JavaScript functions:
  - `moveRider(lat, lon)`: ขยับมาร์กเกอร์ rider
  - `drawRoute(routeJson)`: วาด polyline จาก GeoJSON
  - `findSnapPoint(lon, lat)`: หาจุด snap บน polyline
  - `updatePolylineAfterSnap()`: อัพเดท polyline หลัง snap
  - `fitBounds()`: ปรับมุมกล้องให้เห็นทุก markers

## Usage

```dart
import 'package:rider_map_poc/modules/longdo_map_navigation/longdo_map_navigation.dart';

// Navigate to the screen
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const LongDoMapNavigation(),
  ),
);

// เมื่อเข้ามาหน้าจอ:
// 1. ระบบขอ Location Permission
// 2. เมื่อได้ permission แล้ว จะดึงตำแหน่งปัจจุบัน
// 3. ⭐ คำนวณเส้นทางจากตำแหน่งปัจจุบัน → Shop → Customer ทันที
// 4. เริ่ม tracking GPS และนำทางอัตโนมัติ
// 5. แสดงเส้นทางบนแผนที่พร้อม snap-to-polyline
```

## Auto-Start Navigation Flow

```
User opens screen
   ↓
Request Permission
   ↓
Get Current Location (GPS)
   ↓
⭐ Auto Calculate Route
   ├─ Rider → Shop
   └─ Shop → Customer
   ↓
Draw Route on Map (GeoJSON polylines)
   ↓
⭐ Auto Start GPS Tracking
   ↓
Navigate with Snap-to-Polyline
```

## Snap-to-Polyline Algorithm Details

### 1. Point-to-Line Distance Calculation
```dart
// หาจุดที่ใกล้ที่สุดบน line segment (p1 -> p2) จากจุด (current)
Map<String, double> _findClosestPointOnLineSegment(
  double currentLat, double currentLon,
  double p1Lat, double p1Lon,
  double p2Lat, double p2Lon,
) {
  // Vector projection
  final dx = p2Lon - p1Lon;
  final dy = p2Lat - p1Lat;
  
  // Parameter t คือตำแหน่งบนเส้น (0 = p1, 1 = p2)
  final t = ((currentLon - p1Lon) * dx + (currentLat - p1Lat) * dy) / 
            (dx * dx + dy * dy);
  
  // จำกัด t ให้อยู่ใน [0, 1]
  final tClamped = t.clamp(0.0, 1.0);
  
  return {
    'lat': p1Lat + tClamped * dy,
    'lon': p1Lon + tClamped * dx,
  };
}
```

### 2. Haversine Distance
```dart
// คำนวณระยะห่างจริงบนทรงกลม (เมตร)
double _calculateDistance(
  double lat1, double lon1,
  double lat2, double lon2,
) {
  const earthRadius = 6371000.0; // เมตร
  
  final dLat = _degreesToRadians(lat2 - lat1);
  final dLon = _degreesToRadians(lon2 - lon1);
  
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
      sin(dLon / 2) * sin(dLon / 2);
  
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  
  return earthRadius * c;
}
```

### 3. Snap Process Flow
```
1. GPS อัพเดทตำแหน่งใหม่
   ↓
2. วนหาทุก route segments (เริ่มจาก currentFeatureIndex)
   ├─ คำนวณระยะห่างจาก segment
   ├─ หาจุดที่ใกล้ที่สุดใน segment นั้น
   └─ เก็บ segment ที่ใกล้ที่สุด
   ↓
3. Check ระยะห่าง
   ├─ < 50m → หยุดค้นหา (ใกล้พอแล้ว)
   ├─ < 100m → Snap ตำแหน่ง
   └─ >= 100m → Off-route (ยิง route ใหม่)
   ↓
4. อัพเดท state
   ├─ snappedLat, snappedLon
   ├─ currentFeatureIndex (ถ้าข้ามไป segment ใหม่)
   └─ แจ้ง JavaScript ให้อัพเดท polyline
```

## Dependencies

- `flutter_bloc`: State management
- `geolocator`: GPS tracking
- `permission_handler`: Permission management
- `webview_flutter`: Longdo Map embedding
- `injectable`: Dependency injection
- `equatable`: State comparison

## Mock Data

ตำแหน่งทดสอบ (Bangkok):
- **Shop**: Siam Paragon (13.7466, 100.5347)
- **Customer**: Central World (13.7468, 100.5392)
- ระยะห่าง ~500 เมตร

## Notes

- ใช้ Longdo Map JavaScript API ผ่าน WebView
- การ snap ช่วยลด GPS drift และทำให้การนำทางราบรื่น
- ระบบจะลบ polyline ที่ผ่านไปแล้ว เพื่อแสดงเฉพาะเส้นทางข้างหน้า
- Off-route detection ทำงานอัตโนมัติ และคำนวณเส้นทางใหม่
