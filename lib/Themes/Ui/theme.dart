import "package:flutter/material.dart";

class AppThemes {
  final TextTheme textTheme;
  const AppThemes(this.textTheme);

  // ===================================================================
  // LIGHT — clean clinical blue + healing teal
  // ===================================================================
  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,

      // Primary — medical blue (trust, professionalism)
      primary: Color(0xff0b6fb8),
      surfaceTint: Color(0xff0b6fb8),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xffd5e9ff),
      onPrimaryContainer: Color(0xff001d34),

      // Secondary — muted teal (calm, healing)
      secondary: Color(0xff2b7a78),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xffd2eeec),
      onSecondaryContainer: Color(0xff00201f),

      // Tertiary — soft cyan (freshness)
      tertiary: Color(0xff1c8a94),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xffcef4f7),
      onTertiaryContainer: Color(0xff001f23),

      // Error — clean medical red
      error: Color(0xffc62828),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffffebee),
      onErrorContainer: Color(0xff4a0002),

      // Surfaces — bright, high-contrast clinical white
      surface: Color(0xFFFCFDFF),
      onSurface: Color(0xff101417),
      onSurfaceVariant: Color(0xff41484d),
      outline: Color(0xff71787e),
      outlineVariant: Color(0xffc1c7ce),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff2d3135),
      inversePrimary: Color(0xff9dcdff),

      // Fixed (Material 3 role slots)
      primaryFixed: Color(0xffd5e9ff),
      onPrimaryFixed: Color(0xff001d34),
      primaryFixedDim: Color(0xff9dcdff),
      onPrimaryFixedVariant: Color(0xff00497d),

      secondaryFixed: Color(0xffd2eeec),
      onSecondaryFixed: Color(0xff00201f),
      secondaryFixedDim: Color(0xffa8d3d0),
      onSecondaryFixedVariant: Color(0xff155e5c),

      tertiaryFixed: Color(0xffcef4f7),
      onTertiaryFixed: Color(0xff001f23),
      tertiaryFixedDim: Color(0xffa1d8dc),
      onTertiaryFixedVariant: Color(0xff0c656c),

      // Surface tiers — very subtle grey shifts
      surfaceDim: Color(0xffd9dde1),
      surfaceBright: Color(0xFFFCFDFF),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff6f8fa),
      surfaceContainer: Color(0xffeff2f5),
      surfaceContainerHigh: Color(0xffe9ecef),
      surfaceContainerHighest: Color(0xffe2e6e9),
    );
  }

  ThemeData light() {
    return theme(lightScheme(), true);
  }

  // ===================================================================
  // DARK — deep navy hospital-at-night
  // ===================================================================
  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,

      // Primary — bright cyan-blue, easy on the eyes
      primary: Color(0xff7dc4ff),
      surfaceTint: Color(0xff7dc4ff),
      onPrimary: Color(0xff003257),
      primaryContainer: Color(0xff00497d),
      onPrimaryContainer: Color(0xffd5e9ff),

      // Secondary — healing teal
      secondary: Color(0xff8fd0cd),
      onSecondary: Color(0xff003735),
      secondaryContainer: Color(0xff155e5c),
      onSecondaryContainer: Color(0xffd2eeec),

      // Tertiary — soft cyan
      tertiary: Color(0xff85cfd6),
      onTertiary: Color(0xff003a3f),
      tertiaryContainer: Color(0xff0c656c),
      onTertiaryContainer: Color(0xffcef4f7),

      // Error — softer red for dark mode
      error: Color(0xffff8a80),
      onError: Color(0xff5f0003),
      errorContainer: Color(0xff8c0009),
      onErrorContainer: Color(0xffffdad6),

      // Surfaces — deep, cool navy-black (easier than pure black)
      surface: Color(0xff101417),
      onSurface: Color(0xffe2e6e9),
      onSurfaceVariant: Color(0xffc1c7ce),
      outline: Color(0xff8b9198),
      outlineVariant: Color(0xff41484d),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe2e6e9),
      inversePrimary: Color(0xff0b6fb8),

      primaryFixed: Color(0xffd5e9ff),
      onPrimaryFixed: Color(0xff001d34),
      primaryFixedDim: Color(0xff9dcdff),
      onPrimaryFixedVariant: Color(0xff00497d),

      secondaryFixed: Color(0xffd2eeec),
      onSecondaryFixed: Color(0xff00201f),
      secondaryFixedDim: Color(0xffa8d3d0),
      onSecondaryFixedVariant: Color(0xff155e5c),

      tertiaryFixed: Color(0xffcef4f7),
      onTertiaryFixed: Color(0xff001f23),
      tertiaryFixedDim: Color(0xffa1d8dc),
      onTertiaryFixedVariant: Color(0xff0c656c),

      surfaceDim: Color(0xff101417),
      surfaceBright: Color(0xff363a3e),
      surfaceContainerLowest: Color(0xff0b0e11),
      surfaceContainerLow: Color(0xff181c1f),
      surfaceContainer: Color(0xff1c2023),
      surfaceContainerHigh: Color(0xff262a2e),
      surfaceContainerHighest: Color(0xff313539),
    );
  }

  ThemeData dark() {
    return theme(darkScheme(), false);
  }

  // ===================================================================
  // Theme builder — same as before, with medical tuning
  // ===================================================================
  ThemeData theme(ColorScheme colorScheme, bool isLight) => ThemeData(
    useMaterial3: true,
    fontFamily: "NotoSans",
    brightness: colorScheme.brightness,
    colorScheme: colorScheme,

    dialogTheme: DialogThemeData(
      elevation: 0,
      backgroundColor: colorScheme.surface,
      barrierColor: Colors.black.withValues(alpha: 0.3),
    ),

    // Clean AppBar with subtle separation
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      elevation: isLight ? 1 : 0,
      shadowColor: isLight ? Colors.black12 : Colors.black38,
      surfaceTintColor: colorScheme.surface,
      centerTitle: false,
    ),

    textTheme: textTheme.apply(
      fontFamily: "NotoSans",
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    ),

    scaffoldBackgroundColor: colorScheme.surfaceContainerLowest,
    canvasColor: colorScheme.surface,

    // Elevated buttons — flat medical blue
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: isLight ? 1 : 0,
        shadowColor: colorScheme.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.primary,
        side: BorderSide(color: colorScheme.outline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: colorScheme.surfaceContainerHigh,
      selectedColor: colorScheme.primaryContainer,
      labelStyle: TextStyle(color: colorScheme.onSurface),
      secondaryLabelStyle: TextStyle(color: colorScheme.onPrimaryContainer),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),

    listTileTheme: ListTileThemeData(
      tileColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),

    dividerTheme: DividerThemeData(
      color: colorScheme.outlineVariant,
      thickness: 0.5,
      space: 8,
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),

    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colorScheme.surfaceContainerHigh,
      surfaceTintColor: colorScheme.surfaceTint,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: colorScheme.surfaceContainer,
      elevation: 2,
      indicatorColor: colorScheme.primaryContainer,
      labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
          color: states.contains(WidgetState.selected)
              ? colorScheme.onPrimaryContainer
              : colorScheme.onSurfaceVariant,
        ),
      ),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: colorScheme.inverseSurface,
      contentTextStyle: TextStyle(color: colorScheme.onInverseSurface),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),

    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: colorScheme.primary,
      circularTrackColor: colorScheme.surfaceContainerHigh,
      linearTrackColor: colorScheme.surfaceContainerHigh,
    ),
  );

  List<ExtendedColor> get extendedColors => [];
}

class ExtendedColor {
  final Color seed, value;
  final ColorFamily light;
  final ColorFamily lightHighContrast;
  final ColorFamily lightMediumContrast;
  final ColorFamily dark;
  final ColorFamily darkHighContrast;
  final ColorFamily darkMediumContrast;

  const ExtendedColor({
    required this.seed,
    required this.value,
    required this.light,
    required this.lightHighContrast,
    required this.lightMediumContrast,
    required this.dark,
    required this.darkHighContrast,
    required this.darkMediumContrast,
  });
}

class ColorFamily {
  const ColorFamily({
    required this.color,
    required this.onColor,
    required this.colorContainer,
    required this.onColorContainer,
  });

  final Color color;
  final Color onColor;
  final Color colorContainer;
  final Color onColorContainer;
}