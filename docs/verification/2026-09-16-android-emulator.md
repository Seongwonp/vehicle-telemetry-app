# 2026-09-16 Android 에뮬레이터 확인 — 차량 상세 '현재 상태' 탭

처음으로 위젯 테스트가 아닌 **실제 Android 런타임**에서 앱을 돌렸다. 실기기는 아니다.

## 환경

| 항목 | 값 |
| --- | --- |
| 호스트 | Windows 11 Pro 10.0.26200 |
| Flutter | 3.41.6 stable |
| 기기 | Android 에뮬레이터 `Medium_Phone_API_35` (1080×2400) |
| 앱 | `58e5897` + 작업 트리(한글 글꼴 번들·Android 플랫폼). **버튼 여백 수정(아래 2번)은 이 확인 뒤에 했고, 수정한 APK는 에뮬레이터에서 다시 보지 않았다** — 위젯 테스트로만 확인 |
| 빌드 | `flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:8080` |
| 백엔드 | `vehicle-telemetry-platform` `4c46cf5`, `docker compose -f docker-compose.yml -f docker-compose.dev.yml --profile simulator up -d` |
| 데이터 | 시뮬레이터 SIM-001~003. 로그인은 사용자가 직접 했다(계정 값은 백엔드 `.env`의 `ADMIN_USERNAME`/`ADMIN_PASSWORD`) |

차량은 DB에 없어 앱의 '차량 추가'로 SIM-001을 등록했다. 이름은 긴 이름 확인용
`IONIQ 5 Long Range AWD Calligraphy 2024 Sales Team 3 Shared`(adb 입력이 한글을 못 넣어 영문).

## 결과

| # | 확인 | 결과 | 스크린샷 |
| --- | --- | --- | --- |
| 1 | 한글이 번들 글꼴로 그려진다 | 됨 — □ 없음 | `01-landing.png` |
| 2 | 빈 목록 | **결함 발견** — '차량 추가' 버튼의 마지막 글자가 잘렸다. 채움 버튼 테마의 가로 여백이 0이었다 → 여백 추가, 회귀 테스트 `test/button_label_fit_test.dart`(수정 전 실패 확인) | `02-empty-list-button-clipped.png`(수정 전) |
| 3 | 수신 중 | 됨 — 상태 요약 "현재 수신 데이터에서 감지된 이상 없음", 네 타일, 긴 이름 두 줄 | `03-detail-live.png` |
| 4 | 시뮬레이터 정지(12:55:28 정지, 약 18초 뒤 촬영) | 됨 — "데이터 지연 — 지금 상태를 알 수 없음", 큰 숫자 `—`, "지난 값 54.8 km/h", 머리 "12:55:26에 받은 값 · 현재 값 아님", 차트·지도 "마지막으로 받은" | `04-detail-stale.png` |
| 5 | 시뮬레이터 재시작(약 20초 뒤 촬영) | 됨 — 실시간으로 돌아옴 | `05-detail-recovered.png` |

스크린샷은 `docs/verification/2026-09-16-android-emulator/`.

## 확인하지 않은 것

- **재연결 경로**: 4번은 시뮬레이터(데이터 원천)를 멈춘 것이라 WebSocket은 붙어 있었다 — 데이터 지연 경로다.
  백엔드를 내려 소켓이 끊기고 다시 붙는 경로(`재연결 중` → 새 프레임 뒤 실시간)는 위젯 테스트로만 확인했다.
- 긴 이름 '전체 이름' 버튼: 이 이름은 1080px 폭에서 두 줄에 들어가 버튼이 나오지 않았다(정상). 버튼이 나오는 경우는 위젯 테스트로만.
- 글자 크기 1.5배, 다크 모드, 가로 모드, 한글 긴 이름.
- 실기기(터치 감·성능·실제 네트워크 끊김).

## 환경 문제와 우회 (재현용)

- **adb가 뜨지 않았다**: 기본 포트 5037이 Windows 예약 포트 범위(`netsh interface ipv4 show excludedportrange protocol=tcp` → 4994–5093)에 들어 있었다.
  시스템 설정은 바꾸지 않고 `ANDROID_ADB_SERVER_PORT=15037`로 우회했다(같은 셸의 `flutter`·`adb` 모두).
- **`unauthorized`**: adb 키가 처음 만들어지기 전에 켜진 에뮬레이터라 키를 몰랐다. 에뮬레이터를 재시작하니 인증됐다.
- 첫 Gradle 빌드 약 8분 반.
