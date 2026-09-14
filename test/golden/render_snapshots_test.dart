@Tags(['golden'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:telemetrix/core/theme/app_theme.dart';
import 'package:telemetrix/core/theme/design_tokens.dart';
import 'package:telemetrix/core/models/anomaly.dart';
import 'package:telemetrix/core/models/vehicle.dart';
import 'package:telemetrix/features/anomalies/widgets/anomaly_card.dart';
import 'package:telemetrix/features/dashboard/widgets/anomaly_banner.dart';
import 'package:telemetrix/features/dashboard/widgets/dtc_section.dart';
import 'package:telemetrix/features/dashboard/widgets/primary_metric_card.dart';
import 'package:telemetrix/features/dashboard/widgets/secondary_metric_card.dart';
import 'package:telemetrix/features/diagnosis/widgets/header_card.dart';
import 'package:telemetrix/features/vehicle_list/widgets/vehicle_card.dart';
import 'package:telemetrix/features/landing/widgets/hero_section.dart';
import 'package:telemetrix/features/landing/widgets/promo_visual.dart';

/// 화면을 실제로 렌더해 PNG로 남긴다.
///
/// 코드만 읽고 디자인을 판단하면 "값이 그럴듯한가"까지만 알 수 있고,
/// 모아놨을 때의 리듬·밀도·대비는 보이지 않는다. `flutter test --update-goldens`로
/// 이미지를 뽑아 눈으로 확인하기 위한 것이다.
///
/// 비교(회귀 감지) 용도가 아니라 **확인** 용도라 기본 실행에서는 제외한다
/// (`--exclude-tags golden`). 폰트 렌더링이 환경마다 미세하게 달라 CI에서
/// 픽셀 비교를 하면 계속 깨지기 때문이다.
Anomaly _anomaly({bool high = true}) => Anomaly(
      vehicleId: 'KR-GA-1234',
      anomalyType: high ? '엔진 온도 임계값 초과' : 'RPM 과부하 구간 진입',
      field: high ? 'engine_temp' : 'rpm',
      value: high ? 118.4 : 6420,
      threshold: high ? '105' : '6000',
      severity: high ? 'HIGH' : 'MEDIUM',
      detector: 'RULE',
      detectedAt: DateTime.now().subtract(const Duration(minutes: 7)),
    );

Vehicle _vehicle({
  String name = '아이오닉 5 롱레인지 AWD',
  Duration? lastSeenAgo = const Duration(minutes: 2),
  int highAnomalies = 0,
  bool active = true,
}) =>
    Vehicle(
      vehicleId: 'KR-GA-1234',
      name: name,
      owner: '홍길동',
      active: active,
      registeredAt: DateTime(2026, 1, 2),
      lastSeenAt:
          lastSeenAgo == null ? null : DateTime.now().subtract(lastSeenAgo),
      latestSpeed: 118.4,
      highAnomalyCount: highAnomalies,
    );

Widget _gallery() => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionLabel('차량 카드 — 상태별'),
        VehicleCard(vehicle: _vehicle(), onTap: () {}, onDeleted: () {}),
        const SizedBox(height: Spacing.xs),
        VehicleCard(
          vehicle: _vehicle(
            name: '스타리아 라운지 9인승',
            lastSeenAgo: const Duration(minutes: 9),
            highAnomalies: 3,
          ),
          onTap: () {},
          onDeleted: () {},
        ),
        const SizedBox(height: Spacing.xs),
        VehicleCard(
          vehicle: _vehicle(
            name: '포터 II 일렉트릭',
            lastSeenAgo: null,
            active: false,
          ),
          onTap: () {},
          onDeleted: () {},
        ),
        const SizedBox(height: Spacing.lg),
        const _SectionLabel('계측 카드'),
        const Row(
          children: [
            Expanded(
              child: PrimaryMetricCard(
                label: '엔진 온도',
                value: 118.4,
                maxValue: 130,
                unit: '°C',
                icon: Icons.thermostat,
                danger: true,
              ),
            ),
            SizedBox(width: Spacing.sm),
            Expanded(
              child: PrimaryMetricCard(
                label: '속도',
                value: 87.3,
                maxValue: 200,
                unit: 'km/h',
                icon: Icons.speed,
                danger: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.sm),
        const Row(
          children: [
            Expanded(
              child: SecondaryMetricCard(
                label: '배터리 전압',
                value: '13.8 V',
                icon: Icons.battery_charging_full,
                danger: false,
              ),
            ),
            SizedBox(width: Spacing.sm),
            Expanded(
              child: SecondaryMetricCard(
                label: '연료',
                value: '67 %',
                icon: Icons.local_gas_station,
                danger: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.lg),
        const _SectionLabel('이상 이력'),
        AnomalyCard(anomaly: _anomaly()),
        const SizedBox(height: Spacing.xs),
        AnomalyCard(anomaly: _anomaly(high: false)),
        const SizedBox(height: Spacing.lg),
        const _SectionLabel('경고와 진단'),
        const AnomalyBanner(dtcCodes: ['P0301', 'P0420']),
        const SizedBox(height: Spacing.sm),
        const DtcSection(codes: ['P0301', 'P0420', 'U0100']),
        const SizedBox(height: Spacing.sm),
        const DiagnosisHeaderCard(vehicleId: 'KR-GA-1234'),
      ],
    );

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: Spacing.xs),
        child: Text(
          text,
          style: TextStyle(
            fontSize: FontSizes.caption,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: context.appColors.textTertiary,
          ),
        ),
      );
}

Future<void> _snap(
  WidgetTester tester,
  String name, {
  required Brightness brightness,
  required double width,
  double textScale = 1.0,
  Widget? body,
  // 랜딩에는 끝나지 않는 반복 애니메이션이 있어 pumpAndSettle이 타임아웃한다.
  // 그런 화면은 고정 시간만 진행시켜 한 프레임을 잡는다.
  bool settle = true,
}) async {
  tester.view.physicalSize = Size(width, 1800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final theme =
      brightness == Brightness.dark ? AppTheme.dark() : AppTheme.light();
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(width, 1800),
            textScaler: TextScaler.linear(textScale),
          ),
          child: Scaffold(
            backgroundColor: theme.extension<AppSemanticColors>()!.background,
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(Spacing.md),
              child: body ?? _gallery(),
            ),
          ),
        ),
      ),
    ),
  );
  // 이미지 에셋은 fake_async 밖의 **실제 비동기**로 읽고 디코딩된다. pump만으로는 끝나지 않아
  // 스위트에서 **처음** 이미지를 쓰는 테스트는 빈 자리로 찍히고, 뒤 테스트는 캐시 덕에 나왔다
  // (2026-09-14 확인: 랜딩 라이트·다크를 각각 단독 실행하면 둘 다 로고가 빠진다 — 테마가 아니라 순서 의존).
  await tester.runAsync(() async {
    for (final element in find.byType(Image).evaluate()) {
      await precacheImage((element.widget as Image).image, element);
    }
  });
  // 게이지가 600ms 애니메이션이라 한 프레임만 pump하면 값이 0에서 멈춘 그림이 나온다.
  if (settle) {
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
  } else {
    await tester.pump(const Duration(milliseconds: 800));
  }
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('snapshots/$name.png'),
  );
}

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
Future<void> _loadTestFonts() async {
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

/// 랜딩은 앱의 첫인상이라 따로 본다. 여기가 시각 효과가 가장 많은 화면이다.
Widget _landing() => Column(
      children: [
        HeroSection(
          reveal: const AlwaysStoppedAnimation<double>(1),
          onGetStarted: () {},
        ),
        const SizedBox(height: Spacing.lg),
        const PromoVisual(),
      ],
    );

void main() {
  setUpAll(() async {
    // 앱은 main()에서 한국어 메시지를 등록한다. 테스트는 main()을 거치지 않아
    // locale: 'ko'가 영어로 떨어졌다("2 minutes ago").
    timeago.setLocaleMessages('ko', timeago.KoMessages());
    await _loadTestFonts();
  });

  testWidgets('랜딩 360px', (t) async {
    await _snap(t, 'landing_360',
        brightness: Brightness.light,
        width: 360,
        body: _landing(),
        settle: false);
  });
  testWidgets('랜딩 다크 360px', (t) async {
    await _snap(t, 'landing_dark_360',
        brightness: Brightness.dark,
        width: 360,
        body: _landing(),
        settle: false);
  });

  testWidgets('라이트 360px', (t) async {
    await _snap(t, 'light_360', brightness: Brightness.light, width: 360);
  });
  testWidgets('다크 360px', (t) async {
    await _snap(t, 'dark_360', brightness: Brightness.dark, width: 360);
  });
  testWidgets('라이트 320px', (t) async {
    await _snap(t, 'light_320', brightness: Brightness.light, width: 320);
  });
  testWidgets('라이트 360px 글자 1.5배', (t) async {
    await _snap(t, 'light_360_scale15',
        brightness: Brightness.light, width: 360, textScale: 1.5);
  });

  // 넓은 화면에서 내용이 얼마나 늘어나도 되는지를 눈으로 보기 위한 것.
  // overflow 검사(responsive_overflow_test)는 "잘리지 않는가"만 보고,
  // "한 줄이 너무 길어 읽기 나쁜가"는 못 잡는다. 두 장을 나란히 두고 판단한다.
  testWidgets('데스크톱 1280px — 폭 제한 없음(비교용)', (t) async {
    await _snap(t, 'light_1280_unbounded',
        brightness: Brightness.light, width: 1280);
  });
  testWidgets('데스크톱 1280px — ContentWidths.feed 적용', (t) async {
    await _snap(t, 'light_1280_feed',
        brightness: Brightness.light,
        width: 1280,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: ContentWidths.feed),
            child: _gallery(),
          ),
        ));
  });
}
