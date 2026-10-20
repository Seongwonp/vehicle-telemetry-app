# Vehicle Telemetry App (Flutter)

차량 실시간 모니터링 모바일 앱. `vehicle-telemetry-platform` 백엔드 API를 사용한다.

- **백엔드 레포**: https://github.com/Seongwonp/vehicle-telemetry-platform
- **기준점**: 태그 `v0.9-pre-vehicle`(`0a4e1b4`) — 백엔드 `911c2e4`와 짝. 실차 작업 전 마지막 기준이다.
- **상태**: OBD-II 동글이 도착할 때까지 일시 중지. 전체 계획은 백엔드
  [`docs/RESUME.md`](https://github.com/Seongwonp/vehicle-telemetry-platform/blob/main/docs/RESUME.md).

## 디자인

밝은 테마가 기본이고 설정에서 시스템·라이트·다크를 고른다(선택값은 인증 토큰과 분리된 로컬 설정에 저장).
화면은 정적 팔레트를 직접 참조하지 않고 `ThemeExtension`(`AppSemanticColors`)과
`design_tokens.dart`의 간격·모서리·글자·내용 폭 토큰만 쓴다. 상태 알약과 선택 칩은
공통 위젯(`StatusPill`, `AppChoiceChip`)으로 모았다. 라틴·숫자는 Manrope, 한글은 나눔고딕을
앱에 번들한다(둘 다 OFL). 규칙과 이유는 [`docs/design-system.md`](docs/design-system.md).

## 현재 검증 상태

| 항목 | 상태 |
| --- | --- |
| format / analyze / unit·widget test | GitHub Actions `verify` 잡(ubuntu). 테스트 통과의 근거는 CI다 |
| 골든 스냅샷 비교 | GitHub Actions `golden` 잡(Windows) — 비교만, 기준 이미지는 갱신하지 않는다 |
| 320~1280px, 글자 배율 1.0/1.3/1.5 overflow | widget test |
| WebSocket 재연결·stale·malformed·역전·동일 timestamp | unit/widget test |
| Android 15 에뮬레이터 — 로그인·수신·원천 정지 후 stale·복구 | 1회 확인 ([2026-09-16](docs/verification/2026-09-16-android-emulator.md)) |
| Android 15 에뮬레이터 — 비밀번호 변경, 관리자·일반 사용자 메뉴 노출(실제 로컬 백엔드) | 1회 확인 ([2026-10-07](docs/verification/2026-10-07-android-emulator-auth-roles.md)) |
| 2026-10-17 차량 목록 화면 변경(로그인 전 미리보기·상태 요약) | widget test·골든만. 에뮬레이터 미확인 |
| '미수신' 표시(연료량·전압 없음) | widget test만. 실제 차량 데이터로는 미검증 |
| 실제 소켓 단절·재연결(백엔드를 내렸다 올림) | 미검증 — widget test로만 확인 |
| 실기기 조작, 다크 모드·글자 1.5배 기기 확인 | 미검증 |
| 실제 백엔드 integration test | 테스트 파일은 있으나 macOS Keychain entitlement로 로그인 후 차단, Android에서는 미실행 |
| iOS | 플랫폼 미추가 |

## 화면 구성

| 화면 | 설명 |
|------|------|
| 부팅 | 저장된 토큰을 확인하는 동안 보이는 Telemetrix 로고 화면 |
| 차량 목록(첫 화면) | 로그인 전에는 "로그인 전 미리보기"와 로그인 버튼. 로그인 후에는 상태 요약(확인 필요 대수) + 카드별 최근 수신·오래전 수신·오프라인·데이터 없음, 최근 속도, HIGH 이상 건수 |
| 로그인 | JWT 인증 |
| 차량 등록 | 관리자만. 소유자 계정을 비우면 관리자 본인에게 배정 |
| 차량 상세 | 현재 상태/이상 이력/주행 기록/보조 진단 TabBar + 스와이프, 탭 상태 유지 |
| 현재 상태 | STOMP WebSocket 실시간 수치 타일 + 연결·재연결·데이터 지연 상태 + 역전·동일 timestamp 방어 + 속도 추이·경로. 지연·재연결 중엔 큰 숫자를 비우고 지난 값은 작게. 연료량·전압이 오지 않으면 0이 아니라 '미수신'(백엔드 ADR-030). 기준 초과 시 '이상 이력 보기' |
| 이상 이력 | 감지된 이상 이벤트 목록 + 심각도/기간 필터 |
| 보조 진단 | 센서·DTC·이상 이력을 바탕으로 사용자가 요청할 때 생성하는 참고 결과 |
| 설정 | 계정 정보, 비밀번호 변경, 시스템·라이트·다크 테마, 로그아웃 |
| 비밀번호 변경 | 현재·새·확인 입력(8~72자). 성공하면 로그아웃 후 다시 로그인 |

역할별 메뉴: 차량 등록 버튼(앱바 `+`, 빈 화면 버튼)과 카드의 삭제(`⋮`) 메뉴는 관리자에게만 보인다.

`lib/features/landing/`(예전 첫 화면)은 2026-10-17 변경 뒤 진입 경로가 없다.

## 시작하기

```bash
# 1. 의존성 설치
flutter pub get

# 2. 로컬 실행 (기본값 http://localhost:8080)
flutter run

# 다른 개발 서버 / Android 에뮬레이터(호스트의 localhost는 10.0.2.2)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080

# 운영 release 빌드: 토큰 보호를 위해 non-local HTTPS URL이 필수다.
# 누락하거나 http:// URL을 주면 앱 시작 단계의 설정 검증이 실패한다.
# 서명은 ANDROID_KEYSTORE_FILE·ANDROID_KEYSTORE_PASSWORD·ANDROID_KEY_ALIAS·ANDROID_KEY_PASSWORD
# 환경 변수로만 넣는다(없으면 서명 없이 빌드되고 debug 키로 서명하지 않는다).
flutter build apk --release \
  --dart-define=API_BASE_URL=https://api.example.com
```

## 백엔드 연동

차량 등록·소유자 배정·삭제(비활성화)는 백엔드에서 관리자 전용이다. 앱은 `GET /api/auth/me`의
roles에 `ROLE_ADMIN`이 있을 때만 등록 버튼과 삭제 메뉴를 보인다. 권한 조회가 실패하면 닫힘(버튼 없음)이고,
일반 사용자에게는 관리자에게 배정을 요청하라고 안내한다. 소유자에는 표시 이름이 아닌 등록된 계정 이름을 입력한다.
비밀번호 변경은 `POST /api/auth/password`를 쓴다. 401은 refresh 후 한 번만 재시도하고, refresh가 401·403일 때만 토큰을 지운다.

백엔드 실행은 백엔드 README의 "실행" 절을 따른다(평문 dev):

```bash
# vehicle-telemetry-platform 디렉토리에서
docker compose -f docker-compose.yml -f docker-compose.dev.yml --profile simulator up -d
```

## 프로젝트 구조

화면마다 `<feature>_screen.dart`(State, API 호출, 네비게이션)와 `widgets/`(순수 표현용
StatelessWidget)를 분리했다.

```
lib/
├── main.dart                       # 인증 상태별 첫 화면(부팅 / 차량 목록)
├── core/
│   ├── api/api_client.dart         # Dio 클라이언트 + JWT interceptor(401 refresh 1회)
│   ├── auth/                       # auth_provider(Riverpod), token_storage
│   ├── models/                     # vehicle, telemetry, telemetry_limits, anomaly, trip
│   ├── navigation/navigator_key.dart
│   ├── providers/                  # vehicle / anomaly / trip providers
│   ├── responsive/breakpoints.dart
│   ├── settings/local_settings.dart # 테마 선택값 저장
│   ├── theme/                      # app_theme, design_tokens, theme_provider
│   └── widgets/                    # arc_gauge, status_pill, choice_chip
└── features/
    ├── boot/boot_screen.dart
    ├── landing/                    # 진입 경로 없음(위 참고)
    ├── login/login_screen.dart
    ├── vehicle_list/               # vehicle_list_screen, add_vehicle_screen
    │   └── widgets/                # vehicle_card, empty_view, error_view, info_chip
    ├── vehicle_detail/             # 4개 탭 컨테이너 + widgets/vehicle_title
    ├── dashboard/                  # 현재 상태 탭: dashboard_screen, dashboard_view_state
    │   └── widgets/                # metric_tile(_grid), status_summary, extra_readings,
    │                               # speed_chart, route_map, dtc_section 등
    ├── anomalies/                  # anomaly_list_screen + widgets/
    ├── trips/trip_history_tab.dart
    ├── diagnosis/                  # diagnosis_screen + widgets/
    └── settings/                   # settings_screen, change_password_screen
```

## 테스트

```bash
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
flutter test
```

단위/위젯 테스트는 모델 파싱, API refresh 경계, 차량 CRUD·등록 권한 계약, WebSocket 재연결·stale·malformed
frame·역전 및 동일 timestamp, 현재 상태 탭 판정과 배치, 비밀번호 변경, 인증 초기화·로그인·로그아웃,
에러/빈 상태, 반응형 overflow를 검증한다. 실제 백엔드 통합 흐름은 `integration_test/app_test.dart`에 있다.

CI(`.github/workflows/ci.yml`)가 매 push마다 위 세 단계와 Windows 골든 비교를 실행한다. 노트북에서는
`flutter_tester`가 isolate를 만들지 못하고 죽어 `flutter test`를 돌릴 수 없으므로 테스트 결과는 CI로 본다.
마지막 로컬 기록은 2026-10-07의 470건 통과(skip 2 = 골든)이고, 그 뒤 테스트가 바뀌었으므로 현재 수치는 CI 기준이다.
통합 테스트와 실기기 조작은 CI 범위가 아니다.
