import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// 스냅샷의 글꼴을 **네트워크 없이, 출처와 라이선스가 확인된 파일로만** 싣는다.
///
/// - **Manrope**: 앱과 같은 파일(`assets/google_fonts/`, OFL). google_fonts가 에셋에서 찾는다.
///   `allowRuntimeFetching = false`라 에셋에 없으면 내려받지 않고 예외로 실패한다.
/// - **한글**: `test/fonts/NanumGothic-*.ttf`(OFL, `test/fonts/NanumGothic-OFL.txt`) — **테스트 전용**.
///   Manrope에는 한글이 없고, google_fonts는 fallback 이름을 `'Manrope'`로만 두므로 그 이름에 싣는다.
///   앱은 기기 OS의 한글 글꼴로 떨어지므로 **스냅샷의 한글 모양·폭은 실기기와 다를 수 있다.**
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

  final hangul = FontLoader('Manrope')
    ..addFont(_fontFile('test/fonts/NanumGothic-Regular.ttf'))
    ..addFont(_fontFile('test/fonts/NanumGothic-Bold.ttf'));
  await hangul.load();

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

Future<ByteData> _fontFile(String path) async =>
    ByteData.view((await File(path).readAsBytes()).buffer);
