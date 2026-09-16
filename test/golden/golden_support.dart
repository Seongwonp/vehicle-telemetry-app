import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// 스냅샷의 글꼴을 **네트워크 없이, 출처와 라이선스가 확인된 파일로만** 싣는다.
///
/// - **Manrope**: 앱과 같은 파일(`assets/google_fonts/`, OFL). google_fonts가 에셋에서 찾는다.
///   `allowRuntimeFetching = false`라 에셋에 없으면 내려받지 않고 예외로 실패한다.
/// - **한글**: 앱이 싣는 `assets/fonts/NanumGothic-*.ttf`(OFL). pubspec `fonts:`에 있어 `FontManifest.json`으로 함께 실린다.
///   2026-09-16부터 앱도 같은 글꼴을 테마 fallback으로 쓴다 — 스냅샷과 앱의 한글 글꼴이 같다
///   (래스터화는 OS마다 다르므로 픽셀 비교는 여전히 Windows에서만).
/// - **Material Icons**: flutter test가 자동으로 싣지 않는다. 테스트 번들 `FontManifest.json`에서 싣는다.
///
/// 예전 스냅샷의 □ 원인(2026-09-14 확인): google_fonts가 쓰는 굵기별 이름(`Manrope_regular`,
/// `Manrope_700`)에 글꼴이 없어 라틴·숫자가 테스트 기본 글꼴로 그려졌고, 아이콘 글꼴도 없었다.
Future<void> loadTestFonts() async {
  GoogleFonts.config.allowRuntimeFetching = false;

  final manifest =
      jsonDecode(await rootBundle.loadString('FontManifest.json')) as List;
  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final loader = FontLoader(entry['family'] as String);
    for (final font in (entry['fonts'] as List).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }

  // 테마가 쓰는 굵기를 첫 프레임 전에 전부 싣는다 — 로딩이 늦으면 스냅샷이 대체 글꼴로 찍힌다.
  for (final weight in const [
    FontWeight.w400,
    FontWeight.w500,
    FontWeight.w600,
    FontWeight.w700,
    FontWeight.w800,
  ]) {
    GoogleFonts.manrope(fontWeight: weight);
  }
  await GoogleFonts.pendingFonts();
}
