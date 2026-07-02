# 개발 일지 (Dev Log)

> 날짜별 작업 내용, 결정 사항, 이유를 기록한다. (`vehicle-telemetry-platform`의 devlog와 같은 방식)

---

## 2026-07-02

### UI 전면 개편 — 테마, 파일 구조, 반응형, 랜딩페이지

백엔드(vehicle-telemetry-platform) Phase 6~10을 마무리한 뒤, 앱 쪽도 정리했다.
계기는 단순: 기본 Material 3 dark 시드 테마 그대로 쓰고 있어서 화면이 밋밋했고,
포트폴리오 첫 화면(스크린샷)이 로그인 폼이라 인상이 약했다.

**1. 다크 테마 도입 (`lib/core/theme/app_theme.dart`)**

기존엔 `ColorScheme.fromSeed(seedColor: Color(0xFF1565C0))` 하나만 지정하고
나머지는 화면마다 `Colors.redAccent`, `Colors.orange`, `Colors.grey.shade400` 같은
리터럴을 따로 하드코딩하고 있었다. 화면별로 톤이 미묘하게 달랐던 이유.

- `AppTheme` 클래스에 배경/표면/텍스트/시맨틱(success/warning/danger) 색상을 한 곳에 정의.
- `InputDecorationTheme`, `CardThemeData`, `FilledButtonThemeData` 등을 커스텀해서
  기본 Material 아웃라인 필드 대신 filled + rounded 14px 필드로 변경.
- `AppSemanticColors`(`ThemeExtension`)로 success/warning/danger를 테마에 등록 —
  화면 코드에서 `Colors.redAccent` 대신 `AppTheme.danger`를 쓰도록 전체 화면 교체.

**2. 파일 구조 재편**

화면당 파일 하나에 State + private 위젯이 전부 뭉쳐 있었다(대시보드는 500줄 넘음).
`features/<feature>/widgets/`로 재사용 가능한 표현용 위젯을 분리:

```
features/<feature>/
  <feature>_screen.dart   # State, API 호출, 네비게이션만
  widgets/
    ...                   # 순수 표현용 StatelessWidget
```

State/네비게이션 로직은 스크린 파일에 남기고, 카드/배너/차트처럼 "데이터를 받아
그리기만 하는" 위젯만 옮겼다. 재사용 안 되는 것까지 무리하게 쪼개진 않았다.

**3. 반응형 (`lib/core/responsive/breakpoints.dart`)**

모바일 앱이 기본이지만 웹 브라우저(데스크톱 폭)로도 열어볼 상황이 많아서
(포트폴리오 시연, 이번 세션의 Preview 툴 검증 등) 데스크톱에서 안 깨지게 손봤다.

- `BuildContext.isMobile` / `isDesktop` 확장 — 600px / 1024px 기준.
- 차량 목록: 모바일은 세로 리스트, 데스크톱은 2~3열 그리드.
- 대시보드: 보조지표 그리드 모바일 2열 → 데스크톱 4열, 전체 폭 900px로 제한.
- 이상이력/AI진단: 넓은 화면에서 텍스트가 과도하게 안 늘어나도록 700~800px 제한.

**4. 랜딩페이지 (`features/landing/`)**

첫 화면을 로그인 폼에서 랜딩페이지로 교체(`main.dart`: `isLoggedIn ? VehicleList : Landing`).
랜딩의 "시작하기" 버튼이 로그인 화면으로 push.

- 히어로(로고+타이틀+태그라인) + **라이브 데이터 프리뷰 카드** + 기능 소개 카드 4개.
- 라이브 프리뷰는 로그인 전이라 실제 API를 호출할 수 없어서 순수 장식 —
  `Timer.periodic`으로 속도/RPM/온도를 완만하게 흔들며 `fl_chart` 라인차트에 그린다.
  실제 대시보드(`SpeedChart`)와 톤을 맞춰서 "이 앱이 진짜 하는 일"을 미리 보여주는 용도.
- 진입 애니메이션은 `AnimationController` 하나를 여러 `Interval`로 나눠 히어로 →
  라이브 프리뷰 → 기능카드 순으로 stagger.
- 데스크톱: 히어로(좌)/라이브 프리뷰(우) 2단, 기능카드 4열.
  모바일: 세로 스택, 기능카드 2열.

**트러블슈팅**: 기능카드 설명 텍스트를 `childAspectRatio` 기반 그리드에 넣었더니
모바일 폭에서 텍스트가 카드보다 커서 "BOTTOM OVERFLOWED" 에러가 났다.
원인 두 가지 — (1) 설명 문구에 수동으로 `\n`을 넣어놨는데 좁은 폭에서 자동 줄바꿈까지
겹쳐서 의도한 2줄이 3줄이 됐던 것, (2) `childAspectRatio`는 폭이 좁아지면 높이도 같이
줄어들어 텍스트 길이 변화에 취약함. `mainAxisExtent`(고정 높이)로 바꾸고, 설명 문구도
수동 줄바꿈 없이 짧게 다시 써서 해결.

---

## 로컬에서 다시 시작할 때

```bash
flutter pub get
flutter run
```

웹 프리뷰: `flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080`
(백엔드 `vehicle-telemetry-platform`이 먼저 떠 있어야 함)
