# Vehicle Telemetry App (Flutter)

차량 실시간 모니터링 모바일 앱. `vehicle-telemetry-platform` 백엔드 API를 사용한다.

## 화면 구성

| 화면 | 설명 |
|------|------|
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

```
lib/
├── main.dart
├── core/
│   ├── api/api_client.dart         # Dio HTTP 클라이언트 + JWT interceptor
│   ├── auth/
│   │   ├── auth_provider.dart      # Riverpod 로그인 상태 관리
│   │   └── token_storage.dart      # JWT 토큰 안전 저장
│   └── models/
│       ├── vehicle.dart
│       ├── telemetry.dart
│       └── anomaly.dart
└── features/
    ├── login/login_screen.dart
    ├── vehicle_list/vehicle_list_screen.dart
    ├── dashboard/dashboard_screen.dart     # 실시간 센서 + fl_chart
    ├── anomalies/anomaly_list_screen.dart
    └── diagnosis/diagnosis_screen.dart     # AI 진단
```
