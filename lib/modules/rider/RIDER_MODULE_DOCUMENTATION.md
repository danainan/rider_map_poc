# Rider Module Documentation

## 📋 Overview
Rider Module เป็นระบบแผนที่สำหรับไรเดอร์ส่งอาหาร แสดงตำแหน่งปัจจุบัน เส้นทางไปรับของที่ร้าน และส่งของให้ลูกค้า พร้อมติดตาม GPS แบบ real-time

## 🏗️ Architecture
```
rider/
├── cubit/              # State Management (Cubit pattern)
│   ├── rider_cubit.dart
│   └── rider_state.dart
├── data/               # Mock Data
│   └── rider_mock_data.dart
├── pages/              # Screen UI
│   └── rider_screen.dart
└── widgets/            # Reusable Components
    ├── location_permission_view.dart
    ├── location_service_dialog.dart
    ├── rider_bottom_sheet.dart
    ├── rider_map_view.dart
    └── rider_marker_builder.dart
```

---

## 🌐 1. API Integration

### 1.1 Google Routes API - Compute Routes

**Endpoint:**
```
POST https://routes.googleapis.com/directions/v2:computeRoutes
```

**Headers:**
```json
{
  "Content-Type": "application/json",
  "X-Goog-Api-Key": "<YOUR_GOOGLE_MAPS_API_KEY>",
  "X-Goog-FieldMask": "routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline"
}
```

**Request Body:**
```json
{
  "origin": {
    "location": {
      "latLng": {
        "latitude": 13.7563,
        "longitude": 100.5018
      }
    }
  },
  "destination": {
    "location": {
      "latLng": {
        "latitude": 13.7466,
        "longitude": 100.5347
      }
    }
  },
  "travelMode": "TWO_WHEELER",
  "routingPreference": "TRAFFIC_AWARE",
  "computeAlternativeRoutes": false,
  "languageCode": "th",
  "units": "METRIC"
}
```

**Request Parameters:**
| Parameter | Type | Description | Required |
|-----------|------|-------------|----------|
| `origin.location.latLng` | Object | จุดเริ่มต้นเส้นทาง (LatLng) | ✅ Yes |
| `destination.location.latLng` | Object | จุดหมายปลายทาง (LatLng) | ✅ Yes |
| `travelMode` | String | ประเภทยานพาหนะ: `TWO_WHEELER`, `DRIVE`, `WALK`, `BICYCLE` | ✅ Yes |
| `routingPreference` | String | การคำนวณเส้นทาง: `TRAFFIC_AWARE` (คำนึงถึงการจราจร) | ❌ No |
| `computeAlternativeRoutes` | Boolean | คำนวณเส้นทางทางเลือก | ❌ No |
| `languageCode` | String | ภาษาที่ต้องการ (เช่น `th`, `en`) | ❌ No |
| `units` | String | หน่วยวัด: `METRIC` (กม.), `IMPERIAL` (ไมล์) | ❌ No |

**Response Success (200):**
```json
{
  "routes": [
    {
      "distanceMeters": 2547,
      "duration": "485s",
      "polyline": {
        "encodedPolyline": "w~r}Auwa_RAgAXcAJk@VgAB[Js@Lw@"
      }
    }
  ]
}
```

**Response Fields:**
| Field | Type | Description |
|-------|------|-------------|
| `routes` | Array | รายการเส้นทาง (เลือกเส้นทางแรก [0]) |
| `distanceMeters` | Integer | ระยะทางรวมเป็นเมตร |
| `duration` | String | เวลาโดยประมาณ (รูปแบบ: "485s" = 485 วินาที) |
| `polyline.encodedPolyline` | String | เส้นทางแบบเข้ารหัส (ต้อง decode ก่อนใช้) |

**Response Error (400/404/500):**
```json
{
  "error": {
    "code": 400,
    "message": "Invalid request",
    "status": "INVALID_ARGUMENT"
  }
}
```

**การใช้งานใน Code:**
- **Service:** `RiderRouteServiceImpl`
- **Method:** `getMultiStopRoute()`
- **Flow:**
  1. เรียก API 2 ครั้ง: Rider → Shop และ Shop → Customer
  2. Decode polyline เป็น `List<LatLng>`
  3. Format ระยะทางและเวลา
  4. Return `RiderMultiRouteResult`

**ตัวอย่าง Response ที่ประมวลผลแล้ว:**
```dart
RiderMultiRouteResult(
  riderToShopPoints: [LatLng(13.7563, 100.5018), ...],
  shopToCustomerPoints: [LatLng(13.7466, 100.5347), ...],
  totalDistance: "2.5 กม. + 0.8 กม.",
  totalDuration: "8 นาที + 3 นาที",
  riderToShopDistance: "2.5 กม.",
  riderToShopDuration: "8 นาที",
  shopToCustomerDistance: "0.8 กม.",
  shopToCustomerDuration: "3 นาที",
  isSuccess: true,
  errorMessage: null
)
```

---

### 1.2 GPS Location Tracking (Geolocator)

**Service:** `GeolocatorService` (Wrapper ของ geolocator package)

**Methods:**

#### `determinePosition()`
**Description:** ดึงตำแหน่งปัจจุบันครั้งเดียว

**Return:**
```dart
Position {
  latitude: 13.7563,
  longitude: 100.5018,
  accuracy: 5.0,  // เมตร
  altitude: 10.5,
  heading: 90.0,  // องศา (0-360)
  speed: 0.0,     // m/s
  timestamp: 2026-02-04T10:30:00.000Z
}
```

#### `getPositionStream()`
**Description:** Stream สำหรับติดตาม GPS แบบ real-time

**Configuration:**
```dart
LocationSettings {
  accuracy: LocationAccuracy.high,  // ความแม่นยำสูงสุด
  distanceFilter: 5,                // อัพเดตทุก 5 เมตร
  timeLimit: null                   // ไม่จำกัดเวลา
}
```

**Stream Data:**
```dart
Stream<Position> {
  // Emit ทุกครั้งที่เคลื่อนที่ > 5 เมตร
  Position(lat: 13.7563, lng: 100.5018),
  Position(lat: 13.7564, lng: 100.5020),
  ...
}
```

---

## ⚙️ 2. Configuration

### 2.1 Mock Data Configuration
**File:** `rider_mock_data.dart`

```dart
class RiderMockData {
  // ตำแหน่งร้านค้า
  static const LatLng shopLocation = LatLng(13.7466, 100.5347);
  static const String shopName = 'ร้านอาหาร Siam Paragon';
  static const String shopAddress = 'สยามพารากอน, ปทุมวัน, กรุงเทพฯ';

  // ตำแหน่งลูกค้า
  static const LatLng customerLocation = LatLng(13.7468, 100.5392);
  static const String customerName = 'คุณสมชาย';
  static const String customerAddress = 'เซ็นทรัลเวิลด์, ปทุมวัน, กรุงเทพฯ';

  // ค่าเริ่มต้นแผนที่
  static const LatLng mapCenter = LatLng(13.7563, 100.5018);
  static const double defaultZoom = 15.0;
}
```

**วิธีแก้ไข:**
- เปลี่ยน `shopLocation` = พิกัดร้านจริง
- เปลี่ยน `customerLocation` = พิกัดลูกค้าจริง
- ใช้ Google Maps หาพิกัดได้จากการคลิกขวา → "What's here?"

---

### 2.2 Google Maps API Key

**Android:** `android/app/src/main/AndroidManifest.xml`
```xml
<manifest>
  <application>
    <meta-data
      android:name="com.google.android.geo.API_KEY"
      android:value="YOUR_ANDROID_API_KEY"/>
  </application>
</manifest>
```

**iOS:** `ios/Runner/AppDelegate.swift`
```swift
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(...) -> Bool {
    GMSServices.provideAPIKey("YOUR_IOS_API_KEY")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

**Code:** `lib/core/constants/api_constants.dart`
```dart
class ApiConstants {
  static const googleMapsApiKey = 'YOUR_API_KEY_FOR_ROUTES_API';
}
```

---

### 2.3 GPS Tracking Settings

**File:** `lib/data/services/geolocator/geolocator_service_impl.dart`

```dart
LocationSettings(
  accuracy: LocationAccuracy.high,     // ปรับความแม่นยำ
  distanceFilter: 5,                   // อัพเดตทุก X เมตร
)
```

**ค่าที่ปรับได้:**
| Setting | Options | Description |
|---------|---------|-------------|
| `accuracy` | `best`, `high`, `medium`, `low` | ความแม่นยำ GPS (high = แบต‌เตอรี่เปลืองมาก) |
| `distanceFilter` | `0-100` เมตร | อัพเดตทุก X เมตร (0 = อัพเดตทุกครั้ง) |

---

### 2.4 Map Styling

**File:** `rider_map_view.dart`

```dart
GoogleMap(
  myLocationEnabled: false,         // ซ่อนปุ่ม My Location
  myLocationButtonEnabled: false,   // ซ่อนปุ่ม Center
  zoomControlsEnabled: false,       // ซ่อนปุ่ม Zoom
  mapToolbarEnabled: false,         // ซ่อน Toolbar (Android)
)
```

**Polyline Configuration:**
```dart
Polyline(
  color: Colors.blue,                       // สีเส้นทาง
  width: 5,                                 // ความหนา
  patterns: [PatternItem.dash(10),         // เส้นประ (10px)
             PatternItem.gap(10)]          // ช่องว่าง (10px)
)
```

---

## 📊 3. State Management (RiderState)

### 3.1 State Fields

```dart
class RiderState {
  // Permission & Location Service
  final PermissionRequestStatus permissionStatus;        // สถานะขอ permission
  final LocationServiceStatus locationServiceStatus;     // สถานะ GPS
  final bool showLocationServiceDialog;                  // แสดง dialog เปิด GPS

  // Rider Position
  final LatLng? riderPosition;                          // ตำแหน่งปัจจุบัน
  final bool isTrackingLocation;                        // กำลังติดตาม GPS

  // Route Data
  final RouteLoadingStatus routeLoadingStatus;          // สถานะโหลดเส้นทาง
  final List<LatLng> riderToShopPoints;                 // จุดเส้นทาง rider → shop
  final List<LatLng> shopToCustomerPoints;              // จุดเส้นทาง shop → customer
  final String riderToShopDistance;                     // ระยะทาง rider → shop
  final String riderToShopDuration;                     // เวลา rider → shop
  final String shopToCustomerDistance;                  // ระยะทาง shop → customer
  final String shopToCustomerDuration;                  // เวลา shop → customer
  final String totalDistance;                           // ระยะทางรวม
  final String totalDuration;                           // เวลารวม
  final String? routeErrorMessage;                      // Error message

  // Delivery Status
  final RiderDeliveryStatus deliveryStatus;             // สถานะการส่งของ

  // Camera Control
  final RiderCameraAction cameraAction;                 // คำสั่งควบคุมกล้อง
  final bool isFollowingRider;                          // ติดตามไรเดอร์อัตโนมัติ
  final bool isMapReady;                                // แผนที่โหลดเสร็จ
}
```

### 3.2 Enums

#### PermissionRequestStatus
```dart
enum PermissionRequestStatus {
  initial,       // ยังไม่ขอ
  requesting,    // กำลังขอ
  granted,       // อนุญาต ✅
  denied,        // ปฏิเสธ ❌
  permanentlyDenied  // ปฏิเสธถาวร (ต้องเข้า Settings)
}
```

#### LocationServiceStatus
```dart
enum LocationServiceStatus {
  initial,      // ยังไม่ตรวจสอบ
  checking,     // กำลังตรวจสอบ
  enabled,      // เปิด GPS ✅
  disabled      // ปิด GPS ❌
}
```

#### RouteLoadingStatus
```dart
enum RouteLoadingStatus {
  initial,      // ยังไม่โหลด
  loading,      // กำลังโหลด
  loaded,       // โหลดเสร็จ ✅
  error         // เกิดข้อผิดพลาด ❌
}
```

#### RiderDeliveryStatus
```dart
enum RiderDeliveryStatus {
  idle,                 // ยังไม่เริ่ม
  headingToShop,        // กำลังไปรับของ 🏍️ → 🏪
  arrivedAtShop,        // ถึงร้านแล้ว 🏪
  headingToCustomer,    // กำลังส่งของ 🏍️ → 👤
  delivered             // ส่งเสร็จแล้ว ✅
}
```

#### RiderCameraAction
```dart
enum RiderCameraAction {
  none,              // ไม่ทำอะไร
  centerOnRider,     // เซ็นเตอร์ที่ไรเดอร์
  fitAllMarkers,     // แสดง Markers ทั้งหมด
  followRider        // ติดตามไรเดอร์
}
```

---

## 🎯 4. Component Functionality

### 4.1 RiderCubit (State Manager)

**ตำแหน่งไฟล์:** `cubit/rider_cubit.dart`

#### Methods & การใช้งาน

| Method | Description | Return | Use Case |
|--------|-------------|--------|----------|
| `initialize()` | เริ่มต้นระบบ (ขอ permission) | `Future<void>` | เรียกตอน `initState()` |
| `requestLocationPermission()` | ขอสิทธิ์เข้าถึง GPS | `Future<void>` | กดปุ่มขอ permission |
| `checkLocationService()` | ตรวจสอบ GPS เปิดหรือไม่ | `Future<void>` | หลังได้ permission |
| `onAppResumed()` | เช็ค GPS เมื่อกลับมาที่แอป | `Future<void>` | `didChangeAppLifecycleState` |
| `onLocationReady()` | เริ่มงานหลัก GPS + โหลดเส้นทาง | `Future<void>` | หลัง GPS พร้อม |
| `startLocationTracking()` | เริ่มติดตาม GPS แบบ real-time | `void` | หลังได้ตำแหน่งแรก |
| `stopLocationTracking()` | หยุดติดตาม GPS | `void` | ออกจากหน้า/Error |
| `loadRoute()` | โหลดเส้นทาง Rider → Shop → Customer | `Future<void>` | Auto เรียกหลัง GPS พร้อม |
| `refreshRoute()` | โหลดเส้นทางใหม่ | `Future<void>` | ดึงลง Refresh |
| `centerOnRider()` | กล้องเซ็นเตอร์ที่ตำแหน่งไรเดอร์ | `void` | กดปุ่ม My Location |
| `fitAllMarkers()` | แสดง Markers ทั้งหมดในหน้าจอ | `void` | กดปุ่ม Fit Route |
| `toggleFollowRider()` | เปิด/ปิดโหมดติดตามไรเดอร์ | `void` | กดปุ่ม Follow |
| `resetCameraAction()` | รีเซ็ต CameraAction (ป้องกันซ้ำ) | `void` | หลังทำ Camera Action |
| `onMapReady()` | แผนที่โหลดเสร็จ | `void` | `onMapCreated` callback |
| `updateDeliveryStatus()` | เปลี่ยนสถานะการส่งของ | `void` | Manual update |
| `arrivedAtShop()` | ถึงร้านแล้ว | `void` | เมื่อถึงจุดหมาย |

---

### 4.2 RiderScreen (หน้าจอหลัก)

**ตำแหน่งไฟล์:** `pages/rider_screen.dart`

**UI Flow:**
```
1. Permission ยังไม่ได้ → แสดง LocationPermissionView
2. GPS ปิดอยู่ → แสดง Loading + Dialog
3. Permission + GPS OK → แสดง RiderMapView + RiderBottomSheet
```

**Features:**
- ✅ ตรวจสอบ permission ตอนเข้าหน้า
- ✅ แสดง dialog เมื่อ GPS ปิด
- ✅ Auto refresh เมื่อกลับมาที่แอป (AppLifecycleState)
- ✅ Loading overlay ขณะโหลดเส้นทาง

---

### 4.3 RiderMapView (แผนที่)

**ตำแหน่งไฟล์:** `widgets/rider_map_view.dart`

**แสดงอะไร:**
- 🗺️ Google Map (โหมด TWO_WHEELER)
- 📍 Rider Marker (ไอคอนมอเตอร์ไซค์)
- 🏪 Shop Marker (ไอคอนร้าน)
- 👤 Customer Marker (ไอคอนลูกค้า)
- 🛣️ Polyline Rider → Shop (สีน้ำเงิน)
- 🛣️ Polyline Shop → Customer (สีเขียว)

**Camera Actions:**
- `centerOnRider` → เซ็นเตอร์ที่ไรเดอร์ (zoom 17)
- `fitAllMarkers` → แสดงทั้ง 3 markers + polylines
- `followRider` → ติดตามไรเดอร์ขณะเคลื่อนที่

**Polyline Behavior:**
| Delivery Status | Rider → Shop | Shop → Customer |
|-----------------|--------------|-----------------|
| `headingToShop` | เส้นตรง (Active) | เส้นประ (Inactive) |
| `headingToCustomer` | เส้นประ | เส้นตรง (Active) |

---

### 4.4 RiderBottomSheet (ข้อมูลเส้นทาง)

**ตำแหน่งไฟล์:** `widgets/rider_bottom_sheet.dart`

**แสดงข้อมูล:**
```
┌─────────────────────────────────────┐
│  ถึงร้าน           ถึงลูกค้า        │
│  🏪 2.5 กม.       👤 0.8 กม.       │
│     8 นาที            3 นาที        │
├─────────────────────────────────────┤
│  [📍] [🎯] [👁️] [🔄]               │
└─────────────────────────────────────┘
```

**ปุ่มควบคุม:**
- 📍 My Location → `centerOnRider()`
- 🎯 Fit Route → `fitAllMarkers()`
- 👁️ Follow Rider → `toggleFollowRider()` (เปิด/ปิด)
- 🔄 Refresh Route → `refreshRoute()`

**Route Info:**
- ระยะทางแบ่งเป็น 2 ช่วง
- เปลี่ยนสี highlight ตาม `deliveryStatus`

---

### 4.5 RiderMarkerBuilder (สร้าง Markers)

**ตำแหน่งไฟล์:** `widgets/rider_marker_builder.dart`

**Marker Icons:**
| Marker | Icon | Size | Color |
|--------|------|------|-------|
| Rider | 🏍️ (two_wheeler) | 80x80 | Orange |
| Shop | 🏪 (store) | 70x70 | Orange |
| Customer | 👤 (person_pin) | 70x70 | Green |

**การสร้าง:**
- ใช้ `Canvas` วาดเป็น `BitmapDescriptor`
- ไม่ใช้ไฟล์รูปภาพ (เบา + ไม่ต้อง manage assets)
- เรียก `initialize()` ครั้งเดียวตอน `initState`

---

## 🔄 5. Data Flow

### 5.1 Initialization Flow
```
RiderScreen.initState()
    ↓
RiderCubit.initialize()
    ↓
requestLocationPermission()
    ↓
[Permission Granted] → checkLocationService()
    ↓
[GPS Enabled] → onLocationReady()
    ↓
┌─────────────────────┬──────────────────────┐
↓                     ↓                      ↓
_getCurrentPosition() startLocationTracking() loadRoute()
                      (Stream GPS)           (Call API)
```

### 5.2 Route Loading Flow
```
loadRoute()
    ↓
RiderRouteService.getMultiStopRoute()
    ↓
┌───────────────────────────┬──────────────────────────┐
↓                           ↓                          ↓
API: Rider → Shop           API: Shop → Customer       
(Polyline + Distance)       (Polyline + Distance)
    ↓                           ↓
┌───────────────────────────────────────────────┘
↓
RiderMultiRouteResult
    ↓
Emit State → UI Update
```

### 5.3 GPS Tracking Flow
```
startLocationTracking()
    ↓
GeolocatorService.getPositionStream()
    ↓
Stream<Position> (ทุก 5 เมตร)
    ↓
_updateRiderPosition(lat, lng)
    ↓
emit(state.copyWith(riderPosition: ...))
    ↓
[isFollowingRider == true] → Animate Camera
```

---

## 🛠️ 6. การแก้ไข & Customize

### 6.1 เปลี่ยนตำแหน่งร้าน/ลูกค้า

**File:** `data/rider_mock_data.dart`
```dart
static const LatLng shopLocation = LatLng(YOUR_LAT, YOUR_LNG);
static const String shopName = 'ชื่อร้านของคุณ';
```

### 6.2 เปลี่ยนสีเส้นทาง

**File:** `widgets/rider_map_view.dart`
```dart
Polyline(
  polylineId: const PolylineId('rider_to_shop'),
  color: Colors.purple,  // เปลี่ยนสี
  width: 8,              // เปลี่ยนความหนา
)
```

### 6.3 เปลี่ยนความแม่นยำ GPS

**File:** `lib/data/services/geolocator/geolocator_service_impl.dart`
```dart
LocationSettings(
  accuracy: LocationAccuracy.best,  // best > high > medium > low
  distanceFilter: 3,                // อัพเดตทุก 3 เมตร
)
```

### 6.4 ปรับ Zoom Level

**File:** `widgets/rider_map_view.dart`
```dart
// เซ็นเตอร์ไรเดอร์
MapUtils.animateCameraTo(
  controller,
  state.riderPosition!,
  zoom: 18.0,  // เปลี่ยนค่า zoom (13-20)
);
```

### 6.5 เพิ่มปุ่มใหม่ใน Bottom Sheet

**File:** `widgets/rider_bottom_sheet.dart`
```dart
IconButton(
  onPressed: () {
    context.read<RiderCubit>().yourNewMethod();
  },
  icon: const Icon(Icons.your_icon),
)
```

---

## ⚠️ 7. Troubleshooting

### ปัญหาที่พบบ่อย

| ปัญหา | สาเหตุ | วิธีแก้ |
|-------|--------|---------|
| แผนที่ขาว/ว่างเปล่า | API Key ไม่ถูกต้อง | เช็ค AndroidManifest.xml / AppDelegate.swift |
| Marker ไม่แสดง | ยังไม่เรียก `initialize()` | เช็ค `RiderMarkerBuilder.initialize()` ใน initState |
| Polyline หาย | Response API ไม่ได้ polyline | เช็ค X-Goog-FieldMask header |
| GPS ไม่อัพเดต | Permission ถูกปฏิเสธ | ขอ permission ใหม่ / เข้า Settings |
| เส้นทางไม่โหลด | API Key หมดโควต้า | เช็ค Google Cloud Console |

---

## 📱 8. Permission Required

### Android
```xml
<!-- AndroidManifest.xml -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

### iOS
```xml
<!-- Info.plist -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>แอปต้องการเข้าถึงตำแหน่งเพื่อแสดงเส้นทางการส่งอาหาร</string>

<key>NSLocationAlwaysUsageDescription</key>
<string>แอปต้องการติดตามตำแหน่งเพื่ออัพเดตเส้นทางแบบ real-time</string>
```

---

## 📦 9. Dependencies

```yaml
dependencies:
  # Maps
  google_maps_flutter: ^2.x.x
  
  # Location
  geolocator: ^10.x.x
  permission_handler: ^11.x.x
  
  # State Management
  flutter_bloc: ^8.x.x
  equatable: ^2.x.x
  
  # DI
  injectable: ^2.x.x
  get_it: ^7.x.x
  
  # HTTP
  http: ^1.x.x
```

---

## 📝 10. ตัวอย่างการใช้งาน

### เรียกใช้หน้า Rider
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const RiderScreen()),
);
```

### ดึง State ปัจจุบัน
```dart
final cubit = context.read<RiderCubit>();
final state = cubit.state;

print('Rider Position: ${state.riderPosition}');
print('Distance to Shop: ${state.riderToShopDistance}');
print('Is Following: ${state.isFollowingRider}');
```

### เปลี่ยนสถานะ Delivery
```dart
context.read<RiderCubit>().updateDeliveryStatus(
  RiderDeliveryStatus.headingToCustomer
);
```

---

## 🎨 11. UI Components Summary

| Widget | Purpose | Input | Output |
|--------|---------|-------|--------|
| RiderScreen | หน้าจอหลัก | - | แสดง UI ตาม State |
| LocationPermissionView | ขอ permission | onRequestPermission | UI ขอสิทธิ์ |
| LocationServiceDialog | เปิด GPS | onOpenSettings | Dialog Alert |
| RiderMapView | แผนที่ | State (markers, polylines) | Google Map |
| RiderBottomSheet | ข้อมูล + ควบคุม | State (distance, duration) | Route Info + Buttons |
| RiderMarkerBuilder | Marker Icons | - | BitmapDescriptor |

---

## 📊 12. ข้อมูลที่ Module บอกได้

### 12.1 ตำแหน่งและการเคลื่อนที่
- ✅ ตำแหน่ง GPS ปัจจุบันของไรเดอร์ (Lat/Lng)
- ✅ ทิศทางการเคลื่อนที่ (Heading)
- ✅ ความเร็ว (Speed)
- ✅ ความแม่นยำ GPS (Accuracy)

### 12.2 เส้นทางและระยะทาง
- ✅ เส้นทางจาก Rider → Shop (Polyline Points)
- ✅ เส้นทางจาก Shop → Customer (Polyline Points)
- ✅ ระยะทางแต่ละช่วง (เมตร/กิโลเมตร)
- ✅ เวลาโดยประมาณ (นาที/ชั่วโมง)
- ✅ ระยะทางรวมทั้งหมด
- ✅ เวลารวมทั้งหมด

### 12.3 สถานะระบบ
- ✅ สถานะ Permission (Granted/Denied)
- ✅ สถานะ GPS (Enabled/Disabled)
- ✅ สถานะการโหลดเส้นทาง (Loading/Loaded/Error)
- ✅ สถานะการส่งของ (Heading to Shop/Delivered)
- ✅ กำลังติดตาม GPS หรือไม่
- ✅ กำลังติดตามไรเดอร์ด้วยกล้องหรือไม่

### 12.4 ข้อมูล Mock (ปัจจุบัน)
- ✅ ตำแหน่งร้าน Siam Paragon
- ✅ ตำแหน่งลูกค้า Central World
- ✅ ชื่อร้าน/ลูกค้า
- ✅ ที่อยู่ร้าน/ลูกค้า

---

## 🔐 13. Security & Best Practices

### ✅ DO
- เก็บ API Key ใน `secrets.properties` (Android) / `Secrets.xcconfig` (iOS)
- ปิด API Key ด้วย Bundle ID / Package Name restrictions
- ใช้ HTTPS เท่านั้น
- Cancel subscription ตอน `dispose()`

### ❌ DON'T
- ไม่ hardcode API Key ใน Dart code
- ไม่ commit API Key ขึ้น Git
- ไม่เปิด API Key แบบ unrestricted

---

## 📚 14. Related Files

```
Core Services:
- lib/data/services/geolocator/geolocator_service.dart
- lib/data/services/rider/rider_route_service.dart
- lib/data/services/permission_status/app_permission_status_service.dart

Utils:
- lib/core/utils/map_utils.dart

Constants:
- lib/core/constants/api_constants.dart

DI:
- lib/core/di/injectable.dart
```

---

## 🚀 15. Future Enhancements

### แนะนำฟีเจอร์ที่ควรเพิ่ม:
- [ ] Voice Navigation (นำทาง TTS)
- [ ] Offline Map Support
- [ ] Multi-language Support
- [ ] Night Mode Map Style
- [ ] ETA Calculation (เวลาถึงที่แม่นยำกว่า)
- [ ] Traffic Layer Toggle
- [ ] Route Alternatives (เลือกเส้นทางอื่น)
- [ ] Geofencing (แจ้งเตือนเมื่อใกล้ถึง)

---

**Document Version:** 1.0  
**Last Updated:** 2026-02-04  
**Author:** Rider Map POC Team
