# Vehicle Telemetry App (Flutter)

차량 실시간 모니터링 모바일 앱. `vehicle-telemetry-platform` 백엔드 API를 사용한다.

- **백엔드 레포**: https://github.com/Seongwonp/vehicle-telemetry-platform

## 디자인

라이트 테마(`lib/core/theme/app_theme.dart`) 기반 — 옅은 회색 배경(`#F7F8FA`) 위에
테두리 없는 흰 카드, 큰 radius, 넉넉한 여백을 쓰는 플랫 스타일로 전 화면을 통일했다.
반응형(`lib/core/responsive/breakpoints.dart`)도 적용되어 모바일/데스크톱(웹) 폭에서
레이아웃이 분기된다.

## 화면 구성

| 화면 | 설명 |
|------|------|
| 랜딩 | 첫 진입 화면 — 서비스 소개 + "시작하기" → 로그인 |
| 로그인 | JWT 인증 |
| 차량 목록 | 등록된 차량 리스트 |
| 대시보드 | 속도/RPM/엔진온도 등 실시간 센서 + 속도 추이 차트 |
| 이상 이력 | 감지된 이상 이벤트 목록 |
| AI 진단 | Gemini API 기반 차량 진단 (백엔드 `GET /api/vehicles/{vehicleId}/diagnosis` 연동 완료) |

## 시작하기

```bash
# 1. 의존성 설치
flutter pub get

# 2. 백엔드 주소 설정
# lib/core/api/api_client.dart → baseUrl 수정
# 로컬: http://localhost:8080
# AWS 배포 후: http://<EC2-IP>:8080

# 3. 실행
flutter run
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
    ├── dashboard/                  # 실시간 센서 + fl_chart
    │   ├── dashboard_screen.dart
    │   └── widgets/                # metric_card, speed_chart, dtc_section 등
    ├── anomalies/
    │   ├── anomaly_list_screen.dart
    │   └── widgets/                # anomaly_card, empty_view
    └── diagnosis/                  # AI 진단
        ├── diagnosis_screen.dart
        └── widgets/                # header_card, result_section, error_section 등
```
