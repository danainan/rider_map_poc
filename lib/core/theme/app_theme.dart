import 'package:flutter/material.dart';
import 'package:rider_map_poc/core/theme/app_colors.dart';
import 'package:rider_map_poc/core/theme/app_typography.dart';

/// App theme extension for custom theming
final class AppTheme extends ThemeExtension<AppTheme> {
  const AppTheme({
    required this.colors,
    required this.typography,
  });

  static final light = AppTheme(
    colors: AppColors.light,
    typography: AppTypography.typography,
  );

  final AppColors colors;
  final AppTypography typography;

  @override
  AppTheme copyWith({
    AppColors? colors,
    AppTypography? typography,
  }) {
    return AppTheme(
      colors: colors ?? this.colors,
      typography: typography ?? this.typography,
    );
  }

  @override
  AppTheme lerp(ThemeExtension<AppTheme>? other, double t) {
    if (other is! AppTheme) {
      return this;
    }
    return AppTheme(
      colors: colors.lerp(other.colors, t),
      typography: typography,
    );
  }
}

/// Extension for easy access to AppTheme
extension AppThemeX on BuildContext {
  AppTheme get appTheme => Theme.of(this).extension<AppTheme>()!;
  AppColors get colors => appTheme.colors;
  AppTypography get typography => appTheme.typography;
}
