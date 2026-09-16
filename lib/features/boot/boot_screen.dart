import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';

/// 앱을 켠 직후 저장된 로그인 상태를 확인하는 동안 보이는 화면.
///
/// Android 시스템 시작 화면(앱 배경색 + 가운데 로고)에서 이어지도록 같은 배경색·같은 로고 위치를 쓴다.
/// **일부러 오래 붙잡지 않는다** — 확인이 끝나면 곧바로 랜딩이나 차량 목록으로 넘어간다.
///
/// 워드마크는 이미지가 아니라 글자로 그린다: `assets/logo.png`는 투명 배경을 흉내 낸 체크무늬가
/// 이미지에 박혀 있어 쓸 수 없고(2026-09-16 확인), 글자는 라이트·다크 모두 테마 색을 따른다.
class BootScreen extends StatelessWidget {
  const BootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
            child: Semantics(
              label: 'TELEMETRIX, 로그인 상태 확인 중',
              excludeSemantics: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Android 12+ 시작 화면 아이콘의 로고 폭(150dp)과 맞춘다.
                  Image.asset(
                    'assets/logo_icon.png',
                    key: const Key('boot_logo'),
                    width: 150,
                    excludeFromSemantics: true,
                  ),
                  const SizedBox(height: Spacing.lg),
                  Text(
                    'TELEMETRIX',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      fontSize: FontSizes.title,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: Spacing.xxs),
                  Text(
                    '차량 텔레메트리 모니터링',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: FontSizes.caption,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: Spacing.xl),
                  SizedBox(
                    width: 96,
                    child: ClipRRect(
                      borderRadius: Radii.pillAll,
                      child: LinearProgressIndicator(
                        key: const Key('boot_progress'),
                        minHeight: 3,
                        color: primary,
                        backgroundColor: colors.surfaceHigh,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
