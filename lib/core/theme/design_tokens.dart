import 'package:flutter/widgets.dart';

/// 간격·반경·글자 크기의 단일 출처. 4pt 그리드를 따른다(docs/design-system.md).
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

/// 모서리 반경. 칩·배지는 [pill], 일반 요소는 [sm], 카드는 [md], 시트·모달은 [lg].
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

/// 글자 크기 6단. 계측 수치는 [display]/[title]에 tabular figures 서체를 쓴다.
class FontSizes {
  FontSizes._();

  /// 32 — 대시보드의 대표 수치 하나, 랜딩 제목.
  static const double display = 32;

  /// 24 — 600px 미만 폭의 제목. 32px이면 좁은 화면에서 고아 줄이 생긴다.
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

/// 터치 타겟 최소 크기. 작아 보이는 아이콘 버튼도 눌리는 영역은 이 값을 지킨다.
class TouchTarget {
  TouchTarget._();

  static const double min = 48;
}

/// 화면 너비 구간.
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

/// 화면 높이 구간. 폭만 보면 가로 모드 폰을 태블릿으로 오해한다.
class Heights {
  Heights._();

  /// 480 — 이 아래는 가로 모드 폰으로 본다. 앱바가 세로로 커지면 본문이 거의 남지 않으므로
  /// 여러 줄로 늘어나는 머리글은 한 줄로 줄인다.
  static const double compactLandscape = 480;
}

/// 내용의 최대 폭. 화면 폭이 아니라 내용의 종류로 고른다.
class ContentWidths {
  ContentWidths._();

  /// 480 — 입력 한 열. 로그인, 차량 등록처럼 필드를 세로로 쌓는 화면.
  static const double form = 480;

  /// 640 — 읽는 한 열. 설정, 진단 결과처럼 문장이 이어지는 화면(권장 행 길이 기준).
  static const double reading = 640;

  /// 840 — 카드 한 열. 이상 이력처럼 카드를 세로로 쌓는 목록.
  static const double feed = 840;

  /// 1200 — 여러 열. 대시보드 계측 그리드, 차량 목록 그리드, 랜딩.
  static const double grid = 1200;
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
