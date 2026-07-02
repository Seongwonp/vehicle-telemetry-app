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
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.4),
                  blurRadius: 50,
                  spreadRadius: 6,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset('assets/logo.png',
                  height: 84, width: 84, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'TELEMETRIX',
            textAlign: textAlign,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '차량 센서 데이터를 실시간으로 수집하고,\nAI가 이상 징후를 먼저 알아채는 텔레메트리 플랫폼',
            textAlign: textAlign,
            style: const TextStyle(
              fontSize: 15,
              height: 1.6,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          _GetStartedButton(onTap: onGetStarted, alignLeft: alignLeft),
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
    final button = DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.35),
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
                Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );

    return alignLeft ? button : Center(child: button);
  }
}
