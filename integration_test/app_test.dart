// 실제 위젯 트리를 찾아서(find.text/find.byKey) 탭하는 통합 테스트다 — 렌더링
// 픽셀 좌표에 의존하는 브라우저 자동화(CanvasKit 캔버스)와 달리 화면이 어떻게
// 그려지는지와 무관하게 동작한다.
//
// 전제 조건:
//   - vehicle-telemetry-platform 백엔드가 로컬에서 떠 있어야 한다
//     (해당 레포에서 `docker compose up -d`)
//   - 최소 1대 이상의 차량이 등록돼 있어야 한다
//   - 기본 테스트 계정은 admin/localpassword123(로컬 .env 기준). 다른 계정을
//     쓰려면 --dart-define으로 덮어쓴다.
//
// 실행 (macOS 데스크톱 — `flutter test`로 직접 실행 가능):
//   flutter test integration_test/app_test.dart -d macos \
//     --dart-define=TEST_USERNAME=admin \
//     --dart-define=TEST_PASSWORD=localpassword123
//
// 웹은 `flutter test -d chrome`으로 통합 테스트를 못 돌린다(엔진 제약 —
// "Web devices are not supported for integration tests yet") — 대신
// `flutter drive --driver=test_driver/integration_test.dart
// --target=integration_test/app_test.dart -d chrome`와 별도 드라이버 스크립트가
// 필요하다(아직 준비 안 함).
//
// 알려진 한계: 이 프로젝트의 macOS 빌드는 ad-hoc 서명(실제 Apple Developer
// Team 미설정)이라 로그인 이후 flutter_secure_storage의 Keychain 쓰기가
// `PlatformException(-34018, "A required entitlement isn't present.")`로
// 실패한다 — 그래서 이 테스트는 현재 로그인 단계에서 막힌다. App Sandbox를
// 꺼봐도 동일하게 실패해 원인이 샌드박스가 아니라 서명 자체임을 확인했다.
// Xcode에서 실제 Apple ID로 개발자 서명을 설정해야 풀리는 문제라 이 세션에서는
// 해결하지 못했다. iOS 플랫폼은 이 프로젝트에 아직 추가되지 않았다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:telemetrix/features/login/login_screen.dart';
import 'package:telemetrix/features/vehicle_detail/vehicle_detail_screen.dart';
import 'package:telemetrix/features/vehicle_list/vehicle_list_screen.dart';
import 'package:telemetrix/features/vehicle_list/widgets/vehicle_card.dart';
import 'package:telemetrix/main.dart' as app;

const _testUsername =
    String.fromEnvironment('TEST_USERNAME', defaultValue: 'admin');
const _testPassword =
    String.fromEnvironment('TEST_PASSWORD', defaultValue: 'localpassword123');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('로그인 → 차량목록 → 차량 상세(탭 스와이프) → 로그아웃', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // ── 랜딩 → 로그인 화면 ──────────────────────────────────────
    expect(find.text('시작하기'), findsOneWidget);
    await tester.tap(find.text('시작하기'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);

    // ── 로그인 ──────────────────────────────────────────────────
    // 데스크톱 플랫폼에서는 enterText 전에 명시적으로 탭해서 포커스를 주지 않으면
    // 값이 실제로 안 채워지는 경우가 있어, 필드마다 탭 → pump → enterText → pump 순서로 한다.
    await tester.tap(find.byKey(const Key('login_username_field')));
    await tester.pump();
    await tester.enterText(
        find.byKey(const Key('login_username_field')), _testUsername);
    await tester.pump();

    await tester.tap(find.byKey(const Key('login_password_field')));
    await tester.pump();
    await tester.enterText(
        find.byKey(const Key('login_password_field')), _testPassword);
    await tester.pump();

    await tester.tap(find.byKey(const Key('login_submit_button')));

    // 네트워크 왕복이 걸리니 pumpAndSettle 한 번으로는 부족할 수 있다 — 최대 15초까지
    // 짧은 간격으로 반복 pump하며 화면 전환을 기다린다(고정 시간 대기보다 안정적).
    var navigated = false;
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 500));
      if (find.byType(VehicleListScreen).evaluate().isNotEmpty) {
        navigated = true;
        break;
      }
    }
    await tester.pumpAndSettle();

    if (!navigated) {
      final errorTexts = find
          .byType(Text)
          .evaluate()
          .map((e) => (e.widget as Text).data)
          .whereType<String>()
          .where((t) => t.isNotEmpty)
          .toList();
      fail('로그인 후 15초 내에 차량 목록으로 전환되지 않았다. 현재 화면에 보이는 텍스트: '
          '$errorTexts');
    }

    expect(find.byType(VehicleListScreen), findsOneWidget);

    // ── 차량 목록 → 대시보드 ────────────────────────────────────
    expect(
      find.byType(VehicleCard),
      findsWidgets,
      reason: '등록된 차량이 없습니다 — 백엔드에 최소 1대 이상 등록돼 있어야 합니다.',
    );
    await tester.tap(find.byType(VehicleCard).first);
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(find.byType(VehicleDetailScreen), findsOneWidget);

    // ── 탭 전환: 현재 상태(기본) → 이상 이력 → 주행 기록 → 보조 진단 ──
    // TabBarView는 네 탭을 전부 미리 마운트해두므로(스와이프 지연 없이 즉시
    // 전환), 위젯이 "존재"하는지가 아니라 TabController.index로 "지금 보이는
    // 탭이 맞는지"를 확인한다.
    final tabController =
        DefaultTabController.of(tester.element(find.byType(TabBar)));
    expect(tabController.index, 0);

    await tester.tap(find.widgetWithText(Tab, '이상 이력'));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(tabController.index, 1);

    await tester.tap(find.widgetWithText(Tab, '주행 기록'));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(tabController.index, 2);
    expect(find.text('1시간'), findsOneWidget);

    await tester.tap(find.widgetWithText(Tab, '보조 진단'));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(tabController.index, 3);
    expect(find.text('고장진단하기'), findsOneWidget);

    // 차량 목록으로 복귀
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(VehicleListScreen), findsOneWidget);

    // ── 설정 → 로그아웃 → 랜딩 화면 복귀 ─────────────────────────
    await tester.tap(find.byTooltip('설정'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('로그아웃'));
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(find.text('시작하기'), findsOneWidget);
  });
}
