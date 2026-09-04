import 'package:flutter/widgets.dart';

/// 간격·반경·글자 크기의 단일 출처.
///
/// 색은 이미 `AppSemanticColors`로 토큰화돼 있었는데 나머지는 아니었다.
/// 실제로 세어보니 화면마다 눈으로 맞춘 흔적이 그대로 남아 있었다:
///
/// ```
/// padding       19종 (3, 5, 7, 9, 11 …)
/// borderRadius  10종 (7, 8, 10, 12, 14, 16, 18, 20, 28 …)
/// 간격          18종 (2, 3, 6, 10, 14, 18 …)
/// fontSize      15종 (9.5, 10.5, 11.5, 12.5 …)
/// ```
///
/// 반 포인트 글자 크기와 3·5·7·9·11 패딩은 스케일 없이 그때그때 맞췄다는 뜻이다.
/// 값 하나하나는 그럴듯해 보여도 모아놓으면 리듬이 없어서, 화면을 넘길 때마다
/// 미묘하게 다른 앱처럼 느껴진다.
///
/// 그래서 4pt 그리드로 수렴시킨다. Material과 Apple HIG가 공통으로 쓰는 기준이고,
/// 아이콘·조밀한 수치 표시에는 4의 배수가, 레이아웃에는 8의 배수가 맞는다.
class Spacing {
  Spacing._();

  /// 4 — 아이콘과 라벨 사이처럼 붙어 있어야 하는 것.
  static const double xxs = 4;

  /// 8 — 같은 덩어리 안의 요소 사이.
  static const double xs = 8;

  /// 12 — 카드 내부의 행 사이.
  static const double sm = 12;

  /// 16 — 카드 안쪽 여백, 화면 좌우 여백의 기본값.
  static const double md = 16;

  /// 24 — 서로 다른 덩어리(섹션) 사이.
  static const double lg = 24;

  /// 32 — 화면 상단/하단의 큰 여백.
  static const double xl = 32;

  /// 48 — 랜딩처럼 여백 자체가 메시지인 곳에서만.
  static const double xxl = 48;
}

/// 모서리 반경. 10종을 4종으로 줄인다.
///
/// 반경이 여러 개면 "무엇이 더 중요한 요소인가"를 반경으로 말할 수 없게 된다.
/// 칩·배지는 [pill], 일반 요소는 [sm], 카드는 [md], 시트·모달은 [lg]로 고정한다.
class Radii {
  Radii._();

  /// 8 — 버튼, 입력창, 작은 컨테이너.
  static const double sm = 8;

  /// 12 — 카드. 이 앱의 기본 표면 단위다.
  static const double md = 12;

  /// 20 — 바텀시트, 모달처럼 화면을 덮는 표면.
  static const double lg = 20;

  /// 999 — 상태 배지, 칩.
  static const double pill = 999;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));
}

/// 글자 크기. 15종(반 포인트 포함)을 6단으로 줄인다.
///
/// 계측 수치(속도, 온도 같은 것)는 별도 단이 아니라 [display]/[title]을 쓰고
/// 서체만 tabular figures로 바꾼다 — 숫자가 바뀔 때 폭이 흔들리지 않아야 한다.
class FontSizes {
  FontSizes._();

  /// 32 — 대시보드의 대표 수치 하나, 랜딩 제목.
  static const double display = 32;

  /// 24 — 태블릿 미만(600px 미만) 폭의 제목.
  ///
  /// 한글 제목은 32px에서 360px 화면에 한 줄이 안 들어가 고아 줄이 생긴다
  /// ("차량 상태와 데이터 / 흐름을 / 한눈에 확인하기"). 줄바꿈 위치를 손으로
  /// 잡는 대신 글자를 한 단 줄여 자연스럽게 두 줄이 되게 한다.
  static const double displayCompact = 24;

  /// 20 — 화면 제목.
  static const double title = 20;

  /// 16 — 카드 제목, 강조 본문.
  static const double subtitle = 16;

  /// 14 — 본문 기본값.
  static const double body = 14;

  /// 12 — 보조 설명, 라벨.
  static const double caption = 12;

  /// 11 — 배지 안의 글자. 이보다 작게는 쓰지 않는다.
  static const double badge = 11;
}

/// 터치 타겟 최소 크기.
///
/// 모바일 UI 가이드가 공통으로 44~48px를 권한다. 시각적으로 작아 보여야 하는
/// 아이콘 버튼도 눌리는 영역은 이 값을 지켜야 한다.
class TouchTarget {
  TouchTarget._();

  static const double min = 48;
}

/// 화면 너비 구간.
///
/// 기존 `Breakpoints`에는 600과 1024만 있었는데, AGENTS.md 체크리스트는
/// 320px까지 지원한다고 적어두고 있었다. 검사해보니 실제로 320px에서
/// 차량 카드가 기본 글자 크기로도 99px 넘쳐 잘리고 있었다.
class Widths {
  Widths._();

  /// 320 — 지원하는 최소 너비. 이 아래는 대상이 아니다.
  static const double compact = 320;

  /// 360 — 흔한 안드로이드 폰 너비.
  static const double regular = 360;

  /// 600 — 이 위부터 태블릿 레이아웃.
  static const double tablet = 600;

  /// 1024 — 데스크톱 브라우저.
  static const double desktop = 1024;
}

extension SpacingContext on BuildContext {
  /// 화면 좌우 여백. 좁은 화면에서는 한 단계 줄여 내용 폭을 확보한다.
  double get screenPadding =>
      MediaQuery.sizeOf(this).width < Widths.regular ? Spacing.sm : Spacing.md;

  /// 320px대 좁은 화면인지. 이때는 부가 정보를 접거나 줄바꿈을 허용한다.
  bool get isCompactWidth => MediaQuery.sizeOf(this).width < Widths.regular;

  /// 제목 크기. 좁은 화면에서는 한 단 줄인다.
  double get displayFontSize => MediaQuery.sizeOf(this).width < Widths.tablet
      ? FontSizes.displayCompact
      : FontSizes.display;
}
