# Vehicle Telemetry App (Flutter)

차량 실시간 모니터링 모바일 앱. `vehicle-telemetry-platform` 백엔드 API를 사용한다.

- **백엔드 레포**: https://github.com/Seongwonp/vehicle-telemetry-platform

## 디자인

`lib/core/theme/app_theme.dart`의 밝은 테마를 기본으로 사용한다. 흰 카드와 중립적인 회색
배경, 블루 포인트, Manrope 서체로 차량 데이터의 판독성을 우선했다.
화면은 정적 팔레트를 직접 참조하지 않고 `ThemeExtension`으로 배경·표면·경계·텍스트
색상을 조회한다. 설정에서 시스템·라이트·다크 모드를 선택할 수 있고 선택값은
인증 토큰과 분리된 로컬 설정에 저장된다.
반응형(`lib/core/responsive/breakpoints.dart`)도 적용되어 모바일/데스크톱(웹) 폭에서
레이아웃이 분기된다.

## 화면 구성

| 화면 | 설명 |
|------|------|
| 랜딩 | 첫 진입 화면 — 서비스 소개 + "시작하기" → 로그인 |
| 로그인 | JWT 인증 |
| 차량 목록 | 마지막 신호 기준 정상·지연·오프라인, 최근 속도, HIGH 이상 건수 요약 |
| 차량 상세 | 현재 상태/이상 이력/주행 기록/보조 진단 TabBar + 스와이프, 탭 상태 유지 |
| 대시보드 | STOMP WebSocket 실시간 센서 + 재연결/stale 상태 + 속도 추이 차트 |
| 이상 이력 | 감지된 이상 이벤트 목록 + 심각도/기간 필터 |
| 보조 진단 | 센서·DTC·이상 이력을 바탕으로 사용자가 요청할 때 생성하는 참고 결과 |
| 설정 | 계정 정보, 시스템·라이트·다크 테마, 로그아웃 |

## 시작하기

```bash
# 1. 의존성 설치
flutter pub get

# 2. 로컬 실행 (기본값 http://localhost:8080)
flutter run

# 다른 개발 서버 사용
flutter run --dart-define=API_BASE_URL=http://<개발서버>:8080

# 운영 release 빌드: 토큰 보호를 위해 non-local HTTPS URL이 필수다.
# 누락하거나 http:// URL을 주면 앱 시작 단계의 설정 검증이 실패한다.
flutter build apk --release \
  --dart-define=API_BASE_URL=https://api.example.com
```

## 백엔드 연동

`vehicle-telemetry-platform` 프로젝트의 Spring Boot 서버가 실행 중이어야 함.

```bash
# 백엔드 실행 (vehicle-telemetry-platform 디렉토리에서)
docker compose up -d
# IntelliJ에서 TelemetryApplication 실행
```

## 프로젝트 구조

화면마다 `<feature>_screen.dart`(State, API 호출, 네비게이션)와 `widgets/`(순수 표현용
StatelessWidget)를 분리했다.

```
lib/
├── main.dart
├── core/
│   ├── api/api_client.dart         # Dio HTTP 클라이언트 + JWT interceptor
│   ├── auth/
│   │   ├── auth_provider.dart      # Riverpod 로그인 상태 관리
│   │   └── token_storage.dart      # JWT 토큰 안전 저장
│   ├── models/
│   │   ├── vehicle.dart
│   │   ├── telemetry.dart
│   │   └── anomaly.dart
│   ├── responsive/breakpoints.dart # isMobile / isDesktop 확장
│   └── theme/app_theme.dart        # 라이트 팔레트 + 시맨틱 컬러 중앙 관리
└── features/
    ├── landing/                    # 첫 진입 화면 (랜딩)
    │   ├── landing_screen.dart
    │   └── widgets/                # hero_section, feature_card, promo_visual
    ├── login/login_screen.dart
    ├── vehicle_list/
    │   ├── vehicle_list_screen.dart
    │   └── widgets/                # vehicle_card, empty_view, error_view, info_chip
    ├── dashboard/                  # STOMP 실시간 센서 + 연결/stale 상태 + fl_chart
    │   ├── dashboard_screen.dart
    │   └── widgets/                # metric_card, speed_chart, dtc_section 등
    ├── anomalies/
    │   ├── anomaly_list_screen.dart
    │   └── widgets/                # anomaly_card, empty_view
    ├── diagnosis/                  # 센서 기반 보조 진단
    │   ├── diagnosis_screen.dart
    │   └── widgets/                # header_card, result_section, error_section 등
    ├── settings/                   # 계정/로그아웃
    └── vehicle_detail/             # 4개 탭 컨테이너
```

## 테스트

```bash
flutter analyze
flutter test
```

단위/위젯 테스트는 모델 파싱, API refresh single-flight, 차량 CRUD 계약,
WebSocket 재연결·최신 토큰·stale·malformed frame, 진단 결과/탭 상태 유지와
인증 초기화·로그인·로그아웃·refresh 실패, 에러/빈 상태를 검증한다. 실제 백엔드
통합 흐름은 `integration_test/app_test.dart`에 있다.
