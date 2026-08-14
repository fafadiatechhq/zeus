import 'package:flutter/material.dart';

/// Single source of truth for all colors, text styles, and component themes.
/// Every widget must reference tokens from here — no raw Color() literals in
/// screen or widget files.
class AppTheme {
  AppTheme._();

  // ---------------------------------------------------------------------------
  // Brand palette
  // ---------------------------------------------------------------------------
  static const Color primary     = Color(0xFF233A66); // navy blue
  static const Color primaryDark = Color(0xFF162344); // deep navy
  static const Color accent      = Color(0xFFFFD691); // golden yellow
  static const Color gold        = Color(0xFFD7A859); // warm gold

  // ---------------------------------------------------------------------------
  // Semantic / status colors
  // ---------------------------------------------------------------------------
  static const Color success = Color(0xFF2E7D52);
  static const Color warning = Color(0xFFD7A859); // reuses gold
  static const Color danger  = Color(0xFFFF6E80); // coral pink

  // ---------------------------------------------------------------------------
  // Text hierarchy
  // ---------------------------------------------------------------------------
  static const Color textPrimary   = Color(0xFF1E293B); // headings, labels
  static const Color textSecondary = Color(0xFF475569); // body copy
  static const Color textMuted     = Color(0xFF64748B); // meta, timestamps
  static const Color textSubtle    = Color(0xFF94A3B8); // hints, placeholders

  // Text on primary/dark backgrounds
  static const Color textOnPrimary = Colors.white;
  static const Color textOnAccent  = Color(0xFF233A66); // navy on gold

  // ---------------------------------------------------------------------------
  // Surfaces & borders
  // ---------------------------------------------------------------------------
  static const Color surface     = Color(0xFFFFF8EE); // warm cream scaffold bg
  static const Color cardBg      = Colors.white;
  static const Color divider     = Color(0xFFEDE8DF); // warm card border
  static const Color borderLight = Color(0xFFCBD5E1); // input / inactive border

  // ---------------------------------------------------------------------------
  // Task priority colors
  // ---------------------------------------------------------------------------
  static const Color priorityLow    = Color(0xFF94A3B8); // subtle grey
  static const Color priorityMedium = Color(0xFFD7A859); // gold
  static const Color priorityHigh   = Color(0xFFEA580C); // orange
  static const Color priorityUrgent = Color(0xFFFF6E80); // coral pink

  // ---------------------------------------------------------------------------
  // ThemeData
  // ---------------------------------------------------------------------------
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: accent,
        surface: surface,
      ),
      scaffoldBackgroundColor: surface,

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: textOnPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textOnPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
        iconTheme: IconThemeData(color: textOnPrimary),
      ),

      // Bottom navigation
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: primary,
        unselectedItemColor: textSubtle,
        backgroundColor: cardBg,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 11),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: divider),
        ),
        margin: EdgeInsets.zero,
      ),

      // Divider
      dividerTheme: const DividerThemeData(color: divider, space: 1, thickness: 1),

      // Elevated button — primary navy
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: textOnPrimary,
          disabledBackgroundColor: borderLight,
          disabledForegroundColor: textSubtle,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      // Outlined button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      // Text button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      // Floating action button — accent gold
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: textOnPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
      ),

      // Checkbox
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return success;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(textOnPrimary),
        side: const BorderSide(color: borderLight, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return textSubtle;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary.withValues(alpha: 0.3);
          }
          return borderLight;
        }),
      ),

      // Tab bar
      tabBarTheme: const TabBarThemeData(
        labelColor: textOnPrimary,
        unselectedLabelColor: accent,
        indicatorColor: textOnPrimary,
        dividerColor: Colors.transparent,
        labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
      ),

      // Snack bar
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        contentTextStyle: const TextStyle(color: textOnPrimary, fontSize: 14),
      ),

      // Input / form fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardBg,
        labelStyle: const TextStyle(color: textMuted, fontSize: 14),
        hintStyle: const TextStyle(color: textSubtle, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: danger, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        prefixIconColor: textMuted,
        suffixIconColor: textMuted,
      ),

      // List tile
      listTileTheme: const ListTileThemeData(
        iconColor: textMuted,
        titleTextStyle: TextStyle(fontSize: 14, color: textPrimary, fontWeight: FontWeight.w500),
        subtitleTextStyle: TextStyle(fontSize: 12, color: textMuted),
      ),

      // Progress indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: divider,
      ),

      // Icon
      iconTheme: const IconThemeData(color: textMuted, size: 22),

      // Text
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: textPrimary),
        headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: textPrimary),
        headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textPrimary),
        titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary),
        titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary),
        titleSmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
        bodyLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: textSecondary),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: textSecondary),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: textMuted),
        labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textMuted),
        labelMedium: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textMuted),
        labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: textSubtle),
      ),

      // Popup menu
      popupMenuTheme: PopupMenuThemeData(
        color: cardBg,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 14, color: textPrimary),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Reusable status badge helper
  // ---------------------------------------------------------------------------
  static Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'present':
      case 'checked in':
      case 'approved':
      case 'completed':
        return success;
      case 'warning':
      case 'on leave':
      case 'in progress':
      case 'submitted':
        return warning;
      case 'danger':
      case 'absent':
      case 'blocked':
      case 'rejected':
        return danger;
      default:
        return textSubtle;
    }
  }
}
