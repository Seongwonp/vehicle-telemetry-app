import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/arc_gauge.dart';

/// 대시보드 상단의 속도/RPM처럼 가장 중요한 지표 — 막대 대신 실물 계기판을
/// 흉내낸 아크 게이지(ArcGauge)로 보여준다.
class PrimaryMetricCard extends StatelessWidget {
  final String label;
  final double value;
  final double maxValue;
  final String unit;
  final IconData icon;
  final bool danger;
  final bool warning;

  const PrimaryMetricCard({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.unit,
    required this.icon,
    required this.danger,
    required this.warning,
    super.key,
  });

  Color get _accentColor {
    if (danger) return AppTheme.danger;
    if (warning) return AppTheme.warning;
    return AppTheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final color = _accentColor;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ArcGauge(
            value: value,
            maxValue: maxValue,
            label: label,
            unit: unit,
            danger: danger,
            warning: warning,
            color: color,
          ),
        ],
      ),
    );
  }
}
