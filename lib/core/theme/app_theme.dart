import 'package:flutter/material.dart';

/// 심각도/상태 색상을 화면마다 다시 정의하지 않고 테마 한 곳에서 관리한다.
/// 전엔 Colors.redAccent / Colors.orange / Colors.greenAccent가 화면마다
/// 제각각 하드코딩돼 있어서 톤이 서로 미묘하게 어긋났다.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  final Color success;
  final Color warning;
  final Color danger;
  final Gradient primaryGradient;

  const AppSemanticColors({
    required this.success,
    required this.warning,
    required this.danger,
    required this.primaryGradient,
  });

  @override
  AppSemanticColors copyWith({
    Color? success,
    Color? warning,
    Color? danger,
    Gradient? primaryGradient,
  }) {
    return AppSemanticColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      primaryGradient: primaryGradient ?? this.primaryGradient,
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
    );
  }
}

class AppTheme {
  AppTheme._();

  // ── 팔레트 ───────────────────────────────────────────────────
  // 라이트 테마: 연한 회색 배경 위에 흰 카드를 얹어 테두리/그림자 없이도
  // 카드 경계가 자연스럽게 구분되도록 한다(토스 스타일).
  static const bg = Color(0xFFF7F8FA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceHigh = Color(0xFFF0F2F5);
  static const border = Color(0xFFE5E7EB);

  static const primary = Color(0xFF3E7BFA);
  static const primaryDark = Color(0xFF2F5FD6);

  static const textPrimary = Color(0xFF1A1D29);
  static const textSecondary = Color(0xFF6B7280);
  static const textTertiary = Color(0xFF9CA3AF);

  // 다크 배경 대비로 맞췄던 채도라 흰 배경에서는 명도를 낮춰 대비를 다시 맞춘다.
  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFD97706);
  static const danger = Color(0xFFDC2626);

  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4C8DFF), primaryDark],
  );

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: primary,
      surface: surface,
      error: danger,
      onSurface: textPrimary,
      outline: border,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bg,
      splashFactory: InkSparkle.splashFactory,
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: textPrimary,
        ),
        titleLarge: TextStyle(fontWeight: FontWeight.w700, color: textPrimary),
        titleMedium: TextStyle(fontWeight: FontWeight.w600, color: textPrimary),
        bodyLarge: TextStyle(color: textPrimary, height: 1.4),
        bodyMedium: TextStyle(color: textPrimary, height: 1.4),
        bodySmall: TextStyle(color: textSecondary, height: 1.4),
        labelLarge: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.2),
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
        // 테두리 없이 배경색 대비만으로 카드 경계를 표현하는 플랫 스타일.
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
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
          disabledBackgroundColor: primary.withOpacity(0.4),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: border),
          padding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
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
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      extensions: const [
        AppSemanticColors(
          success: success,
          warning: warning,
          danger: danger,
          primaryGradient: primaryGradient,
        ),
      ],
    );
  }
}
