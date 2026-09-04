# Telemetrix Flutter 앱 협업 가이드

## 작업 원칙

- 이 저장소는 Telemetrix의 Flutter 클라이언트다. 백엔드 저장소와 역할을 섞지 않는다.
- 화면에 표시하는 상태, 임계값, 성능 수치는 코드나 API 응답으로 확인할 수 있을 때만 단정한다.
- 생성형 AI를 제품의 주인공처럼 표현하지 않는다. 진단 기능은 센서·DTC·이상 이력을 해석하는 참고 도구로 표시한다.
- 새 패키지나 시각 효과보다 정보 위계, 접근성, 오류·로딩·빈 상태를 우선한다.
- 사용자 변경사항과 비밀정보를 수정하거나 커밋하지 않는다.

## 현재 검증 상태

- 노트북 환경에는 Flutter/Dart SDK가 없어 정적 분석, 테스트, 실제 렌더링을 실행하지 못했다.
- 따라서 코드 리뷰와 텍스트 기반 점검만 통과한 변경은 **데스크톱 검증 전** 상태다.
- Flutter 테스트를 실행하지 않은 변경을 `검증 완료`로 기록하지 않는다.

## 데스크톱 필수 검증

저장소 루트에서 아래 순서로 실행한다.

```powershell
git checkout main
git pull --ff-only
flutter --version
flutter devices
flutter pub get
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
flutter test
flutter test integration_test/app_test.dart -d <device-id>
```

통합 테스트는 실행 가능한 백엔드가 준비된 경우에만 수행하고, 사용한 API 주소와 백엔드 커밋을 결과에 함께 기록한다. 앱을 직접 확인할 때는 다음처럼 API 주소를 명시한다.

```powershell
flutter run -d <device-id> --dart-define=API_BASE_URL=http://localhost:8080
```

## 디자인 시스템

간격·모서리·글자 크기는 `lib/core/theme/design_tokens.dart`의 토큰만 쓴다.
없는 값이 필요하면 값을 새로 적지 말고 먼저 `docs/design-system.md`를 고친다.
그 문서에 왜 이 스케일인지, 어떤 실수를 반복했는지가 적혀 있다.

아래 두 체크리스트 항목은 **자동 검사로 옮겼다.** 눈으로 확인하는 대신 돌린다.

```powershell
flutter test test/responsive_overflow_test.dart
```

화면을 눈으로 확인할 때는 스냅샷을 뽑는다(회귀 감지가 아니라 확인용이라 기본
실행에서는 제외된다).

```powershell
flutter test test/golden --update-goldens --run-skipped
# test/golden/snapshots/*.png
```

## 화면 확인 체크리스트

- 시스템/라이트/다크 모드가 각각 적용되고, 앱 재시작 후 선택값이 유지되는가
- ~~320px, 360px, 400px 너비와 태블릿 너비에서 overflow가 없는가~~ — `responsive_overflow_test.dart`가 검사한다
- ~~글자 크기 1.3배와 1.5배에서도 버튼, 상태 배지, 수치가 잘리지 않는가~~ — 같은 테스트가 검사한다
- 랜딩·로그인 화면의 텍스트와 입력 필드 대비가 충분한가
- 차량 목록에서 정상·지연·오프라인·데이터 없음 기준과 카드 상태가 일치하는가
- 차량 상세의 현재 상태·이상 이력·주행 기록·보조 진단 탭이 모두 전환되는가
- 연결 중·재연결·오래된 데이터 상태에서 마지막 정상값과 상태 안내가 구분되는가
- 지도 타일 실패, 잘못된 GPS 값, 빈 주행 기록이 앱 종료로 이어지지 않는가
- 보조 진단의 요청 중·실패·성공·재요청 상태가 구분되고 마지막 성공 결과가 유지되는가
- 로그아웃 후 뒤로 가기로 인증 화면에 다시 진입할 수 없는가

## 결과 기록

- 실행 날짜, OS, Flutter/Dart 버전, 기기, 앱·백엔드 커밋 SHA를 기록한다.
- `flutter analyze`, `flutter test`, 통합 테스트의 원문 결과를 보관한다.
- 라이트/다크 핵심 화면과 오류·빈 상태 스크린샷을 남긴다.
- 실패가 하나라도 있으면 원인과 재현 절차를 기록하고, 성공으로 표시하거나 푸시하지 않는다.

## 완료 기준

- 포맷 검사, 정적 분석, 단위·위젯 테스트가 모두 성공한다.
- 백엔드가 필요한 시나리오는 실행 환경을 명시하거나 `미검증`으로 남긴다.
- 수동 체크리스트의 결과와 발견한 한계를 README 또는 검증 기록에 반영한다.
