# 2026-10-07 Android 에뮬레이터 확인 — 역할별 화면·비밀번호 변경 (실제 로컬 백엔드)

관리자 전용 차량 등록·삭제(`8ff93c5`, `19b4483`)와 비밀번호 변경 화면(`8fadd56`)을
**실제 백엔드에 붙은 Android 런타임**에서 처음 확인했다. 실기기는 아니다. 각 항목 1회.

## 환경

| 항목 | 값 |
| --- | --- |
| 호스트 | Windows 11 Pro 10.0.26200 |
| Flutter | 3.41.6 stable (framework `db50e20168`, Dart 3.11.4) |
| 기기 | Android 에뮬레이터 `Medium_Phone_API_35` (Android 15, API 35, 1080×2400) |
| 앱 | `8fadd56775b0625788a32e2babe0595ff4be8048`, 작업 트리 깨끗함(빌드 시점) |
| 빌드 | `flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:8080` |
| API URL | `http://10.0.2.2:8080` (에뮬레이터 → 호스트 `localhost:8080`) |
| 백엔드 | `vehicle-telemetry-platform` `4b73eaa`, 이미지 `sha256:fe411c07201c`, dev Compose 스택 + `simulator` 프로파일 |
| 계정 | 이번 확인용 로컬 테스트 계정 `qa-admin`(ADMIN), `qa-user`(USER). 비밀번호는 문서·스크린샷에 남기지 않았다 |
| 데이터 | 시뮬레이터 SIM-001~003 발행 중. SIM-001(소유자 `admin`)은 09-16에 등록된 것. SIM-002는 이번에 `qa-admin`으로 등록(소유자 `qa-user`) |

입력은 `adb shell input text`로 넣었다. 비밀번호 칸이 채워진 상태의 스크린샷은 가림 표시(•)만 남는 것을 확인한 것만 보관했다.

## 결과

| # | 확인 | 결과 | 스크린샷 |
| --- | --- | --- | --- |
| 1 | 관리자 목록 — 차량 추가 버튼 | 됨 — 앱바에 `+`(차량 추가) | `02-admin-list.png` |
| 2 | 관리자 — 차량 관리 메뉴(삭제) | 됨 — 카드의 `⋮` → "삭제". 누르지는 않았다 | `03-admin-manage-menu.png` |
| 3 | 관리자 — 차량 등록(SIM-002, 소유자 `qa-user`) | 됨 — 목록에 두 대, 둘 다 실시간 수신 | `04-admin-register-sim002.png`, `05-admin-list-after-register.png` |
| 4 | 일반 사용자 목록 — 추가 버튼·관리 메뉴 없음 | 됨 — 앱바는 새로고침·설정만, 카드에 `⋮` 없음 | `07-user-list.png` |
| 5 | 일반 사용자에게 보이는 차량 | **자기 소유 SIM-002만** 보인다. SIM-001(소유자 `admin`)은 목록에 없다 | `07-user-list.png` |
| 6 | 일반 사용자 — 자기 차량 상세 | 됨 — 현재 상태 탭이 실시간 수신 중 | `08-user-detail-own-vehicle.png` |
| 7 | 비밀번호 변경 — 현재 비밀번호 틀림(서버 판정) | 됨 — 현재 비밀번호 칸에 "현재 비밀번호가 맞지 않습니다"(백엔드 `CURRENT_PASSWORD_INCORRECT`) | `10-pw-change-wrong-current.png` |
| 8 | 비밀번호 변경 — 새 비밀번호 6자(클라이언트 판정) | 됨 — "새 비밀번호는 8~72자로 입력하세요", 요청 안 보냄 | `11-pw-change-too-short.png` |
| 9 | 비밀번호 변경 성공 | 됨 — 처음 화면으로 돌아가고 스낵바 "비밀번호를 바꿨습니다. 다시 로그인해 주세요." | `12-pw-change-success-snackbar.png` |
| 10 | 옛 비밀번호로 로그인 | 거부 — "아이디 또는 비밀번호가 올바르지 않습니다." | `13-login-old-password-rejected.png` |
| 11 | 새 비밀번호로 로그인 | 됨 — 목록(SIM-002) | `14-login-new-password-ok.png` |
| 12 | **결함** — 비밀번호 변경 화면에서 키보드 '다음' | 아래 참고(위젯 테스트로 수정 확인) | — (포커스는 스크린샷에 안 보여 uiautomator 덤프로 확인) |

그 밖의 스크린샷: `01-landing.png`(처음 화면), `06-admin-settings.png`·`09-user-settings.png`(설정 — 계정 칸에 비밀번호 변경 항목).

보조 확인(앱 밖, 같은 백엔드, `qa-user` 토큰, 상태 코드만 기록):
`GET /api/vehicles` → `["SIM-002"]`, `GET /api/vehicles/SIM-002/telemetry` → 200,
`GET /api/vehicles/SIM-001/telemetry` → **404**(403이 아니다 — 남의 차량 존재 여부를 드러내지 않는 응답으로 보인다. 백엔드 의도는 이 문서에서 확인하지 않았다).

### 결함 — '다음' 키가 다음 칸이 아니라 '보기' 버튼으로 간다

비밀번호 변경 화면의 현재·새 비밀번호 칸은 `TextInputAction.next`인데, 다음 포커스가
다음 입력 칸이 아니라 **같은 칸의 보기 토글(`IconButton`)** 이다. 소프트 키보드의 '다음'(→)을 누르면
키보드가 닫히고 포커스가 "현재 비밀번호 보기" 버튼에 간다(`uiautomator dump`의 `focused="true"`, `dumpsys input_method` `mInputShown=false`).
하드웨어 Enter도 같다. 사용자는 칸을 손으로 다시 눌러야 하고, 그 상태에서 Enter를 한 번 더 누르면 **비밀번호가 평문으로 보이게 토글된다.**

- 재현: 설정 → 비밀번호 변경 → 현재 비밀번호 칸 탭 → 키보드 '다음'.
- 원인: `lib/features/settings/change_password_screen.dart`의 `_field()`가 `suffixIcon`에 포커스 가능한 `IconButton`을 두고, `next`가 `FocusScope.nextFocus()`의 순회 순서를 따른다.
  로그인 화면은 보기 토글이 마지막 칸(비밀번호, `done`)에만 있어 같은 문제가 드러나지 않는다.
- **고쳤다(같은 날, 뒤 커밋).** 토글을 순회에서 빼면 하드웨어 키보드·스크린 리더의 토글 접근성을 잃으므로,
  새·확인 칸에 `FocusNode`를 두고 `onSubmitted`에서 다음 칸으로 직접 옮겼다. 토글은 Tab 순회에 그대로 남는다.
  회귀 테스트 `test/change_password_screen_test.dart`("키보드 '다음'은 … 다음 입력칸으로 간다") — 수정 전 실패·수정 뒤 통과 확인.
  `flutter analyze` 이슈 0, `flutter test` 470 통과(skip 2는 기존). **에뮬레이터에서 다시 보지는 않았다.**

## 확인하지 않은 것

- 관리자 **삭제 실행**과 그 뒤 목록: 메뉴가 보이는 것까지만 봤다.
- 일반 사용자가 API로 직접 등록·삭제를 시도할 때의 서버 거부(403): 앱 화면만 봤다.
- 비밀번호 변경 뒤 **다른 기기·세션의 refresh 폐기**: 이 에뮬레이터 세션 하나만 봤다.
- 비밀번호 변경의 503(Redis 장애)·연결 실패·세션 만료 문구: 위젯 테스트에만 있다.
- 새 비밀번호 확인 불일치, 현재와 같은 새 비밀번호 문구.
- 로그아웃 뒤 뒤로 가기로 인증 화면 재진입 불가.
- 다크 모드, 글자 1.5배, 가로 모드, 실기기.
- `flutter analyze`·`flutter test`는 이번에 돌리지 않았다(코드 변경 없음).

## 환경 문제와 우회 (재현용)

- adb 기본 포트 5037이 Windows 예약 포트 범위라 `ANDROID_ADB_SERVER_PORT=15037`(09-16과 같음). adb는 PATH에 없어 `%LOCALAPPDATA%\Android\Sdk\platform-tools\adb`를 직접 불렀다.
- 에뮬레이터는 이미 떠 있었고 처음엔 `offline`, 수 초 뒤 `device`가 됐다(재시작 불필요).
- 덮어쓰기 설치가 `INSTALL_FAILED_INSUFFICIENT_STORAGE`(`/data` 92%)로 실패해 **이 앱만** 지우고 다시 설치했다(88%). 다른 앱은 건드리지 않았다.
- Gradle 빌드 약 1분(캐시 있음).
- 키보드 '다음'으로 칸을 옮기면 위 결함 때문에 입력이 엉뚱한 곳에 들어간다 — 비밀번호 변경 화면은 칸을 하나씩 탭해서 입력했다.
- Android가 비밀번호 칸에 **마지막으로 친 글자를 잠깐 평문으로 보여 주므로**, 입력 직후 찍은 로그인 화면 스크린샷 1장은 지우고 보관하지 않았다.
