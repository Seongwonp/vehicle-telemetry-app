# 디자인 다음 단계 (라이트 테마 전환 + 고도화)

> 이 문서는 다음 세션에서 이어서 작업하기 위한 작업 목록이다. 현재까지 상태와 결정 사항을 먼저 정리하고, 그 다음 할 일을 적는다.

---

## 지금까지 상태 (2026-07-04 기준)

- `lib/core/theme/app_theme.dart`에 다크 테마(`AppTheme.dark()`)를 만들어 전 화면에 적용함. 배경 `#090D15`, 표면 `#141A26`, 텍스트/시맨틱 컬러(success/warning/danger) 전부 이 파일에 중앙화돼 있음.
- 화면 구조를 `features/<feature>/widgets/`로 분리 완료 (로그인/차량목록/대시보드/이상이력/AI진단/랜딩 전부).
- 반응형(`core/responsive/breakpoints.dart`) 적용 완료 — 모바일/데스크톱 레이아웃 분기.
- 랜딩페이지(`features/landing/`) 신규 추가, 첫 화면이 로그인이 아니라 랜딩 → "시작하기" → 로그인 흐름으로 바뀜.
- 로그인/로그아웃 시 `Navigator.pushAndRemoveUntil`로 명시적 화면 전환 처리 (Flutter의 `home: 조건 ? A : B` 패턴이 이미 push된 라우트 위에서는 안 먹히는 문제를 발견해서 고침).
- 랜딩페이지의 "라이브 프리뷰" 카드(가짜 실시간 데이터를 보여주던 것)는 "로그인 안 했는데 로그인된 것처럼 보인다"는 피드백으로 제거하고, 숫자 없는 순수 홍보용 그래픽(`widgets/promo_visual.dart`)으로 교체함.

## 이번에 받은 피드백 — 배경색이 마음에 안 듦

지금 다크 테마(진한 남색 배경)가 별로라서 **흰 배경(라이트 테마) 위주로 다시 가고 싶다.**

---

## 할 일 1 — 라이트 테마로 전환

`lib/core/theme/app_theme.dart`의 색상 상수만 교체하면 대부분의 화면에 자동 반영된다(색을 하드코딩하지 않고 `AppTheme.xxx`를 참조하도록 이미 리팩터링해뒀기 때문). 다만 아래 항목들은 다크 전제로 짜여 있어서 값만 바꾸는 것 이상으로 손을 봐야 한다:

- **배경/표면 색상**: `bg`, `surface`, `surfaceHigh`, `border`를 흰색·연한 회색 계열로 (예: `bg = #FFFFFF` 또는 `#F7F8FA`, `surface = #FFFFFF` 카드+그림자 또는 `#F5F6F8`, `border = #E5E7EB`, `textPrimary = #1A1D29`, `textSecondary = #6B7280`).
- **시맨틱 컬러(success/warning/danger/primary)**: 다크 배경 대비로 맞춰둔 채도라 흰 배경에서는 너무 흐리거나 반대로 튈 수 있음 — 대비 다시 확인.
- **로그인/랜딩 화면의 배경 그라디언트**: `login_screen.dart`, `landing_screen.dart`에 있는 `RadialGradient`가 `Color(0xFF17264A)` 같은 다크 전용 색을 하드코딩하고 있음. 흰 배경에 어울리는 아주 옅은 톤(또는 그라디언트 없이 플랫 화이트)으로 재작업 필요.
- **`fl_chart` 관련 하드코딩**: `dashboard/widgets/speed_chart.dart`의 그리드 라인 색이 `Colors.white.withOpacity(0.06)`으로 다크 배경 전제 — 흰 배경에서는 안 보이니 `Colors.black.withOpacity(0.06)` 등으로 교체.
- **아이콘/그림자**: 다크 테마에서 잘 보이던 `BoxShadow(color: AppTheme.primary.withOpacity(0.35))` 같은 은은한 글로우 효과가 흰 배경에서는 안 어울릴 수 있음 — 톤 다운하거나 제거 검토.

라이트/다크 토글 기능까지는 필요 없음(요청받은 건 아님) — 그냥 `AppTheme.dark()`의 값 자체를 라이트 팔레트로 바꾸는 정도로 스코프 유지.

## 할 일 2 — 디자인 고도화 (토스 스타일 계속 밀고 나가기)

랜딩페이지에 적용한 방향(테두리 없는 플랫 카드, 큰 radius, 넉넉한 여백, 굵고 큰 헤드라인)을 다른 화면에도 일관되게 적용:

- **차량목록**: `VehicleCard`도 테두리 있는 카드 스타일 → 랜딩 피처카드처럼 플랫하게.
- **대시보드**: `PrimaryMetricCard`/`SecondaryMetricCard`가 지금은 테두리+반투명 배경 방식 — 톤 통일 검토.
- **이상이력/AI진단**: 카드 스타일 통일.
- 전체적으로 폰트 크기/굵기 위계(헤드라인-본문-캡션)를 랜딩페이지 수준으로 다른 화면에도 맞추기.

## 참고

- 관리자 로그인: `admin` / `changeme` (docker-compose.yml이 `.env`의 `ADMIN_PASSWORD`를 백엔드 컨테이너로 전달하지 않아서 스프링 기본값이 적용되고 있음 — 이것도 고칠지 결정 필요. `.env`엔 `localpassword123`으로 적혀있지만 실제로는 무시됨).
- 로컬 실행: `docker compose up -d` (백엔드 레포에서) 후 `flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080`.
- 시뮬레이터로 실데이터 흐르게 하려면 백엔드 레포의 `simulator/vehicle_simulator.py` 실행 (차량 `SIM-001`이 이미 등록돼 있음).
