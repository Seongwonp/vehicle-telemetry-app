import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'design_tokens.dart';

/// 심각도/상태 색상을 화면마다 다시 정의하지 않고 테마 한 곳에서 관리한다.
/// 전엔 Colors.redAccent / Colors.orange / Colors.greenAccent가 화면마다
/// 제각각 하드코딩돼 있어서 톤이 서로 미묘하게 어긋났다.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  final Color background;
  final Color backgroundElevated;
  final Color surface;
  final Color surfaceHigh;
  final Color border;
  final Color borderStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color success;
  final Color warning;
  final Color danger;
  final Gradient primaryGradient;
  final List<BoxShadow> accentGlow;

  const AppSemanticColors({
    required this.background,
    required this.backgroundElevated,
    required this.surface,
    required this.surfaceHigh,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.success,
    required this.warning,
    required this.danger,
    required this.primaryGradient,
    required this.accentGlow,
  });

  @override
  AppSemanticColors copyWith({
    Color? background,
    Color? backgroundElevated,
    Color? surface,
    Color? surfaceHigh,
    Color? border,
    Color? borderStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? success,
    Color? warning,
    Color? danger,
    Gradient? primaryGradient,
    List<BoxShadow>? accentGlow,
  }) {
    return AppSemanticColors(
      background: background ?? this.background,
      backgroundElevated: backgroundElevated ?? this.backgroundElevated,
      surface: surface ?? this.surface,
      surfaceHigh: surfaceHigh ?? this.surfaceHigh,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      primaryGradient: primaryGradient ?? this.primaryGradient,
      accentGlow: accentGlow ?? this.accentGlow,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      background: Color.lerp(background, other.background, t)!,
      backgroundElevated:
          Color.lerp(backgroundElevated, other.backgroundElevated, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceHigh: Color.lerp(surfaceHigh, other.surfaceHigh, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      primaryGradient: t < 0.5 ? primaryGradient : other.primaryGradient,
      accentGlow: t < 0.5 ? accentGlow : other.accentGlow,
    );
  }
}

extension AppThemeContext on BuildContext {
  AppSemanticColors get appColors =>
      Theme.of(this).extension<AppSemanticColors>() ??
      AppTheme.light().extension<AppSemanticColors>()!;
}

/// "코크핏 다크" — 야간 차량 계기판 무드. 앰버 포인트 컬러 하나만 쓰고
/// (성공/경고/위험 제외) 나머지는 전부 무채색으로 눌러서, 계기판이 켜졌을 때
/// 앰버 숫자만 도드라져 보이는 느낌을 낸다.
class AppTheme {
  AppTheme._();

  // ── 팔레트 ───────────────────────────────────────────────────
  static const bg = Color(0xFFF5F7FA);
  static const bgElevated = Color(0xFFEEF2F6);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceHigh = Color(0xFFE7ECF2);
  static const border = Color(0xFFDCE2E9);
  static const borderStrong = Color(0xFFC5CED8);

  static const primary = Color(0xFF2457D6);
  static const primaryBright = Color(0xFF3C6BE2);
  static const primaryDark = Color(0xFF173FA8);

  static const textPrimary = Color(0xFF18212F);
  static const textSecondary = Color(0xFF5D6878);
  static const textTertiary = Color(0xFF8792A2);

  static const success = Color(0xFF18865B);
  static const warning = Color(0xFFB56B08);
  static const danger = Color(0xFFC43D4B);

  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBright, primary],
  );

  static final accentGlow = [
    BoxShadow(
      color: primary.withValues(alpha: 0.14),
      blurRadius: 20,
      spreadRadius: -8,
    ),
  ];

  // 계기판 숫자(속도/RPM 등) 전용 — 일반 UI 폰트(Manrope)와 의도적으로 분리해
  // "숫자만 다른 서체"인 HUD 느낌을 낸다. tabular figures로 자릿수 흔들림 방지.
  static TextStyle gaugeNumberStyle({
    double fontSize = 36,
    required Color color,
    FontWeight weight = FontWeight.w600,
  }) {
    return GoogleFonts.manrope(
      fontSize: fontSize,
      fontWeight: weight,
      color: color,
      height: 1.0,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  static ThemeData light() {
    final base = GoogleFonts.manropeTextTheme(ThemeData.light().textTheme);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: primary,
      onPrimary: Colors.white,
      surface: surface,
      onSurface: textPrimary,
      error: danger,
      outline: border,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bg,
      splashFactory: InkSparkle.splashFactory,
      textTheme: base.copyWith(
        headlineSmall: base.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: textPrimary,
        ),
        titleLarge: base.titleLarge
            ?.copyWith(fontWeight: FontWeight.w700, color: textPrimary),
        titleMedium: base.titleMedium
            ?.copyWith(fontWeight: FontWeight.w600, color: textPrimary),
        bodyLarge: base.bodyLarge?.copyWith(color: textPrimary, height: 1.4),
        bodyMedium: base.bodyMedium?.copyWith(color: textPrimary, height: 1.4),
        bodySmall: base.bodySmall?.copyWith(color: textSecondary, height: 1.4),
        labelLarge: base.labelLarge
            ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.2),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: textPrimary,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: FontSizes.subtitle,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: const CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        // 다크 배경에서는 순수 배경색 대비만으로 경계가 잘 안 보여서, 라이트
        // 테마 때와 달리 얇은 테두리를 같이 준다.
        shape: RoundedRectangleBorder(
          borderRadius: Radii.mdAll,
          side: BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: bgElevated,
        contentPadding:
            EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.md),
        border: OutlineInputBorder(
          borderRadius: Radii.smAll,
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: Radii.smAll,
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: Radii.smAll,
          borderSide: BorderSide(color: primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: Radii.smAll,
          borderSide: BorderSide(color: danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: Radii.smAll,
          borderSide: BorderSide(color: danger, width: 1.6),
        ),
        labelStyle: TextStyle(color: textSecondary),
        hintStyle: TextStyle(color: textTertiary),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: primary.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(vertical: Spacing.md),
          shape: const RoundedRectangleBorder(borderRadius: Radii.smAll),
          textStyle: const TextStyle(
              fontWeight: FontWeight.w700, fontSize: FontSizes.subtitle),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: borderStrong),
          padding: const EdgeInsets.symmetric(
              vertical: Spacing.md, horizontal: Spacing.lg),
          shape: const RoundedRectangleBorder(borderRadius: Radii.smAll),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primary),
      ),
      iconTheme: const IconThemeData(color: textSecondary),
      dividerTheme: const DividerThemeData(color: border, space: 1),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: primary),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: surfaceHigh,
        contentTextStyle: TextStyle(color: textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: Radii.smAll),
      ),
      extensions: [
        AppSemanticColors(
          background: bg,
          backgroundElevated: bgElevated,
          surface: surface,
          surfaceHigh: surfaceHigh,
          border: border,
          borderStrong: borderStrong,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          textTertiary: textTertiary,
          success: success,
          warning: warning,
          danger: danger,
          primaryGradient: primaryGradient,
          accentGlow: accentGlow,
        ),
      ],
    );
  }

  static ThemeData dark() {
    const darkBg = Color(0xFF111318);
    const darkBgElevated = Color(0xFF171A21);
    const darkSurface = Color(0xFF1D2129);
    const darkSurfaceHigh = Color(0xFF272C36);
    const darkBorder = Color(0xFF323844);
    const darkBorderStrong = Color(0xFF46505F);
    const darkTextPrimary = Color(0xFFF3F5F7);
    const darkTextSecondary = Color(0xFFAAB2BF);
    const darkTextTertiary = Color(0xFF7B8493);
    const darkPrimary = Color(0xFF7CA2FF);
    const darkSuccess = Color(0xFF4DBA8B);
    const darkWarning = Color(0xFFE0A33A);
    const darkDanger = Color(0xFFE16B75);

    final base = GoogleFonts.manropeTextTheme(ThemeData.dark().textTheme);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: darkPrimary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: darkPrimary,
      onPrimary: const Color(0xFF0C1B3E),
      surface: darkSurface,
      onSurface: darkTextPrimary,
      error: darkDanger,
      outline: darkBorder,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: darkBg,
      splashFactory: InkSparkle.splashFactory,
      textTheme: base.copyWith(
        headlineSmall: base.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: darkTextPrimary,
        ),
        titleLarge: base.titleLarge
            ?.copyWith(fontWeight: FontWeight.w700, color: darkTextPrimary),
        titleMedium: base.titleMedium
            ?.copyWith(fontWeight: FontWeight.w600, color: darkTextPrimary),
        bodyLarge:
            base.bodyLarge?.copyWith(color: darkTextPrimary, height: 1.4),
        bodyMedium:
            base.bodyMedium?.copyWith(color: darkTextPrimary, height: 1.4),
        bodySmall:
            base.bodySmall?.copyWith(color: darkTextSecondary, height: 1.4),
        labelLarge: base.labelLarge
            ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.2),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: darkTextPrimary,
        titleTextStyle: TextStyle(
          color: darkTextPrimary,
          fontSize: FontSizes.subtitle,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: const CardThemeData(
        color: darkSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.mdAll,
          side: BorderSide(color: darkBorder),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: darkBgElevated,
        contentPadding:
            EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.md),
        border: OutlineInputBorder(
          borderRadius: Radii.smAll,
          borderSide: BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: Radii.smAll,
          borderSide: BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: Radii.smAll,
          borderSide: BorderSide(color: darkPrimary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: Radii.smAll,
          borderSide: BorderSide(color: darkDanger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: Radii.smAll,
          borderSide: BorderSide(color: darkDanger, width: 1.6),
        ),
        labelStyle: TextStyle(color: darkTextSecondary),
        hintStyle: TextStyle(color: darkTextTertiary),
        prefixIconColor: darkTextSecondary,
        suffixIconColor: darkTextSecondary,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: darkPrimary,
          foregroundColor: const Color(0xFF0C1B3E),
          disabledBackgroundColor: darkPrimary.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(vertical: Spacing.md),
          shape: const RoundedRectangleBorder(borderRadius: Radii.smAll),
          textStyle: const TextStyle(
              fontWeight: FontWeight.w700, fontSize: FontSizes.subtitle),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkTextPrimary,
          side: const BorderSide(color: darkBorderStrong),
          padding: const EdgeInsets.symmetric(
              vertical: Spacing.md, horizontal: Spacing.lg),
          shape: const RoundedRectangleBorder(borderRadius: Radii.smAll),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: darkPrimary),
      ),
      iconTheme: const IconThemeData(color: darkTextSecondary),
      dividerTheme: const DividerThemeData(color: darkBorder, space: 1),
      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: darkPrimary),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: darkSurfaceHigh,
        contentTextStyle: TextStyle(color: darkTextPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: Radii.smAll),
      ),
      extensions: [
        AppSemanticColors(
          background: darkBg,
          backgroundElevated: darkBgElevated,
          surface: darkSurface,
          surfaceHigh: darkSurfaceHigh,
          border: darkBorder,
          borderStrong: darkBorderStrong,
          textPrimary: darkTextPrimary,
          textSecondary: darkTextSecondary,
          textTertiary: darkTextTertiary,
          success: darkSuccess,
          warning: darkWarning,
          danger: darkDanger,
          primaryGradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF9AB8FF), darkPrimary],
          ),
          accentGlow: [
            BoxShadow(
              color: darkPrimary.withValues(alpha: 0.18),
              blurRadius: 20,
              spreadRadius: -8,
            ),
          ],
        ),
      ],
    );
  }
}
