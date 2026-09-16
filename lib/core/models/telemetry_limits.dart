/// 앱이 "기준 초과"로 표시하는 값 — 백엔드 `anomaly-detector/rules.py`와 같은 규칙이다.
///
/// 경계값은 정상이다(`> 105`이지 `>= 105`가 아니다). 예전에는 `Telemetry.hasAnomaly`와
/// 대시보드 위젯이 같은 숫자를 따로 적어 두어, 한쪽만 바꾸면 배너와 카드가 서로 다른 판정을 할 수 있었다.
abstract final class TelemetryLimits {
  static const double speedMax = 200;
  static const double rpmMax = 6000;
  static const double engineTempMax = 105;
  static const double batteryMin = 11.5;
  static const double batteryMax = 15.0;

  static bool speedOver(double kmh) => kmh > speedMax;
  static bool rpmOver(double rpm) => rpm > rpmMax;
  static bool engineTempOver(double celsius) => celsius > engineTempMax;
  static bool batteryOut(double volts) =>
      volts < batteryMin || volts > batteryMax;
}
