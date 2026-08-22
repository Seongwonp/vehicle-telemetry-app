import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 심각도/상태 색상을 화면마다 다시 정의하지 않고 테마 한 곳에서 관리한다.
/// 전엔 Colors.redAccent / Colors.orange / Colors.greenAccent가 화면마다
/// 제각각 하드코딩돼 있어서 톤이 서로 미묘하게 어긋났다.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  final Color success;
  final Color warning;
  final Color danger;
  final Gradient primaryGradient;
  final List<BoxShadow> accentGlow;

  const AppSemanticColors({
    required this.success,
    required this.warning,
    required this.danger,
    required this.primaryGradient,
    required this.accentGlow,
  });

  @override
  AppSemanticColors copyWith({
    Color? success,
    Color? warning,
    Color? danger,
    Gradient? primaryGradient,
    List<BoxShadow>? accentGlow,
  }) {
    return AppSemanticColors(
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
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      primaryGradient: t < 0.5 ? primaryGradient : other.primaryGradient,
      accentGlow: t < 0.5 ? accentGlow : other.accentGlow,
    );
  }
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
      color: primary.withOpacity(0.14),
      blurRadius: 20,
      spreadRadius: -8,
    ),
  ];

  // 계기판 숫자(속도/RPM 등) 전용 — 일반 UI 폰트(Manrope)와 의도적으로 분리해
  // "숫자만 다른 서체"인 HUD 느낌을 낸다. tabular figures로 자릿수 흔들림 방지.
  static TextStyle gaugeNumberStyle({
    double fontSize = 36,
    Color color = textPrimary,
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
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        // 다크 배경에서는 순수 배경색 대비만으로 경계가 잘 안 보여서, 라이트
        // 테마 때와 달리 얇은 테두리를 같이 준다.
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgElevated,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: danger, width: 1.6),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textTertiary),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: primary.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: borderStrong),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primary),
      ),
      iconTheme: const IconThemeData(color: textSecondary),
      dividerTheme: const DividerThemeData(color: border, space: 1),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: primary),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceHigh,
        contentTextStyle: const TextStyle(color: textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      extensions: [
        AppSemanticColors(
          success: success,
          warning: warning,
          danger: danger,
          primaryGradient: primaryGradient,
          accentGlow: accentGlow,
        ),
      ],
    );
  }
}
