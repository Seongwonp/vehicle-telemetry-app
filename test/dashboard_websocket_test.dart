import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:telemetrix/features/dashboard/dashboard_screen.dart';

class FakeStompClient extends StompClient {
  FakeStompClient(StompConfig config) : super(config: config);

  bool activated = false;
  int deactivateCount = 0;
  StompFrameCallback? messageCallback;

  @override
  void activate() => activated = true;

  @override
  void deactivate() {
    deactivateCount++;
    activated = false;
  }

  @override
  StompUnsubscribe subscribe({
    required String destination,
    required StompFrameCallback callback,
    Map<String, String>? headers,
  }) {
    messageCallback = callback;
    return ({Map<String, String>? unsubscribeHeaders}) {};
  }

  Future<void> connect() async {
    await config.beforeConnect();
    config.onConnect(StompFrame(command: 'CONNECTED'));
  }

  void emit(String body) =>
      messageCallback?.call(StompFrame(command: 'MESSAGE', body: body));

  void fail() => config.onWebSocketError(StateError('socket failed'));
  void disconnect() => config.onWebSocketDone();
}

void main() {
  const validTelemetry = '''{
    "vehicleId":"SIM-001",
    "timestamp":"2026-08-04T10:00:00Z",
    "speed":42.0,
    "rpm":1800,
    "engineTemp":90.0,
    "throttlePosition":20.0,
    "fuelLevel":70.0,
    "batteryVoltage":13.8,
    "dtcCodes":[]
  }''';

  const anomalousTelemetry = '''{
    "vehicleId":"SIM-001",
    "timestamp":"2026-08-04T10:00:01Z",
    "speed":201.0,
    "rpm":6001,
    "engineTemp":106.0,
    "throttlePosition":20.0,
    "fuelLevel":5.0,
    "batteryVoltage":15.1,
    "dtcCodes":[]
  }''';

  late List<FakeStompClient> clients;
  late String token;
  late DateTime now;

  setUp(() {
    clients = [];
    token = 'token-1';
    now = DateTime.utc(2026, 8, 4, 10);
  });

  test('API scheme을 WebSocket 보안 scheme으로 변환한다', () {
    expect(
      webSocketUrlForApiBase('https://api.example.com'),
      'wss://api.example.com/ws',
    );
    expect(
      webSocketUrlForApiBase('http://localhost:8080'),
      'ws://localhost:8080/ws',
    );
  });

  Future<void> pumpDashboard(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DashboardTab(
          vehicleId: 'SIM-001',
          tokenLoader: () async => token,
          noSignalTimeout: const Duration(milliseconds: 200),
          staleTimeout: const Duration(milliseconds: 1200),
          now: () => now,
          stompClientFactory: (config) {
            final client = FakeStompClient(config);
            clients.add(client);
            return client;
          },
        ),
      ),
    ));
  }

  testWidgets('수동 재시도 전에 기존 자동 재연결 client를 정리한다', (tester) async {
    await pumpDashboard(tester);
    expect(clients, hasLength(1));

    clients.single.fail();
    await tester.pump();
    await tester.tap(find.text('재시도'));
    await tester.pump();

    expect(clients, hasLength(2));
    expect(clients.first.deactivateCount, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('재연결 직전마다 최신 토큰을 CONNECT header에 넣는다', (tester) async {
    await pumpDashboard(tester);
    final client = clients.single;

    await client.config.beforeConnect();
    expect(
        client.config.stompConnectHeaders?['Authorization'], 'Bearer token-1');
    token = 'token-2';
    await client.config.beforeConnect();
    expect(
        client.config.stompConnectHeaders?['Authorization'], 'Bearer token-2');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('연결 종료와 stale 상태를 마지막 데이터 위에 표시한다', (tester) async {
    await pumpDashboard(tester);
    await clients.single.connect();
    clients.single.emit(validTelemetry);
    await tester.pump();
    expect(find.text('실시간 수신 중'), findsOneWidget);
    expect(find.textContaining('방금 업데이트'), findsOneWidget);

    clients.single.disconnect();
    await tester.pump();
    expect(find.textContaining('재연결 중'), findsOneWidget);

    now = now.add(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.textContaining('데이터 지연'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('malformed frame은 무시하고 다음 정상 frame을 처리한다', (tester) async {
    await pumpDashboard(tester);
    await clients.single.connect();
    clients.single.emit('{not-json');
    await tester.pump();
    expect(tester.takeException(), isNull);

    clients.single.emit(validTelemetry);
    await tester.pump();
    expect(find.text('42'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('백엔드 규칙을 넘는 지표만 이상 기준 초과로 표시한다', (tester) async {
    await pumpDashboard(tester);
    await clients.single.connect();
    clients.single.emit(anomalousTelemetry);
    await tester.pump();

    expect(find.text('이상 기준 초과'), findsNWidgets(2));
    expect(find.text('5.0%'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
