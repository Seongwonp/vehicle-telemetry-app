# 기여 가이드

Telemetrix Flutter 클라이언트에서 작업하는 사람이 지켜야 할 원칙과 검증 방법이다.
앱 소개는 [`README.md`](README.md)에 있다. 백엔드는
[vehicle-telemetry-platform](https://github.com/Seongwonp/vehicle-telemetry-platform)이고,
전체 상태와 다음 계획은 그쪽 `docs/RESUME.md`에 있다.

## 작업 원칙

- 이 저장소는 Telemetrix의 Flutter 클라이언트다. 백엔드 저장소와 역할을 섞지 않는다.
- 화면에 표시하는 상태, 임계값, 성능 수치는 코드나 API 응답으로 확인할 수 있을 때만 단정한다.
- 생성형 AI를 제품의 주인공처럼 표현하지 않는다. 보조 진단은 센서·DTC·이상 이력을 해석하는 참고 결과로 표시한다.
- 새 패키지나 시각 효과보다 정보 위계, 접근성, 오류·로딩·빈 상태를 우선한다.
- 비밀정보를 커밋하지 않는다. API 주소와 테스트 계정은 `--dart-define`으로 주입한다.

## 작업 전에 읽을 문서

1. [`README.md`](README.md) — 앱 구조와 현재 검증 범위
2. [`docs/design-system.md`](docs/design-system.md) — 간격·색·내용 폭 토큰과 변경 이유
3. [`docs/verification/`](docs/verification/) — 에뮬레이터 확인 기록
4. [`docs/design-next-steps.md`](docs/design-next-steps.md), [`docs/devlog.md`](docs/devlog.md) — 디자인 후속 후보, 이미 해결한 UI 문제

## 검증

저장소 루트에서 아래 순서로 실행한다.

```bash
flutter pub get
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
flutter test
```

- GitHub Actions(Flutter 3.41.6)가 같은 명령을 `verify` 잡(ubuntu)에서 돌린다(`.github/workflows/ci.yml`).
  로컬에서 `flutter test`를 돌릴 수 없는 환경이면 push 뒤 CI 결과를 근거로 삼는다. 그 전에는 "테스트 통과"라고 쓰지 않는다.
- Flutter 테스트를 실행하지 않은 변경을 `검증 완료`로 기록하지 않는다.
- CI가 대체하지 **못하는** 것: 통합 테스트, 골든 스냅샷의 시각 확인, **실기기 확인**(스크롤·터치·키보드·네트워크 재연결).
  하지 않았으면 `미검증`으로 적는다.

### 통합 테스트·기기 확인

통합 테스트는 실행 가능한 백엔드가 준비된 경우에만 수행하고, 사용한 API 주소와 백엔드 커밋을 결과에 함께 기록한다.

```bash
flutter test integration_test/app_test.dart -d <device-id> \
  --dart-define=TEST_USERNAME=<test-user> \
  --dart-define=TEST_PASSWORD=<test-password> \
  --dart-define=API_BASE_URL=http://<backend-host>:8080

flutter run -d <device-id> --dart-define=API_BASE_URL=http://localhost:8080
```

- USB 실제 기기에서 백엔드가 PC의 localhost에 있다면 `adb reverse tcp:8080 tcp:8080`을 쓴다.
  에뮬레이터는 `10.0.2.2:8080`(호스트의 localhost)을 쓴다. 사용한 주소를 결과에 적는다.
- Windows에서 adb 기본 포트 5037이 예약 범위에 들어가 adb가 뜨지 않으면, 같은 셸에서
  `$env:ANDROID_ADB_SERVER_PORT = '15037'`을 먼저 둔다(`flutter`·`adb` 모두).

### 골든 스냅샷

```bash
flutter test test/golden --update-goldens --run-skipped
# test/golden/snapshots/*.png
```

- 회귀 감지가 아니라 화면 확인용이라 기본 실행에서는 제외된다.
- 플랫폼별 폰트·래스터화 차이가 있어 `verify` 잡에는 넣지 않는다. 기준 이미지를 만든 OS 계열(Windows)의
  `golden` 잡이 **비교만** 한다 — CI는 기준 이미지를 갱신하지 않는다.
- 글꼴은 저장소 안 파일만 쓴다([`docs/design-system.md`](docs/design-system.md) "스냅샷의 글꼴"). 통과를 디자인 검증 완료로
  포장하지 말고 화면 확인 자료로 쓴다. 기준 이미지는 의도한 변경일 때만 바꾸고 바뀐 이미지를 전부 열어 본다.

## 디자인 시스템

간격·모서리·글자 크기·**내용 최대 폭**은 `lib/core/theme/design_tokens.dart`의 토큰만 쓴다.
없는 값이 필요하면 값을 새로 적지 말고 먼저 `docs/design-system.md`를 고친다.
그 문서에 왜 이 스케일인지, 어떤 실수를 반복했는지가 적혀 있다.

새 화면에서 `BoxConstraints(maxWidth: ...)`에 숫자를 직접 쓰지 말고
`ContentWidths.form / reading / feed / grid` 중에서 고른다 — 기준은 폭이 아니라
**한 줄에 무엇이 들어가는가**다.

320~400px·태블릿 너비와 글자 배율 1.3·1.5배의 overflow는 자동 검사로 옮겼다. 눈으로 확인하는 대신 돌린다.

```bash
flutter test test/responsive_overflow_test.dart
```

## 화면 판단 기준

- 정보 위계와 센서 판독성을 장식보다 우선한다.
- 임의 gradient, glow, 과도한 badge를 추가하지 않는다.
- 여백과 글자 크기를 화면 파일에 직접 늘리지 말고 기존 token을 먼저 검토한다.
- 정상·지연·오프라인·데이터 없음과 연결·재연결·stale 상태를 서로 섞지 않는다.
- 마지막 정상값을 유지하는 경우 사용자가 그것이 최신값이라고 오해하지 않게 상태를 표시한다.
- 실제 기기에서 확인하지 않은 디자인을 `완료`로 기록하지 않는다.

## 화면 확인 체크리스트

- 시스템/라이트/다크 모드가 각각 적용되고, 앱 재시작 후 선택값이 유지되는가
- 로그인 전 첫 화면(차량 목록 미리보기)·로그인 화면의 텍스트와 입력 필드 대비가 충분한가
- 차량 목록에서 최근 수신·오래전 수신·오프라인·데이터 없음 기준과 카드 상태가 일치하는가
  (상세 탭의 "데이터 지연"은 10초 기준의 **다른 판정**이다 — 두 낱말이 섞이지 않았는가)
- 관리자에게만 차량 등록 버튼과 삭제 메뉴가 보이고, 일반 사용자에게는 보이지 않는가(빈 목록이면 관리자에게 요청하라는 안내)
- 차량 상세의 현재 상태·이상 이력·주행 기록·보조 진단 탭이 모두 전환되는가
- 연료량·전압이 오지 않은 프레임에서 0이 아니라 '미수신'으로 보이는가
- 연결 중·재연결·오래된 데이터 상태에서 큰 숫자 자리가 비고(`—`), 지난 값이 받은 시각과 함께 작게만 보이는가
  — 위젯 테스트는 `dashboard_websocket_test`가 검사한다. 실기기 확인은 별도
- 긴 차량 이름이 잘릴 때 앱바의 전체 이름 버튼으로 전체 이름을 볼 수 있는가(글자 1.5배 포함)
- 지도 타일 실패, 잘못된 GPS 값, 빈 주행 기록이 앱 종료로 이어지지 않는가
- 보조 진단의 요청 중·실패·성공·재요청 상태가 구분되고 마지막 성공 결과가 유지되는가
- 로그아웃 후 뒤로 가기로 인증 화면에 다시 진입할 수 없는가

## 결과 기록

- 실행 날짜, OS, Flutter/Dart 버전, 기기, 앱·백엔드 커밋 SHA를 기록한다.
- `flutter analyze`, `flutter test`, 통합 테스트의 원문 결과를 보관한다.
- 라이트/다크 핵심 화면과 오류·빈 상태 스크린샷을 남긴다.
- 실패가 하나라도 있으면 원인과 재현 절차를 기록하고, 성공으로 표시하거나 푸시하지 않는다.
- 백엔드가 필요한 시나리오는 실행 환경을 명시하거나 `미검증`으로 남긴다.
- 실패나 플랫폼 제약은 `미검증` 또는 `차단`으로 남긴다.

## 완료 조건

- format, analyze, unit/widget test가 모두 성공한다.
- 백엔드 의존 시 앱·백엔드 SHA와 API URL을 기록한다.
- 실기기 시나리오의 로그와 스크린샷을 보존한다.
- README와 devlog가 변경된 동작을 따라간다.

## 커밋 규칙

- 여러 PC에서 작업하면 커밋 전에 `git fetch`로 원격 커밋부터 확인한다.
- 푸시한 커밋·태그(`v0.9-pre-vehicle`)를 재작성하지 않는다.
- 날짜가 붙은 문서(`docs/verification/<날짜>-*.md`, `docs/plans/<날짜>-*.md`)는 그날의 기록이다. 고치지 않고 새 문서를 쓴다.
