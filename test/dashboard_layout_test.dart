import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telemetrix/core/theme/app_theme.dart';
import 'package:telemetrix/features/dashboard/dashboard_screen.dart';
import 'package:telemetrix/features/dashboard/widgets/metric_tile_grid.dart';
import 'package:telemetrix/features/dashboard/widgets/speed_chart.dart';

import 'fake_stomp_client.dart';

/// '현재 상태' 탭을 **화면 단위로** 폭 × 글자 배율 × 테마 × 상태 조합에서 검사한다.
///
/// `responsive_overflow_test`는 구성 요소 단위라 배치(그리드 칸 크기, 2단 레이아웃)에서 나는
/// 넘침을 못 잡는다 — 2026-09-16 320px·1.5배 보조 지표 그리드가 그렇게 빠져 있었다.
///
/// 수신 중 상태는 넣지 않는다: 기준 초과 상태가 같은 배치에 경고 아이콘·굵은 문구를 더한 것이라
/// 폭이 더 필요한 쪽만 검사한다. GPS는 넣지 않는다(지도 타일이 네트워크를 탄다).
const _widths = [320.0, 360.0, 400.0, 768.0, 1024.0, 1280.0];
const _scales = [1.0, 1.3, 1.5];

final _base = DateTime.utc(2026, 8, 4, 14, 41);

String _frame(int second, {bool over = false}) => jsonEncode({
      'vehicleId': 'KR-GA-1234',
      'timestamp': _base.add(Duration(seconds: second)).toIso8601String(),
      // 폭이 가장 많이 필요한 값: 계약 상한 근처 자릿수
      'speed': over ? 254.9 : 62.4,
      'rpm': over ? 16383.75 : 2140,
      'engineTemp': over ? 214.9 : 91.2,
      'throttlePosition': 100.0,
      'fuelLevel': 100.0,
      'batteryVoltage': over ? 10.95 : 13.92,
      'dtcCodes': over ? ['P0217', 'P0301', 'U0100', 'C1234'] : <String>[],
    });

enum _State { over, stale }

Future<List<String>> _pumpDashboard(
  WidgetTester tester, {
  required double width,
  required double textScale,
  required Brightness brightness,
  required _State state,
}) async {
  final overflows = <String>[];
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    final message = details.exceptionAsString();
    if (message.contains('overflowed')) {
      overflows.add(message.split('\n').first);
    } else {
      previous?.call(details);
    }
  };
  addTearDown(() => FlutterError.onError = previous);

  const height = 1400.0;
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  var now = _base.add(const Duration(seconds: 10));
  final clients = <FakeStompClient>[];
  await tester.pumpWidget(MaterialApp(
    theme: brightness == Brightness.dark ? AppTheme.dark() : AppTheme.light(),
    home: MediaQuery(
      data: MediaQueryData(
        size: Size(width, height),
        textScaler: TextScaler.linear(textScale),
      ),
      child: Scaffold(
        body: DashboardTab(
          vehicleId: 'KR-GA-1234',
          tokenLoader: () async => 'test',
          now: () => now,
          stompClientFactory: (config) {
            final client = FakeStompClient(config);
            clients.add(client);
            return client;
          },
        ),
      ),
    ),
  ));
  final client = clients.single;
  await client.connect();
  for (var i = 0; i < 5; i++) {
    client.emit(_frame(i, over: state == _State.over && i == 4));
  }
  await tester.pump();
  if (state == _State.stale) {
    client.disconnect();
    now = now.add(const Duration(seconds: 14));
  }
  await tester.pump(const Duration(milliseconds: 1100));
  await tester.pump();
  return overflows;
}

Future<void> _dispose(WidgetTester tester) =>
    tester.pumpWidget(const SizedBox());

double _top(WidgetTester tester, String key) =>
    tester.getTopLeft(find.byKey(Key(key))).dy;

void main() {
  for (final width in _widths) {
    for (final scale in _scales) {
      for (final brightness in Brightness.values) {
        for (final state in _State.values) {
          testWidgets(
            '${width.toInt()}px · 글자 ${scale}x · ${brightness.name} · ${state.name} — overflow 없음',
            (tester) async {
              final overflows = await _pumpDashboard(tester,
                  width: width,
                  textScale: scale,
                  brightness: brightness,
                  state: state);
              expect(overflows, isEmpty);
              await _dispose(tester);
            },
          );
        }
      }
    }
  }

  group('폭에 따른 타일 열 수', () {
    Future<int> columns(WidgetTester tester, double width, double scale) async {
      await _pumpDashboard(tester,
          width: width,
          textScale: scale,
          brightness: Brightness.light,
          state: _State.over);
      final tops = [
        for (final k in ['speed', 'rpm', 'engineTemp', 'battery'])
          _top(tester, 'metric_tile_$k'),
      ];
      final firstRow = tops.where((t) => t == tops.first).length;
      await _dispose(tester);
      return firstRow;
    }

    testWidgets(
        '320px·1.0배 2열', (t) async => expect(await columns(t, 320, 1.0), 2));
    testWidgets(
        '320px·1.5배 1열', (t) async => expect(await columns(t, 320, 1.5), 1));
    testWidgets(
        '360px·1.5배 2열', (t) async => expect(await columns(t, 360, 1.5), 2));
    testWidgets('768px·1.0배 4열 한 줄',
        (t) async => expect(await columns(t, 768, 1.0), 4));
    testWidgets('1280px·1.0배 2단 안에서 2열',
        (t) async => expect(await columns(t, 1280, 1.0), 2));
  });

  group('2단 배치', () {
    Future<(double, double, double)> positions(
        WidgetTester tester, double width) async {
      await _pumpDashboard(tester,
          width: width,
          textScale: 1.0,
          brightness: Brightness.light,
          state: _State.over);
      final tile = tester.getRect(find.byKey(const Key('metric_tile_speed')));
      final chart = tester.getRect(find.byType(SpeedChart));
      await _dispose(tester);
      return (tile.right, chart.left, chart.top - tile.top);
    }

    testWidgets('1024px 이상은 차트가 값 오른쪽에', (tester) async {
      for (final width in const [1024.0, 1280.0]) {
        final (tileRight, chartLeft, _) = await positions(tester, width);
        expect(chartLeft, greaterThan(tileRight), reason: '${width}px');
      }
    });
    testWidgets('1024px 미만은 차트가 값 아래에', (tester) async {
      for (final width in const [360.0, 768.0]) {
        final (_, _, dy) = await positions(tester, width);
        expect(dy, greaterThan(0), reason: '${width}px');
      }
    });
  });

  test('열 수 계산 — 3열은 2열로 내린다', () {
    expect(MetricTileGrid.columnsFor(380, 1.0, 4), 2);
    expect(MetricTileGrid.columnsFor(500, 1.0, 4), 4);
    expect(MetricTileGrid.columnsFor(200, 1.0, 2), 1);
  });
}
