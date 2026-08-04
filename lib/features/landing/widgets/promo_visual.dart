import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/arc_gauge.dart';

/// 제품을 아이콘+카드로 "설명"하는 대신, 실제 대시보드에서 쓰는 아크 게이지를
/// 그대로 히어로 비주얼로 세운다 — 로그인 전이라 실데이터는 없지만, 켜지는
/// 순간 0에서 목표값까지 스윕하는 연출로 "라이브 계기판"이라는 인상을 준다.
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
    // 카드가 뜨자마자 바로 차면 "이미 정지된 목업"처럼 보여서, 한 박자 쉬었다가
    // 스윕하도록 살짝 지연을 준다.
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _speed = 87);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _LivePulse(),
              const SizedBox(width: 8),
              const Text(
                'LIVE PREVIEW',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: AppTheme.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ArcGauge(
            value: _speed,
            maxValue: 220,
            label: '속도',
            unit: 'km/h',
            size: 200,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.bgElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
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
    return Column(
      children: [
        Text(value, style: AppTheme.gaugeNumberStyle(fontSize: 15)),
        const SizedBox(height: 2),
        Text(label,
            style:
                const TextStyle(fontSize: 10.5, color: AppTheme.textTertiary)),
      ],
    );
  }
}

class _VDivider extends StatelessWidget {
  const _VDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 28, color: AppTheme.border);
  }
}
