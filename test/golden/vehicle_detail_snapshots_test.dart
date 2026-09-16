@Tags(['golden'])
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:telemetrix/core/theme/app_theme.dart';
import 'package:telemetrix/features/dashboard/dashboard_screen.dart';

import '../fake_stomp_client.dart';
import 'golden_support.dart';

/// 차량 상세 '현재 상태' 탭을 **화면 전체**로 찍는다.
///
/// `render_snapshots_test`는 구성 요소 갤러리라 배치·위계·지연 표시를 화면 단위로 볼 수 없다.
/// 상태별(수신 중·기준 초과·데이터 지연·재연결)로 같은 데이터를 찍어 화면이 바뀔 때 diff로 비교한다.
///
/// GPS 좌표는 넣지 않는다 — 지도 타일은 네트워크를 타므로 스냅샷에서 뺀다(지도는 좌표 2개 미만이면 숨는다).
enum _Fixture { live, over, stale, reconnecting }

final _base = DateTime.utc(2026, 8, 4, 14, 41);

String _frame(
  int second, {
  required double speed,
  double rpm = 2140,
  double engineTemp = 91.2,
  double battery = 13.92,
  List<String> dtc = const [],
}) =>
    jsonEncode({
      'vehicleId': 'KR-GA-1234',
      'timestamp': _base.add(Duration(seconds: second)).toIso8601String(),
      'speed': speed,
      'rpm': rpm,
      'engineTemp': engineTemp,
      'throttlePosition': 18.5,
      'fuelLevel': 58.0,
      'batteryVoltage': battery,
      'dtcCodes': dtc,
    });

const _speeds = [48.0, 51, 55, 57, 56, 58, 61, 63, 60, 59, 62, 64, 66, 65, 63];

Future<void> _snapDetail(
  WidgetTester tester,
  String name, {
  required _Fixture fixture,
  Brightness brightness = Brightness.light,
  double width = 360,
  double textScale = 1.0,
  // 바꾸기 전 화면의 **알려진 결함**을 스냅샷으로 남길 때만 쓴다. 넘침이 실제로 났는지 단언한다.
  String? knownOverflow,
}) async {
  final overflows = <String>[];
  if (knownOverflow != null) {
    final original = FlutterError.onError;
    FlutterError.onError = (details) {
      final message = details.exceptionAsString();
      if (message.contains('overflowed')) {
        overflows.add(message);
      } else {
        original?.call(details);
      }
    };
    addTearDown(() => FlutterError.onError = original);
  }

  const height = 1600.0;
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  var now = _base.add(const Duration(seconds: 20));
  final clients = <FakeStompClient>[];
  final theme =
      brightness == Brightness.dark ? AppTheme.dark() : AppTheme.light();

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(width, height),
          textScaler: TextScaler.linear(textScale),
        ),
        child: Scaffold(
          body: DashboardTab(
            vehicleId: 'KR-GA-1234',
            tokenLoader: () async => 'golden',
            now: () => now,
            stompClientFactory: (config) {
              final client = FakeStompClient(config);
              clients.add(client);
              return client;
            },
          ),
        ),
      ),
    ),
  );

  final client = clients.single;
  await client.connect();
  for (var i = 0; i < _speeds.length; i++) {
    client.emit(_frame(i, speed: _speeds[i].toDouble()));
  }
  final over = fixture == _Fixture.over;
  client.emit(_frame(
    _speeds.length,
    speed: over ? 74.1 : 62.4,
    rpm: over ? 3120 : 2140,
    engineTemp: over ? 118.4 : 91.2,
    battery: over ? 13.61 : 13.92,
    dtc: over ? const ['P0217'] : const [],
  ));
  await tester.pump();

  switch (fixture) {
    case _Fixture.live || _Fixture.over:
      break;
    case _Fixture.stale:
      now = now.add(const Duration(seconds: 14));
    case _Fixture.reconnecting:
      client.disconnect();
      now = now.add(const Duration(seconds: 6));
  }
  // 게이지·차트 애니메이션(600ms)이 끝나고, 1초 주기 지연 검사가 한 번 돈 뒤를 찍는다.
  await tester.pump(const Duration(milliseconds: 1100));
  await tester.pump();

  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('snapshots/detail/$name.png'),
  );
  if (knownOverflow != null) {
    expect(overflows, isNotEmpty, reason: knownOverflow);
  }
  // 1초 주기 타이머를 끝낸다 — 남으면 테스트가 대기 타이머로 실패한다.
  await tester.pumpWidget(const SizedBox());
}

void main() {
  setUpAll(() async {
    timeago.setLocaleMessages('ko', timeago.KoMessages());
    await loadTestFonts();
  });

  testWidgets(
      '수신 중 360', (t) => _snapDetail(t, 'live_360', fixture: _Fixture.live));
  testWidgets(
      '기준 초과 360', (t) => _snapDetail(t, 'over_360', fixture: _Fixture.over));
  testWidgets('데이터 지연 360',
      (t) => _snapDetail(t, 'stale_360', fixture: _Fixture.stale));
  testWidgets(
      '재연결 중 360',
      (t) =>
          _snapDetail(t, 'reconnecting_360', fixture: _Fixture.reconnecting));
  testWidgets(
      '기준 초과 다크 360',
      (t) => _snapDetail(t, 'over_dark_360',
          fixture: _Fixture.over, brightness: Brightness.dark));
  testWidgets(
      '기준 초과 360 글자 1.5배',
      (t) => _snapDetail(t, 'over_360_scale15',
          fixture: _Fixture.over, textScale: 1.5));
  testWidgets(
      '데이터 지연 320 글자 1.5배',
      (t) => _snapDetail(t, 'stale_320_scale15',
          fixture: _Fixture.stale, width: 320, textScale: 1.5));
  testWidgets('기준 초과 1280',
      (t) => _snapDetail(t, 'over_1280', fixture: _Fixture.over, width: 1280));
}
