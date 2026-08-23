import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class HeroSection extends StatelessWidget {
  final Animation<double> reveal;
  final VoidCallback onGetStarted;
  final bool alignLeft;

  const HeroSection({
    required this.reveal,
    required this.onGetStarted,
    this.alignLeft = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final primary = Theme.of(context).colorScheme.primary;
    final crossAlign =
        alignLeft ? CrossAxisAlignment.start : CrossAxisAlignment.center;
    final textAlign = alignLeft ? TextAlign.left : TextAlign.center;

    return AnimatedBuilder(
      animation: reveal,
      builder: (context, child) => Opacity(
        opacity: reveal.value,
        child: Transform.translate(
          offset: Offset(0, 24 * (1 - reveal.value)),
          child: child,
        ),
      ),
      child: Column(
        crossAxisAlignment: crossAlign,
        children: [
          SizedBox(
            height: 92,
            width: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primary.withOpacity(0.18),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                ),
                Image.asset('assets/logo_icon.png',
                    height: 72, fit: BoxFit.contain),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _StatusPill(),
          const SizedBox(height: 18),
          Text(
            '차량 상태와 데이터 흐름을\n한눈에 확인하기',
            textAlign: textAlign,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              height: 1.3,
              letterSpacing: -0.8,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '실시간 센서 값과 마지막 수신 시각,\n이상 이력을 한 화면에서 확인하세요',
            textAlign: textAlign,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: colors.textSecondary.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 36),
          _GetStartedButton(onTap: onGetStarted, alignLeft: alignLeft),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill();

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: primary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '텔레메트리 모니터링',
            style: AppTheme.gaugeNumberStyle(
              fontSize: 11,
              color: primary,
              weight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _GetStartedButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool alignLeft;
  const _GetStartedButton({required this.onTap, required this.alignLeft});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final primary = Theme.of(context).colorScheme.primary;
    final button = DecoratedBox(
      decoration: BoxDecoration(
        gradient: colors.primaryGradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.2),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '시작하기',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded,
                    size: 18, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );

    return alignLeft ? button : Center(child: button);
  }
}
