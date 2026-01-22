import 'package:flutter/material.dart';

/// App color palette
final class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.secondary,
    required this.onSecondary,
    required this.surface,
    required this.onSurface,
    required this.background,
    required this.onBackground,
    required this.error,
    required this.onError,
    required this.success,
    required this.onSuccess,
    required this.warning,
    required this.onWarning,
    required this.outline,
    required this.shadow,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDisabled,
    required this.riderMarker,
    required this.destinationMarker,
    required this.routePolyline,
    required this.routePolylineAlt,
  });

  static const light = AppColors(
    primary: Color(0xFF2196F3),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFBBDEFB),
    secondary: Color(0xFFFF9800),
    onSecondary: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF1C1B1F),
    background: Color(0xFFF5F5F5),
    onBackground: Color(0xFF1C1B1F),
    error: Color(0xFFB00020),
    onError: Color(0xFFFFFFFF),
    success: Color(0xFF4CAF50),
    onSuccess: Color(0xFFFFFFFF),
    warning: Color(0xFFFF9800),
    onWarning: Color(0xFF000000),
    outline: Color(0xFFDBDEE6),
    shadow: Color(0x24000000),
    textPrimary: Color(0xFF323643),
    textSecondary: Color(0xFF62646A),
    textDisabled: Color(0xFFCECDCA),
    riderMarker: Color(0xFF2196F3),
    destinationMarker: Color(0xFFE91E63),
    routePolyline: Color(0xFF2196F3),
    routePolylineAlt: Color(0xFFBDBDBD),
  );

  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color secondary;
  final Color onSecondary;
  final Color surface;
  final Color onSurface;
  final Color background;
  final Color onBackground;
  final Color error;
  final Color onError;
  final Color success;
  final Color onSuccess;
  final Color warning;
  final Color onWarning;
  final Color outline;
  final Color shadow;
  final Color textPrimary;
  final Color textSecondary;
  final Color textDisabled;

  // Map specific colors
  final Color riderMarker;
  final Color destinationMarker;
  final Color routePolyline;
  final Color routePolylineAlt;

  @override
  AppColors copyWith({
    Color? primary,
    Color? onPrimary,
    Color? primaryContainer,
    Color? secondary,
    Color? onSecondary,
    Color? surface,
    Color? onSurface,
    Color? background,
    Color? onBackground,
    Color? error,
    Color? onError,
    Color? success,
    Color? onSuccess,
    Color? warning,
    Color? onWarning,
    Color? outline,
    Color? shadow,
    Color? textPrimary,
    Color? textSecondary,
    Color? textDisabled,
    Color? riderMarker,
    Color? destinationMarker,
    Color? routePolyline,
    Color? routePolylineAlt,
  }) {
    return AppColors(
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      secondary: secondary ?? this.secondary,
      onSecondary: onSecondary ?? this.onSecondary,
      surface: surface ?? this.surface,
      onSurface: onSurface ?? this.onSurface,
      background: background ?? this.background,
      onBackground: onBackground ?? this.onBackground,
      error: error ?? this.error,
      onError: onError ?? this.onError,
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      outline: outline ?? this.outline,
      shadow: shadow ?? this.shadow,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textDisabled: textDisabled ?? this.textDisabled,
      riderMarker: riderMarker ?? this.riderMarker,
      destinationMarker: destinationMarker ?? this.destinationMarker,
      routePolyline: routePolyline ?? this.routePolyline,
      routePolylineAlt: routePolylineAlt ?? this.routePolylineAlt,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) {
      return this;
    }
    return AppColors(
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      primaryContainer: Color.lerp(primaryContainer, other.primaryContainer, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      onSecondary: Color.lerp(onSecondary, other.onSecondary, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
      background: Color.lerp(background, other.background, t)!,
      onBackground: Color.lerp(onBackground, other.onBackground, t)!,
      error: Color.lerp(error, other.error, t)!,
      onError: Color.lerp(onError, other.onError, t)!,
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      riderMarker: Color.lerp(riderMarker, other.riderMarker, t)!,
      destinationMarker: Color.lerp(destinationMarker, other.destinationMarker, t)!,
      routePolyline: Color.lerp(routePolyline, other.routePolyline, t)!,
      routePolylineAlt: Color.lerp(routePolylineAlt, other.routePolylineAlt, t)!,
    );
  }
}
