# Telemetrix Flutter 앱 데스크탑 작업 인수인계

> 마지막 정리: 2026-10-20
>
> 기준: 태그 `v0.9-pre-vehicle`(`0a4e1b4`, 백엔드 `911c2e4`와 짝). 그 뒤 2026-10-17 차량 목록 화면 변경과
> 2026-10-20 주석 정리(동작 변경 없음)가 있다. **프로젝트는 OBD-II 동글이 올 때까지 일시 중지.**

## 먼저 읽을 것

1. `../vehicle-telemetry-platform/docs/RESUME.md` — 전체 상태와 다음 계획(앱·백엔드 공통)
2. `.claude/AGENTS.md` — 작업 원칙, 필수 검증, 화면 체크리스트
3. `README.md` — 앱 구조와 현재 검증 범위
4. `docs/design-system.md` — 간격·색·내용 폭 토큰과 변경 이유
5. `docs/HANDOFF_2026-09-28.md`, `docs/verification/` — 마지막 앱 인계와 에뮬레이터 기록
6. `docs/design-next-steps.md`, `docs/devlog.md` — 디자인 후속 후보, 이미 해결한 UI 문제

## 현재 확인된 상태

- 밝은 테마가 기본이며 시스템/라이트/다크 선택을 지원한다. 화면은 `ThemeExtension`과 `design_tokens.dart`만 쓰고,
  알약·칩은 `StatusPill`·`AppChoiceChip` 공통 위젯이다. Manrope·나눔고딕을 앱에 번들한다.
- 로그인 전 첫 화면은 차량 목록의 미리보기다(2026-10-17). `LandingScreen`은 진입 경로가 없다.
- 차량 등록 버튼·삭제 메뉴는 `/api/auth/me`가 관리자일 때만 보인다. 설정에 비밀번호 변경 화면이 있다.
- 연료량·전압이 없는 프레임은 0이 아니라 '미수신'으로 표시한다(백엔드 ADR-030).
- 320~1280px와 글자 배율 조합의 overflow, WebSocket 재연결·최신 token·malformed·stale·역전·동일 timestamp를
  widget/unit test로 검사한다.
- GitHub Actions(Flutter 3.41.6): `verify`(format·analyze·test, ubuntu)와 `golden`(비교만, Windows).
- Android 플랫폼·앱 아이콘·시작 화면·부팅 화면이 있다. **iOS 플랫폼은 없다.**
- Android 15 에뮬레이터 확인(각 1회): 2026-09-16 로그인·수신·stale·복구, 2026-10-07 비밀번호 변경과 관리자/일반 사용자 메뉴
  (실제 로컬 백엔드). 2026-10-17 목록 화면 변경은 에뮬레이터에서 보지 않았다.
- **미검증**: 실기기, 백엔드를 내렸다 올리는 실제 소켓 재연결, 다크 모드·글자 1.5배·가로 회전의 기기 확인,
  실제 차량 데이터의 '미수신' 표시, Android에서의 integration test(macOS에서는 Keychain entitlement로 차단).

## 다음 앱 작업

전체 순서는 백엔드 `docs/RESUME.md`를 따른다(동글 정차 수집 → 주행 → VM 배포). 앱 쪽 남은 것:

1. 실차 데이터가 들어오면 에뮬레이터 또는 실기기에서 '미수신'·목록 상태·현재 상태 탭을 확인하고 `docs/verification/`에 기록
2. 2026-10-17 목록 화면 변경(로그인 전 미리보기·상태 요약)을 에뮬레이터에서 1회 확인
3. 실제 소켓 단절/복구(백엔드를 내렸다 올림) → `재연결 중` → 새 프레임 뒤 실시간
4. `integration_test/app_test.dart`의 테스트 계정 기본값을 없애고 `--dart-define` 필수화, Android에서 실행
5. 라이트/다크 핵심 화면, 빈 상태, 오류 상태 스크린샷
6. 결과 문서에 OS, Flutter/Dart, device, 앱·백엔드 SHA, API URL 기록

새 화면, 새 패키지, 장식 효과는 이 검증보다 뒤다.

## 실행 절차

```powershell
git checkout main
git fetch
git pull --ff-only
git status --short --branch
flutter --version
flutter devices
flutter pub get
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
flutter test            # 노트북에서는 실패(아래). CI에서 확인
```

노트북에서는 `flutter_tester.exe`가 isolate를 만들지 못하고 죽는다(`0xC0000409`, 3.41.6·3.47.5 모두, 원인 미확정).
노트북에서 바꾼 것의 테스트 통과 근거는 push 뒤 GitHub Actions `verify` 잡이다 — 그 전에는 "테스트 통과"라고 쓰지 않는다.

백엔드가 실행 중이고 Android device ID를 확인한 뒤:

```powershell
flutter test integration_test/app_test.dart -d <device-id> `
  --dart-define=TEST_USERNAME=<test-user> `
  --dart-define=TEST_PASSWORD=<test-password> `
  --dart-define=API_BASE_URL=http://<backend-host>:8080
```

USB 실제 기기에서 백엔드가 PC의 localhost에 있다면 `adb reverse tcp:8080 tcp:8080` 사용을
검토한다. 에뮬레이터는 `10.0.2.2:8080`(호스트의 localhost)을 쓴다. 사용한 주소를 결과에 적는다.
이 Windows 환경에서는 adb 기본 포트 5037이 예약 범위라 `$env:ANDROID_ADB_SERVER_PORT = '15037'`을 먼저 둔다
(같은 셸의 `flutter`·`adb` 모두). adb가 PATH에 없으면 `%LOCALAPPDATA%\Android\Sdk\platform-tools\adb`.

수동 확인용 snapshot:

```powershell
flutter test test/golden --update-goldens --run-skipped
```

golden은 플랫폼별 폰트 차이가 있어 기본 `verify` 잡(ubuntu)에는 포함하지 않는다. 2026-09-14부터
기준 이미지를 만든 OS 계열(Windows)의 **`golden` 잡이 비교만** 한다 — CI는 기준 이미지를 갱신하지 않는다.
글꼴은 저장소 안 파일만 쓴다(`docs/design-system.md` "스냅샷의 글꼴"). 2026-09-16부터 한글 글꼴(나눔고딕)도 앱과 같지만
래스터화는 OS마다 다르므로 통과를 디자인 검증 완료로 포장하지 말고 화면 확인 자료로 사용한다.

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

## 커밋 규칙

- 커밋 메시지에 AI 공동저자 트레일러(`Co-Authored-By: …`)를 넣지 않는다.
- 두 PC(노트북·데스크탑)에서 작업한다. 커밋 전에 `git fetch`로 다른 PC의 커밋부터 확인한다.
- 푸시한 커밋·태그(`v0.9-pre-vehicle`)를 재작성하지 않는다.
- 날짜가 붙은 문서(`docs/HANDOFF_*.md`, `docs/verification/<날짜>-*.md`, `docs/plans/<날짜>-*.md`)는 그날의 기록이다. 고치지 않고 새 문서를 쓴다.
