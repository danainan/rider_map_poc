# Copilot Instructions for Rider Map POC

## Architecture Overview
Feature-first Clean Architecture with BLoC pattern. Each module is self-contained under `lib/modules/`.

```
lib/modules/rider_map/
├── rider_map.dart          # Barrel export (import this, not individual files)
├── bloc/                   # BLoC: Events → State transformations
├── data/                   # Data sources (MockRouteData for POC)
├── pages/                  # Screen widgets (provide BLoC via BlocProvider)
└── widgets/                # Stateless UI components
```

## Key Patterns

### Adding Features (strict order)
1. Define event in `bloc/rider_map_event.dart` extending `RiderMapEvent`
2. Add state fields in `bloc/rider_map_state.dart` with `copyWith` support
3. Register handler in BLoC constructor: `on<NewEvent>(_onNewEvent);`
4. Implement `_onNewEvent` handler using `emit(state.copyWith(...))`

### BLoC Conventions
- Events/States must extend `Equatable` with `props` override
- Camera operations use `GoogleMapController` stored in BLoC (not state)
- Timer-based animations: start in event handler, cancel in `close()`
- Example pattern from `rider_map_bloc.dart`:
```dart
void _onStartRiderSimulation(...) {
  emit(state.copyWith(isSimulationRunning: true));
  _simulationTimer = Timer.periodic(Duration(milliseconds: 800), (_) => add(UpdateRiderPosition()));
}
```

### Custom Markers (Canvas-based)
Create markers via `_createCustomMarkerBitmap()` using `Canvas` drawing—no image assets needed. Pattern: draw circle → border → icon using `TextPainter` for Material icons.

### Mock Data Strategy
`MockRouteData` provides hardcoded Bangkok coordinates (Siam Paragon → Central World). No API calls in POC. Modify `getMockRoutePoints()` to change route.

## Quick Commands
```bash
flutter pub get && flutter run          # Run app
flutter analyze                         # Check for issues
```

## Google Maps Setup (Required)
- **Android**: Add API key to `android/app/src/main/AndroidManifest.xml` as `com.google.android.geo.API_KEY`
- **iOS**: Call `GMSServices.provideAPIKey()` in `ios/Runner/AppDelegate.swift` before plugin registration

## Widget Patterns
- Pages wrap content in `BlocProvider` + `BlocBuilder`
- Widgets receive callbacks (`VoidCallback`) for actions, not BLoC directly
- Use Dart 3 switch expressions for status-based styling (see `_StatusBadge`)

## Troubleshooting
| Issue | Check |
|-------|-------|
| Map blank | API key configured, SDK enabled in Google Cloud |
| Markers missing | BLoC initialized with `InitializeMap` event |
| Polyline invisible | Width ≥ 3, color has opacity |
