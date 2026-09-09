# Telemetrix Flutter 앱 데스크탑 작업 인수인계

> 마지막 정리: 2026-09-09
>
> 기준 커밋: `e4266a424581635167c28514d808809e7f105ea9`

## 먼저 읽을 것

1. `AGENTS.md` — 작업 원칙, 필수 검증, 화면 체크리스트
2. `README.md` — 앱 구조와 현재 검증 범위
3. `docs/design-system.md` — 간격·색·내용 폭 토큰과 변경 이유
4. `docs/design-next-steps.md` — 디자인 후속 후보
5. `docs/devlog.md` — 이미 해결한 UI 문제와 남은 한계

백엔드의 종합 감사와 8주 계획은 형제 저장소
`../vehicle-telemetry-platform/docs/current-state-audit-2026-09-09.md`에 있다.

## 현재 확인된 상태

- 밝은 테마가 기본이며 시스템/라이트/다크 선택을 지원한다.
- 화면은 `ThemeExtension`과 `design_tokens.dart`를 사용한다.
- 내용 최대 폭은 `ContentWidths` 네 단계로 통일했다.
- 320~1280px와 글자 배율 조합의 overflow를 widget test로 검사한다.
- WebSocket 재연결, 최신 token, malformed frame, stale, out-of-order, 동일 timestamp
  재전달 방어 테스트가 있다.
- GitHub Actions는 Flutter 3.41.6에서 format, analyze, unit/widget test를 실행한다.
- 실제 백엔드 통합 테스트 파일은 있지만 macOS의 secure storage Keychain entitlement 문제로
  로그인 단계에서 막혔다.
- iOS 플랫폼은 아직 추가하지 않았다.
- 실제 Android 기기/에뮬레이터의 조작·재연결·스크린샷은 **미검증**이다.

## 다음 앱 작업

백엔드 P0 작업을 먼저 닫은 뒤 다음 순서로 진행한다.

1. Android 실제 기기 또는 에뮬레이터에서 integration test 실행
2. 테스트 계정 비밀번호의 코드 기본값을 없애고 `--dart-define`을 필수화
3. 로그인 → 차량 목록 → 상세 → WebSocket 연결 → 네트워크 단절/복구 → 로그아웃 검증
4. 오래된 frame, 동일 timestamp 재전달, 역전 timestamp가 UI 값을 되돌리지 않는지 확인
5. 라이트/다크 핵심 화면, 빈 상태, 오류 상태 스크린샷 저장
6. 결과 문서에 OS, Flutter/Dart, device, 앱·백엔드 SHA, API URL 기록

새 화면, 새 패키지, 장식 효과는 이 검증보다 뒤다.

## 데스크탑 실행 절차

```powershell
git checkout main
git pull --ff-only
git status --short --branch
flutter --version
flutter devices
flutter pub get
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
flutter test
```

백엔드가 실행 중이고 Android device ID를 확인한 뒤:

```powershell
flutter test integration_test/app_test.dart -d <device-id> `
  --dart-define=TEST_USERNAME=<test-user> `
  --dart-define=TEST_PASSWORD=<test-password> `
  --dart-define=API_BASE_URL=http://<backend-host>:8080
```

USB 실제 기기에서 백엔드가 PC의 localhost에 있다면 `adb reverse tcp:8080 tcp:8080` 사용을
검토한다. 에뮬레이터는 환경에 따라 `10.0.2.2:8080`이 필요하다. 사용한 주소를 결과에 적는다.

수동 확인용 snapshot:

```powershell
flutter test test/golden --update-goldens --run-skipped
```

golden은 플랫폼별 폰트 차이가 있어 기본 CI에 포함하지 않는다. 회귀 통과 수치로 포장하지
말고 화면 확인 자료로 사용한다.

## 화면 판단 기준

- 정보 위계와 센서 판독성을 장식보다 우선한다.
- 생성형 AI를 제품의 중심처럼 보이게 하지 않는다. 보조 진단은 참고 결과로 표현한다.
- 임의 gradient, glow, 과도한 badge를 추가하지 않는다.
- 여백과 글자 크기를 화면 파일에 직접 늘리지 말고 기존 token을 먼저 검토한다.
- 정상·지연·오프라인·데이터 없음과 연결·재연결·stale 상태를 서로 섞지 않는다.
- 마지막 정상값을 유지하는 경우 사용자가 그것이 최신값이라고 오해하지 않게 상태를 표시한다.
- 실제 기기에서 확인하지 않은 디자인을 `완료`로 기록하지 않는다.

## 완료 조건

- format, analyze, unit/widget test가 모두 성공한다.
- 백엔드 의존 시 앱·백엔드 SHA와 API URL을 기록한다.
- 실기기 시나리오의 로그와 스크린샷을 보존한다.
- 실패나 플랫폼 제약은 `미검증` 또는 `차단`으로 남긴다.
- README와 devlog가 변경된 동작을 따라간다.
- 사용자가 명시적으로 요청한 경우에만 commit/push한다.
