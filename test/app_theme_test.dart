import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telemetrix/core/models/anomaly.dart';
import 'package:telemetrix/core/theme/app_theme.dart';
import 'package:telemetrix/features/anomalies/widgets/anomaly_card.dart';
import 'package:telemetrix/features/diagnosis/widgets/error_section.dart';

void main() {
  testWidgets('화면 색상은 ThemeExtension에서 조회한다', (tester) async {
    AppSemanticColors? colors;

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: Builder(builder: (context) {
        colors = context.appColors;
        return const SizedBox();
      }),
    ));

    expect(colors, isNotNull);
    expect(colors!.background, AppTheme.bg);
    expect(colors!.surface, AppTheme.surface);
    expect(colors!.border, AppTheme.border);
    expect(colors!.textPrimary, AppTheme.textPrimary);
    expect(colors!.danger, AppTheme.danger);
  });

  testWidgets('라이트와 다크는 서로 다른 표면과 텍스트 토큰을 제공한다', (tester) async {
    AppSemanticColors? lightColors;
    AppSemanticColors? darkColors;

    // 같은 구조의 트리를 연달아 pump하면 엘리먼트가 재사용돼 두 번째 Builder가
    // 갱신된 테마를 못 읽는다(darkColors에 light 값이 들어와 테스트가 실패했다).
    // 테마마다 다른 key를 줘서 엘리먼트를 새로 만들게 한다.
    await tester.pumpWidget(MaterialApp(
      key: const ValueKey('light'),
      theme: AppTheme.light(),
      home: Builder(builder: (context) {
        lightColors = context.appColors;
        return const SizedBox();
      }),
    ));
    await tester.pumpWidget(MaterialApp(
      key: const ValueKey('dark'),
      theme: AppTheme.dark(),
      home: Builder(builder: (context) {
        darkColors = context.appColors;
        return const SizedBox();
      }),
    ));

    expect(lightColors!.background, isNot(darkColors!.background));
    expect(lightColors!.surface, isNot(darkColors!.surface));
    expect(lightColors!.textPrimary, isNot(darkColors!.textPrimary));
    expect(AppTheme.dark().brightness, Brightness.dark);
  });

  // 회귀 방어: 여러 화면이 `AppTheme.danger` 같은 **정적 팔레트 상수**를 직접
  // 쓰고 있었다. 정적 상수는 라이트 값이라 다크 테마에서 그대로 남아 어두운
  // 배경 대비가 무너진다. "다크에서 색이 바뀌는가"를 위젯을 실제로 렌더해서 본다.
  testWidgets('다크 테마에서 위험 색은 다크 토큰을 따른다 — 정적 상수가 아니다', (tester) async {
    final darkTheme = AppTheme.dark();
    final darkDanger = darkTheme.extension<AppSemanticColors>()!.danger;

    // 전제: 두 값이 애초에 다르지 않으면 이 테스트는 아무것도 막지 못한다.
    expect(darkDanger, isNot(AppTheme.danger));

    await tester.pumpWidget(MaterialApp(
      theme: darkTheme,
      home: Scaffold(
        body: Column(
          children: [
            const DiagnosisErrorSection(message: '진단에 실패했습니다.'),
            AnomalyCard(
              anomaly: Anomaly(
                vehicleId: 'KR-GA-1234',
                anomalyType: '엔진 온도 임계값 초과',
                severity: 'HIGH',
                detectedAt: DateTime.utc(2026, 8, 5, 1),
              ),
            ),
          ],
        ),
      ),
    ));

    Color? colorOf(String text) =>
        tester.widget<Text>(find.text(text)).style?.color;

    expect(colorOf('진단에 실패했습니다.'), darkDanger);
    // 심각도 알약(StatusPill)과 이상 유형 제목도 같은 토큰에서 나온다.
    expect(colorOf('HIGH'), darkDanger);
    expect(colorOf('엔진 온도 임계값 초과'), darkDanger);

    expect(
      tester.widget<Icon>(find.byIcon(Icons.error_outline).first).color,
      darkDanger,
    );
  });
}
