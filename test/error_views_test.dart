import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telemetrix/features/anomalies/widgets/error_view.dart';
import 'package:telemetrix/features/dashboard/widgets/error_view.dart';

// 코덱스 리뷰에서 지적된 문제(대시보드/이상이력 화면이 조회 실패를 "데이터 없음"/
// "이상 없음(정상)"으로 잘못 보여주던 것)를 고치며 새로 만든 전용 에러 뷰들이
// 실제로 렌더링되고 재시도 콜백을 호출하는지 확인한다.
void main() {
  group('DashboardErrorView', () {
    testWidgets('실패 메시지를 보여주고 재시도 버튼이 콜백을 호출한다', (tester) async {
      var retried = false;

      await tester.pumpWidget(MaterialApp(
        home: DashboardErrorView(onRetry: () => retried = true),
      ));

      expect(find.text('센서 데이터를 불러오지 못했습니다'), findsOneWidget);
      // "데이터 없음"(NoDataView 전용 문구)과 혼동되지 않아야 한다.
      expect(find.text('데이터 없음'), findsNothing);

      await tester.tap(find.text('재시도'));
      expect(retried, isTrue);
    });
  });

  group('AnomalyErrorView', () {
    testWidgets('실패 메시지를 보여주고 재시도 버튼이 콜백을 호출한다', (tester) async {
      var retried = false;

      await tester.pumpWidget(MaterialApp(
        home: AnomalyErrorView(onRetry: () => retried = true),
      ));

      expect(find.text('이상 이력을 불러오지 못했습니다'), findsOneWidget);
      // "이상 이벤트 없음"(정상 상태)과 혼동되면 안 된다 — 실패를 성공처럼 보여주는
      // 문제를 재발시키는 회귀를 잡기 위한 검증.
      expect(find.text('이상 이벤트 없음'), findsNothing);

      await tester.tap(find.text('재시도'));
      expect(retried, isTrue);
    });
  });
}
