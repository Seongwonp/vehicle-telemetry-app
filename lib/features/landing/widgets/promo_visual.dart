import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/arc_gauge.dart';
import '../../../core/theme/design_tokens.dart';

class PromoVisual extends StatefulWidget {
  const PromoVisual({super.key});

  @override
  State<PromoVisual> createState() => _PromoVisualState();
}

class _PromoVisualState extends State<PromoVisual> {
  double _speed = 0;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _speed = 87);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.fromLTRB(
          Spacing.xl, Spacing.lg, Spacing.xl, Spacing.xl),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _LivePulse(),
              const SizedBox(width: Spacing.xs),
              Text(
                'SAMPLE TELEMETRY',
                style: TextStyle(
                  fontSize: FontSizes.badge,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: colors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.xs),
          ArcGauge(
            value: _speed,
            maxValue: 220,
            label: '속도',
            unit: 'km/h',
            size: 200,
          ),
          const SizedBox(height: Spacing.lg),
          Container(
            padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
            decoration: BoxDecoration(
              color: colors.backgroundElevated,
              borderRadius: BorderRadius.circular(Radii.md),
              border: Border.all(color: colors.border),
            ),
            child: const Row(
              children: [
                Expanded(child: _MiniReadout(label: 'RPM', value: '2400')),
                _VDivider(),
                Expanded(child: _MiniReadout(label: '온도', value: '92°C')),
                _VDivider(),
                Expanded(child: _MiniReadout(label: '연료', value: '67%')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LivePulse extends StatefulWidget {
  @override
  State<_LivePulse> createState() => _LivePulseState();
}

class _LivePulseState extends State<_LivePulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.35, end: 1.0).animate(_controller),
      child: Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(
          color: AppTheme.primary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _MiniReadout extends StatelessWidget {
  final String label;
  final String value;
  const _MiniReadout({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      children: [
        Text(value,
            style: AppTheme.gaugeNumberStyle(
                fontSize: FontSizes.body, color: colors.textPrimary)),
        const SizedBox(height: Spacing.xxs),
        Text(label,
            style: TextStyle(
                fontSize: FontSizes.badge, color: colors.textTertiary)),
      ],
    );
  }
}

class _VDivider extends StatelessWidget {
  const _VDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 28, color: context.appColors.border);
  }
}
