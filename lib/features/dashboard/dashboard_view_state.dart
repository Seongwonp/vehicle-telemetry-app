import '../../core/models/telemetry.dart';
import '../../core/models/telemetry_limits.dart';

/// 실시간 연결 상태. 판정 규칙은 `DashboardTab`이 갖고 있다(연결·끊김 이벤트와 1초 주기 지연 검사).
enum DashboardConnectionState {
  connecting,
  connected,
  reconnecting,
  stale,
}

/// 기준이 있는 네 계측값. 화면에서 같은 크기의 타일로 나란히 둔다.
enum MetricKind { speed, rpm, engineTemp, battery }

class MetricReading {
  final MetricKind kind;
  final String label;
  final String valueText;
  final String unit;

  /// 이 레코드에 값이 있는가. 선택 센서(전압)는 차량이 지원하지 않으면 값이 없다 —
  /// 그때 [valueText]는 [DashboardViewState.missingText]이고 단위·기준 판정이 없다.
  final bool available;

  /// 값만 보고 한 판정. **지금 수신 중일 때만 화면에 기준 초과로 드러낸다** — [DashboardViewState.showsOver].
  final bool over;

  /// "기준 200 이하"처럼 값과 기준의 관계를 한 줄로.
  final String limitText;

  const MetricReading({
    required this.kind,
    required this.label,
    required this.valueText,
    required this.unit,
    required this.over,
    required this.limitText,
    this.available = true,
  });
}

/// 기준이 없는 값(연료·스로틀). 초과 판정을 하지 않는다.
class ExtraReading {
  final String label;
  final String valueText;
  final String unit;

  /// 값이 있는가. 없으면 [valueText]가 [DashboardViewState.missingText]이고 [unit]은 비어 있다.
  final bool available;

  const ExtraReading({
    required this.label,
    required this.valueText,
    required this.unit,
    this.available = true,
  });
}

/// '현재 상태' 탭이 무엇을 어떻게 보여줄지 — 위젯 없이 판정한다.
///
/// 핵심 규칙: **수신 중이 아니면(재연결·지연) 마지막 값을 현재 값처럼 보이지 않는다.**
/// 큰 숫자 자리를 비우고, 지난 값은 수신 시각과 함께 작게 둔다. 지난 값으로 기준 초과를 판정하지 않는다.
class DashboardViewState {
  final DashboardConnectionState connection;
  final List<MetricReading> readings;
  final List<ExtraReading> extras;
  final List<String> dtcCodes;

  /// 앱이 마지막 프레임을 **받은** 시각(차량 timestamp가 아니다). "14:41:08" 형식.
  final String receivedClock;

  const DashboardViewState._({
    required this.connection,
    required this.readings,
    required this.extras,
    required this.dtcCodes,
    required this.receivedClock,
  });

  factory DashboardViewState.from({
    required Telemetry latest,
    required DashboardConnectionState connection,
    required DateTime receivedAt,
  }) {
    final speedOver = TelemetryLimits.speedOver(latest.speed);
    final rpmOver = TelemetryLimits.rpmOver(latest.rpm);
    final tempOver = TelemetryLimits.engineTempOver(latest.engineTemp);
    final battery = latest.batteryVoltage;
    final fuel = latest.fuelLevel;
    // 값이 없으면 기준 판정 자체를 하지 않는다 — "기준 밖"도 "기준 안"도 아니다.
    final batteryOut = battery != null && TelemetryLimits.batteryOut(battery);
    return DashboardViewState._(
      connection: connection,
      readings: [
        MetricReading(
          kind: MetricKind.speed,
          label: '속도',
          valueText: latest.speed.toStringAsFixed(1),
          unit: 'km/h',
          over: speedOver,
          // 단위는 값 옆에 이미 있다 — 좁은 칸에서 기준 문구가 단어 중간에서 접히지 않게 뺀다.
          limitText:
              '기준 ${_n(TelemetryLimits.speedMax)} ${speedOver ? '초과' : '이하'}',
        ),
        MetricReading(
          kind: MetricKind.rpm,
          label: 'RPM',
          valueText: latest.rpm.toStringAsFixed(0),
          unit: 'rpm',
          over: rpmOver,
          limitText:
              '기준 ${_n(TelemetryLimits.rpmMax)} ${rpmOver ? '초과' : '이하'}',
        ),
        MetricReading(
          kind: MetricKind.engineTemp,
          label: '엔진 온도',
          valueText: latest.engineTemp.toStringAsFixed(1),
          unit: '°C',
          over: tempOver,
          limitText: '기준 ${_n(TelemetryLimits.engineTempMax)}°C '
              '${tempOver ? '초과' : '이하'}',
        ),
        if (battery != null)
          MetricReading(
            kind: MetricKind.battery,
            label: '배터리 전압',
            valueText: battery.toStringAsFixed(2),
            unit: 'V',
            over: batteryOut,
            limitText: '기준 ${TelemetryLimits.batteryMin.toStringAsFixed(1)}–'
                '${TelemetryLimits.batteryMax.toStringAsFixed(1)}V '
                '${batteryOut ? '밖' : '안'}',
          )
        else
          const MetricReading(
            kind: MetricKind.battery,
            label: '배터리 전압',
            valueText: missingText,
            unit: '',
            over: false,
            limitText: '차량이 보내지 않음 · 판정 안 함',
            available: false,
          ),
      ],
      extras: [
        if (fuel != null)
          ExtraReading(
            label: '연료',
            valueText: fuel.toStringAsFixed(1),
            unit: '%',
          )
        else
          const ExtraReading(
            label: '연료',
            valueText: missingText,
            unit: '',
            available: false,
          ),
        ExtraReading(
          label: '스로틀 개도',
          valueText: latest.throttlePosition.toStringAsFixed(1),
          unit: '%',
        ),
      ],
      dtcCodes: List.unmodifiable(latest.dtcCodes),
      receivedClock: clockText(receivedAt),
    );
  }

  /// 선택 센서(연료량·전압) 값이 레코드에 없을 때의 표기. 0이나 `—`(연결 문제의 빈자리)와 구분한다 —
  /// `—`는 "지금 수신 중이 아님", 이 낱말은 "수신 중이지만 차량이 이 값을 보내지 않음"이다.
  static const String missingText = '미수신';

  bool get isLive => connection == DashboardConnectionState.connected;

  /// 이 계측값을 화면에서 기준 초과로 드러낼지.
  bool showsOver(MetricReading reading) => isLive && reading.over;

  /// 요약에 쓰는 기준 초과 건수 — 기준을 넘은 계측값 수 + DTC가 있으면 1.
  /// 수신 중이 아니면 0이다(지난 값으로 판정하지 않는다).
  int get overCount {
    if (!isLive) return 0;
    return readings.where((r) => r.over).length + (dtcCodes.isEmpty ? 0 : 1);
  }

  static String clockText(DateTime t) =>
      '${_two(t.hour)}:${_two(t.minute)}:${_two(t.second)}';

  static String _two(int v) => v.toString().padLeft(2, '0');
  static String _n(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();
}
