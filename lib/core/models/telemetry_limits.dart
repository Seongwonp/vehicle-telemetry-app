/// "기준 초과" 판정값 — 백엔드 `anomaly-detector/rules.py`와 같아야 한다.
/// 경계값은 정상이다(`>= 105`가 아니라 `> 105`). 판정은 여기 한 곳에서만 한다.
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
