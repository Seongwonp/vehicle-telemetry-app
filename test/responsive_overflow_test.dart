import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:telemetrix/core/theme/app_theme.dart';
import 'package:telemetrix/features/anomalies/widgets/anomaly_card.dart';
import 'package:telemetrix/features/anomalies/widgets/empty_view.dart';
import 'package:telemetrix/features/dashboard/widgets/anomaly_banner.dart';
import 'package:telemetrix/features/dashboard/widgets/dtc_section.dart';
import 'package:telemetrix/features/dashboard/widgets/no_data_view.dart';
import 'package:telemetrix/features/dashboard/widgets/primary_metric_card.dart';
import 'package:telemetrix/features/dashboard/widgets/secondary_metric_card.dart';
import 'package:telemetrix/features/diagnosis/widgets/header_card.dart';
import 'package:telemetrix/features/landing/widgets/hero_section.dart';
import 'package:telemetrix/features/vehicle_list/widgets/info_chip.dart';
import 'package:telemetrix/features/vehicle_list/widgets/vehicle_card.dart';
import 'package:telemetrix/core/models/anomaly.dart';
import 'package:telemetrix/core/models/vehicle.dart';

/// AGENTS.md 화면 확인 체크리스트의 두 항목을 자동화한다.
///
/// - "320px, 360px, 400px 너비와 태블릿 너비에서 overflow가 없는가"
/// - "글자 크기 1.3배와 1.5배에서도 버튼, 상태 배지, 수치가 잘리지 않는가"
///
/// 사람이 매번 눈으로 확인하는 대신 조합을 전부 돌린다. 320px는 이 앱이 지원한다고
/// 적어둔 최소 너비인데 `Breakpoints`에는 그 값이 없었고, 코드에는 고정 width/height가
/// 179곳 있었다 — 검사 없이 "괜찮다"고 말할 수 있는 상태가 아니었다.
///
/// overflow는 Flutter가 렌더 단계에서 FlutterError로 보고하므로, 그것을 가로채
/// 실패로 만든다. 화면에 노란 줄무늬가 뜨는 것과 같은 신호다.
// 데스크톱 폭(1024/1280)도 넣는다. 화면마다 ContentWidths로 내용 폭을 제한하지만,
// 카드 내부는 그 제한 폭 안에서 다시 늘어나므로 좁은 쪽만 검사하면 놓치는 것이 생긴다.
const List<double> _widths = [320, 360, 400, 768, 1024, 1280];
const List<double> _textScales = [1.0, 1.3, 1.5];

/// 렌더 중 발생한 overflow를 모아 테스트 실패로 올린다.
Future<void> _expectNoOverflow(
  WidgetTester tester,
  String label,
  Widget child, {
  required double width,
  required double textScale,
  Brightness brightness = Brightness.light,
}) async {
  final overflows = <String>[];
  final previousOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    final message = details.exceptionAsString();
    if (message.contains('overflowed')) {
      overflows.add(message.split('\n').first);
    } else {
      previousOnError?.call(details);
    }
  };

  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme:
            brightness == Brightness.dark ? AppTheme.dark() : AppTheme.light(),
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(width, 900),
            textScaler: TextScaler.linear(textScale),
          ),
          // 실제 화면은 스크롤 안에 놓이므로 세로 overflow는 검사 대상이 아니다.
          // 여기서 잡으려는 건 가로 방향으로 잘리는 경우다.
          child: Scaffold(
            body: SingleChildScrollView(child: child),
          ),
        ),
      ),
    ),
  );
  await tester.pump();

  FlutterError.onError = previousOnError;
  expect(
    overflows,
    isEmpty,
    reason: '$label — 너비 ${width.toInt()}px, 글자배율 $textScale 에서 overflow:\n'
        '${overflows.join('\n')}',
  );
}

// 실제 데이터에서 나올 수 있는 '긴 값'을 쓴다 — 짧은 더미로는 overflow가 안 난다.
Anomaly _anomaly() => Anomaly(
      vehicleId: 'KR-GA-1234',
      anomalyType: '엔진 과열 경고 상태가 길게 이어지는 중',
      field: 'engine_temp',
      value: 118.4,
      threshold: '105',
      severity: 'HIGH',
      detector: 'RULE',
      detectedAt: DateTime(2026, 9, 4, 13, 45),
    );

Vehicle _vehicle() => Vehicle(
      vehicleId: 'KR-GA-1234',
      name: '아이오닉 5 롱레인지 AWD 2026',
      owner: '홍길동',
      active: true,
      registeredAt: DateTime(2026, 1, 2),
      lastSeenAt: DateTime(2026, 9, 4, 13, 45),
      latestSpeed: 118.4,
      highAnomalyCount: 12,
    );

/// 화면 전체가 아니라 구성 요소 단위로 돈다 — 화면은 네트워크·프로바이더가 얽혀 있어
/// 조합 검사에 적합하지 않고, overflow는 대부분 구성 요소 안에서 난다.
Map<String, Widget> _cases() => {
      'HeroSection': HeroSection(
        reveal: const AlwaysStoppedAnimation<double>(1),
        onGetStarted: () {},
      ),
      'AnomalyCard': AnomalyCard(anomaly: _anomaly()),
      'VehicleCard': VehicleCard(
        vehicle: _vehicle(),
        onTap: () {},
        onDeleted: () {},
      ),
      // 계측 카드는 실제로 Row 안에서 절반 폭으로 쓰인다. 전체 폭으로만 검사하면
      // 1.5배 글자에서 게이지 안 숫자가 넘치는 걸 놓친다(실제로 놓쳤다).
      'MetricCardRow(절반 폭)': const Row(
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
          SizedBox(width: 12),
          Expanded(
            child: SecondaryMetricCard(
              label: '배터리 전압',
              value: '13.8 V',
              icon: Icons.battery_charging_full,
              danger: false,
            ),
          ),
        ],
      ),
      'PrimaryMetricCard': const PrimaryMetricCard(
        label: '엔진 온도',
        value: 118.4,
        maxValue: 130,
        unit: '°C',
        icon: Icons.thermostat,
        danger: true,
      ),
      'SecondaryMetricCard': const SecondaryMetricCard(
        label: '배터리 전압',
        value: '13.8 V',
        icon: Icons.battery_charging_full,
        danger: false,
      ),
      'InfoChip': const InfoChip(icon: Icons.speed, label: '118.4 km/h'),
      'AnomalyBanner':
          const AnomalyBanner(dtcCodes: ['P0301', 'P0420', 'U0100']),
      'DtcSection': const DtcSection(codes: ['P0301', 'P0420', 'U0100']),
      'NoDataView': const NoDataView(vehicleId: 'KR-GA-1234'),
      'AnomalyEmptyView': const AnomalyEmptyView(),
      'DiagnosisHeaderCard': const DiagnosisHeaderCard(vehicleId: 'KR-GA-1234'),
    };

void main() {
  for (final entry in _cases().entries) {
    for (final width in _widths) {
      for (final scale in _textScales) {
        testWidgets(
          '${entry.key} — ${width.toInt()}px / 글자 ${scale}x 에서 overflow 없음',
          (tester) => _expectNoOverflow(
            tester,
            entry.key,
            entry.value,
            width: width,
            textScale: scale,
          ),
        );
      }
    }
  }
}
