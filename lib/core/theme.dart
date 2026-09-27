import 'package:flutter/material.dart';

import 'tokens.dart';

/// One theme, built from [AppColor] and [AppFont].
///
/// Component themes are set here rather than on each widget so a button in
/// Settings and a button in the result sheet cannot quietly drift apart.
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    const ColorScheme scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColor.green900,
      onPrimary: AppColor.onDark,
      secondary: AppColor.green700,
      onSecondary: AppColor.onDark,
      error: AppColor.danger,
      onError: AppColor.onDark,
      surface: AppColor.surface,
      onSurface: AppColor.ink,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColor.bg,
      fontFamily: AppFont.family,
      splashFactory: InkSparkle.splashFactory,

      iconTheme: const IconThemeData(color: AppColor.ink, size: 22),

      // Icon-only buttons keep the 48dp target even when the glyph is small.
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColor.ink,
          minimumSize: const Size(Insets.tap, Insets.tap),
          iconSize: 22,
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColor.surface,
        side: const BorderSide(color: AppColor.line),
        labelStyle: AppFont.labelSm.copyWith(color: AppColor.ink),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Insets.rFull),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColor.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: AppColor.ink),
        titleTextStyle: TextStyle(
          fontFamily: AppFont.family,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppColor.ink,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColor.green900,
          foregroundColor: AppColor.onDark,
          disabledBackgroundColor: AppColor.mintLine,
          disabledForegroundColor: AppColor.onDark,
          elevation: 0,
          minimumSize: const Size(double.infinity, Insets.button),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Insets.rMd),
          ),
          textStyle: AppFont.label.copyWith(fontSize: 14.5),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColor.green900,
          side: const BorderSide(color: AppColor.line),
          backgroundColor: AppColor.surface,
          minimumSize: const Size(double.infinity, Insets.button),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Insets.rMd),
          ),
          textStyle: AppFont.label.copyWith(fontSize: 14.5),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColor.green700,
          minimumSize: const Size(64, Insets.tap),
          textStyle: AppFont.label,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColor.surface,
        hintStyle: AppFont.body.copyWith(color: AppColor.ink3),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Insets.rMd),
          borderSide: const BorderSide(color: AppColor.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Insets.rMd),
          borderSide: const BorderSide(color: AppColor.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Insets.rMd),
          borderSide: const BorderSide(color: AppColor.green700, width: 1.6),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColor.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Insets.rLg),
        ),
        titleTextStyle: AppFont.h2.copyWith(color: AppColor.ink),
        contentTextStyle: AppFont.body.copyWith(color: AppColor.ink2),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColor.ink,
        contentTextStyle: AppFont.bodySm.copyWith(color: AppColor.onDark),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Insets.rSm),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColor.line,
        thickness: 1,
        space: 1,
      ),

      textTheme: const TextTheme(
        displayMedium: AppFont.display,
        headlineMedium: AppFont.h1,
        titleLarge: AppFont.h2,
        titleMedium: AppFont.h3,
        bodyMedium: AppFont.body,
        bodySmall: AppFont.bodySm,
        labelLarge: AppFont.label,
        labelSmall: AppFont.labelSm,
      ).apply(bodyColor: AppColor.ink, displayColor: AppColor.ink),
    );
  }
}
